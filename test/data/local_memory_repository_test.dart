import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/storage_service.dart';
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
}
