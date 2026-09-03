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

  static const Map<String, int> _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

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

  /// Parses currency amount string (e.g. "₹1,847.50", "Rs. 500", "INR 12,500") into a double.
  ///
  /// Returns null if [rawAmount] is null, empty, or cannot be parsed without throwing.
  static double? parseAmount(String? rawAmount) {
    if (rawAmount == null || rawAmount.trim().isEmpty) return null;
    try {
      final cleaned = rawAmount
          .replaceAll(RegExp(r'[₹,\s]|Rs\.?|INR', caseSensitive: false), '')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Parses date string in either numeric (dd/mm/yyyy, dd-mm-yyyy) or
  /// named month ("5 Sep 2026", "15 OCTOBER 2026") format into a DateTime.
  ///
  /// Returns null if [rawDate] is null, empty, or invalid without throwing.
  static DateTime? parseDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    final trimmed = rawDate.trim();

    try {
      // 1. Try numeric format dd/mm/yyyy or dd-mm-yyyy
      final numericMatch = _numericDateRegex.firstMatch(trimmed);
      if (numericMatch != null) {
        final matchStr = numericMatch.group(0)!;
        final separator = matchStr.contains('/') ? '/' : '-';
        final parts = matchStr.split(separator);
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          var year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            if (year < 100) year += 2000;
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100) {
              return DateTime(year, month, day);
            }
          }
        }
      }

      // 2. Try named month format: "5 Sep 2026" or "15 OCTOBER 2026"
      final namedMatch = _namedMonthDateRegex.firstMatch(trimmed);
      if (namedMatch != null) {
        final matchStr = namedMatch.group(0)!;
        final parts = matchStr.split(RegExp(r'\s+'));
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final monthStr = parts[1].length >= 3 ? parts[1].substring(0, 3).toLowerCase() : '';
          final month = _monthMap[monthStr];
          var year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            if (year < 100) year += 2000;
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100) {
              return DateTime(year, month, day);
            }
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Determines whether the document date represents an 'expiryDate' or 'dueDate'.
  ///
  /// Bill/Prescription -> 'dueDate'
  /// Insurance/Warranty/PUC -> 'expiryDate'
  static String dateTargetFor(String? documentType) {
    switch (documentType) {
      case 'Insurance':
      case 'Warranty':
      case 'PUC':
      case 'Vehicle PUC':
        return 'expiryDate';
      case 'Bill':
      case 'Prescription':
      default:
        return 'dueDate';
    }
  }

  /// Parses [rawText] into both human-readable string fields and typed values.
  static ParsedDocumentFields parse(String rawText) {
    final rawFields = extractFields(rawText);
    final docType = rawFields['documentType'];
    final categoryKey = categoryKeyFor(docType);
    final rawAmount = rawFields['amount'];
    final amount = parseAmount(rawAmount);

    final rawDate = rawFields['dueDate'] ?? rawFields['expiryDate'];
    final date = parseDate(rawDate);
    final dateTarget = dateTargetFor(docType);

    return ParsedDocumentFields(
      documentType: docType,
      categoryKey: categoryKey,
      rawAmount: rawAmount,
      amount: amount,
      rawDate: rawDate,
      date: date,
      dateTarget: dateTarget,
      rawFields: rawFields,
    );
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

/// Represents the typed, structured extraction from raw document text.
class ParsedDocumentFields {
  final String? documentType;
  final String? categoryKey;
  final String? rawAmount;
  final double? amount;
  final String? rawDate;
  final DateTime? date;
  final String dateTarget; // 'dueDate' or 'expiryDate'
  final Map<String, String> rawFields;

  DateTime? get dueDate => dateTarget == 'dueDate' ? date : null;
  DateTime? get expiryDate => dateTarget == 'expiryDate' ? date : null;

  const ParsedDocumentFields({
    this.documentType,
    this.categoryKey,
    this.rawAmount,
    this.amount,
    this.rawDate,
    this.date,
    this.dateTarget = 'dueDate',
    this.rawFields = const {},
  });
}
