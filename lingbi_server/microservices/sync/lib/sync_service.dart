import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:webdav_client/client.dart' as webdav;
import 'conflict_resolver.dart';
import 'webdav_client.dart';

class SyncService {
  Database? _db;
  late ConflictResolver conflictResolver;
  late WebDAVClient webdavClient;
  String? _configPath;
  bool _isRunning = false;
  final Map<String, dynamic> _config = {};
  final Map<String, dynamic> _status = {
    'lastSync': null,
    'status': 'idle',
    'filesSynced': 0,
    'errors': 0,
  };

  Future<SyncService> initialize() async {
    await _initDatabase();
    conflictResolver = ConflictResolver();
    webdavClient = WebDAVClient();
    _loadConfig();
    return this;
  }

  Future<void> _initDatabase() async {
    final dbPath = path.join('data', 'sync.db');
    _db = Database(path.dirname(dbPath), path.basename(dbPath));
    
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS sync_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        source TEXT NOT NULL,
        destination TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        conflict_resolved INTEGER DEFAULT 0,
        conflict_strategy TEXT,
        error_message TEXT
      )
    ''');
    
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS sync_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  void _loadConfig() {
    final rows = _db?.query('SELECT * FROM sync_config') ?? [];
    for (final row in rows) {
      _config[row['key']] = row['value'];
    }
  }

  Future<void> startSync(String sourcePath, String destPath) async {
    if (_isRunning) {
      throw StateError('Sync already running');
    }

    _isRunning = true;
    _status['status'] = 'running';

    try {
      await _performSync(sourcePath, destPath);
      _status['status'] = 'success';
      _status['lastSync'] = DateTime.now().toIso8601String();
    } catch (e) {
      _status['status'] = 'error';
      _status['errors']++;
      print('Sync failed: $e');
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _performSync(String sourcePath, String destPath) async {
    // Here you would integrate with Rclone for actual file sync
    // This is a simplified version that demonstrates the structure
    
    // List files in source
    // For each file, check if it exists in destination
    // If exists, compare checksums
    // If different, resolve conflict
    // If not exists, copy
    
    // Using Rclone (pseudo-code, actual implementation would use rclone_dart package)
    // await rclone.sync(sourcePath, destPath, options: rcloneOptions);
    
    _status['filesSynced'] = 0; // Would be incremented by actual sync
    
    // Log sync completion
    await _db!.execute(
      'INSERT INTO sync_history (file_path, source, destination, action) VALUES (?, ?, ?, ?)',
      [sourcePath, destPath, 'sync'],
    );
  }

  Future<void> setConfig(String key, dynamic value) async {
    _config[key] = value;
    await _db!.execute(
      'INSERT OR REPLACE INTO sync_config (key, value) VALUES (?, ?)',
      [key, value.toString()],
    );
  }

  Future<Map<String, dynamic>> getConfig() async {
    return Map<String, dynamic>.from(_config);
  }

  Map<String, dynamic> getStatus() {
    return Map<String, dynamic>.from(_status);
  }

  Future<void> stopSync() async {
    _isRunning = false;
    _status['status'] = 'stopped';
  }

  Future<void> dispose() async {
    await stopSync();
    _db?.close();
  }
}