// DEMO / DEVELOPMENT ONLY
//
// This service provides deterministic local extraction for testing the YAAD
// Understanding & Review UX flow.
// It DOES NOT perform real OCR, and DOES NOT call any external AI / Vision APIs.
// Real on-device Vision/OCR implementations will be plugged in via the
// [MemoryUnderstandingService] interface in future releases.

import '../../../data/models/memory.dart';
import 'memory_understanding_service.dart';
import 'understanding_field.dart';
import 'understanding_result.dart';

class DemoMemoryUnderstandingService implements MemoryUnderstandingService {
  @override
  Future<UnderstandingResult> understand(Memory memory) async {
    // Deterministic instant or near-instant processing
    await Future.delayed(const Duration(milliseconds: 150));

    // Handle seeded demo memories with known metadata
    if (memory.id == 'mem_1' || memory.title.toLowerCase().contains('electricity bill')) {
      return const UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Electricity Bill',
        categoryKey: 'bills',
        overallConfidence: 0.95,
        fields: [
          UnderstandingField(
            fieldName: 'documentType',
            value: 'Electricity Bill',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'provider',
            value: 'BSES Yamuna',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'amount',
            value: '₹1,847',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'dueDate',
            value: '5 Sep 2026',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'accountNumber',
            value: '••••••8475',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
        ],
      );
    }

    if (memory.id == 'mem_2' || memory.title.toLowerCase().contains('bike insurance')) {
      return const UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Two-Wheeler Insurance',
        categoryKey: 'vehicles',
        overallConfidence: 0.92,
        fields: [
          UnderstandingField(
            fieldName: 'documentType',
            value: 'Two-Wheeler Insurance',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'provider',
            value: 'ICICI Lombard',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'policyNumber',
            value: '3005/1829384',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'expiryDate',
            value: '10 Sep 2026',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
        ],
      );
    }

    if (memory.id == 'mem_3' || memory.title.toLowerCase().contains('medicine')) {
      return const UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Prescription',
        categoryKey: 'medical',
        overallConfidence: 0.88,
        fields: [
          UnderstandingField(
            fieldName: 'documentType',
            value: 'Prescription',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'person',
            value: 'Mom',
            confidence: FieldConfidence.medium,
            source: FieldSource.inferred,
          ),
          UnderstandingField(
            fieldName: 'medicine',
            value: 'Thyronorm 50mcg',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'dosage',
            value: '2 tablets daily after dinner',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
        ],
      );
    }

    if (memory.id == 'mem_4' || memory.title.toLowerCase().contains('warranty')) {
      return const UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Warranty',
        categoryKey: 'warranties',
        overallConfidence: 0.85,
        fields: [
          UnderstandingField(
            fieldName: 'documentType',
            value: 'Warranty Invoice',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'provider',
            value: 'boAt',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'documentNumber',
            value: 'INV-92837',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'warrantyEnd',
            value: '1 Year Warranty',
            confidence: FieldConfidence.medium,
            source: FieldSource.visible,
          ),
        ],
      );
    }

    if (memory.id == 'mem_7' || memory.title.toLowerCase().contains('aadhaar')) {
      return const UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Aadhaar Card',
        categoryKey: 'ids',
        overallConfidence: 0.98,
        fields: [
          UnderstandingField(
            fieldName: 'documentType',
            value: 'Aadhaar Card',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'documentNumber',
            value: 'XXXX XXXX 8921',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'person',
            value: 'Self',
            confidence: FieldConfidence.medium,
            source: FieldSource.inferred,
          ),
        ],
      );
    }

    // For real captured memories where no OCR has run yet:
    // Return needsReview with NO fabricated fields.
    return const UnderstandingResult(
      status: UnderstandingStatus.needsReview,
      documentType: null,
      categoryKey: null,
      fields: [],
      overallConfidence: null,
      understoodAt: null,
    );
  }
}
