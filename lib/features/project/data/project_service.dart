import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:lingbi/shared/interfaces/i_project_service.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project_storage_migration.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_brief_repository.dart';
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
    // The directory selected by the user is authoritative. This also makes
    // an interrupted storage move recoverable when metadata still has the
    // previous absolute path.
    project.directoryPath = directoryPath;

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

  /// Finds portable projects directly on disk, including projects that have
  /// not yet been indexed by ZVec.
  Future<List<Project>> discoverPortableProjects(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) return const [];

    final projects = <Project>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final metadata = File(p.join(entity.path, '.lingbi', 'project.json'));
      if (!await metadata.exists()) continue;
      try {
        final decoded = jsonDecode(await metadata.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        final project = Project.fromJson(decoded);
        // The directory entry is authoritative when legacy metadata contains
        // a stale path. This also keeps migration independent of ZVec.
        project.directoryPath = entity.path;
        projects.add(project);
      } on FormatException {
        // A malformed portable project is left in place for manual recovery.
      } on TypeError {
        // A malformed portable project is left in place for manual recovery.
      }
    }
    return projects;
  }

  /// Moves portable projects from one root to another without overwriting
  /// existing directories. Metadata and the optional ZVec index are updated
  /// atomically enough to roll back a failed move.
  @override
  Future<Result<ProjectStorageMigrationResult>> migratePortableProjects({
    required String oldRoot,
    required String newRoot,
  }) async {
    final targetRoot = Directory(newRoot);
    late final List<Project> projects;
    try {
      projects = await discoverPortableProjects(oldRoot);
    } catch (error) {
      return Result.failure(
        FileError('无法扫描旧存储目录', cause: error),
      );
    }
    if (projects.isEmpty || _samePath(oldRoot, newRoot)) {
      return Result.success(
        const ProjectStorageMigrationResult(migrated: 0, failed: 0),
      );
    }
    try {
      await targetRoot.create(recursive: true);
    } catch (error) {
      return Result.failure(
        FileError('无法创建新的存储目录', cause: error),
      );
    }

    var migrated = 0;
    var failed = 0;
    for (final project in projects) {
      final sourcePath = project.directoryPath;
      final targetPath = p.join(newRoot, p.basename(sourcePath));
      if (_samePath(sourcePath, targetPath) ||
          await Directory(targetPath).exists()) {
        failed++;
        continue;
      }

      final sourceProject = _projectWithDirectory(project, sourcePath);
      final targetProject = _projectWithDirectory(project, targetPath);
      try {
        targetProject.updatedAt = DateTime.now();
        await Directory(sourcePath).rename(targetPath);
        final metadataResult =
            await _writePortableMetadata(targetPath, targetProject);
        var metadataWritten = false;
        metadataResult.when(
          success: (_) => metadataWritten = true,
          failure: (_) {},
        );
        if (!metadataWritten) {
          failed++;
          await _rollbackMigration(
            sourceProject: sourceProject,
            sourcePath: sourcePath,
            targetPath: targetPath,
          );
          continue;
        }
        await _zvec?.upsert(
            'projects', targetProject.id, targetProject.toJson());
        migrated++;
      } catch (_) {
        failed++;
        await _rollbackMigration(
          sourceProject: sourceProject,
          sourcePath: sourcePath,
          targetPath: targetPath,
        );
      }
    }

    return Result.success(
      ProjectStorageMigrationResult(migrated: migrated, failed: failed),
    );
  }

  Project _projectWithDirectory(Project project, String directoryPath) {
    return Project(
      id: project.id,
      name: project.name,
      description: project.description,
      directoryPath: directoryPath,
      targetPlatform: project.targetPlatform,
      genre: project.genre,
      audience: project.audience,
      templateId: project.templateId,
      targetLength: project.targetLength,
      premise: project.premise,
      briefRevision: project.briefRevision,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    );
  }

  bool _samePath(String left, String right) =>
      p.normalize(p.absolute(left)).toLowerCase() ==
      p.normalize(p.absolute(right)).toLowerCase();

  Future<Result<void>> _writePortableMetadata(
    String projectPath,
    Project project,
  ) async {
    try {
      final metadata = File(p.join(projectPath, '.lingbi', 'project.json'));
      final decoded = jsonDecode(await metadata.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return Result.failure(
          FileError('project.json 必须是 JSON 对象'),
        );
      }
      final merged = <String, dynamic>{...decoded, ...project.toJson()};
      final temporary = File('${metadata.path}.tmp');
      final backup = File('${metadata.path}.migration.bak');
      await temporary.writeAsString(jsonEncode(merged), flush: true);
      if (await backup.exists()) await backup.delete();
      if (await metadata.exists()) await metadata.rename(backup.path);
      try {
        await temporary.rename(metadata.path);
        if (await backup.exists()) await backup.delete();
      } catch (error) {
        if (await metadata.exists()) await metadata.delete();
        if (await backup.exists()) await backup.rename(metadata.path);
        return Result.failure(
          FileError('无法更新便携项目元数据', cause: error),
        );
      }
      return Result.success(null);
    } catch (error) {
      return Result.failure(
        FileError('无法写入便携项目元数据', cause: error),
      );
    }
  }

  Future<void> _rollbackMigration({
    required Project sourceProject,
    required String sourcePath,
    required String targetPath,
  }) async {
    try {
      if (await Directory(targetPath).exists()) {
        await _writePortableMetadata(targetPath, sourceProject);
        await Directory(targetPath).rename(sourcePath);
      } else if (await Directory(sourcePath).exists()) {
        await _writePortableMetadata(sourcePath, sourceProject);
      }
      await _zvec?.upsert('projects', sourceProject.id, sourceProject.toJson());
    } catch (_) {
      // Keep the original exception as the migration result; recovery center
      // can handle a directory that could not be restored automatically.
    }
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
