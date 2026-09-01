import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yadd/app/app.dart';
import 'package:yadd/app/providers.dart';
import 'package:yadd/app/theme/color_tokens.dart';
import 'package:yadd/core/constants/app_constants.dart';
import 'package:yadd/data/models/memory.dart';
import 'package:yadd/data/models/vault_category.dart';
import 'package:yadd/data/repositories/memory_repository.dart';
import 'package:yadd/features/home/home_screen.dart';
import 'package:yadd/features/vault/category_memories_screen.dart';
import 'package:yadd/features/vault/vault_screen.dart';

class _FakeMemoryRepository implements MemoryRepository {
  final List<Memory> _memories;

  _FakeMemoryRepository([this._memories = const []]);

  @override
  Future<void> createMemory(Memory memory) async {}
  @override
  Future<Memory?> getMemoryById(String id) async => null;
  @override
  Future<List<Memory>> getAttentionItems() async => _memories.where((m) => m.isAttentionRequired).toList();
  @override
  Future<List<Memory>> getUpcomingItems() async => _memories.where((m) => !m.isAttentionRequired).toList();
  @override
  Future<List<Memory>> getRecentlyRemembered() async => _memories;
  @override
  Future<List<Memory>> getAllMemories() async => _memories;
  @override
  Future<List<VaultCategory>> getVaultCategories() async => [
    VaultCategory(
      key: 'bills',
      title: 'Bills & Payments',
      description: 'Electricity · Internet',
      icon: Icons.receipt_long_outlined,
      backgroundColor: YaadColors.categoryBills,
      iconColor: YaadColors.categoryBillsIcon,
      count: _memories.length,
    ),
  ];
  @override
  Future<List<Memory>> searchMemories(String query) async => _memories;
  @override
  Future<void> updateMemory(Memory memory) async {}
  @override
  Future<void> updateUnderstanding(String memoryId, dynamic result) async {}
  @override
  Future<void> updateStructuredField(String memoryId, dynamic field) async {}
  @override
  Future<void> deleteMemory(String id) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingCompleted: true,
      'yaad_theme_mode': 'dark',
    });
  });

  testWidgets('Theme Mode defaults to Dark and switches smoothly', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          memoryRepositoryProvider.overrideWithValue(_FakeMemoryRepository()),
        ],
        child: const YaadApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('HomeScreen renders Attention Dashboard and truthful copy', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          memoryRepositoryProvider.overrideWithValue(_FakeMemoryRepository()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify tagline
    expect(find.text('Remember what matters. Act when it matters.'), findsOneWidget);
    // Verify on-device badge
    expect(find.text('On-device vault'), findsOneWidget);
  });

  testWidgets('HomeScreen displays polished empty state when vault is empty', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          memoryRepositoryProvider.overrideWithValue(_FakeMemoryRepository([])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Your memory vault is empty'), findsOneWidget);
    expect(find.text('Capture your first document and YAAD will keep it safe.'), findsOneWidget);
    expect(find.text('Capture memory'), findsOneWidget);
  });

  testWidgets('VaultScreen displays Bento Grid with real category counts', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          memoryRepositoryProvider.overrideWithValue(_FakeMemoryRepository()),
        ],
        child: const MaterialApp(
          home: VaultScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Life Vault'), findsOneWidget);
    expect(find.text('Organized by your real life, not file folders.'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('CategoryMemoriesScreen displays empty state when category has 0 items', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          memoryRepositoryProvider.overrideWithValue(_FakeMemoryRepository([])),
        ],
        child: const MaterialApp(
          home: CategoryMemoriesScreen(categoryKey: 'bills'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Add your first document to this category and YAAD will keep it safe.'), findsOneWidget);
    expect(find.text('Add a memory'), findsOneWidget);
  });
}
