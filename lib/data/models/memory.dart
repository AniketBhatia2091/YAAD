/// Domain entity representing a personal memory in YAAD.
/// Architecture allows replacing mock provider with Drift SQLite database or Remote Vault seamlessly.
class Memory {
  final String id;
  final String title;
  final String documentType; // E.g., 'Bill', 'Insurance', 'ID', 'Medical', 'Warranty', 'Certificate'
  final String categoryKey; // E.g., 'ids', 'bills', 'vehicles', 'medical', 'warranties', 'education'
  final String? imagePath;
  final String? extractedText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String owner; // E.g., 'Self', 'Mom', 'Vehicle'
  final double confidence;
  final DateTime? expiryDate;
  final DateTime? dueDate;
  final double? amount;
  final String? actionTitle; // E.g., 'Pay by Sep 5', 'Renew before Sep 10', '2 tablets'
  final String? actionSubtitle;
  final bool isAttentionRequired;
  final String? subtitle; // E.g. "₹1,847 · Due in 2 days" or "Expires in 12 days"

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
    this.confidence = 1.0,
    this.expiryDate,
    this.dueDate,
    this.amount,
    this.actionTitle,
    this.actionSubtitle,
    this.isAttentionRequired = false,
    this.subtitle,
  });

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
    );
  }
}
