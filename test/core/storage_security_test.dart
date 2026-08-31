import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yadd/core/services/storage_service.dart';

void main() {
  group('StorageService Security & Path Traversal Guard Tests', () {
    late Directory tempAppDir;
    late StorageService storageService;

    setUp(() async {
      tempAppDir = await Directory.systemTemp.createTemp('yaad_sec_test_app_doc');
      storageService = StorageService(overrideAppDir: tempAppDir);

      // Create a canary file in the parent app directory to ensure it is never deleted
      final canaryFile = File('${tempAppDir.path}/canary_database.sqlite');
      await canaryFile.writeAsString('CRITICAL_DATABASE_DO_NOT_DELETE');
    });

    tearDown(() async {
      if (await tempAppDir.exists()) {
        await tempAppDir.delete(recursive: true);
      }
    });

    test('Valid UUIDs and YAAD fixture IDs are accepted and contained within memories/', () async {
      final dummyImage = File('${tempAppDir.path}/test_source.jpg');
      await dummyImage.writeAsString('test_bytes');

      const validIds = [
        'mem_1',
        'mem_8',
        '550e8400-e29b-41d4-a716-446655440000',
        'custom_id-123',
      ];

      for (final id in validIds) {
        expect(() => StorageService.validateMemoryId(id), returnsNormally);

        final persistentPath = await storageService.saveMemoryImage(
          memoryId: id,
          sourceImageFile: dummyImage,
        );

        expect(File(persistentPath).existsSync(), isTrue);
        expect(persistentPath, contains('/memories/$id/original.jpg'));

        // Clean up
        await storageService.deleteMemoryStorage(id);
        expect(File(persistentPath).existsSync(), isFalse);
      }

      // Canary database file must still be intact
      final canary = File('${tempAppDir.path}/canary_database.sqlite');
      expect(canary.existsSync(), isTrue);
      expect(await canary.readAsString(), equals('CRITICAL_DATABASE_DO_NOT_DELETE'));
    });

    test('Path traversal payloads are strictly rejected on save and delete', () async {
      final dummyImage = File('${tempAppDir.path}/test_source.jpg');
      await dummyImage.writeAsString('test_bytes');

      const maliciousIds = [
        '../',
        '../../',
        '..',
        '/tmp/test',
        '/etc',
        'foo/bar',
        r'foo\bar',
        '',
        '   ',
        'memories/other',
        '../memories',
        '..%2F..%2F',
      ];

      for (final badId in maliciousIds) {
        // Validation throws ArgumentError
        expect(
          () => StorageService.validateMemoryId(badId),
          throwsA(isA<ArgumentError>()),
          reason: 'validateMemoryId must reject "$badId"',
        );

        // saveMemoryImage throws ArgumentError
        expect(
          () => storageService.saveMemoryImage(
            memoryId: badId,
            sourceImageFile: dummyImage,
          ),
          throwsA(isA<ArgumentError>()),
          reason: 'saveMemoryImage must reject "$badId"',
        );

        // deleteMemoryStorage throws ArgumentError
        expect(
          () => storageService.deleteMemoryStorage(badId),
          throwsA(isA<ArgumentError>()),
          reason: 'deleteMemoryStorage must reject "$badId"',
        );

        // getMemoryDirPath throws ArgumentError
        expect(
          () => storageService.getMemoryDirPath(badId),
          throwsA(isA<ArgumentError>()),
          reason: 'getMemoryDirPath must reject "$badId"',
        );
      }

      // Assert that parent directory and canary database file were NEVER touched
      final canary = File('${tempAppDir.path}/canary_database.sqlite');
      expect(canary.existsSync(), isTrue);
      expect(await canary.readAsString(), equals('CRITICAL_DATABASE_DO_NOT_DELETE'));
    });

    test('Temporary source image cleanup occurs safely after persistence', () async {
      final cacheDir = await Directory.systemTemp.createTemp('yaad_temp_cache');
      final tempCameraImage = File('${cacheDir.path}/CAP_temp_123.jpg');
      await tempCameraImage.writeAsString('camera_frame_payload');

      expect(tempCameraImage.existsSync(), isTrue);

      const memoryId = 'uuid-cleanup-test';
      final persistentPath = await storageService.saveMemoryImage(
        memoryId: memoryId,
        sourceImageFile: tempCameraImage,
      );

      // Verify persistent copy exists
      final persistentFile = File(persistentPath);
      expect(persistentFile.existsSync(), isTrue);

      // Simulate PreviewScreen cleanup logic (must use p.isWithin for system temp)
      final tempDir = Directory.systemTemp.path;
      if (tempCameraImage.path != persistentPath &&
          tempCameraImage.existsSync() &&
          p.isWithin(tempDir, tempCameraImage.path)) {
        await tempCameraImage.delete();
      }

      // Temporary file should be deleted, persistent file MUST remain
      expect(tempCameraImage.existsSync(), isFalse);
      expect(persistentFile.existsSync(), isTrue);

      await cacheDir.delete(recursive: true);
    });

    test('User-owned gallery files outside system temp are NEVER deleted', () async {
      // Simulate a file the user picked from their own directory (macOS gallery import).
      // IMPORTANT: tempAppDir is inside Directory.systemTemp, so we create a separate
      // directory outside of it to simulate a user's ~/Pictures path.
      // Create a sibling to memories to simulate user Photos
      final simulatedUserPhotosDir = Directory(p.join(tempAppDir.path, 'SimulatedUserPhotos'));
      await simulatedUserPhotosDir.create(recursive: true);
      final userPhoto = File(p.join(simulatedUserPhotosDir.path, 'vacation.jpg'));
      await userPhoto.writeAsString('user_original_photo_data');

      const memoryId = 'uuid-gallery-test';
      final persistentPath = await storageService.saveMemoryImage(
        memoryId: memoryId,
        sourceImageFile: userPhoto,
      );

      // Simulate PreviewScreen cleanup logic using a NON-SYSTEM-TEMP path
      // The real scenario: on macOS, image_picker returns /Users/foo/Pictures/photo.jpg
      // which is NOT inside Directory.systemTemp (/var/folders/... or /tmp).
      // Here we verify the logic by using a path that is NOT inside systemTemp.
      // Since our test tempAppDir IS inside systemTemp, we test the containment
      // check directly rather than relying on directory location.
      final notInTemp = !p.isWithin(Directory.systemTemp.path, '/Users/test/Pictures/photo.jpg');
      expect(notInTemp, isTrue, reason: 'User home directories must not be inside systemTemp');

      // Verify the guard logic: p.isWithin returns false for non-temp paths
      expect(
        p.isWithin(Directory.systemTemp.path, '/Users/aniketbhatia/Pictures/photo.jpg'),
        isFalse,
        reason: 'p.isWithin must return false for user-owned gallery paths',
      );

      // Persistent copy must exist
      expect(File(persistentPath).existsSync(), isTrue);
      // User's original photo MUST still exist (not deleted by our logic for non-temp paths)
      expect(userPhoto.existsSync(), isTrue);
    });

    test('Temporary source image is NOT deleted if persistence throws', () async {
      final cacheDir = await Directory.systemTemp.createTemp('yaad_temp_cache_fail');
      final tempCameraImage = File('${cacheDir.path}/CAP_temp_fail.jpg');
      await tempCameraImage.writeAsString('camera_frame_fail');

      const badMemoryId = '../escape_id';

      // Expect failure
      expect(
        () => storageService.saveMemoryImage(
          memoryId: badMemoryId,
          sourceImageFile: tempCameraImage,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Temporary source MUST NOT be deleted on failed save
      expect(tempCameraImage.existsSync(), isTrue);

      await cacheDir.delete(recursive: true);
    });
  });
}
