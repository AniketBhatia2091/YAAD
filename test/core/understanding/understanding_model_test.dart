import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/understanding/understanding_field.dart';
import 'package:yadd/core/services/understanding/understanding_result.dart';

void main() {
  group('Understanding Models Tests', () {
    test('FieldConfidence and FieldSource enum values are correct', () {
      expect(FieldConfidence.values, containsAll([
        FieldConfidence.high,
        FieldConfidence.medium,
        FieldConfidence.low,
        FieldConfidence.unknown,
      ]));

      expect(FieldSource.values, containsAll([
        FieldSource.visible,
        FieldSource.inferred,
        FieldSource.unknown,
      ]));

      expect(UnderstandingStatus.values, containsAll([
        UnderstandingStatus.unknown,
        UnderstandingStatus.processing,
        UnderstandingStatus.needsReview,
        UnderstandingStatus.confirmed,
        UnderstandingStatus.failed,
      ]));
    });

    test('UnderstandingField serializes to and deserializes from JSON accurately', () {
      const field = UnderstandingField(
        fieldName: 'amount',
        value: '₹1,847',
        confidence: FieldConfidence.high,
        source: FieldSource.visible,
      );

      final json = field.toJson();
      expect(json['fieldName'], equals('amount'));
      expect(json['value'], equals('₹1,847'));
      expect(json['confidence'], equals('high'));
      expect(json['source'], equals('visible'));

      final deserialized = UnderstandingField.fromJson(json);
      expect(deserialized, equals(field));
      expect(deserialized.displayLabel, equals('Amount'));
    });

    test('UnderstandingField handles null and missing values safely', () {
      final json = <String, dynamic>{
        'fieldName': 'account_number',
        'value': null,
        'confidence': 'unknown',
        'source': 'unknown',
      };

      final field = UnderstandingField.fromJson(json);
      expect(field.fieldName, equals('account_number'));
      expect(field.value, isNull);
      expect(field.confidence, equals(FieldConfidence.unknown));
      expect(field.source, equals(FieldSource.unknown));
      expect(field.displayLabel, equals('Account / Doc Number'));
    });

    test('UnderstandingField copyWith works as expected', () {
      const field = UnderstandingField(
        fieldName: 'dueDate',
        value: '5 Sep 2026',
        confidence: FieldConfidence.high,
        source: FieldSource.visible,
      );

      final edited = field.copyWith(
        value: '6 Sep 2026',
        confidence: FieldConfidence.unknown,
      );

      expect(edited.fieldName, equals('dueDate'));
      expect(edited.value, equals('6 Sep 2026'));
      expect(edited.confidence, equals(FieldConfidence.unknown));
      expect(edited.source, equals(FieldSource.visible));
    });

    test('UnderstandingResult serializes to and deserializes from JSON accurately', () {
      final understoodTime = DateTime(2026, 8, 29, 15, 30);
      final result = UnderstandingResult(
        status: UnderstandingStatus.confirmed,
        documentType: 'Electricity Bill',
        categoryKey: 'bills',
        overallConfidence: 0.95,
        understoodAt: understoodTime,
        fields: const [
          UnderstandingField(
            fieldName: 'provider',
            value: 'BSES',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
          UnderstandingField(
            fieldName: 'amount',
            value: '1847',
            confidence: FieldConfidence.high,
            source: FieldSource.visible,
          ),
        ],
      );

      final json = result.toJson();
      expect(json['status'], equals('confirmed'));
      expect(json['documentType'], equals('Electricity Bill'));
      expect(json['categoryKey'], equals('bills'));
      expect(json['overallConfidence'], equals(0.95));

      final deserialized = UnderstandingResult.fromJson(json);
      expect(deserialized.status, equals(UnderstandingStatus.confirmed));
      expect(deserialized.documentType, equals('Electricity Bill'));
      expect(deserialized.categoryKey, equals('bills'));
      expect(deserialized.fields.length, equals(2));
      expect(deserialized.fields.first.fieldName, equals('provider'));
      expect(deserialized.fields.first.value, equals('BSES'));
    });

    test('UnderstandingResult copyWith works as expected', () {
      const result = UnderstandingResult(
        status: UnderstandingStatus.needsReview,
        documentType: 'Bill',
      );

      final confirmed = result.copyWith(
        status: UnderstandingStatus.confirmed,
        categoryKey: 'bills',
      );

      expect(confirmed.status, equals(UnderstandingStatus.confirmed));
      expect(confirmed.documentType, equals('Bill'));
      expect(confirmed.categoryKey, equals('bills'));
    });
  });
}
