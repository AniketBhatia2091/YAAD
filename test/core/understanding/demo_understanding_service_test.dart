import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/understanding/demo_understanding_service.dart';
import 'package:yadd/core/services/understanding/understanding_field.dart';
import 'package:yadd/core/services/understanding/understanding_result.dart';
import 'package:yadd/data/models/memory.dart';

void main() {
  group('DemoMemoryUnderstandingService Tests', () {
    late DemoMemoryUnderstandingService service;

    setUp(() {
      service = DemoMemoryUnderstandingService();
    });

    test('mem_1 yields deterministic expected bill fields with high confidence', () async {
      final billMemory = Memory(
        id: 'mem_1',
        title: 'Electricity Bill',
        documentType: 'Bill',
        categoryKey: 'bills',
        owner: 'Home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        extractedText: 'BSES Yamuna Power Limited. Account: 102938475. Amount: ₹1847. Due Date: Sep 5.',
      );

      final result = await service.understand(billMemory);

      expect(result.status, equals(UnderstandingStatus.needsReview));
      expect(result.documentType, equals('Electricity Bill'));
      expect(result.categoryKey, equals('bills'));
      expect(result.overallConfidence, greaterThanOrEqualTo(0.9));
      expect(result.fields.isNotEmpty, isTrue);

      final fieldMap = {for (var f in result.fields) f.fieldName: f.value};
      expect(fieldMap['documentType'], equals('Electricity Bill'));
      expect(fieldMap['provider'], equals('BSES Yamuna'));
      expect(fieldMap['amount'], equals('₹1,847'));
      expect(fieldMap['dueDate'], equals('5 Sep 2026'));
      expect(fieldMap['accountNumber'], equals('••••••8475'));

      // Check confidence & sources
      for (final f in result.fields) {
        expect(f.confidence, equals(FieldConfidence.high));
        expect(f.source, equals(FieldSource.visible));
      }
    });

    test('mem_2 yields expected insurance fields', () async {
      final insuranceMemory = Memory(
        id: 'mem_2',
        title: 'Bike Insurance',
        documentType: 'Insurance',
        categoryKey: 'vehicles',
        owner: 'Vehicle',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await service.understand(insuranceMemory);

      expect(result.status, equals(UnderstandingStatus.needsReview));
      expect(result.documentType, equals('Two-Wheeler Insurance'));
      expect(result.categoryKey, equals('vehicles'));

      final fieldMap = {for (var f in result.fields) f.fieldName: f.value};
      expect(fieldMap['provider'], equals('ICICI Lombard'));
      expect(fieldMap['policyNumber'], equals('3005/1829384'));
      expect(fieldMap['expiryDate'], equals('10 Sep 2026'));
    });

    test('Real captured memory with no extracted text produces needsReview with zero fabricated fields', () async {
      final realCapturedMemory = Memory.createUnclassified(
        id: 'real-uuid-capture-123',
        imagePath: '/data/user/0/com.yaad.app/app_flutter/memories/real-uuid-capture-123/original.jpg',
      );

      final result = await service.understand(realCapturedMemory);

      // Must require review and NOT fabricate fields
      expect(result.status, equals(UnderstandingStatus.needsReview));
      expect(result.documentType, isNull);
      expect(result.categoryKey, isNull);
      expect(result.fields, isEmpty, reason: 'Must not fabricate fields from real unextracted images');
      expect(result.overallConfidence, isNull);
    });
  });
}
