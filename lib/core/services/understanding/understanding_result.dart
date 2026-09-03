import 'understanding_field.dart';

enum UnderstandingStatus {
  unknown,
  processing,
  needsReview,
  confirmed,
  failed,
}

/// Represents the structured result of the memory understanding pipeline.
class UnderstandingResult {
  final UnderstandingStatus status;
  final String? documentType;
  final String? categoryKey;
  final List<UnderstandingField> fields;
  final double? overallConfidence;
  final DateTime? understoodAt;
  final double? amount;
  final DateTime? dueDate;
  final DateTime? expiryDate;
  final bool clearAmount;
  final bool clearDueDate;
  final bool clearExpiryDate;

  const UnderstandingResult({
    required this.status,
    this.documentType,
    this.categoryKey,
    this.fields = const [],
    this.overallConfidence,
    this.understoodAt,
    this.amount,
    this.dueDate,
    this.expiryDate,
    this.clearAmount = false,
    this.clearDueDate = false,
    this.clearExpiryDate = false,
  });

  UnderstandingResult copyWith({
    UnderstandingStatus? status,
    String? documentType,
    String? categoryKey,
    List<UnderstandingField>? fields,
    double? overallConfidence,
    DateTime? understoodAt,
    double? amount,
    DateTime? dueDate,
    DateTime? expiryDate,
    bool? clearAmount,
    bool? clearDueDate,
    bool? clearExpiryDate,
  }) {
    return UnderstandingResult(
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      categoryKey: categoryKey ?? this.categoryKey,
      fields: fields ?? this.fields,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      understoodAt: understoodAt ?? this.understoodAt,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      clearAmount: clearAmount ?? this.clearAmount,
      clearDueDate: clearDueDate ?? this.clearDueDate,
      clearExpiryDate: clearExpiryDate ?? this.clearExpiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'documentType': documentType,
      'categoryKey': categoryKey,
      'fields': fields.map((f) => f.toJson()).toList(),
      'overallConfidence': overallConfidence,
      'understoodAt': understoodAt?.toIso8601String(),
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'clearAmount': clearAmount,
      'clearDueDate': clearDueDate,
      'clearExpiryDate': clearExpiryDate,
    };
  }

  factory UnderstandingResult.fromJson(Map<String, dynamic> json) {
    return UnderstandingResult(
      status: UnderstandingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UnderstandingStatus.unknown,
      ),
      documentType: json['documentType'] as String?,
      categoryKey: json['categoryKey'] as String?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => UnderstandingField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble(),
      understoodAt: json['understoodAt'] != null
          ? DateTime.tryParse(json['understoodAt'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      clearAmount: json['clearAmount'] as bool? ?? false,
      clearDueDate: json['clearDueDate'] as bool? ?? false,
      clearExpiryDate: json['clearExpiryDate'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnderstandingResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          documentType == other.documentType &&
          categoryKey == other.categoryKey &&
          overallConfidence == other.overallConfidence &&
          understoodAt == other.understoodAt &&
          amount == other.amount &&
          dueDate == other.dueDate &&
          expiryDate == other.expiryDate &&
          clearAmount == other.clearAmount &&
          clearDueDate == other.clearDueDate &&
          clearExpiryDate == other.clearExpiryDate;

  @override
  int get hashCode => Object.hash(
        status,
        documentType,
        categoryKey,
        overallConfidence,
        understoodAt,
        amount,
        dueDate,
        expiryDate,
        clearAmount,
        clearDueDate,
        clearExpiryDate,
      );

  @override
  String toString() =>
      'UnderstandingResult(status: $status, docType: $documentType, category: $categoryKey, fields: ${fields.length}, amount: $amount, dueDate: $dueDate, expiryDate: $expiryDate, clearAmount: $clearAmount, clearDueDate: $clearDueDate, clearExpiryDate: $clearExpiryDate)';
}
