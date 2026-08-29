import 'package:flutter/material.dart';

import '../../app/theme/color_tokens.dart';
import '../../core/services/storage_service.dart';
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

    final updated = memory.copyWith(
      title: newTitle,
      documentType: result.documentType ?? memory.documentType,
      categoryKey: result.categoryKey ?? memory.categoryKey,
      structuredFields: result.fields,
      confidence: result.overallConfidence ?? memory.confidence,
      understandingStatus: result.status,
      understoodAt: result.understoodAt ??
          (result.status == UnderstandingStatus.confirmed ? DateTime.now() : memory.understoodAt),
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
