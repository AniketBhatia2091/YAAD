import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/storage_service.dart';
import 'package:yadd/data/database/app_database.dart';
import 'package:yadd/data/models/memory.dart';
import 'package:yadd/data/repositories/local_memory_repository.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yaad_persistence_test');
    dbFile = File('${tempDir.path}/yaad_persistence.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Simulate App Restart: Database A writes memory, closes; Database B opens same file and retrieves it', () async {
    final now = DateTime(2026, 8, 29, 12, 0);

    // 1. First "Session": App runs with Database Instance A
    final dbA = AppDatabase.forTesting(NativeDatabase(dbFile));
    final storageA = StorageService(overrideAppDir: tempDir);
    final repoA = LocalMemoryRepository(
      storageService: storageA,
      database: dbA,
    );

    final memory = Memory(
      id: 'uuid-persistent-100',
      title: 'Electricity Bill Sep',
      documentType: 'Bill',
      categoryKey: 'bills',
      imagePath: '/path/to/original.jpg',
      extractedText: 'BSES Yamuna ₹1847',
      createdAt: now,
      updatedAt: now,
      owner: 'Self',
      confidence: 0.95,
      expiryDate: null,
      dueDate: DateTime(2026, 9, 5),
      amount: 1847.0,
      actionTitle: 'Pay Bill',
      actionSubtitle: 'Due in 7 days',
      isAttentionRequired: true,
      subtitle: '₹1,847 · Due Sep 5',
      metadata: '{"provider": "BSES Yamuna"}',
    );

    await repoA.createMemory(memory);

    // Verify it exists in Session A
    final memoryInSessionA = await repoA.getMemoryById('uuid-persistent-100');
    expect(memoryInSessionA, isNotNull);
    expect(memoryInSessionA!.title, 'Electricity Bill Sep');

    // Close Database A (simulating app process termination)
    await dbA.close();

    // 2. Second "Session": App relaunches with fresh Database Instance B pointing to same SQLite file
    final dbB = AppDatabase.forTesting(NativeDatabase(dbFile));
    final storageB = StorageService(overrideAppDir: tempDir);
    final repoB = LocalMemoryRepository(
      storageService: storageB,
      database: dbB,
    );

    final memoryInSessionB = await repoB.getMemoryById('uuid-persistent-100');
    expect(memoryInSessionB, isNotNull, reason: 'Memory must survive app restart in SQLite');
    expect(memoryInSessionB!.id, equals('uuid-persistent-100'));
    expect(memoryInSessionB.title, equals('Electricity Bill Sep'));
    expect(memoryInSessionB.documentType, equals('Bill'));
    expect(memoryInSessionB.categoryKey, equals('bills'));
    expect(memoryInSessionB.imagePath, equals('/path/to/original.jpg'));
    expect(memoryInSessionB.extractedText, equals('BSES Yamuna ₹1847'));
    expect(memoryInSessionB.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    expect(memoryInSessionB.owner, equals('Self'));
    expect(memoryInSessionB.confidence, equals(0.95));
    expect(memoryInSessionB.amount, equals(1847.0));
    expect(memoryInSessionB.actionTitle, equals('Pay Bill'));
    expect(memoryInSessionB.actionSubtitle, equals('Due in 7 days'));
    expect(memoryInSessionB.isAttentionRequired, isTrue);
    expect(memoryInSessionB.subtitle, equals('₹1,847 · Due Sep 5'));
    expect(memoryInSessionB.metadata, equals('{"provider": "BSES Yamuna"}'));

    // Search also works across restart
    final searchResults = await repoB.searchMemories('BSES');
    expect(searchResults.any((m) => m.id == 'uuid-persistent-100'), isTrue);

    // Vault category count reflects persistent memory
    final categories = await repoB.getVaultCategories();
    final billsCategory = categories.firstWhere((c) => c.key == 'bills');
    // Base mock count is 5 + 1 real memory = 6
    expect(billsCategory.count, greaterThanOrEqualTo(6));

    await dbB.close();
  });
}
