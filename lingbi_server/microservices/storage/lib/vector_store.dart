import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

/// Vector Store service for storing and querying vectors with SQLite
class VectorStore {
  late Database _db;
  final String _dbName;

  VectorStore._(this._dbName);

  /// Initialize the vector store with SQLite database
  static Future<VectorStore> initialize(String dbName) async {
    final instance = VectorStore._(dbName);
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
    _db.execute('''
      CREATE TABLE IF NOT EXISTS vectors (
        id TEXT PRIMARY KEY,
        namespace TEXT NOT NULL DEFAULT 'default',
        vector BLOB NOT NULL,
        payload TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index for faster namespace filtering
    _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vectors_namespace 
      ON vectors(namespace)
    ''');
  }

  /// Upsert a vector with optional payload
  Future<void> upsert(String id, List<double> vector, 
      {String namespace = 'default', Map<String, dynamic>? payload}) async {
    final payloadJson = payload != null ? jsonEncode(payload) : null;
    final vectorBytes = _encodeVector(vector);

    await _db.execute('''
      INSERT OR REPLACE INTO vectors (id, namespace, vector, payload)
      VALUES (?, ?, ?, ?)
    ''', [id, namespace, vectorBytes, payloadJson]);
  }

  /// Search for similar vectors using cosine similarity
  Future<List<Map<String, dynamic>>> search(List<double> queryVector, 
      {int limit = 5, String namespace = 'default'}) async {
    
    final results = <Map<String, dynamic>>[];

    final query = _db.query('''
      SELECT id, vector, payload FROM vectors 
      WHERE namespace = ?
      LIMIT ?
    ''', [namespace, limit]);

    for (final row in query) {
      final storedVector = _decodeVector(row['vector'] as List<int>);
      final distance = _cosineDistance(queryVector, storedVector);
      
      results.add({
        'id': row['id'],
        'distance': distance,
        'payload': row['payload'] != null ? jsonDecode(row['payload']) : null,
      });
    }

    return results;
  }

  /// Get a vector by ID
  Future<Map<String, dynamic>?> getById(String id, 
      {String namespace = 'default'}) async {
    final query = _db.query('''
      SELECT id, vector, payload FROM vectors 
      WHERE id = ? AND namespace = ?
    ''', [id, namespace]);

    if (query.isEmpty) return null;

    final row = query.first;
    return {
      'id': row['id'],
      'vector': _decodeVector(row['vector'] as List<int>),
      'payload': row['payload'] != null ? jsonDecode(row['payload']) : null,
    };
  }

  /// Delete a vector by ID
  Future<void> delete(String id, {String namespace = 'default'}) async {
    await _db.execute('''
      DELETE FROM vectors WHERE id = ? AND namespace = ?
    ''', [id, namespace]);
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

  /// Close the database connection
  void close() {
    _db.close();
  }
}