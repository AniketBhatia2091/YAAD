import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// StorageService manages persistent local file storage for YAAD memories.
///
/// IMMUTABILITY GUARANTEE:
/// The captured/imported original image is saved as `original.jpg` inside an application-controlled
/// persistent directory (`memories/<memory-uuid>/original.jpg`). It is never overwritten or
/// destructively modified.
class StorageService {
  final Directory? _overrideAppDir;

  StorageService({Directory? overrideAppDir}) : _overrideAppDir = overrideAppDir;

  Future<Directory> _getAppDocDir() async {
    if (_overrideAppDir != null) return _overrideAppDir!;
    return await getApplicationDocumentsDirectory();
  }

  /// Copies an image file into `<ApplicationDocumentsDirectory>/memories/<memoryId>/original.jpg`.
  /// Returns the absolute persistent file path.
  Future<String> saveMemoryImage({
    required String memoryId,
    required File sourceImageFile,
  }) async {
    final appDir = await _getAppDocDir();
    final memoryDir = Directory(p.join(appDir.path, 'memories', memoryId));

    if (!await memoryDir.exists()) {
      await memoryDir.create(recursive: true);
    }

    final destinationPath = p.join(memoryDir.path, 'original.jpg');
    final destinationFile = await sourceImageFile.copy(destinationPath);
    return destinationFile.path;
  }

  /// Deletes the entire local directory for a memory (including original.jpg).
  Future<void> deleteMemoryStorage(String memoryId) async {
    final appDir = await _getAppDocDir();
    final memoryDir = Directory(p.join(appDir.path, 'memories', memoryId));

    if (await memoryDir.exists()) {
      await memoryDir.delete(recursive: true);
    }
  }

  /// Returns the persistent memory directory path for a memory ID.
  Future<String> getMemoryDirPath(String memoryId) async {
    final appDir = await _getAppDocDir();
    return p.join(appDir.path, 'memories', memoryId);
  }
}
