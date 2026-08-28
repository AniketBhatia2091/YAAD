import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/storage_service.dart';
import 'package:yadd/data/models/memory.dart';
import 'package:yadd/data/repositories/local_memory_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late LocalMemoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yaad_test_repo');
    storageService = StorageService(overrideAppDir: tempDir);
    repository = LocalMemoryRepository(storageService: storageService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('LocalMemoryRepository creates and retrieves unclassified memory', () async {
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
  });

  test('LocalMemoryRepository places newly created memories at top of recent memories', () async {
    final m1 = Memory.createUnclassified(id: 'uuid-1', imagePath: '/path1');
    final m2 = Memory.createUnclassified(id: 'uuid-2', imagePath: '/path2');

    await repository.createMemory(m1);
    await repository.createMemory(m2);

    final recents = await repository.getRecentlyRemembered();
    expect(recents.length, greaterThanOrEqualTo(2));
    expect(recents[0].id, equals('uuid-2'));
    expect(recents[1].id, equals('uuid-1'));
  });

  test('LocalMemoryRepository deletes memory record and associated storage', () async {
    // Create physical dummy file
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
  });
}
