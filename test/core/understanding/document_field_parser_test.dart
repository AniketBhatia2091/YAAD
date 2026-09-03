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

    test('parseAmount parses currencies, commas, and decimals into double', () {
      expect(DocumentFieldParser.parseAmount('₹1,847.50'), equals(1847.5));
      expect(DocumentFieldParser.parseAmount('₹1,847'), equals(1847.0));
      expect(DocumentFieldParser.parseAmount('Rs. 500'), equals(500.0));
      expect(DocumentFieldParser.parseAmount('Rs 2,500'), equals(2500.0));
      expect(DocumentFieldParser.parseAmount('INR 12,500'), equals(12500.0));
      expect(DocumentFieldParser.parseAmount('99.99'), equals(99.99));
      expect(DocumentFieldParser.parseAmount(''), isNull);
      expect(DocumentFieldParser.parseAmount('   '), isNull);
      expect(DocumentFieldParser.parseAmount(null), isNull);
      expect(DocumentFieldParser.parseAmount('no-numbers'), isNull);
    });

    test('parseDate parses numeric and named month formats accurately into DateTime', () {
      expect(DocumentFieldParser.parseDate('05/09/2026'), equals(DateTime(2026, 9, 5)));
      expect(DocumentFieldParser.parseDate('10-12-2026'), equals(DateTime(2026, 12, 10)));
      expect(DocumentFieldParser.parseDate('5 Sep 2026'), equals(DateTime(2026, 9, 5)));
      expect(DocumentFieldParser.parseDate('15 OCTOBER 2026'), equals(DateTime(2026, 10, 15)));
      expect(DocumentFieldParser.parseDate('1 Jan 2027'), equals(DateTime(2027, 1, 1)));
      expect(DocumentFieldParser.parseDate(''), isNull);
      expect(DocumentFieldParser.parseDate('   '), isNull);
      expect(DocumentFieldParser.parseDate(null), isNull);
      expect(DocumentFieldParser.parseDate('invalid-date'), isNull);
    });

    test('dateTargetFor classifies expiry vs due dates correctly', () {
      expect(DocumentFieldParser.dateTargetFor('Insurance'), equals('expiryDate'));
      expect(DocumentFieldParser.dateTargetFor('Warranty'), equals('expiryDate'));
      expect(DocumentFieldParser.dateTargetFor('PUC'), equals('expiryDate'));
      expect(DocumentFieldParser.dateTargetFor('Vehicle PUC'), equals('expiryDate'));
      expect(DocumentFieldParser.dateTargetFor('Bill'), equals('dueDate'));
      expect(DocumentFieldParser.dateTargetFor('Prescription'), equals('dueDate'));
      expect(DocumentFieldParser.dateTargetFor('Unknown'), equals('dueDate'));
      expect(DocumentFieldParser.dateTargetFor(null), equals('dueDate'));
    });

    test('parse method returns typed fields alongside raw fields', () {
      final parsedBill = DocumentFieldParser.parse('ELECTRICITY BILL Total Amount: ₹1,847 Due: 05/09/2026');
      expect(parsedBill.documentType, equals('Bill'));
      expect(parsedBill.categoryKey, equals('bills'));
      expect(parsedBill.rawAmount, equals('₹1,847'));
      expect(parsedBill.amount, equals(1847.0));
      expect(parsedBill.rawDate, equals('05/09/2026'));
      expect(parsedBill.date, equals(DateTime(2026, 9, 5)));
      expect(parsedBill.dateTarget, equals('dueDate'));
      expect(parsedBill.dueDate, equals(DateTime(2026, 9, 5)));
      expect(parsedBill.expiryDate, isNull);

      final parsedInsurance = DocumentFieldParser.parse('Vehicle Insurance Policy Expires on: 10-12-2026');
      expect(parsedInsurance.documentType, equals('Insurance'));
      expect(parsedInsurance.categoryKey, equals('vehicles'));
      expect(parsedInsurance.dateTarget, equals('expiryDate'));
      expect(parsedInsurance.expiryDate, equals(DateTime(2026, 12, 10)));
      expect(parsedInsurance.dueDate, isNull);

      final emptyParsed = DocumentFieldParser.parse('');
      expect(emptyParsed.documentType, isNull);
      expect(emptyParsed.amount, isNull);
      expect(emptyParsed.date, isNull);
    });
  });
}
