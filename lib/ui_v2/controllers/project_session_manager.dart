import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../shared/models/document.dart';
import '../../shared/models/project.dart';
import '../../domain/project/project_brief.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/features/writing/data/pipeline/project_session_scope.dart';
import '../../services/ai_service.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import '../../services/document_service.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

/// The durable, UI-facing state for one opened project.
class ProjectSessionSnapshot {
  const ProjectSessionSnapshot({
    required this.project,
    required this.documents,
    this.selectedDocument,
  });

  final Project project;
  final List<Document> documents;
  final Document? selectedDocument;

  ProjectSessionSnapshot copyWith({
    List<Document>? documents,
    Document? selectedDocument,
  }) =>
      ProjectSessionSnapshot(
        project: project,
        documents: documents ?? this.documents,
        selectedDocument: selectedDocument ?? this.selectedDocument,
      );
}

/// Owns every Windows Desktop project create/open/select transition.
///
/// Widgets ask this manager for a session instead of separately opening a
/// project, indexing documents, creating chapters and binding the AI scope.
class ProjectSessionManager extends ChangeNotifier {
  ProjectSessionManager({
    required DocumentService documentService,
    required CanonService canonService,
    required AIService aiService,
    ProjectService? projectService,
    this.recentStateFilePath,
    MutationProtocol? mutationProtocol,
  })  : _mutationProtocol = mutationProtocol,
        _documentService = documentService,
        _canonService = canonService,
        _aiService = aiService,
        _projectService = projectService ??
            ProjectService(mutationProtocol: mutationProtocol);

  static const _projectStateRelativePath = '.lingbi/session.json';

  final DocumentService _documentService;
  final CanonService _canonService;
  final AIService _aiService;
  final MutationProtocol? _mutationProtocol;
  final ProjectService _projectService;

  /// Optional app-level recent-project index. Tests inject a disposable path;
  /// production wires one under the application documents directory.
  final String? recentStateFilePath;

  ProjectSessionScope? _activeScope;
  ProjectSessionSnapshot? _activeSession;
  final Map<String, ProjectSessionScope> _openScopes = {};

  ProjectSessionScope? get activeScope => _activeScope;
  ProjectSessionSnapshot? get activeSession => _activeSession;
  Project? get activeProject => _activeSession?.project;
  Document? get selectedDocument => _activeSession?.selectedDocument;
  String? get activeProjectId => _activeScope?.projectId;
  NovelApplicationService? get activeNovelService => _activeScope?.novelService;
  bool get hasActiveProject => _activeScope != null;

