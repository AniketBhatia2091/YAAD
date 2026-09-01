/// Pure-Dart heuristic parser for extracting structured document metadata from raw OCR text.
///
/// Designed with zero platform-channel dependencies to allow fast, isolated unit testing.
class DocumentFieldParser {
  // Regex for currency amounts: ₹, Rs, Rs., INR followed by formatted numbers
  static final RegExp _amountRegex = RegExp(
    r'(?:₹|Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  // Regex for dates: dd/mm/yyyy, dd-mm-yyyy, or "5 Sep 2026", "05 September 2026"
  static final RegExp _numericDateRegex = RegExp(
    r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
    caseSensitive: false,
  );

  static final RegExp _namedMonthDateRegex = RegExp(
    r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b',
    caseSensitive: false,
  );

  /// Extracts structured document fields from [rawText].
  ///
  /// Returns a Map containing extracted keys like 'documentType', 'amount', 'dueDate'.
  static Map<String, String> extractFields(String rawText) {
    final Map<String, String> fields = {};
    if (rawText.trim().isEmpty) {
      return fields;
    }

    final lowerText = rawText.toLowerCase();

    // Keyword-based documentType classification.
    // Order matters (first match wins).
    // NOTE: Overlapping keywords like "mg" in a medical bill vs prescription
    // are a known limitation of lightweight heuristic keyword matching.
    String? docType;
    if (_containsAny(lowerText, ['bill', 'electricity', 'invoice'])) {
      docType = 'Bill';
    } else if (_containsAny(lowerText, ['insurance', 'policy'])) {
      docType = 'Insurance';
    } else if (_containsAny(lowerText, ['prescription', 'tablet', 'mg'])) {
      docType = 'Prescription';
    } else if (_containsAny(lowerText, ['warranty'])) {
      docType = 'Warranty';
    } else if (_containsAny(lowerText, ['aadhaar', 'aadhar'])) {
      docType = 'Aadhaar Card';
    }

    if (docType != null) {
      fields['documentType'] = docType;
    }

    // Amount extraction
    final amountMatch = _amountRegex.firstMatch(rawText);
    if (amountMatch != null) {
      fields['amount'] = amountMatch.group(0)!.trim();
    }

    // Due Date / Date extraction (checks numeric date first, then named month date)
    final numericDateMatch = _numericDateRegex.firstMatch(rawText);
    if (numericDateMatch != null) {
      fields['dueDate'] = numericDateMatch.group(0)!.trim();
    } else {
      final namedMonthMatch = _namedMonthDateRegex.firstMatch(rawText);
      if (namedMonthMatch != null) {
        fields['dueDate'] = namedMonthMatch.group(0)!.trim();
      }
    }

    return fields;
  }

  /// Maps [documentType] string to vault category key.
  static String? categoryKeyFor(String? documentType) {
    switch (documentType) {
      case 'Bill':
        return 'bills';
      case 'Insurance':
        return 'vehicles';
      case 'Prescription':
        return 'medical';
      case 'Warranty':
        return 'warranties';
      case 'Aadhaar Card':
        return 'ids';
      default:
        return null;
    }
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}
