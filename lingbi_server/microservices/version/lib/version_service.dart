import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';
import 'package:lzo/lzo.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// Represents a version snapshot of a document
class VersionSnapshot {
  final String id;
  final String docId;
  final String content;
  final String checksum;
  final String? comment;
  final DateTime timestamp;
  final String author;

  VersionSnapshot({
    required this.id,
    required this.docId,
    required this.content,
    required this.checksum,
    this.comment,
    required this.timestamp,
    required this.author,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'docId': docId,
        'content': content,
        'checksum': checksum,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
        'author': author,
      };

  factory VersionSnapshot.fromJson(Map<String, dynamic> json) {
    return VersionSnapshot(
      id: json['id'] as String,
      docId: json['docId'] as String,
      content: json['content'] as String,
      checksum: json['checksum'] as String,
      comment: json['comment'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      author: json['author'] as String,
    );
  }
}

/// Represents a diff between two versions
class VersionDiff {
  final String docId;
  final String version1;
  final String version2;
  final List<Map<String, dynamic>> changes;
  final DateTime timestamp;

  VersionDiff({
    required this.docId,
    required this.version1,
    required this.version2,
    required this.changes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'docId': docId,
        'version1': version1,
        'version2': version2,
        'changes': changes,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service for managing document version history with SQLite storage and LZO compression
class VersionService {
  late Database _db;
  String _dbPath = 'version_history.db';

  Future<void> init() async {
    _dbPath = path.join(
      Directory.current.path,
      'data',
      'version_history.db',
    );

    // Create data directory if it doesn't exist
    final dataDir = Directory(path.dirname(_dbPath));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    // Open or create database
    _db = open(databaseFile: _dbPath);

    // Create tables
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS version_snapshots (
        id TEXT PRIMARY KEY,
        doc_id TEXT NOT NULL,
        content BLOB NOT NULL,
        checksum TEXT NOT NULL,
        comment TEXT,
        timestamp TEXT NOT NULL,
        author TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_doc_id ON version_snapshots(doc_id)
    ''');

    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timestamp ON version_snapshots(timestamp)
    ''');
  }

  /// Create a new version snapshot with LZO compression
  VersionSnapshot createSnapshot({
    required String docId,
    required String content,
    String? comment,
    required String author,
  }) {
    final timestamp = DateTime.now();
    final checksum = _computeChecksum(content);
    final id = '${docId}_${timestamp.millisecondsSinceEpoch}';

    // Compress content using LZO
    final compressedContent = _compressContent(content);

    // Insert into database
    _db.execute(
      '''
      INSERT INTO version_snapshots (id, doc_id, content, checksum, comment, timestamp, author, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        docId,
        compressedContent,
        checksum,
        comment,
        timestamp.toIso8601String(),
        author,
        timestamp.toIso8601String(),
      ],
    );

    return VersionSnapshot(
      id: id,
      docId: docId,
      content: content, // Return uncompressed content
      checksum: checksum,
      comment: comment,
      timestamp: timestamp,
      author: author,
    );
  }

  /// Get all version history for a document
  List<VersionSnapshot> getVersionHistory(String docId) {
    final snapshots = <VersionSnapshot>[];

    final stmt = _db.prepare('''
      SELECT id, doc_id, content, checksum, comment, timestamp, author
      FROM version_snapshots
      WHERE doc_id = ?
      ORDER BY timestamp DESC
    ''');

    for (final row in stmt) {
      final compressedContent = row['content'] as Uint8List;
      final content = _decompressContent(compressedContent);

      snapshots.add(VersionSnapshot(
        id: row['id'] as String,
        docId: row['doc_id'] as String,
        content: content,
        checksum: row['checksum'] as String,
        comment: row['comment'] as String?,
        timestamp: DateTime.parse(row['timestamp'] as String),
        author: row['author'] as String,
      ));
    }

    return snapshots;
  }

  /// Get a specific version snapshot
  VersionSnapshot? getVersionSnapshot(String docId, String versionId) {
    final stmt = _db.prepare('''
      SELECT id, doc_id, content, checksum, comment, timestamp, author
      FROM version_snapshots
      WHERE id = ? AND doc_id = ?
    ''');

    final result = stmt.select([versionId, docId]);
    if (result.isEmpty) return null;

    final row = result.first;
    final compressedContent = row['content'] as Uint8List;
    final content = _decompressContent(compressedContent);

    return VersionSnapshot(
      id: row['id'] as String,
      docId: row['doc_id'] as String,
      content: content,
      checksum: row['checksum'] as String,
      comment: row['comment'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String),
      author: row['author'] as String,
    );
  }

  /// Get diff between two versions
  VersionDiff getDiff(String docId, String v1, String v2) {
    final snapshot1 = getVersionSnapshot(docId, v1);
    final snapshot2 = getVersionSnapshot(docId, v2);

    if (snapshot1 == null || snapshot2 == null) {
      throw Exception('One or both versions not found');
    }

    final changes = _computeDiff(snapshot1.content, snapshot2.content);
    final timestamp = DateTime.now();

    return VersionDiff(
      docId: docId,
      version1: v1,
      version2: v2,
      changes: changes,
      timestamp: timestamp,
    );
  }

  /// Compute checksum of content
  String _computeChecksum(String content) {
    final bytes = utf8.encode(content);
    final digest = md5.convert(bytes);
    return hex.encode(digest.bytes);
  }

  /// Compress content using LZO
  Uint8List _compressContent(String content) {
    final input = Uint8List.fromList(utf8.encode(content));
    final lzo = LZO();
    final compressed = lzo.compress(input);
    return Uint8List.fromList(compressed);
  }

  /// Decompress content using LZO
  String _decompressContent(Uint8List compressed) {
    final lzo = LZO();
    final decompressed = lzo.decompress(Uint8List.fromList(compressed));
    return utf8.decode(decompressed);
  }

  /// Simple diff algorithm (line-based)
  List<Map<String, dynamic>> _computeDiff(String content1, String content2) {
    final lines1 = content1.split('\n');
    final lines2 = content2.split('\n');
    final changes = <Map<String, dynamic>>[];

    // Simple line-by-line comparison
    final maxLen = lines1.length > lines2.length ? lines1.length : lines2.length;

    for (int i = 0; i < maxLen; i++) {
      final line1 = i < lines1.length ? lines1[i] : null;
      final line2 = i < lines2.length ? lines2[i] : null;

      if (line1 != line2) {
        if (line1 != null && line2 != null) {
          changes.add({
            'type': 'modified',
            'line': i + 1,
            'old': line1,
            'new': line2,
          });
        } else if (line1 != null) {
          changes.add({
            'type': 'removed',
            'line': i + 1,
            'old': line1,
          });
        } else {
          changes.add({
            'type': 'added',
            'line': i + 1,
            'new': line2!,
          });
        }
      }
    }

    return changes;
  }

  /// Dispose of the database connection
  void dispose() {
    _db.dispose();
  }
}
