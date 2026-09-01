import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/understanding/document_field_parser.dart';

void main() {
  group('DocumentFieldParser Tests', () {
    test('extractFields classifies document types accurately (case-insensitive)', () {
      expect(
        DocumentFieldParser.extractFields('ELECTRICITY BILL FOR AUGUST')['documentType'],
        equals('Bill'),
      );
      expect(
        DocumentFieldParser.extractFields('Tax Invoice for BoAt BoAt BoAt')['documentType'],
        equals('Bill'),
      );
      expect(
        DocumentFieldParser.extractFields('Two Wheeler Vehicle Insurance Policy')['documentType'],
        equals('Insurance'),
      );
      expect(
        DocumentFieldParser.extractFields('Medical Prescription - Take 1 Tablet daily (50mg)')['documentType'],
        equals('Prescription'),
      );
      expect(
        DocumentFieldParser.extractFields('Limited 1-Year Warranty Certificate')['documentType'],
        equals('Warranty'),
      );
      expect(
        DocumentFieldParser.extractFields('Government of India AADHAAR CARD')['documentType'],
        equals('Aadhaar Card'),
      );
      expect(
        DocumentFieldParser.extractFields('Aadhar Number XXXX XXXX 1234')['documentType'],
        equals('Aadhaar Card'),
      );
    });

    test('extractFields extracts amount with currency symbols, commas, and decimals', () {
      final res1 = DocumentFieldParser.extractFields('Total Amount Payable: ₹1,847.50 due soon');
      expect(res1['amount'], equals('₹1,847.50'));

      final res2 = DocumentFieldParser.extractFields('Net Charge Rs. 500 only');
      expect(res2['amount'], equals('Rs. 500'));

      final res3 = DocumentFieldParser.extractFields('Paid INR 12,500 via UPI');
      expect(res3['amount'], equals('INR 12,500'));
    });

    test('extractFields extracts dueDate in numeric and month-name formats with mixed casing', () {
      final resNumericSlash = DocumentFieldParser.extractFields('Due date: 05/09/2026 before 5 PM');
      expect(resNumericSlash['dueDate'], equals('05/09/2026'));

      final resNumericDash = DocumentFieldParser.extractFields('Expires on: 10-12-2026');
      expect(resNumericDash['dueDate'], equals('10-12-2026'));

      final resNamedMonth = DocumentFieldParser.extractFields('Valid till 5 Sep 2026');
      expect(resNamedMonth['dueDate'], equals('5 Sep 2026'));

      final resNamedMonthUpper = DocumentFieldParser.extractFields('DUE DATE 15 OCTOBER 2026');
      expect(resNamedMonthUpper['dueDate'], equals('15 OCTOBER 2026'));
    });

    test('extractFields returns empty map for blank or unmatching text', () {
      expect(DocumentFieldParser.extractFields(''), isEmpty);
      expect(DocumentFieldParser.extractFields('   \n  '), isEmpty);
      expect(DocumentFieldParser.extractFields('Random text without keywords or amounts'), isEmpty);
    });

    test('categoryKeyFor maps document types to vault category keys correctly', () {
      expect(DocumentFieldParser.categoryKeyFor('Bill'), equals('bills'));
      expect(DocumentFieldParser.categoryKeyFor('Insurance'), equals('vehicles'));
      expect(DocumentFieldParser.categoryKeyFor('Prescription'), equals('medical'));
      expect(DocumentFieldParser.categoryKeyFor('Warranty'), equals('warranties'));
      expect(DocumentFieldParser.categoryKeyFor('Aadhaar Card'), equals('ids'));
      expect(DocumentFieldParser.categoryKeyFor('Unknown'), isNull);
      expect(DocumentFieldParser.categoryKeyFor(null), isNull);
    });
  });
}
