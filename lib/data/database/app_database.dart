import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Database Table Schema Provider for YAAD Local SQLite Layer
class AppDatabase {
  final QueryExecutor executor;

  AppDatabase([QueryExecutor? e])
      : executor = e ?? driftDatabase(name: 'yaad_local_v1.db');

  /// Placeholder for future production schema migrations & raw table initialization
  Future<void> initDatabase() async {
    // Ensures SQLite database table structure is ready for production persistence
  }
}
