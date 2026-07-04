import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'package:document/lib/document.dart';

/// Database service for document management.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Database _db;
  late String _dbPath;

  /// Initializes the database connection and schema.
  Future<void> init() async {
    // Create database directory
    final dbDir = Directory('data');
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    // Database file path
    _dbPath = path.join(dbDir.path, 'documents.db');

    // Open or create database
    _db = sqlite3.open(_dbPath);

    // Create tables
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        word_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Creates a new document.
  Document create(Document document) {
    _db.execute(
      'INSERT INTO documents (id, project_id, title, file_path, word_count, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        document.id,
        document.projectId,
        document.title,
        document.filePath,
        document.wordCount,
        document.createdAt.toIso8601String(),
        document.updatedAt.toIso8601String(),
      ],
    );
    return document;
  }

  /// Gets a document by ID.
  Document? getById(String id) {
    final row = _db.select('SELECT * FROM documents WHERE id = ?', [id]).firstOrNull;
    if (row == null) return null;
    return Document.fromJson({
      'id': row['id'] as String,
      'project_id': row['project_id'] as String,
      'title': row['title'] as String,
      'file_path': row['file_path'] as String,
      'word_count': row['word_count'] as int,
      'created_at': row['created_at'] as String,
      'updated_at': row['updated_at'] as String,
    });
  }

  /// Lists all documents (optionally filtered by project ID).
  List<Document> list({String? projectId}) {
    final List<Map<String, Object?>> rows;
    if (projectId != null) {
      rows = _db.select('SELECT * FROM documents WHERE project_id = ? ORDER BY created_at DESC', [projectId]).toList();
    } else {
      rows = _db.select('SELECT * FROM documents ORDER BY created_at DESC').toList();
    }

    return rows.map((row) => Document.fromJson({
      'id': row['id'] as String,
      'project_id': row['project_id'] as String,
      'title': row['title'] as String,
      'file_path': row['file_path'] as String,
      'word_count': row['word_count'] as int,
      'created_at': row['created_at'] as String,
      'updated_at': row['updated_at'] as String,
    })).toList();
  }

  /// Updates a document.
  Document? update(String id, Document document) {
    final existing = getById(id);
    if (existing == null) return null;

    _db.execute(
      'UPDATE documents SET project_id = ?, title = ?, file_path = ?, word_count = ?, updated_at = ? WHERE id = ?',
      [
        document.projectId,
        document.title,
        document.filePath,
        document.wordCount,
        document.updatedAt.toIso8601String(),
        id,
      ],
    );

    return document.copyWith(id: id, createdAt: existing.createdAt);
  }

  /// Deletes a document.
  bool delete(String id) {
    final result = _db.execute('DELETE FROM documents WHERE id = ?', [id]);
    return result.changes > 0;
  }

  /// Closes the database connection.
  void close() {
    _db.dispose();
  }
}
