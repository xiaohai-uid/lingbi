import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:project/lib/models/project.dart';

/// Service for managing projects with SQLite persistence.
class ProjectService {
  late Database _database;

  /// Initialize the database and create tables if they don't exist.
  Future<void> initialize() async {
    // Use a database file in the project directory
    final dbPath = Directory.current.path + '/data/projects.db';
    final dbDir = Directory(dbPath.substring(0, dbPath.lastIndexOf('/')));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    _database = sqlite3.open(dbPath);
    await _createTables();
  }

  /// Create the projects table if it doesn't exist.
  Future<void> _createTables() async {
    _database.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        directory_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index for faster lookups by name
    _database.execute('''
      CREATE INDEX IF NOT EXISTS idx_projects_name ON projects(name)
    ''');
  }

  /// List all projects.
  List<Project> listProjects() {
    final rows = _database.query('SELECT * FROM projects ORDER BY created_at DESC');
    return rows.map((row) => Project.fromRow(row)).toList();
  }

  /// Get a project by ID.
  Project? getProjectById(int id) {
    final rows = _database.query('SELECT * FROM projects WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Project.fromRow(rows.first);
  }

  /// Create a new project.
  Project createProject({
    required String name,
    required String description,
    required String directoryPath,
  }) {
    final now = DateTime.now().toIso8601String();
    final result = _database.insert(
      'projects',
      {
        'name': name,
        'description': description,
        'directory_path': directoryPath,
        'created_at': now,
        'updated_at': now,
      },
      mode: InsertMode.insert,
    );

    return Project(
      id: result,
      name: name,
      description: description,
      directoryPath: directoryPath,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
  }

  /// Update an existing project.
  Project? updateProject(int id, {
    String? name,
    String? description,
    String? directoryPath,
  }) {
    final existing = getProjectById(id);
    if (existing == null) return null;

    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (directoryPath != null) updates['directory_path'] = directoryPath;
    updates['updated_at'] = now;

    _database.update(
      'projects',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );

    return getProjectById(id);
  }

  /// Delete a project by ID.
  bool deleteProject(int id) {
    final result = _database.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  /// Close the database connection.
  void close() {
    _database.dispose();
  }
}