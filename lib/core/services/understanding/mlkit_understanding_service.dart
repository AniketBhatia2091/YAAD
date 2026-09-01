import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../data/models/memory.dart';
import 'document_field_parser.dart';
import 'memory_understanding_service.dart';
import 'understanding_field.dart';
import 'understanding_result.dart';

/// Real on-device OCR service utilizing Google ML Kit text recognition.
class MlKitMemoryUnderstandingService implements MemoryUnderstandingService {
  final TextRecognizer _recognizer;

  MlKitMemoryUnderstandingService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<UnderstandingResult> understand(Memory memory) async {
    final imagePath = memory.imagePath;
    if (imagePath == null || imagePath.trim().isEmpty) {
      return const UnderstandingResult(status: UnderstandingStatus.failed);
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      return const UnderstandingResult(status: UnderstandingStatus.failed);
    }

    try {
      final inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        return const UnderstandingResult(
          status: UnderstandingStatus.needsReview,
          fields: [],
        );
      }

      final extractedMap = DocumentFieldParser.extractFields(rawText);
      final docType = extractedMap['documentType'];
      final categoryKey = DocumentFieldParser.categoryKeyFor(docType);

      final List<UnderstandingField> fields = [];
      extractedMap.forEach((key, val) {
        if (key != 'documentType') {
          fields.add(
            UnderstandingField(
              fieldName: key,
              value: val,
              confidence: FieldConfidence.medium,
              source: FieldSource.visible,
            ),
          );
        }
      });

      final bool hasExtractedInfo = docType != null || fields.isNotEmpty;
      final double overallConf = hasExtractedInfo ? 0.6 : 0.3;

      return UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: docType,
        categoryKey: categoryKey,
        fields: fields,
        overallConfidence: overallConf,
      );
    } catch (_) {
      return const UnderstandingResult(status: UnderstandingStatus.failed);
    }
  }

  /// Releases native ML Kit recognizer resources.
  void dispose() {
    _recognizer.close();
  }
}
