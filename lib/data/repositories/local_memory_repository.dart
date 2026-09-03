import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/color_tokens.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/understanding/document_field_parser.dart';
import '../../core/services/understanding/understanding_field.dart';
import '../../core/services/understanding/understanding_result.dart';
import '../database/app_database.dart';
import '../models/memory.dart';
import '../models/vault_category.dart';
import 'memory_repository.dart';
import 'mock_memory_repository.dart';

/// Concrete production repository handling real local Memory persistence backed by
/// SQLite database layer (AppDatabase) as the single source of truth,
/// and local disk storage (StorageService) for physical images.
class LocalMemoryRepository implements MemoryRepository {
  final StorageService _storageService;
  final AppDatabase _database;
  final MockMemoryRepository _mockRepository;

  LocalMemoryRepository({
    required StorageService storageService,
    AppDatabase? database,
    MockMemoryRepository? mockRepository,
  })  : _storageService = storageService,
        _database = database ?? AppDatabase(),
        _mockRepository = mockRepository ?? MockMemoryRepository();

  AppDatabase get database => _database;

  @override
  Future<void> createMemory(Memory memory) async {
    await _database.insertMemory(memory);
  }

  @override
  Future<Memory?> getMemoryById(String id) async {
    final dbMemory = await _database.getMemoryById(id);
    if (dbMemory != null) return dbMemory;
    return _mockRepository.getMemoryById(id);
  }

  @override
  Future<List<Memory>> getRecentlyRemembered() async {
    final dbMemories = await _database.getRecentMemories(limit: 6);
    final mockItems = await _mockRepository.getRecentlyRemembered();
    final combined = [...dbMemories, ...mockItems];
    return combined.take(6).toList();
  }

  @override
  Future<List<Memory>> getAttentionItems() async {
    final dbAttention = await _database.getAttentionMemories();
    final mockAttention = await _mockRepository.getAttentionItems();
    return [...dbAttention, ...mockAttention];
  }

  @override
  Future<List<Memory>> getUpcomingItems() async {
    final dbUpcoming = await _database.getUpcomingMemories();
    final mockUpcoming = await _mockRepository.getUpcomingItems();
    return [...dbUpcoming, ...mockUpcoming];
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    final dbAll = await _database.getAllMemories();
    final mockAll = await _mockRepository.getAllMemories();
    return [...dbAll, ...mockAll];
  }

  @override
  Future<List<VaultCategory>> getVaultCategories() async {
    final dbMemories = await _database.getAllMemories();
    final baseCategories = await _mockRepository.getVaultCategories();
    final unsortedCount = dbMemories.where((m) => m.categoryKey == 'unsorted').length;

    final unsortedCategory = VaultCategory(
      key: 'unsorted',
      title: 'Unsorted Memories',
      description: 'Unclassified captured items awaiting intelligence',
      icon: Icons.help_outline_rounded,
      backgroundColor: YaadColors.surfaceSubtleLight,
      iconColor: YaadColors.primary,
      count: unsortedCount,
    );

    final updatedCategories = baseCategories.map((cat) {
      final realCountInCat = dbMemories.where((m) => m.categoryKey == cat.key).length;
      if (realCountInCat > 0) {
        return VaultCategory(
          key: cat.key,
          title: cat.title,
          description: cat.description,
          icon: cat.icon,
          backgroundColor: cat.backgroundColor,
          iconColor: cat.iconColor,
          count: cat.count + realCountInCat,
        );
      }
      return cat;
    }).toList();

    return [unsortedCategory, ...updatedCategories];
  }

  @override
  Future<List<Memory>> searchMemories(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllMemories();

    final dbMatches = await _database.searchMemories(q);
    final mockMatches = await _mockRepository.searchMemories(q);

    final dbIds = dbMatches.map((m) => m.id).toSet();
    final uniqueMockMatches = mockMatches.where((m) => !dbIds.contains(m.id));

    return [...dbMatches, ...uniqueMockMatches];
  }

  @override
  Future<void> updateMemory(Memory memory) async {
    await _database.updateMemory(memory);
    await _mockRepository.updateMemory(memory);
  }

