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

      final parsed = DocumentFieldParser.parse(rawText);
      final docType = parsed.documentType;
      final categoryKey = parsed.categoryKey;

      final List<UnderstandingField> fields = [];
      parsed.rawFields.forEach((key, val) {
        if (key != 'documentType') {
          final fieldName = (key == 'dueDate' && parsed.dateTarget == 'expiryDate')
              ? 'expiryDate'
              : key;
          fields.add(
            UnderstandingField(
              fieldName: fieldName,
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
        amount: parsed.amount,
        dueDate: parsed.dueDate,
        expiryDate: parsed.expiryDate,
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