  Future<ProjectSessionSnapshot> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  }) async {
    final project = await _projectService.createPortableProject(
      directoryPath: directoryPath,
      brief: brief,
    );
    return _activate(project: project, documents: const []);
  }

  Future<ProjectSessionSnapshot> openProjectDirectory(
    String directoryPath,
  ) async {
    final opened = await _projectService.openPortableProject(directoryPath);
    if (opened.identity.kind == ProjectIdentityKind.duplicateCopy) {
      throw StateError(
        '重复副本未注册为独立项目，请先采用独立身份，禁止直接编辑',
      );
    }
    final restoredDocument = await _readSelectedDocument(opened.project);
    final documents = [...opened.documents];
    if (restoredDocument != null) {
      final restoredPath = _normalPath(restoredDocument.filePath);
      documents.removeWhere(
        (document) => _normalPath(document.filePath) == restoredPath,
      );
      documents.insert(0, restoredDocument);
    }
    return _activate(
      project: opened.project,
      documents: documents,
      selectedDocument: restoredDocument,
    );
  }

  Future<ProjectSessionSnapshot?> resumeRecentProject() async {
    final paths = await _readRecentPaths();
    for (final path in paths) {
      if (await Directory(path).exists()) {
        return openProjectDirectory(path);
      }
    }
    return null;
  }

  Future<List<Project>> loadRecentProjects() async {
    final projects = <Project>[];
    for (final path in await _readRecentPaths()) {
      try {
        projects.add((await _projectService.openPortableProject(path)).project);
      } on FileSystemException {
        // A moved/deleted project is omitted without blocking the welcome UI.
      } on FormatException {
        // A damaged recent entry remains recoverable from Open Project.
      }
    }
    return projects;
  }

  /// Creates the first chapter when needed, selects it and binds the AI scope.
  Future<Document> openFirstChapter() async {
    final session = _activeSession;
    if (session == null) throw StateError('请先创建或打开项目');

    Document? chapter;
    for (final document in session.documents) {
      if (document.title == '第一章') {
        chapter = document;
        break;
      }
    }
    chapter ??= await _documentService.createDocument(
      projectId: session.project.id,
      title: '第一章',
      directoryPath: '${session.project.directoryPath}/chapters',
    );

    final documents = [...session.documents];
    if (!documents.any((document) => document.id == chapter!.id)) {
      documents.add(chapter);
    }
    await selectDocument(chapter, documents: documents);
    return chapter;
  }

  Future<void> selectDocument(
    Document document, {
    List<Document>? documents,
  }) async {
    final session = _activeSession;
    if (session == null || document.projectId != session.project.id) {
      throw StateError('章节不属于当前项目');
    }
    _activeScope?.bindChapter(
      chapterId: document.id,
      filePath: document.filePath,
    );
    _activeSession = session.copyWith(
      documents: documents,
      selectedDocument: document,
    );
    await _persistActiveSession();
    notifyListeners();
  }

  /// Low-level scope opener kept for pipeline callers. UI project lifecycle
  /// must use [createProject] or [openProjectDirectory].
  ProjectSessionScope openProject({
    required String projectId,
    required String projectDir,
  }) {
    final existing = _openScopes[projectId];
    if (existing != null) {
      _activeScope = existing;
      notifyListeners();
      return existing;
    }

    final scope = ProjectSessionScope(
      projectId: projectId,
      projectDir: projectDir,
      documentService: _documentService,
      canonService: _canonService,
      aiService: _aiService,
      mutationProtocol: _mutationProtocol,
    );
    _openScopes[projectId] = scope;
    _activeScope = scope;
    notifyListeners();
    return scope;
  }

  ProjectSessionScope? switchToProject(String projectId) {
    final scope = _openScopes[projectId];
    if (scope == null) return null;
    _activeScope?.unbindChapter();
    _activeScope = scope;
    notifyListeners();
    return scope;
  }

  void closeProject(String projectId) {
    final scope = _openScopes[projectId];
    if (scope == null) return;
    if (_activeScope?.projectId == projectId) {
      _activeScope = null;
      _activeSession = null;
    }
    scope.dispose();
    _openScopes.remove(projectId);
    notifyListeners();
  }

  void closeAll() {
    for (final scope in _openScopes.values) {
      scope.dispose();
    }
    _openScopes.clear();
    _activeScope = null;
    _activeSession = null;
    notifyListeners();
  }

  ProjectSessionScope? getScope(String projectId) => _openScopes[projectId];
  bool isProjectOpen(String projectId) => _openScopes.containsKey(projectId);

  Future<ProjectSessionSnapshot> _activate({
    required Project project,
    required List<Document> documents,
    Document? selectedDocument,
  }) async {
    final scope = openProject(
      projectId: project.id,
      projectDir: project.directoryPath,
    );
    if (selectedDocument != null) {
      scope.bindChapter(
        chapterId: selectedDocument.id,
        filePath: selectedDocument.filePath,
      );
    }
    final snapshot = ProjectSessionSnapshot(
      project: project,
      documents: List.unmodifiable(documents),
      selectedDocument: selectedDocument,
    );
    _activeSession = snapshot;
    await _rememberProject(project.directoryPath);
    await _persistActiveSession();
    notifyListeners();
    return snapshot;
  }

  Future<Document?> _readSelectedDocument(Project project) async {
    final file = File('${project.directoryPath}/$_projectStateRelativePath');
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map || json['selectedDocument'] is! Map) return null;
      final document = Document.fromJson(
        Map<String, dynamic>.from(json['selectedDocument'] as Map),
      );
      if (document.projectId != project.id ||
          !await File(document.filePath).exists()) {
        return null;
      }
      return document;
    } on FormatException {
      return null;
    }
  }

  Future<void> _persistActiveSession() async {
    final session = _activeSession;
    if (session == null) return;
    final file = File(
      '${session.project.directoryPath}/$_projectStateRelativePath',
    );
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({
      'projectId': session.project.id,
      if (session.selectedDocument != null)
        'selectedDocument': session.selectedDocument!.toJson(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }));
    await temp.rename(file.path);
  }

  Future<void> _rememberProject(String directoryPath) async {
    final registryPath = recentStateFilePath;
    if (registryPath == null) return;
    final paths = await _readRecentPaths();
    paths
        .removeWhere((path) => _normalPath(path) == _normalPath(directoryPath));
    paths.insert(0, directoryPath);
    if (paths.length > 5) paths.removeRange(5, paths.length);
    final file = File(registryPath);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({'projects': paths}));
    await temp.rename(file.path);
  }

  Future<List<String>> _readRecentPaths() async {
    final registryPath = recentStateFilePath;
    if (registryPath == null) return [];
    final file = File(registryPath);
    if (!await file.exists()) return [];
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map || json['projects'] is! List) return [];
      return (json['projects'] as List)
          .whereType<String>()
          .where((path) => path.trim().isNotEmpty)
          .toList();
    } on FormatException {
      return [];
    }
  }

  String _normalPath(String path) => path.replaceAll(r'\', '/').toLowerCase();

  @override
  void dispose() {
    closeAll();
    super.dispose();
  }
}