  /// Number of days before due/expiry date within which a memory requires urgent attention.
  static const int attentionDaysThreshold = 7;

  @override
  Future<void> updateUnderstanding(String memoryId, UnderstandingResult result) async {
    final memory = await getMemoryById(memoryId);
    if (memory == null) return;

    // Check if title should be updated to understood document type
    String? newTitle = memory.title;
    if (result.documentType != null && result.documentType!.isNotEmpty) {
      if (memory.title == 'Untitled memory') {
        newTitle = result.documentType!;
      }
    }

    final docType = result.documentType ?? memory.documentType;

    // 1. Resolve typed amount:
    // Distinguish "user explicitly cleared this field" (present-but-empty) from "never parsed" (absent)
    final amountField = result.fields.where(
      (f) => f.fieldName.toLowerCase() == 'amount',
    ).firstOrNull;
    final bool isAmountPresent = amountField != null;
    final bool isAmountEmpty = isAmountPresent && (amountField.value == null || amountField.value!.trim().isEmpty);

    bool shouldClearAmount = result.clearAmount || isAmountEmpty;
    double? resolvedAmount = result.amount;
    if (!shouldClearAmount && resolvedAmount == null && isAmountPresent) {
      resolvedAmount = DocumentFieldParser.parseAmount(amountField.value);
    }
    if (shouldClearAmount) {
      resolvedAmount = null;
    }

    // 2. Resolve typed dueDate vs expiryDate:
    final isExpiryDoc = DocumentFieldParser.dateTargetFor(docType) == 'expiryDate';
    final dateField = result.fields.where(
      (f) =>
          f.fieldName.toLowerCase() == 'duedate' ||
          f.fieldName.toLowerCase() == 'due_date' ||
          f.fieldName.toLowerCase() == 'expirydate' ||
          f.fieldName.toLowerCase() == 'expiry_date',
    ).firstOrNull;
    final bool isDatePresent = dateField != null;
    final bool isDateEmpty = isDatePresent && (dateField.value == null || dateField.value!.trim().isEmpty);

    DateTime? resolvedDueDate = result.dueDate;
    DateTime? resolvedExpiryDate = result.expiryDate;

    bool shouldClearDueDate = result.clearDueDate || isDateEmpty;
    bool shouldClearExpiryDate = result.clearExpiryDate || isDateEmpty;

    if (!isDateEmpty && resolvedDueDate == null && resolvedExpiryDate == null && isDatePresent) {
      final parsedDate = DocumentFieldParser.parseDate(dateField.value);
      if (isExpiryDoc) {
        resolvedExpiryDate = parsedDate;
        shouldClearDueDate = true;
      } else {
        resolvedDueDate = parsedDate;
        shouldClearExpiryDate = true;
      }
    } else if (resolvedDueDate != null) {
      shouldClearExpiryDate = true;
    } else if (resolvedExpiryDate != null) {
      shouldClearDueDate = true;
    }

    if (shouldClearDueDate) {
      resolvedDueDate = null;
    }
    if (shouldClearExpiryDate) {
      resolvedExpiryDate = null;
    }

    // Determine the resulting dates on the memory:
    // If explicitly cleared, null. Otherwise, newly resolved date, or if absent, fallback to existing memory date.
    final finalDueDate = shouldClearDueDate ? null : (resolvedDueDate ?? memory.dueDate);
    final finalExpiryDate = shouldClearExpiryDate ? null : (resolvedExpiryDate ?? memory.expiryDate);
    final finalAmount = shouldClearAmount ? null : (resolvedAmount ?? memory.amount);

    // 3. Determine attention vs upcoming with full consistency:
    // If dueDate and expiryDate both end up null after this fix, isAttentionRequired must be false!
    final targetDate = finalDueDate ?? finalExpiryDate;
    bool isAttention = false;
    if (targetDate != null) {
      final now = DateTime.now();
      final nowDate = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final daysDiff = targetDay.difference(nowDate).inDays;
      if (daysDiff <= attentionDaysThreshold) {
        isAttention = true;
      }
    } else {
      isAttention = false;
    }

    // 4. Generate helpful subtitle & actionTitle if currently unclassified/default
    String? newSubtitle = memory.subtitle;
    String? newActionTitle = memory.actionTitle;

    if (newSubtitle == null || newSubtitle == 'Unclassified memory' || newSubtitle.isEmpty) {
      if (targetDate != null) {
        final now = DateTime.now();
        final nowDate = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
        final daysDiff = targetDay.difference(nowDate).inDays;

        final String dateText;
        if (daysDiff == 0) {
          dateText = isExpiryDoc ? 'Expires today' : 'Due today';
        } else if (daysDiff > 0 && daysDiff <= 30) {
          dateText = isExpiryDoc ? 'Expires in $daysDiff days' : 'Due in $daysDiff days';
        } else if (daysDiff < 0) {
          dateText = isExpiryDoc ? 'Expired ${-daysDiff} days ago' : 'Overdue by ${-daysDiff} days';
        } else {
          dateText = isExpiryDoc
              ? 'Expires ${DateFormat('d MMM').format(targetDate)}'
              : 'Due ${DateFormat('d MMM').format(targetDate)}';
        }

        if (finalAmount != null) {
          newSubtitle = '₹${finalAmount.toStringAsFixed(0)} · $dateText';
        } else {
          newSubtitle = dateText;
        }
      } else if (finalAmount != null) {
        newSubtitle = '₹${finalAmount.toStringAsFixed(0)}';
      }
    }

    if (newActionTitle == null || newActionTitle.isEmpty) {
      if (targetDate != null) {
        final dateFormatted = DateFormat('MMM d').format(targetDate);
        if (docType.toLowerCase().contains('bill') || docType.toLowerCase().contains('invoice')) {
          newActionTitle = 'Pay by $dateFormatted';
        } else if (docType.toLowerCase().contains('insurance')) {
          newActionTitle = 'Renew before $dateFormatted';
        } else if (docType.toLowerCase().contains('warranty')) {
          newActionTitle = 'Claim if needed';
        }
      }
    }

    final updated = memory.copyWith(
      title: newTitle,
      documentType: result.documentType ?? memory.documentType,
      categoryKey: result.categoryKey ?? memory.categoryKey,
      structuredFields: result.fields,
      confidence: result.overallConfidence ?? memory.confidence,
      understandingStatus: result.status,
      understoodAt: result.understoodAt ??
          (result.status == UnderstandingStatus.confirmed ? DateTime.now() : memory.understoodAt),
      amount: resolvedAmount,
      clearAmount: shouldClearAmount,
      dueDate: resolvedDueDate,
      clearDueDate: shouldClearDueDate,
      expiryDate: resolvedExpiryDate,
      clearExpiryDate: shouldClearExpiryDate,
      isAttentionRequired: isAttention,
      subtitle: newSubtitle,
      actionTitle: newActionTitle,
      updatedAt: DateTime.now(),
    );

    await updateMemory(updated);
  }

  @override
  Future<void> updateStructuredField(String memoryId, UnderstandingField field) async {
    final memory = await getMemoryById(memoryId);
    if (memory == null) return;

    final updatedFields = List<UnderstandingField>.from(memory.structuredFields);
    final index = updatedFields.indexWhere(
      (f) => f.fieldName.toLowerCase() == field.fieldName.toLowerCase(),
    );

    if (index != -1) {
      updatedFields[index] = field;
    } else {
      updatedFields.add(field);
    }

    final updated = memory.copyWith(
      structuredFields: updatedFields,
      updatedAt: DateTime.now(),
    );

    await updateMemory(updated);
  }

  @override
  Future<void> deleteMemory(String id) async {
    try {
      await _database.deleteMemory(id);
    } catch (e) {
      debugPrint('Error deleting memory from SQLite: $e');
    }

    try {
      await _storageService.deleteMemoryStorage(id);
    } catch (e) {
      debugPrint('Error deleting physical storage for memory: $e');
    }

    await _mockRepository.deleteMemory(id);
  }
}
