import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// StorageService manages persistent local file storage for YAAD memories.
///
/// IMMUTABILITY GUARANTEE:
/// The captured/imported original image is saved as `original.jpg` inside an application-controlled
/// persistent directory (`memories/<memory-uuid>/original.jpg`). It is never overwritten or
/// destructively modified.
///
/// SECURITY GUARANTEE:
/// All memory IDs are strictly validated to prevent path traversal. All operations are strictly
/// constrained to reside within `<ApplicationDocumentsDirectory>/memories/`.
class StorageService {
  final Directory? _overrideAppDir;

  static final RegExp _validIdRegex = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');

  StorageService({Directory? overrideAppDir}) : _overrideAppDir = overrideAppDir;

  /// Validates that a memory ID is safe, non-empty, and free of path traversal sequences.
  static void validateMemoryId(String memoryId) {
    final trimmed = memoryId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(memoryId, 'memoryId', 'Memory ID cannot be empty or whitespace.');
    }
    if (memoryId != trimmed ||
        memoryId.contains('..') ||
        memoryId.contains('/') ||
        memoryId.contains('\\') ||
        p.isAbsolute(memoryId) ||
        !_validIdRegex.hasMatch(memoryId)) {
      throw ArgumentError.value(
        memoryId,
        'memoryId',
        'Invalid memory ID: contains illegal path characters, path traversal segments, or exceeds maximum length.',
      );
    }
  }

  Future<Directory> _getAppDocDir() async {
    if (_overrideAppDir != null) return _overrideAppDir!;
    return await getApplicationDocumentsDirectory();
  }

  /// Resolves the canonical directory for [memoryId] and asserts that it remains strictly
  /// contained within the application's root `memories` directory.
  Future<Directory> _resolveSafeMemoryDir(String memoryId) async {
    validateMemoryId(memoryId);

    final appDir = await _getAppDocDir();
    final memoriesRootDir = Directory(p.join(appDir.path, 'memories'));
    final canonicalRoot = p.canonicalize(memoriesRootDir.path);

    final targetDir = Directory(p.join(canonicalRoot, memoryId));
    final canonicalTarget = p.canonicalize(targetDir.path);

    if (!p.isWithin(canonicalRoot, canonicalTarget)) {
      throw ArgumentError.value(
        memoryId,
        'memoryId',
        'Path traversal violation: memory ID escapes the memories directory.',
      );
    }

    return targetDir;
  }

  /// Copies an image file into `<ApplicationDocumentsDirectory>/memories/<memoryId>/original.jpg`.
  /// Returns the absolute persistent file path.
  Future<String> saveMemoryImage({
    required String memoryId,
    required File sourceImageFile,
  }) async {
    final memoryDir = await _resolveSafeMemoryDir(memoryId);

    if (!await memoryDir.exists()) {
      await memoryDir.create(recursive: true);
    }

    final destinationPath = p.join(memoryDir.path, 'original.jpg');
    final destinationFile = await sourceImageFile.copy(destinationPath);
    return destinationFile.path;
  }

  /// Deletes the entire local directory for a memory (including original.jpg).
  /// Strictly prevents deleting root memories or any external directories.
  Future<void> deleteMemoryStorage(String memoryId) async {
    final memoryDir = await _resolveSafeMemoryDir(memoryId);

    if (await memoryDir.exists()) {
      await memoryDir.delete(recursive: true);
    }
  }

  /// Returns the persistent memory directory path for a memory ID.
  Future<String> getMemoryDirPath(String memoryId) async {
    final memoryDir = await _resolveSafeMemoryDir(memoryId);
    return memoryDir.path;
  }
}
