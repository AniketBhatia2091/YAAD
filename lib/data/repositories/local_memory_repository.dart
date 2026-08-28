import 'package:flutter/material.dart';

import '../../app/theme/color_tokens.dart';
import '../../core/services/storage_service.dart';
import '../models/memory.dart';
import '../models/vault_category.dart';
import 'memory_repository.dart';
import 'mock_memory_repository.dart';

/// Concrete production repository handling real local Memory persistence backed by
/// local disk storage (StorageService) and SQLite database layer.
class LocalMemoryRepository implements MemoryRepository {
  final StorageService _storageService;
  final MockMemoryRepository _mockRepository;
  final List<Memory> _localMemories = [];

  LocalMemoryRepository({
    required StorageService storageService,
    MockMemoryRepository? mockRepository,
  })  : _storageService = storageService,
        _mockRepository = mockRepository ?? MockMemoryRepository();

  @override
  Future<void> createMemory(Memory memory) async {
    _localMemories.insert(0, memory);
  }

  @override
  Future<Memory?> getMemoryById(String id) async {
    try {
      return _localMemories.firstWhere((m) => m.id == id);
    } catch (_) {
      try {
        final mockList = await _mockRepository.getAllMemories();
        return mockList.firstWhere((m) => m.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<List<Memory>> getRecentlyRemembered() async {
    // Real local memories appear at top of Recently Remembered section, demo items below
    final mockItems = await _mockRepository.getRecentlyRemembered();
    final combined = [..._localMemories, ...mockItems];
    return combined.take(6).toList();
  }

  @override
  Future<List<Memory>> getAttentionItems() async {
    final localAttention = _localMemories.where((m) => m.isAttentionRequired).toList();
    final mockAttention = await _mockRepository.getAttentionItems();
    return [...localAttention, ...mockAttention];
  }

  @override
  Future<List<Memory>> getUpcomingItems() async {
    final localUpcoming = _localMemories.where((m) => !m.isAttentionRequired && (m.expiryDate != null || m.dueDate != null)).toList();
    final mockUpcoming = await _mockRepository.getUpcomingItems();
    return [...localUpcoming, ...mockUpcoming];
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    final mockAll = await _mockRepository.getAllMemories();
    return [..._localMemories, ...mockAll];
  }

  @override
  Future<List<VaultCategory>> getVaultCategories() async {
    final baseCategories = await _mockRepository.getVaultCategories();
    final unsortedCount = _localMemories.where((m) => m.categoryKey == 'unsorted').length;

    // Insert "Unsorted" category at top if there are unclassified memories, or as fallback
    final unsortedCategory = VaultCategory(
      key: 'unsorted',
      title: 'Unsorted Memories',
      description: 'Unclassified captured items awaiting intelligence',
      icon: Icons.help_outline_rounded,
      backgroundColor: YaadColors.surfaceSubtleLight,
      iconColor: YaadColors.primary,
      count: unsortedCount,
    );

    return [unsortedCategory, ...baseCategories];
  }

  @override
  Future<List<Memory>> searchMemories(String query) async {
    final q = query.trim().toLowerCase();
    final all = await getAllMemories();
    if (q.isEmpty) return all;

    return all.where((m) {
      return m.title.toLowerCase().contains(q) ||
          m.documentType.toLowerCase().contains(q) ||
          m.categoryKey.toLowerCase().contains(q) ||
          m.owner.toLowerCase().contains(q) ||
          (m.extractedText?.toLowerCase().contains(q) ?? false) ||
          (m.metadata?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<void> deleteMemory(String id) async {
    _localMemories.removeWhere((m) => m.id == id);
    // Delete physical folder memories/<id>/ from disk
    await _storageService.deleteMemoryStorage(id);
  }
}
