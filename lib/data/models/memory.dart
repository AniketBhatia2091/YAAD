/// Domain entity representing a personal memory in YAAD.
class Memory {
  final String id;
  final String title;
  final String documentType; // E.g., 'Bill', 'Insurance', 'ID', 'unknown'
  final String categoryKey; // E.g., 'ids', 'bills', 'vehicles', 'medical', 'warranties', 'education', 'unsorted'
  final String? imagePath;
  final String? extractedText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String owner; // E.g., 'Self', 'Mom', 'Vehicle', 'Unknown'
  final double? confidence;
  final DateTime? expiryDate;
  final DateTime? dueDate;
  final double? amount;
  final String? actionTitle;
  final String? actionSubtitle;
  final bool isAttentionRequired;
  final String? subtitle;
  final String? metadata;

  const Memory({
    required this.id,
    required this.title,
    required this.documentType,
    required this.categoryKey,
    this.imagePath,
    this.extractedText,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    this.confidence,
    this.expiryDate,
    this.dueDate,
    this.amount,
    this.actionTitle,
    this.actionSubtitle,
    this.isAttentionRequired = false,
    this.subtitle,
    this.metadata,
  });

  /// Factory helper for creating an unclassified Memory from capture/import.
  factory Memory.createUnclassified({
    required String id,
    required String imagePath,
  }) {
    final now = DateTime.now();
    return Memory(
      id: id,
      title: 'Untitled memory',
      documentType: 'unknown',
      categoryKey: 'unsorted',
      imagePath: imagePath,
      extractedText: null,
      createdAt: now,
      updatedAt: now,
      owner: 'Self',
      confidence: null,
      expiryDate: null,
      dueDate: null,
      amount: null,
      actionTitle: null,
      actionSubtitle: null,
      isAttentionRequired: false,
      subtitle: 'Unclassified memory',
      metadata: '{}',
    );
  }

  Memory copyWith({
    String? id,
    String? title,
    String? documentType,
    String? categoryKey,
    String? imagePath,
    String? extractedText,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? owner,
    double? confidence,
    DateTime? expiryDate,
    DateTime? dueDate,
    double? amount,
    String? actionTitle,
    String? actionSubtitle,
    bool? isAttentionRequired,
    String? subtitle,
    String? metadata,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      categoryKey: categoryKey ?? this.categoryKey,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      confidence: confidence ?? this.confidence,
      expiryDate: expiryDate ?? this.expiryDate,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      actionTitle: actionTitle ?? this.actionTitle,
      actionSubtitle: actionSubtitle ?? this.actionSubtitle,
      isAttentionRequired: isAttentionRequired ?? this.isAttentionRequired,
      subtitle: subtitle ?? this.subtitle,
      metadata: metadata ?? this.metadata,
    );
  }
}
