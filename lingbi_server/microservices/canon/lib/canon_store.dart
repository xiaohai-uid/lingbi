import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Valid canon entry types
const List<String> validEntryTypes = ['character', 'location', 'lore', 'plotNode'];

/// Canon Store service for managing story elements with SQLite and semantic search
class CanonStore {
  late Database _db;
  final String _dbName;
  final Uuid _uuid = const Uuid();

  CanonStore._(this._dbName);

  /// Initialize the canon store with SQLite database
  static Future<CanonStore> initialize(String dbName) async {
    final instance = CanonStore._(dbName);
    await instance._initDatabase();
    return instance;
  }

  /// Initialize SQLite database and create necessary tables
  Future<void> _initDatabase() async {
    final dbDir = path.dirname(_dbName);
    if (dbDir.isNotEmpty && !Directory(dbDir).existsSync()) {
      Directory(dbDir).createSync(recursive: true);
    }

    _db = Database.open(_dbName);

    // Create canon entries table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS canon_entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        tags TEXT,
        metadata TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index for faster type filtering
    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_canon_type 
      ON canon_entries(type)
    ''');

    // Create index for faster search by name
    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_canon_name 
      ON canon_entries(name)
    ''');

    // Create vectors table for semantic search
    _db.execute('''
      CREATE TABLE IF NOT EXISTS canon_vectors (
        id TEXT PRIMARY KEY,
        canon_id TEXT NOT NULL,
        vector BLOB NOT NULL,
        FOREIGN KEY (canon_id) REFERENCES canon_entries(id) ON DELETE CASCADE
      )
    ''');

    // Create index for canon_id
    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_canon_vectors_canon_id 
      ON canon_vectors(canon_id)
    ''');
  }

  /// Create a new canon entry
  Future<Map<String, dynamic>> create(String type, String name, 
      {String? description, List<String>? tags, Map<String, dynamic>? metadata}) async {
    
    if (!validEntryTypes.contains(type)) {
      throw Exception('Invalid entry type. Must be one of: ${validEntryTypes.join(', ')}');
    }

    final id = _uuid.v4();
    final tagsJson = tags != null ? jsonEncode(tags) : null;
    final metadataJson = metadata != null ? jsonEncode(metadata) : null;

    await _db.execute('''
      INSERT INTO canon_entries (id, type, name, description, tags, metadata)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [id, type, name, description, tagsJson, metadataJson]);

    return getById(id)!;
  }

  /// Get all canon entries, optionally filtered by type
  Future<List<Map<String, dynamic>>> list({String? type}) async {
    final results = <Map<String, dynamic>>[];

    if (type != null) {
      final query = _db.query('SELECT * FROM canon_entries WHERE type = ?', [type]);
      for (final row in query) {
        results.add(_rowToMap(row));
      }
    } else {
      final query = _db.query('SELECT * FROM canon_entries');
      for (final row in query) {
        results.add(_rowToMap(row));
      }
    }

    return results;
  }

  /// Get a canon entry by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    final query = _db.query('SELECT * FROM canon_entries WHERE id = ?', [id]);

    if (query.isEmpty) return null;

    return _rowToMap(query.first);
  }

  /// Update a canon entry
  Future<Map<String, dynamic>?> update(String id, 
      {String? name, String? description, List<String>? tags, Map<String, dynamic>? metadata}) async {
    
    final existing = await getById(id);
    if (existing == null) return null;

    final nameValue = name ?? existing['name'];
    final descValue = description ?? existing['description'];
    final tagsValue = tags != null ? jsonEncode(tags) : existing['tags'];
    final metadataValue = metadata != null ? jsonEncode(metadata) : existing['metadata'];

    await _db.execute('''
      UPDATE canon_entries 
      SET name = ?, description = ?, tags = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    ''', [nameValue, descValue, tagsValue, metadataValue, id]);

    return getById(id);
  }

  /// Delete a canon entry by ID
  Future<bool> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return false;

    await _db.execute('DELETE FROM canon_entries WHERE id = ?', [id]);
    return true;
  }

  /// Search canon entries using semantic similarity
  Future<List<Map<String, dynamic>>> search(List<double> queryVector, 
      {int limit = 5, String? type}) async {
    
    final results = <Map<String, dynamic>>[];

    // Build query with optional type filter
    String whereClause = 'WHERE 1=1';
    List<dynamic> params = [];

    if (type != null) {
      whereClause += ' AND e.type = ?';
      params.add(type);
    }

    // Get all canon entries with their vectors
    final query = _db.query('''
      SELECT e.*, v.vector 
      FROM canon_entries e
      LEFT JOIN canon_vectors v ON e.id = v.canon_id
      $whereClause
    ''', params);

    for (final row in query) {
      // Skip entries without vectors
      if (row['vector'] == null) continue;

      final storedVector = _decodeVector(row['vector'] as List<int>);
      final distance = _cosineDistance(queryVector, storedVector);
      
      results.add({
        ..._rowToMap(row),
        'distance': distance,
      });
    }

    // Sort by distance (lower is better)
    results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return results.take(limit).toList();
  }

  /// Store or update vector for a canon entry
  Future<void> storeVector(String canonId, List<double> vector) async {
    // Encode vector to byte array
    final vectorBytes = _encodeVector(vector);

    await _db.execute('''
      INSERT OR REPLACE INTO canon_vectors (id, canon_id, vector)
      VALUES (?, ?, ?)
    ''', [_uuid.v4(), canonId, vectorBytes]);
  }

  /// Encode vector to byte array
  List<int> _encodeVector(List<double> vector) {
    final buffer = Float64List(vector.length).buffer.asByteData();
    for (int i = 0; i < vector.length; i++) {
      buffer.setFloat64(i * 8, vector[i]);
    }
    return buffer.buffer.asUint8List();
  }

  /// Decode vector from byte array
  List<double> _decodeVector(List<int> bytes) {
    final buffer = Float64List.fromList(bytes.map((b) => b.toDouble()).toList());
    final byteData = buffer.buffer.asByteData();
    final length = buffer.length;
    return List<double>.generate(length, (i) => byteData.getDouble(i * 8));
  }

  /// Calculate cosine distance between two vectors
  double _cosineDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw Exception('Vector dimensions must match');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = normA.sqrt();
    normB = normB.sqrt();

    if (normA == 0 || normB == 0) return 1.0;

    final similarity = dotProduct / (normA * normB);
    return 1.0 - similarity; // Convert to distance
  }

  /// Convert database row to map
  Map<String, dynamic> _rowToMap(dynamic row) {
    return {
      'id': row['id'],
      'type': row['type'],
      'name': row['name'],
      'description': row['description'] ?? '',
      'tags': row['tags'] != null ? jsonDecode(row['tags']) : [],
      'metadata': row['metadata'] != null ? jsonDecode(row['metadata']) : {},
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  /// Close the database connection
  void close() {
    _db.close();
  }
}
