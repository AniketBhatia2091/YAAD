import '../../../data/models/memory.dart';
import 'understanding_result.dart';

/// Pluggable interface for Memory Understanding implementations.
///
/// Designed so future real AI/OCR implementations (on-device Tesseract,
/// ML Kit, or vision models) can be swapped in without modifying UI/consumers.
abstract class MemoryUnderstandingService {
  Future<UnderstandingResult> understand(Memory memory);
}
