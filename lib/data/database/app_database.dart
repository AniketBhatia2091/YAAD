import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/memory.dart';

class _YaadExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        document_type TEXT NOT NULL,
        category_key TEXT NOT NULL,
        image_path TEXT,
        extracted_text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        owner TEXT NOT NULL DEFAULT 'Self',
        confidence REAL,
        expiry_date INTEGER,
        due_date INTEGER,
        amount REAL,
        action_title TEXT,
        action_subtitle TEXT,
        is_attention_required INTEGER NOT NULL DEFAULT 0,
        subtitle TEXT,
        metadata TEXT
      );
    ''');
    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories (created_at DESC);
    ''');
    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_memories_category_key ON memories (category_key);
    ''');
  }
}

/// YAAD Local SQLite Database — Drift QueryExecutor backed persistent storage.
///
/// This serves as the single source of truth for memory metadata.
/// Binary image files are stored separately by [StorageService].
class AppDatabase {
  final QueryExecutor executor;
  final _YaadExecutorUser _user = _YaadExecutorUser();
  bool _isInitialized = false;

  AppDatabase([QueryExecutor? e])
      : executor = e ?? driftDatabase(name: 'yaad_local_v1');

  AppDatabase.forTesting(this.executor);

  /// Initializes the SQLite database and runs migrations/table creation if needed.
  Future<void> initDatabase() async {
    if (_isInitialized) return;
    await executor.ensureOpen(_user);
    _isInitialized = true;
  }

  // ─── CREATE ─────────────────────────────────────────────────────────────────

  /// Insert or replace a memory record into SQLite.
  Future<void> insertMemory(Memory memory) async {
    await initDatabase();
    await executor.runInsert(
      '''
      INSERT OR REPLACE INTO memories (
        id, title, document_type, category_key, image_path, extracted_text,
        created_at, updated_at, owner, confidence, expiry_date, due_date,
        amount, action_title, action_subtitle, is_attention_required, subtitle, metadata
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        memory.id,
        memory.title,
        memory.documentType,
        memory.categoryKey,
        memory.imagePath,
        memory.extractedText,
        memory.createdAt.millisecondsSinceEpoch,
        memory.updatedAt.millisecondsSinceEpoch,
        memory.owner,
        memory.confidence,
        memory.expiryDate?.millisecondsSinceEpoch,
        memory.dueDate?.millisecondsSinceEpoch,
        memory.amount,
        memory.actionTitle,
        memory.actionSubtitle,
        memory.isAttentionRequired ? 1 : 0,
        memory.subtitle,
        memory.metadata,
      ],
    );
  }

  // ─── READ ────────────────────────────────────────────────────────────────────

  /// Retrieve a memory by its UUID primary key.
  Future<Memory?> getMemoryById(String id) async {
    await initDatabase();
    final rows = await executor.runSelect(
      'SELECT * FROM memories WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToMemory(rows.first);
  }

  /// Retrieve all memories ordered by created_at descending.
  Future<List<Memory>> getAllMemories() async {
    await initDatabase();
    final rows = await executor.runSelect(
      'SELECT * FROM memories ORDER BY created_at DESC, rowid DESC',
      [],
    );
    return rows.map(_rowToMemory).toList();
  }

  /// Retrieve memories that require attention.
  Future<List<Memory>> getAttentionMemories() async {
    await initDatabase();
    final rows = await executor.runSelect(
      'SELECT * FROM memories WHERE is_attention_required = 1 ORDER BY created_at DESC, rowid DESC',
      [],
    );
    return rows.map(_rowToMemory).toList();
  }

  /// Retrieve upcoming memories with due or expiry dates that are not urgent attention.
  Future<List<Memory>> getUpcomingMemories() async {
    await initDatabase();
    final rows = await executor.runSelect(
      '''
      SELECT * FROM memories
      WHERE is_attention_required = 0 AND (expiry_date IS NOT NULL OR due_date IS NOT NULL)
      ORDER BY created_at DESC, rowid DESC
      ''',
      [],
    );
    return rows.map(_rowToMemory).toList();
  }

  /// Retrieve the most recent memories up to [limit].
  Future<List<Memory>> getRecentMemories({int limit = 6}) async {
    await initDatabase();
    final rows = await executor.runSelect(
      'SELECT * FROM memories ORDER BY created_at DESC, rowid DESC LIMIT ?',
      [limit],
    );
    return rows.map(_rowToMemory).toList();
  }

  /// Search memories across text fields using SQL LIKE patterns.
  Future<List<Memory>> searchMemories(String query) async {
    await initDatabase();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllMemories();

    final pattern = '%$q%';
    final rows = await executor.runSelect(
      '''
      SELECT * FROM memories
      WHERE LOWER(title) LIKE ?
         OR LOWER(document_type) LIKE ?
         OR LOWER(category_key) LIKE ?
         OR LOWER(owner) LIKE ?
         OR (extracted_text IS NOT NULL AND LOWER(extracted_text) LIKE ?)
         OR (subtitle IS NOT NULL AND LOWER(subtitle) LIKE ?)
         OR (metadata IS NOT NULL AND LOWER(metadata) LIKE ?)
      ORDER BY created_at DESC
      ''',
      [pattern, pattern, pattern, pattern, pattern, pattern, pattern],
    );
    return rows.map(_rowToMemory).toList();
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────────

  /// Update an existing memory record.
  Future<void> updateMemory(Memory memory) async {
    await initDatabase();
    await executor.runUpdate(
      '''
      UPDATE memories SET
        title = ?,
        document_type = ?,
        category_key = ?,
        image_path = ?,
        extracted_text = ?,
        created_at = ?,
        updated_at = ?,
        owner = ?,
        confidence = ?,
        expiry_date = ?,
        due_date = ?,
        amount = ?,
        action_title = ?,
        action_subtitle = ?,
        is_attention_required = ?,
        subtitle = ?,
        metadata = ?
      WHERE id = ?
      ''',
      [
        memory.title,
        memory.documentType,
        memory.categoryKey,
        memory.imagePath,
        memory.extractedText,
        memory.createdAt.millisecondsSinceEpoch,
        memory.updatedAt.millisecondsSinceEpoch,
        memory.owner,
        memory.confidence,
        memory.expiryDate?.millisecondsSinceEpoch,
        memory.dueDate?.millisecondsSinceEpoch,
        memory.amount,
        memory.actionTitle,
        memory.actionSubtitle,
        memory.isAttentionRequired ? 1 : 0,
        memory.subtitle,
        memory.metadata,
        memory.id,
      ],
    );
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────────

  /// Delete a memory row by ID.
  Future<void> deleteMemory(String id) async {
    await initDatabase();
    await executor.runDelete(
      'DELETE FROM memories WHERE id = ?',
      [id],
    );
  }

  /// Closes database connection.
  Future<void> close() async {
    await executor.close();
    _isInitialized = false;
  }

  // ─── MAPPING ─────────────────────────────────────────────────────────────────

  Memory _rowToMemory(Map<String, Object?> row) {
    return Memory(
      id: row['id'] as String,
      title: row['title'] as String,
      documentType: row['document_type'] as String,
      categoryKey: row['category_key'] as String,
      imagePath: row['image_path'] as String?,
      extractedText: row['extracted_text'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      owner: (row['owner'] as String?) ?? 'Self',
      confidence: (row['confidence'] as num?)?.toDouble(),
      expiryDate: row['expiry_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['expiry_date'] as int)
          : null,
      dueDate: row['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int)
          : null,
      amount: (row['amount'] as num?)?.toDouble(),
      actionTitle: row['action_title'] as String?,
      actionSubtitle: row['action_subtitle'] as String?,
      isAttentionRequired: (row['is_attention_required'] as int?) == 1,
      subtitle: row['subtitle'] as String?,
      metadata: row['metadata'] as String?,
    );
  }
}
