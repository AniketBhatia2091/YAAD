import '../lib/core/services/understanding/document_field_parser.dart';

void main() {
  print('=== Running DocumentFieldParser Direct Tests ===');

  // Test 1: Document type classification
  _assertEq(DocumentFieldParser.extractFields('ELECTRICITY BILL FOR AUGUST')['documentType'], 'Bill', 'Bill classification');
  _assertEq(DocumentFieldParser.extractFields('Tax Invoice for BoAt')['documentType'], 'Bill', 'Invoice classification');
  _assertEq(DocumentFieldParser.extractFields('Two Wheeler Vehicle Insurance Policy')['documentType'], 'Insurance', 'Insurance classification');
  _assertEq(DocumentFieldParser.extractFields('Medical Prescription - Take 1 Tablet daily (50mg)')['documentType'], 'Prescription', 'Prescription classification');
  _assertEq(DocumentFieldParser.extractFields('Limited 1-Year Warranty Certificate')['documentType'], 'Warranty', 'Warranty classification');
  _assertEq(DocumentFieldParser.extractFields('Government of India AADHAAR CARD')['documentType'], 'Aadhaar Card', 'Aadhaar classification');
  _assertEq(DocumentFieldParser.extractFields('Aadhar Number XXXX XXXX 1234')['documentType'], 'Aadhaar Card', 'Aadhar classification');

  // Test 2: Amounts
  _assertEq(DocumentFieldParser.extractFields('Total Amount Payable: ₹1,847.50 due soon')['amount'], '₹1,847.50', 'Amount ₹');
  _assertEq(DocumentFieldParser.extractFields('Net Charge Rs. 500 only')['amount'], 'Rs. 500', 'Amount Rs.');
  _assertEq(DocumentFieldParser.extractFields('Paid INR 12,500 via UPI')['amount'], 'INR 12,500', 'Amount INR');

  // Test 3: Due Dates
  _assertEq(DocumentFieldParser.extractFields('Due date: 05/09/2026 before 5 PM')['dueDate'], '05/09/2026', 'DueDate slash numeric');
  _assertEq(DocumentFieldParser.extractFields('Expires on: 10-12-2026')['dueDate'], '10-12-2026', 'DueDate dash numeric');
  _assertEq(DocumentFieldParser.extractFields('Valid till 5 Sep 2026')['dueDate'], '5 Sep 2026', 'DueDate named month');
  _assertEq(DocumentFieldParser.extractFields('DUE DATE 15 OCTOBER 2026')['dueDate'], '15 OCTOBER 2026', 'DueDate UPPER month');

  // Test 4: Blank / Empty text
  _assertTrue(DocumentFieldParser.extractFields('').isEmpty, 'Empty text');
  _assertTrue(DocumentFieldParser.extractFields('   \n  ').isEmpty, 'Whitespace text');
  _assertTrue(DocumentFieldParser.extractFields('Random text without keywords or amounts').isEmpty, 'Unmatching text');

  // Test 5: Category keys
  _assertEq(DocumentFieldParser.categoryKeyFor('Bill'), 'bills', 'Cat bill');
  _assertEq(DocumentFieldParser.categoryKeyFor('Insurance'), 'vehicles', 'Cat insurance');
  _assertEq(DocumentFieldParser.categoryKeyFor('Prescription'), 'medical', 'Cat prescription');
  _assertEq(DocumentFieldParser.categoryKeyFor('Warranty'), 'warranties', 'Cat warranty');
  _assertEq(DocumentFieldParser.categoryKeyFor('Aadhaar Card'), 'ids', 'Cat aadhaar');
  _assertEq(DocumentFieldParser.categoryKeyFor('Unknown'), null, 'Cat unknown');
  _assertEq(DocumentFieldParser.categoryKeyFor(null), null, 'Cat null');

  print('PASSED: All 20 DocumentFieldParser assertions completed successfully!');
}

void _assertEq(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    throw Exception('FAILED [$label]: Expected "$expected", got "$actual"');
  }
}

void _assertTrue(bool condition, String label) {
  if (!condition) {
    throw Exception('FAILED [$label]: Expected true condition');
  }
}
