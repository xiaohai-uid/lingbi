import 'dart:convert';
import 'dart:io';
import 'package:lingbi/services/interfaces/i_project_service.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/services/project_brief_repository.dart';
import 'package:lingbi/services/template_seeder.dart';

class ProjectService implements IProjectService {
  ProjectService({
    ZVecService? zvecService,
    FileService? fileService,
    TemplateSeeder? templateSeeder,
  })  : _zvec = zvecService,
        _fileService = fileService ?? FileService(),
        _templateSeeder = templateSeeder ?? const TemplateSeeder();
  final ZVecService? _zvec;
  final FileService _fileService;
  final TemplateSeeder _templateSeeder;

  /// 创建便携项目 — 先在磁盘建立目录和 .lingbi/project.json，
  /// 再写入 ZVec（若可用）。
  Future<Project> createPortableProject({
    String? name,
    required String directoryPath,
    String description = '',
    ProjectBrief? brief,
  }) async {
    if (brief == null && (name == null || name.trim().isEmpty)) {
      throw ArgumentError('name or brief is required');
    }
    final requestedBrief = brief ??
        ProjectBrief(
          title: name!.trim(),
          genreId: '',
          templateId: '',
          premise: description,
        );
    final project = Project(
      name: requestedBrief.title,
      description: requestedBrief.premise ?? description,
      directoryPath: directoryPath,
      targetPlatform: requestedBrief.targetPlatform ?? '',
      genre: requestedBrief.genreId,
      audience: requestedBrief.audience ?? '',
      templateId: requestedBrief.templateId,
      targetLength: requestedBrief.targetLength,
      premise: requestedBrief.premise ?? '',
      briefRevision: 1,
    );
    await Directory(directoryPath).create(recursive: true);
    // R3 修复：项目状态按目录寻址，同名新建会复用旧目录。
    // 创建新项目时清理残留的 project_meta/（引导状态 / 对话历史 / 设定资产）
    // 与 .lingbi/（旧项目元数据，避免 brief revision 冲突），
    // 使"同名新建"成为一个干净的新项目，不继承任何旧状态。
    final sep = Platform.pathSeparator;
    final staleMetaDir = Directory('$directoryPath${sep}project_meta');
    if (await staleMetaDir.exists()) {
      await staleMetaDir.delete(recursive: true);
    }
    final staleLingbiDir = Directory('$directoryPath$sep.lingbi');
    if (await staleLingbiDir.exists()) {
      await staleLingbiDir.delete(recursive: true);
    }
    final lingbiDir = Directory('$directoryPath/.lingbi');
    await lingbiDir.create();
    final committedBrief = await ProjectBriefRepository(directoryPath).write(
      requestedBrief,
      expectedRevision: 0,
      baseMetadata: project.toJson(),
    );
    project.briefRevision = committedBrief.revision;
    // R1 修复：消费模板 — 按 genreId 预填创作资料骨架，
    // 使新项目"打开即有用"，并为引导流程 / AI 续写提供上下文。
    if (requestedBrief.genreId.isNotEmpty) {
      await _templateSeeder.seedProject(
        projectDir: directoryPath,
        genreId: requestedBrief.genreId,
      );
    }
    await _zvec?.upsert('projects', project.id, project.toJson());
    return project;
  }

  /// 从目录打开便携项目 — 读取 .lingbi/project.json（若不存在则从目录名推断），
  /// 扫描磁盘 .md 文件重建文档列表。不要求 ZVec 可用。
  Future<({Project project, List<Document> documents})> openPortableProject(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw FileSystemException('项目目录不存在', directoryPath);
    }

    final sep = Platform.pathSeparator;
    final metaFile = File('$directoryPath$sep.lingbi${sep}project.json');
    Project project;
    if (metaFile.existsSync()) {
      final json =
          jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      project = Project.fromJson(json);
    } else {
      final normalPath = directoryPath.replaceAll(r'\', '/');
      final segments = normalPath.split('/');
      project = Project(
        name: segments.lastWhere((s) => s.isNotEmpty),
        directoryPath: normalPath,
      );
    }

    final docs = await scanDocumentsFromDisk(directoryPath, project.id);
    return (project: project, documents: docs);
  }

  /// 扫描目录中所有 .md 文件（跳过 .lingbi/），返回 Document 列表。
  Future<List<Document>> scanDocumentsFromDisk(
    String directoryPath,
    String projectId,
  ) async {
    return _fileService.scanMarkdownDocuments(directoryPath, projectId);
  }

  @override
  Future<Project> createProject({
    required String name,
    required String directoryPath,
    String description = '',
  }) async {
    final project = Project(
      name: name,
      description: description,
      directoryPath: directoryPath,
    );
    await _zvec?.upsert('projects', project.id, project.toJson());
    return project;
  }

  @override
  Future<List<Project>> getProjects() async {
    if (_zvec == null) return [];
    final results = await _zvec.query('projects');
    return results.map((json) => Project.fromJson(json)).toList();
  }

  @override
  Future<Project?> getProject(String id) async {
    if (_zvec == null) return null;
    final result = await _zvec.get<Map<String, dynamic>>('projects', id);
    if (result == null) return null;
    return Project.fromJson(result);
  }

  @override
  Future<void> updateProject(Project project) async {
    project.updatedAt = DateTime.now();
    await _zvec?.upsert('projects', project.id, project.toJson());
  }

  @override
  Future<void> deleteProject(String id) async {
    await _zvec?.delete('projects', id);
  }
}
