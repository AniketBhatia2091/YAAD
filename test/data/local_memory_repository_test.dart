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
  late StorageService storageService;
  late AppDatabase database;
  late LocalMemoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yaad_test_repo');
    storageService = StorageService(overrideAppDir: tempDir);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalMemoryRepository(
      storageService: storageService,
      database: database,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('LocalMemoryRepository creates and retrieves unclassified memory from SQLite', () async {
    final unclassifiedMemory = Memory.createUnclassified(
      id: 'uuid-rec-1',
      imagePath: '/fake/path/original.jpg',
    );

    await repository.createMemory(unclassifiedMemory);

    final fetched = await repository.getMemoryById('uuid-rec-1');
    expect(fetched, isNotNull);
    expect(fetched!.id, equals('uuid-rec-1'));
    expect(fetched.title, equals('Untitled memory'));
    expect(fetched.documentType, equals('unknown'));
    expect(fetched.categoryKey, equals('unsorted'));
    expect(fetched.subtitle, equals('Unclassified memory'));
    expect(fetched.metadata, equals('{}'));
  });

  test('LocalMemoryRepository persists all fields with exact values', () async {
    final now = DateTime(2026, 8, 29, 14, 0);
    final due = DateTime(2026, 9, 15);
    final memory = Memory(
      id: 'uuid-full-1',
      title: 'Water Bill',
      documentType: 'Bill',
      categoryKey: 'bills',
      imagePath: '/path/water.jpg',
      extractedText: 'Delhi Jal Board 850',
      createdAt: now,
      updatedAt: now,
      owner: 'Home',
      confidence: 0.98,
      dueDate: due,
      amount: 850.0,
      actionTitle: 'Pay Jal Board',
      actionSubtitle: 'By Sep 15',
      isAttentionRequired: true,
      subtitle: '₹850 · Due Sep 15',
      metadata: '{"service": "DJB"}',
    );

    await repository.createMemory(memory);

    final fetched = await repository.getMemoryById('uuid-full-1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'uuid-full-1');
    expect(fetched.title, 'Water Bill');
    expect(fetched.documentType, 'Bill');
    expect(fetched.categoryKey, 'bills');
    expect(fetched.imagePath, '/path/water.jpg');
    expect(fetched.extractedText, 'Delhi Jal Board 850');
    expect(fetched.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    expect(fetched.updatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    expect(fetched.owner, 'Home');
    expect(fetched.confidence, 0.98);
    expect(fetched.dueDate?.millisecondsSinceEpoch, due.millisecondsSinceEpoch);
    expect(fetched.amount, 850.0);
    expect(fetched.actionTitle, 'Pay Jal Board');
    expect(fetched.actionSubtitle, 'By Sep 15');
    expect(fetched.isAttentionRequired, isTrue);
    expect(fetched.subtitle, '₹850 · Due Sep 15');
    expect(fetched.metadata, '{"service": "DJB"}');
  });

  test('LocalMemoryRepository updates existing memory in SQLite', () async {
    final m = Memory.createUnclassified(id: 'uuid-upd-1', imagePath: '/path');
    await repository.createMemory(m);

    final updated = m.copyWith(
      title: 'Aadhaar Card Updated',
      documentType: 'ID',
      categoryKey: 'ids',
      actionTitle: 'Copy Aadhaar',
    );
    await repository.updateMemory(updated);

    final fetched = await repository.getMemoryById('uuid-upd-1');
    expect(fetched, isNotNull);
    expect(fetched!.title, equals('Aadhaar Card Updated'));
    expect(fetched.documentType, equals('ID'));
    expect(fetched.categoryKey, equals('ids'));
    expect(fetched.actionTitle, equals('Copy Aadhaar'));
  });

  test('LocalMemoryRepository places newly created memories at top of recent memories', () async {
    final m1 = Memory.createUnclassified(id: 'uuid-1', imagePath: '/path1').copyWith(
      createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    final m2 = Memory.createUnclassified(id: 'uuid-2', imagePath: '/path2');

    await repository.createMemory(m1);
    await repository.createMemory(m2);

    final recents = await repository.getRecentlyRemembered();
    expect(recents.length, greaterThanOrEqualTo(2));
    expect(recents[0].id, equals('uuid-2'));
    expect(recents[1].id, equals('uuid-1'));
  });

  test('LocalMemoryRepository searches persistent memories in SQLite', () async {
    final m = Memory(
      id: 'uuid-search-1',
      title: 'Reliance Jio Fiber Bill',
      documentType: 'Bill',
      categoryKey: 'bills',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      owner: 'Self',
      extractedText: 'Account 9876543210 Broadband',
      subtitle: 'Broadband Bill',
    );
    await repository.createMemory(m);

    // Search by title
    final byTitle = await repository.searchMemories('reliance');
    expect(byTitle.any((item) => item.id == 'uuid-search-1'), isTrue);

    // Search by extracted text
    final byText = await repository.searchMemories('broadband');
    expect(byText.any((item) => item.id == 'uuid-search-1'), isTrue);

    // Search non-existent
    final byNone = await repository.searchMemories('xyznonexistentterm');
    expect(byNone.isEmpty, isTrue);
  });

  test('LocalMemoryRepository deletes memory record and associated storage safely', () async {
    final dummyFile = File('${tempDir.path}/temp.jpg');
    await dummyFile.writeAsString('test_bytes');

    final persistentPath = await storageService.saveMemoryImage(
      memoryId: 'uuid-del-1',
      sourceImageFile: dummyFile,
    );

    final memory = Memory.createUnclassified(
      id: 'uuid-del-1',
      imagePath: persistentPath,
    );

    await repository.createMemory(memory);
    expect(await repository.getMemoryById('uuid-del-1'), isNotNull);

    // Delete memory
    await repository.deleteMemory('uuid-del-1');
    expect(await repository.getMemoryById('uuid-del-1'), isNull);
    expect(await File(persistentPath).exists(), isFalse);

    // Deleting again should be safe and not throw
    await repository.deleteMemory('uuid-del-1');
  });

  test('LocalMemoryRepository preserves demo memories alongside real ones', () async {
    // Demo memory mem_1 should be accessible
    final demoMemory = await repository.getMemoryById('mem_1');
    expect(demoMemory, isNotNull);
    expect(demoMemory!.title, equals('Electricity Bill'));

    // Creating real memory does not overwrite or remove demo memories
    final realMemory = Memory.createUnclassified(id: 'uuid-real-1', imagePath: '/path');
    await repository.createMemory(realMemory);

    final all = await repository.getAllMemories();
    expect(all.any((m) => m.id == 'uuid-real-1'), isTrue);
    expect(all.any((m) => m.id == 'mem_1'), isTrue);
  });

  test('LocalMemoryRepository updates understanding status and structured fields in SQLite', () async {
    final memory = Memory.createUnclassified(id: 'uuid-und-1', imagePath: '/path');
    await repository.createMemory(memory);

    const result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Health Insurance',
      categoryKey: 'medical',
      fields: [
        UnderstandingField(
          fieldName: 'policyNumber',
          value: 'HDFC-882910',
          confidence: FieldConfidence.high,
          source: FieldSource.visible,
        ),
      ],
    );

    await repository.updateUnderstanding('uuid-und-1', result);

    final fetched = await repository.getMemoryById('uuid-und-1');
    expect(fetched, isNotNull);
    expect(fetched!.understandingStatus, equals(UnderstandingStatus.confirmed));
    expect(fetched.documentType, equals('Health Insurance'));
    expect(fetched.categoryKey, equals('medical'));
    expect(fetched.structuredFields.length, equals(1));
    expect(fetched.structuredFields.first.fieldName, equals('policyNumber'));
    expect(fetched.structuredFields.first.value, equals('HDFC-882910'));

    // Search by structured field value
    final searchMatches = await repository.searchMemories('882910');
    expect(searchMatches.any((m) => m.id == 'uuid-und-1'), isTrue);
  });

  test('updateUnderstanding maps parsed amount, dueDate, and sets isAttentionRequired = true when <= 7 days', () async {
    final memory = Memory.createUnclassified(id: 'uuid-bill-1', imagePath: '/path/bill.jpg');
    await repository.createMemory(memory);

    final dueDateSoon = DateTime.now().add(const Duration(days: 3));
    final result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Bill',
      categoryKey: 'bills',
      amount: 1847.0,
      dueDate: dueDateSoon,
      fields: const [
        UnderstandingField(fieldName: 'amount', value: '₹1,847'),
        UnderstandingField(fieldName: 'dueDate', value: '06/09/2026'),
      ],
    );

    await repository.updateUnderstanding('uuid-bill-1', result);

    final fetched = await repository.getMemoryById('uuid-bill-1');
    expect(fetched, isNotNull);
    expect(fetched!.amount, equals(1847.0));
    expect(fetched.dueDate, isNotNull);
    expect(fetched.expiryDate, isNull);
    expect(fetched.isAttentionRequired, isTrue);

    // Verify it surfaces in Attention items query
    final attentionItems = await repository.getAttentionItems();
    expect(attentionItems.any((m) => m.id == 'uuid-bill-1'), isTrue);
  });

  test('updateUnderstanding maps parsed expiryDate, and sets isAttentionRequired = false when > 7 days (upcoming)', () async {
    final memory = Memory.createUnclassified(id: 'uuid-ins-1', imagePath: '/path/ins.jpg');
    await repository.createMemory(memory);

    final expiryLater = DateTime.now().add(const Duration(days: 25));
    final result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Insurance',
      categoryKey: 'vehicles',
      expiryDate: expiryLater,
      fields: const [
        UnderstandingField(fieldName: 'expiryDate', value: '28/09/2026'),
      ],
    );

    await repository.updateUnderstanding('uuid-ins-1', result);

    final fetched = await repository.getMemoryById('uuid-ins-1');
    expect(fetched, isNotNull);
    expect(fetched!.expiryDate, isNotNull);
    expect(fetched.dueDate, isNull);
    expect(fetched.isAttentionRequired, isFalse);

    // Verify it surfaces in Upcoming items query
    final upcomingItems = await repository.getUpcomingItems();
    expect(upcomingItems.any((m) => m.id == 'uuid-ins-1'), isTrue);
  });

  test('updateUnderstanding leaves amount/dates null and isAttentionRequired false when no amount/date found without throwing', () async {
    final memory = Memory.createUnclassified(id: 'uuid-aadhaar-1', imagePath: '/path/aadhaar.jpg');
    await repository.createMemory(memory);

    const result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Aadhaar Card',
      categoryKey: 'ids',
      fields: [
        UnderstandingField(fieldName: 'aadhaarNumber', value: 'XXXX XXXX 1234'),
      ],
    );

    await repository.updateUnderstanding('uuid-aadhaar-1', result);

    final fetched = await repository.getMemoryById('uuid-aadhaar-1');
    expect(fetched, isNotNull);
    expect(fetched!.amount, isNull);
    expect(fetched.dueDate, isNull);
    expect(fetched.expiryDate, isNull);
    expect(fetched.isAttentionRequired, isFalse);
  });

  test('updateUnderstanding fallback parses amount and date from structured fields if not in result root', () async {
    final memory = Memory.createUnclassified(id: 'uuid-fallback-1', imagePath: '/path/doc.jpg');
    await repository.createMemory(memory);

    final result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Bill',
      categoryKey: 'bills',
      fields: const [
        UnderstandingField(fieldName: 'amount', value: '₹3,500.50'),
        UnderstandingField(fieldName: 'dueDate', value: '15/10/2026'),
      ],
    );

    await repository.updateUnderstanding('uuid-fallback-1', result);

    final fetched = await repository.getMemoryById('uuid-fallback-1');
    expect(fetched, isNotNull);
    expect(fetched!.amount, equals(3500.5));
    expect(fetched.dueDate, equals(DateTime(2026, 10, 15)));
    expect(fetched.isAttentionRequired, isFalse); // Further out than 7 days
  });

  test('user edits dueDate and amount on review screen: fallback re-parses, overrides original parse, and recomputes isAttentionRequired', () async {
    final originalDueDate = DateTime.now().add(const Duration(days: 2));
    final memory = Memory.createUnclassified(id: 'uuid-edit-1', imagePath: '/path/bill.jpg').copyWith(
      documentType: 'Bill',
      categoryKey: 'bills',
      amount: 500.0,
      dueDate: originalDueDate,
      isAttentionRequired: true,
    );
    await repository.createMemory(memory);

    // Initial state: 2 days away -> isAttentionRequired is true
    final initial = await repository.getMemoryById('uuid-edit-1');
    expect(initial!.isAttentionRequired, isTrue);
    expect(initial.amount, equals(500.0));

    // User corrects dueDate to 25 days in the future (e.g. 29/09/2026) and amount to ₹1,200.50
    // Review screen passes confirmedResult with root amount/dueDate as null, only edited fields list
    const correctedDateStr = '29/09/2026';
    final correctedResult = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Bill',
      categoryKey: 'bills',
      amount: null,
      dueDate: null,
      expiryDate: null,
      fields: const [
        UnderstandingField(fieldName: 'amount', value: '₹1,200.50'),
        UnderstandingField(fieldName: 'dueDate', value: correctedDateStr),
      ],
    );

    await repository.updateUnderstanding('uuid-edit-1', correctedResult);

    final updated = await repository.getMemoryById('uuid-edit-1');
    expect(updated, isNotNull);
    // Amount must reflect the edited field, not original 500.0
    expect(updated!.amount, equals(1200.5));
    // DueDate must reflect the edited field (2026-09-29)
    expect(updated.dueDate, equals(DateTime(2026, 9, 29)));
    // isAttentionRequired must be recomputed off the corrected date (> 7 days -> false)
    expect(updated.isAttentionRequired, isFalse);
  });

  test('updateUnderstanding preserves user-edited custom subtitle and actionTitle on re-confirm pass', () async {
    final memory = Memory.createUnclassified(id: 'uuid-preserve-1', imagePath: '/path/bill.jpg').copyWith(
      documentType: 'Bill',
      categoryKey: 'bills',
      subtitle: 'Paid by Dad via NetBanking',
      actionTitle: 'Check Bank Statement',
    );
    await repository.createMemory(memory);

    final result = UnderstandingResult(
      status: UnderstandingStatus.confirmed,
      documentType: 'Bill',
      categoryKey: 'bills',
      fields: const [
        UnderstandingField(fieldName: 'amount', value: '₹1,847'),
        UnderstandingField(fieldName: 'dueDate', value: '05/09/2026'),
      ],
    );

    await repository.updateUnderstanding('uuid-preserve-1', result);

    final fetched = await repository.getMemoryById('uuid-preserve-1');
    expect(fetched, isNotNull);
    // Must NOT clobber the user's custom subtitle and actionTitle
    expect(fetched!.subtitle, equals('Paid by Dad via NetBanking'));
    expect(fetched.actionTitle, equals('Check Bank Statement'));
  });
}
