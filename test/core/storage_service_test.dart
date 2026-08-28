import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yaad_test_app_doc');
    storageService = StorageService(overrideAppDir: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('StorageService copies source image file to memories/<memoryId>/original.jpg', () async {
    // Create temp source image file
    final sourceFile = File('${tempDir.path}/temp_capture.jpg');
    await sourceFile.writeAsString('mock_image_bytes_12345');

    const memoryId = 'test-uuid-999';
    final persistentPath = await storageService.saveMemoryImage(
      memoryId: memoryId,
      sourceImageFile: sourceFile,
    );

    final savedFile = File(persistentPath);
    expect(await savedFile.exists(), isTrue);
    expect(persistentPath, contains('/memories/test-uuid-999/original.jpg'));
    expect(await savedFile.readAsString(), equals('mock_image_bytes_12345'));
  });

  test('StorageService deletion removes physical memory directory from disk', () async {
    final sourceFile = File('${tempDir.path}/temp_capture.jpg');
    await sourceFile.writeAsString('mock_image_bytes_to_delete');

    const memoryId = 'test-uuid-delete-111';
    final persistentPath = await storageService.saveMemoryImage(
      memoryId: memoryId,
      sourceImageFile: sourceFile,
    );

    final savedFile = File(persistentPath);
    expect(await savedFile.exists(), isTrue);

    // Delete memory storage
    await storageService.deleteMemoryStorage(memoryId);
    expect(await savedFile.exists(), isFalse);
  });
}
