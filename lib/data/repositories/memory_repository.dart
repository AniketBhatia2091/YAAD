import '../models/memory.dart';
import '../models/vault_category.dart';

/// Abstract repository contract for YAAD memories.
/// decouples UI features from Drift SQLite database or mock repositories.
abstract class MemoryRepository {
  Future<List<Memory>> getAttentionItems();
  Future<List<Memory>> getUpcomingItems();
  Future<List<Memory>> getRecentlyRemembered();
  Future<List<Memory>> getAllMemories();
  Future<List<VaultCategory>> getVaultCategories();
  Future<List<Memory>> searchMemories(String query);
  Future<void> addMemory(Memory memory);
  Future<void> deleteMemory(String id);
}
