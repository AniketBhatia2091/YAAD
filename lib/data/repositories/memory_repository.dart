import '../../core/services/understanding/understanding_field.dart';
import '../../core/services/understanding/understanding_result.dart';
import '../models/memory.dart';
import '../models/vault_category.dart';

/// Abstract repository contract for YAAD memories.
abstract class MemoryRepository {
  Future<void> createMemory(Memory memory);
  Future<Memory?> getMemoryById(String id);
  Future<List<Memory>> getAttentionItems();
  Future<List<Memory>> getUpcomingItems();
  Future<List<Memory>> getRecentlyRemembered();
  Future<List<Memory>> getAllMemories();
  Future<List<VaultCategory>> getVaultCategories();
  Future<List<Memory>> searchMemories(String query);
  Future<void> updateMemory(Memory memory);
  Future<void> deleteMemory(String id);

  // v0.8 Understanding & Review Pipeline operations
  Future<void> updateUnderstanding(String memoryId, UnderstandingResult result);
  Future<void> updateStructuredField(String memoryId, UnderstandingField field);
}
