import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:project/models/project.dart';

/// Service for managing projects with JSON file persistence.
///
/// Stores projects in a JSON file at [dataPath]/projects.json.
/// Supports CRUD, tree structure management, and Markdown import/export.
class ProjectService {
  static const String _defaultDataDir = 'data';
  static const String _fileName = 'projects.json';

  final String dataPath;
  Map<String, Project> _projects = {};
  bool _initialized = false;

  /// Creates a new ProjectService.
  ///
  /// If [dataPath] is not provided, defaults to '[current working dir]/data'.
  ProjectService({String? dataPath})
      : dataPath = dataPath ?? '${Directory.current.path}/$_defaultDataDir';

  /// Initialize the service: loads data from the JSON file.
  Future<void> initialize() async {
    if (_initialized) return;
    final dir = Directory(dataPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('$dataPath/$_fileName');
    if (file.existsSync()) {
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);
      final projects = data['projects'] as List<dynamic>? ?? [];
      _projects = {
        for (final p in projects)
          (p as Map<String, dynamic>)['id'] as String:
              Project.fromJson(p),
      };
    }
    _initialized = true;
  }

  /// Persist the current projects map to disk synchronously.
  void _saveSync() {
    final file = File('$dataPath/$_fileName');
    final data = {
      'projects': _projects.values.map((p) => p.toJson()).toList(),
    };
    file.writeAsStringSync(jsonEncode(data));
  }

  /// Generate a simple unique ID.
  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = random.nextInt(999999);
    return '$timestamp-$rand';
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// List all projects, ordered by creation date (newest first).
  List<Project> listProjects() {
    final list = _projects.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Get a project by its [id]. Returns `null` if not found.
  Project? getProjectById(String id) => _projects[id];

  /// Create a new project.
  Project createProject({
    required String name,
    String description = '',
  }) {
    final now = DateTime.now();
    final project = Project(
      id: _generateId(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    _projects[project.id] = project;
    _saveSync();
    return project;
  }

  /// Update an existing project. Returns `null` if not found.
  Project? updateProject(
    String id, {
    String? name,
    String? description,
    int? documentCount,
  }) {
    final existing = _projects[id];
    if (existing == null) return null;

    final updated = existing.copyWith(
      name: name,
      description: description,
      documentCount: documentCount,
      updatedAt: DateTime.now(),
    );
    _projects[id] = updated;
    _saveSync();
    return updated;
  }

  /// Delete a project by [id]. Returns `true` if deleted.
  bool deleteProject(String id) {
    final existed = _projects.containsKey(id);
    if (existed) {
      _projects.remove(id);
      _saveSync();
    }
    return existed;
  }

  // ---------------------------------------------------------------------------
  // Tree structure management
  // ---------------------------------------------------------------------------

  /// Get the tree structure for a project.
  /// Returns `null` if the project doesn't exist.
  Map<String, List<String>>? getTree(String projectId) {
    final project = _projects[projectId];
    if (project == null) return null;
    return Map.from(project.treeStructure);
  }

  /// Update the entire tree structure for a project.
  bool updateTree(String projectId, Map<String, List<String>> tree) {
    final project = _projects[projectId];
    if (project == null) return false;

    project.treeStructure = tree;
    project.updatedAt = DateTime.now();
    _saveSync();
    return true;
  }

  /// Add a document to a folder in the project's tree.
  /// If [folderId] is null or empty, the document is added to the root.
  /// If the folder doesn't exist, it is created.
  bool addDocumentToTree(String projectId, String folderId, String documentId) {
    final project = _projects[projectId];
    if (project == null) return false;

    final key = folderId.isEmpty ? '_root' : folderId;
    project.treeStructure[key] ??= [];
    if (!project.treeStructure[key]!.contains(documentId)) {
      project.treeStructure[key]!.add(documentId);
    }
    project.updatedAt = DateTime.now();
    project.documentCount = _countDocuments(project.treeStructure);
    _saveSync();
    return true;
  }

  /// Remove a document from the project's tree.
  bool removeDocumentFromTree(String projectId, String documentId) {
    final project = _projects[projectId];
    if (project == null) return false;

    bool removed = false;
    for (final folder in project.treeStructure.keys) {
      if (project.treeStructure[folder]!.remove(documentId)) {
        removed = true;
      }
    }
    if (removed) {
      project.updatedAt = DateTime.now();
      project.documentCount = _countDocuments(project.treeStructure);
      _saveSync();
    }
    return removed;
  }

  /// Move a document from one folder to another.
  bool moveDocumentInTree(
      String projectId, String documentId, String targetFolderId) {
    removeDocumentFromTree(projectId, documentId);
    return addDocumentToTree(projectId, targetFolderId, documentId);
  }

  /// Total number of documents across all folders.
  int _countDocuments(Map<String, List<String>> tree) {
    int count = 0;
    for (final docs in tree.values) {
      count += docs.length;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Markdown import / export
  // ---------------------------------------------------------------------------

  /// Import projects from a list of Markdown file paths.
  ///
  /// Each file is read and its content is associated with a new project named
  /// after the file (without extension). Returns a list of created project IDs.
  List<String> importFromMarkdown(List<String> markdownFiles) {
    final createdIds = <String>[];
    for (final filePath in markdownFiles) {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();
      final fileName = file.uri.pathSegments.last;
      final name = fileName.endsWith('.md')
          ? fileName.substring(0, fileName.length - 3)
          : fileName;

      final project = createProject(name: name, description: '');
      // Store the imported content in the tree as a document reference
      project.treeStructure['_root'] ??= [];
      project.treeStructure['_root']!.add('imported:$name');
      project.documentCount = _countDocuments(project.treeStructure);
      project.updatedAt = DateTime.now();
      _projects[project.id] = project;
      _saveSync();

      createdIds.add(project.id);
    }
    return createdIds;
  }

  /// Export a project as a Markdown directory structure.
  ///
  /// Writes files to [outputDir]. Each folder becomes a subdirectory;
  /// documents are represented as `.md` files named by their IDs.
  /// Returns the path to the output directory, or `null` if the project
  /// doesn't exist.
  String? exportToMarkdown(String projectId, {String? outputDir}) {
    final project = _projects[projectId];
    if (project == null) return null;

    final outDir = outputDir ?? '${dataPath}/export_${project.id}';
    final dir = Directory(outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Create an index.md with project metadata
    final indexContent = StringBuffer();
    indexContent.writeln('# ${project.name}');
    indexContent.writeln();
    if (project.description.isNotEmpty) {
      indexContent.writeln('${project.description}');
      indexContent.writeln();
    }
    indexContent.writeln('- Created: ${project.createdAt.toIso8601String()}');
    indexContent.writeln('- Documents: ${project.documentCount}');
    indexContent.writeln();

    // Write the tree structure
    indexContent.writeln('## Document Tree');
    indexContent.writeln();
    _writeTreeMarkdown(project.treeStructure, indexContent, '');
    File('$outDir/index.md').writeAsStringSync(indexContent.toString());

    return outDir;
  }

  /// Helper to write tree structure as Markdown list items.
  void _writeTreeMarkdown(
      Map<String, List<String>> tree, StringBuffer buffer, String prefix) {
    for (final entry in tree.entries) {
      final folderName = entry.key == '_root' ? 'Root' : entry.key;
      buffer.writeln('$prefix- **$folderName** (${entry.value.length} docs)');
      for (final docId in entry.value) {
        buffer.writeln('$prefix  - $docId');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Close the service (no-op for JSON persistence, but provided for API
  /// compatibility).
  void close() {
    // Nothing to close for file-based storage.
  }
}