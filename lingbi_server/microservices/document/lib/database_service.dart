import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:document/document.dart';

/// A search result with rank/score.
class SearchResult {
  final Document document;
  final double rank;

  SearchResult({required this.document, required this.rank});
}

/// A document outline entry (from Markdown headings).
class OutlineEntry {
  final int level;
  final String title;
  final int lineNumber;

  OutlineEntry({
    required this.level,
    required this.title,
    required this.lineNumber,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'title': title,
        'line_number': lineNumber,
      };
}

/// Document statistics.
class DocumentStats {
  final int wordCount;
  final int paragraphCount;
  final int headingCount;
  final int characterCount;

  DocumentStats({
    required this.wordCount,
    required this.paragraphCount,
    required this.headingCount,
    required this.characterCount,
  });

  Map<String, dynamic> toJson() => {
        'word_count': wordCount,
        'paragraph_count': paragraphCount,
        'heading_count': headingCount,
        'character_count': characterCount,
      };
}

/// Database service for document management with FTS5 full-text search.
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
    _dbPath = p.join(dbDir.path, 'documents.db');

    // Open or create database
    _db = sqlite3.open(_dbPath);

    // Enable WAL mode for better concurrent access
    _db.execute('PRAGMA journal_mode=WAL');

    // Create tables
    _createTables();
  }

  void _createTables() {
    // Main documents table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        word_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // FTS5 virtual table for full-text search on title and content
    _db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
        title,
        content,
        content='documents',
        content_rowid='rowid',
        tokenize='unicode61'
      )
    ''');

    // Create triggers to keep FTS index in sync
    _db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_ai AFTER INSERT ON documents BEGIN
        INSERT INTO documents_fts(rowid, title, content)
        VALUES (new.rowid, new.title, new.content);
      END
    ''');

    _db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_ad AFTER DELETE ON documents BEGIN
        INSERT INTO documents_fts(documents_fts, rowid, title, content)
        VALUES ('delete', old.rowid, old.title, old.content);
      END
    ''');

    _db.execute('''
      CREATE TRIGGER IF NOT EXISTS documents_au AFTER UPDATE ON documents BEGIN
        INSERT INTO documents_fts(documents_fts, rowid, title, content)
        VALUES ('delete', old.rowid, old.title, old.content);
        INSERT INTO documents_fts(rowid, title, content)
        VALUES (new.rowid, new.title, new.content);
      END
    ''');
  }

  /// Rebuilds the FTS index from scratch (useful if data was migrated).
  void rebuildFtsIndex() {
    _db.execute("INSERT INTO documents_fts(documents_fts) VALUES('rebuild')");
  }

  /// Creates a new document.
  Document create(Document document) {
    _db.execute(
      'INSERT INTO documents (id, project_id, title, content, word_count, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        document.id,
        document.projectId,
        document.title,
        document.content,
        document.wordCount,
        document.createdAt.toIso8601String(),
        document.updatedAt.toIso8601String(),
      ],
    );
    return document;
  }

  /// Gets a document by ID.
  Document? getById(String id) {
    final row =
        _db.select('SELECT * FROM documents WHERE id = ?', [id]).firstOrNull;
    if (row == null) return null;
    return _rowToDocument(row);
  }

  /// Lists all documents (optionally filtered by project ID).
  List<Document> list({String? projectId}) {
    final List<Map<String, Object?>> rows;
    if (projectId != null) {
      rows = _db.select(
          'SELECT * FROM documents WHERE project_id = ? ORDER BY updated_at DESC',
          [projectId]).toList();
    } else {
      rows = _db
          .select('SELECT * FROM documents ORDER BY updated_at DESC')
          .toList();
    }

    return rows.map(_rowToDocument).toList();
  }

  /// Updates a document's content, title, and optionally projectId.
  Document? update(String id,
      {String? title, String? content, String? projectId}) {
    final existing = getById(id);
    if (existing == null) return null;

    final now = DateTime.now();
    final newTitle = title ?? existing.title;
    final newContent = content ?? existing.content;
    final newWordCount = Document.calculateWordCount(newContent);
    final newProjectId = projectId ?? existing.projectId;

    _db.execute(
      'UPDATE documents SET title = ?, content = ?, project_id = ?, word_count = ?, updated_at = ? WHERE id = ?',
      [
        newTitle,
        newContent,
        newProjectId,
        newWordCount,
        now.toIso8601String(),
        id,
      ],
    );

    return existing.copyWith(
      title: newTitle,
      content: newContent,
      projectId: newProjectId,
      wordCount: newWordCount,
      updatedAt: now,
    );
  }

  /// Deletes a document.
  bool delete(String id) {
    _db.execute('DELETE FROM documents WHERE id = ?', [id]);
    return _db.updatedRows > 0;
  }

  /// Searches documents using FTS5 full-text search.
  /// Returns results sorted by BM25 relevance (lower = more relevant).
  List<SearchResult> search(String query, {String? projectId, int? limit}) {
    // Sanitize the query for FTS5 (support prefix matching)
    final ftsQuery = query
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '$w*')
        .join(' ');

    if (ftsQuery.isEmpty) return [];

    final sql = projectId != null
        ? '''SELECT d.*, bm25(documents_fts, 0.0, 3.0) AS rank
             FROM documents_fts
             JOIN documents d ON d.rowid = documents_fts.rowid
             WHERE documents_fts MATCH ? AND d.project_id = ?
             ORDER BY rank'''
        : '''SELECT d.*, bm25(documents_fts, 0.0, 3.0) AS rank
             FROM documents_fts
             JOIN documents d ON d.rowid = documents_fts.rowid
             WHERE documents_fts MATCH ?
             ORDER BY rank''';

    final params = projectId != null ? [ftsQuery, projectId] : [ftsQuery];
    final rows = _db.select(sql, params).toList();

    if (limit != null && rows.length > limit) {
      rows.length = limit;
    }

    return rows.map((row) {
      final doc = _rowToDocument(row);
      final rank = row['rank'] as double;
      return SearchResult(document: doc, rank: rank);
    }).toList();
  }

  /// Extracts a Markdown heading outline from the document content.
  OutlineResult getOutline(String documentId) {
    final doc = getById(documentId);
    if (doc == null) return OutlineResult(entries: [], documentId: documentId);

    final entries = <OutlineEntry>[];
    final lines = doc.content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').matchAsPrefix(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final title = headingMatch.group(2)!.trim();
        entries
            .add(OutlineEntry(level: level, title: title, lineNumber: i + 1));
      }
    }

    return OutlineResult(entries: entries, documentId: documentId);
  }

  /// Computes document statistics.
  DocumentStats getStats(String documentId) {
    final doc = getById(documentId);
    if (doc == null) {
      return DocumentStats(
        wordCount: 0,
        paragraphCount: 0,
        headingCount: 0,
        characterCount: 0,
      );
    }

    final content = doc.content;
    final lines = content.split('\n');

    // Word count (same as Document.calculateWordCount)
    final wordCount = Document.calculateWordCount(content);

    // Character count (excluding newlines)
    final characterCount =
        content.replaceAll('\n', '').replaceAll('\r', '').length;

    // Paragraph count (non-empty lines)
    final paragraphCount = lines.where((l) => l.trim().isNotEmpty).length;

    // Heading count
    final headingCount =
        RegExp(r'^#{1,6}\s+', multiLine: true).allMatches(content).length;

    return DocumentStats(
      wordCount: wordCount,
      paragraphCount: paragraphCount,
      headingCount: headingCount,
      characterCount: characterCount,
    );
  }

  /// Closes the database connection.
  void close() {
    _db.dispose();
  }

  /// Converts a SQLite row to a Document.
  Document _rowToDocument(Map<String, Object?> row) {
    return Document(
      id: row['id'] as String,
      projectId: row['project_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String? ?? '',
      wordCount: row['word_count'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// Result of an outline extraction.
class OutlineResult {
  final List<OutlineEntry> entries;
  final String documentId;

  OutlineResult({required this.entries, required this.documentId});

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'entries': entries.map((e) => e.toJson()).toList(),
        'count': entries.length,
      };
}
