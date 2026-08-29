import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/storage_service.dart';
import 'package:yadd/core/services/understanding/understanding_field.dart';
import 'package:yadd/core/services/understanding/understanding_result.dart';
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
    expect(billsCategory.count, greaterThanOrEqualTo(6));

    await dbB.close();
  });

  test('Understanding Persistence: Structured fields, confirmed status, and category survive database restart', () async {
    final now = DateTime(2026, 8, 29, 16, 0);

    // 1. Session 1: Create an unclassified memory
    final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
    final storage1 = StorageService(overrideAppDir: tempDir);
    final repo1 = LocalMemoryRepository(storageService: storage1, database: db1);

    final unclassified = Memory.createUnclassified(
      id: 'uuid-understand-test',
      imagePath: '/fake/path/original.jpg',
    );
    await repo1.createMemory(unclassified);

    // 2. Perform understanding & confirmation in Session 1
    final understandingResult = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Electricity Bill',
      categoryKey: 'bills',
      overallConfidence: 0.96,
      understoodAt: now,
      fields: const [
        UnderstandingField(
          fieldName: 'provider',
          value: 'BSES Rajdhani',
          confidence: FieldConfidence.high,
          source: FieldSource.visible,
        ),
        UnderstandingField(
          fieldName: 'amount',
          value: '₹2,340',
          confidence: FieldConfidence.high,
          source: FieldSource.visible,
        ),
        UnderstandingField(
          fieldName: 'dueDate',
          value: '12 Sep 2026',
          confidence: FieldConfidence.high,
          source: FieldSource.visible,
        ),
      ],
    );

    await repo1.updateUnderstanding('uuid-understand-test', understandingResult);

    // Close Session 1
    await db1.close();

    // 3. Session 2: Fresh database instance loads the same file
    final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
    final storage2 = StorageService(overrideAppDir: tempDir);
    final repo2 = LocalMemoryRepository(storageService: storage2, database: db2);

    final retrieved = await repo2.getMemoryById('uuid-understand-test');
    expect(retrieved, isNotNull);
    expect(retrieved!.id, equals('uuid-understand-test'));
    expect(retrieved.understandingStatus, equals(UnderstandingStatus.confirmed));
    expect(retrieved.documentType, equals('Electricity Bill'));
    expect(retrieved.categoryKey, equals('bills'));
    expect(retrieved.understoodAt?.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    expect(retrieved.structuredFields.length, equals(3));

    final providerField = retrieved.structuredFields.firstWhere((f) => f.fieldName == 'provider');
    expect(providerField.value, equals('BSES Rajdhani'));
    expect(providerField.confidence, equals(FieldConfidence.high));
    expect(providerField.source, equals(FieldSource.visible));

    final amountField = retrieved.structuredFields.firstWhere((f) => f.fieldName == 'amount');
    expect(amountField.value, equals('₹2,340'));

    // Search by structured field value across restart
    final searchByProvider = await repo2.searchMemories('Rajdhani');
    expect(searchByProvider.any((m) => m.id == 'uuid-understand-test'), isTrue);

    // Search by structured field amount across restart
    final searchByAmount = await repo2.searchMemories('2,340');
    expect(searchByAmount.any((m) => m.id == 'uuid-understand-test'), isTrue);

    // Verify it moved to the Bills category in Vault across restart
    final categories = await repo2.getVaultCategories();
    final billsCategory = categories.firstWhere((c) => c.key == 'bills');
    expect(billsCategory.count, greaterThanOrEqualTo(6));

    // 4. Update structured field and verify persistence
    const editedAmount = UnderstandingField(
      fieldName: 'amount',
      value: '₹2,500',
      confidence: FieldConfidence.unknown,
      source: FieldSource.visible,
    );
    await repo2.updateStructuredField('uuid-understand-test', editedAmount);

    final afterEdit = await repo2.getMemoryById('uuid-understand-test');
    final updatedAmountField = afterEdit!.structuredFields.firstWhere((f) => f.fieldName == 'amount');
    expect(updatedAmountField.value, equals('₹2,500'));
    expect(updatedAmountField.confidence, equals(FieldConfidence.unknown));

    await db2.close();
  });
}
