import 'package:drift/drift.dart';

/// Drift SQLite Memories Table Schema definition for YAAD Local Data Layer
@DataClassName('MemoryEntity')
class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get documentType => text()();
  TextColumn get categoryKey => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get extractedText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get owner => text().withDefault(const Constant('Self'))();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get actionTitle => text().nullable()();
  TextColumn get actionSubtitle => text().nullable()();
  BoolColumn get isAttentionRequired => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
