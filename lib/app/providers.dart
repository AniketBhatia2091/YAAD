import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/memory.dart';
import '../data/models/vault_category.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/mock_memory_repository.dart';
import '../data/repositories/onboarding_repository.dart';

/// Shared Preferences Provider initialized in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

/// Onboarding State Repository Provider
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs);
});

/// Onboarding Completed State Notifier
final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final repo = ref.watch(onboardingRepositoryProvider);
  return OnboardingNotifier(repo);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final OnboardingRepository _repo;

  OnboardingNotifier(this._repo) : super(_repo.isCompleted());

  Future<void> completeOnboarding() async {
    await _repo.setCompleted();
    state = true;
  }

  Future<void> resetOnboarding() async {
    await _repo.resetOnboarding();
    state = false;
  }
}

/// Memory Repository Provider (Defaults to MockMemoryRepository for YAAD v0.1)
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MockMemoryRepository();
});

/// Attention Items Provider
final attentionItemsProvider = FutureProvider<List<Memory>>((ref) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getAttentionItems();
});

/// Upcoming Items Provider
final upcomingItemsProvider = FutureProvider<List<Memory>>((ref) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getUpcomingItems();
});

/// Recently Remembered Provider
final recentlyRememberedProvider = FutureProvider<List<Memory>>((ref) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getRecentlyRemembered();
});

/// Vault Categories Provider
final vaultCategoriesProvider = FutureProvider<List<VaultCategory>>((ref) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getVaultCategories();
});

/// Search Query State
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search Results Provider
final searchResultsProvider = FutureProvider<List<Memory>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.searchMemories(query);
});
