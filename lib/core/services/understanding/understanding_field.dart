enum FieldConfidence {
  high,
  medium,
  low,
  unknown,
}

enum FieldSource {
  visible,
  inferred,
  unknown,
}

/// Represents an individual understood or extracted data point from a document memory.
class UnderstandingField {
  final String fieldName;
  final String? value;
  final FieldConfidence confidence;
  final FieldSource source;

  const UnderstandingField({
    required this.fieldName,
    this.value,
    this.confidence = FieldConfidence.unknown,
    this.source = FieldSource.unknown,
  });

  UnderstandingField copyWith({
    String? fieldName,
    String? value,
    FieldConfidence? confidence,
    FieldSource? source,
  }) {
    return UnderstandingField(
      fieldName: fieldName ?? this.fieldName,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'value': value,
      'confidence': confidence.name,
      'source': source.name,
    };
  }

  factory UnderstandingField.fromJson(Map<String, dynamic> json) {
    return UnderstandingField(
      fieldName: json['fieldName'] as String? ?? 'Unknown Field',
      value: json['value'] as String?,
      confidence: FieldConfidence.values.firstWhere(
        (e) => e.name == json['confidence'],
        orElse: () => FieldConfidence.unknown,
      ),
      source: FieldSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => FieldSource.unknown,
      ),
    );
  }

  /// Returns a clean human-readable label for common field names.
  String get displayLabel {
    switch (fieldName.toLowerCase()) {
      case 'documenttype':
      case 'document_type':
        return 'Document Type';
      case 'provider':
        return 'Provider / Issuer';
      case 'person':
        return 'Person Name';
      case 'amount':
        return 'Amount';
      case 'currency':
        return 'Currency';
      case 'duedate':
      case 'due_date':
        return 'Due Date';
      case 'expirydate':
      case 'expiry_date':
        return 'Expiry Date';
      case 'documentnumber':
      case 'document_number':
      case 'account_number':
      case 'accountnumber':
        return 'Account / Doc Number';
      case 'policynumber':
      case 'policy_number':
        return 'Policy Number';
      case 'medicine':
        return 'Medicine';
      case 'dosage':
        return 'Dosage & Instructions';
      case 'warrantyend':
      case 'warranty_end':
        return 'Warranty Expiry';
      case 'applicationdeadline':
      case 'application_deadline':
        return 'Application Deadline';
      default:
        // Capitalize first letter or title-case
        if (fieldName.isEmpty) return 'Field';
        return fieldName[0].toUpperCase() + fieldName.substring(1);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnderstandingField &&
          runtimeType == other.runtimeType &&
          fieldName == other.fieldName &&
          value == other.value &&
          confidence == other.confidence &&
          source == other.source;

  @override
  int get hashCode => Object.hash(fieldName, value, confidence, source);

  @override
  String toString() =>
      'UnderstandingField(name: $fieldName, value: $value, confidence: $confidence, source: $source)';
}
