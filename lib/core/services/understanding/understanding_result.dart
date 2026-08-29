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

  const UnderstandingResult({
    required this.status,
    this.documentType,
    this.categoryKey,
    this.fields = const [],
    this.overallConfidence,
    this.understoodAt,
  });

  UnderstandingResult copyWith({
    UnderstandingStatus? status,
    String? documentType,
    String? categoryKey,
    List<UnderstandingField>? fields,
    double? overallConfidence,
    DateTime? understoodAt,
  }) {
    return UnderstandingResult(
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      categoryKey: categoryKey ?? this.categoryKey,
      fields: fields ?? this.fields,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      understoodAt: understoodAt ?? this.understoodAt,
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
          understoodAt == other.understoodAt;

  @override
  int get hashCode =>
      Object.hash(status, documentType, categoryKey, overallConfidence, understoodAt);

  @override
  String toString() =>
      'UnderstandingResult(status: $status, docType: $documentType, category: $categoryKey, fields: ${fields.length})';
}
