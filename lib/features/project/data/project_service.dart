import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:lingbi/shared/interfaces/i_project_service.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project_storage_migration.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_brief_repository.dart';
import 'package:lingbi/services/migrations/legacy_canonical_reader.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';
import 'package:lingbi/services/template_seeder.dart';

/// 项目身份分类（MP-09）：同一 id 出现在多个目录时的处理。
enum ProjectIdentityKind { unique, moved, duplicateCopy }

final class ProjectIdentity {
  const ProjectIdentity({
    required this.kind,
    required this.project,
    this.existingDirectory,
  });

  final ProjectIdentityKind kind;
  final Project project;

  /// duplicateCopy/moved 时原注册目录（若可知）。
  final String? existingDirectory;
}

class ProjectService implements IProjectService {
  ProjectService({
    ZVecService? zvecService,
    FileService? fileService,
    TemplateSeeder? templateSeeder,
    MutationProtocol? mutationProtocol,
  })  : _zvec = zvecService,
        _fileService = fileService ?? FileService(),
        _templateSeeder = templateSeeder ?? const TemplateSeeder(),
        _mutationProtocol = mutationProtocol;
  final ZVecService? _zvec;
  final FileService _fileService;
  final TemplateSeeder _templateSeeder;

  /// 变更协议：brief 写入经由此接口（fail-closed，缺失时拒绝写入）。
  ///
  /// 生产环境存在 resolver→protocol→projectService 的构造环，因此先创建
  /// 裸 ProjectService 供 resolver，protocol 建好后通过 [mutationProtocol]
  /// setter 回填。
  MutationProtocol? _mutationProtocol;

  set mutationProtocol(MutationProtocol? protocol) {
    _mutationProtocol = protocol;
  }

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
    final zvec = _zvec;
    if (zvec != null) {
      await zvec.upsert('projects', project.id, project.toJson());
    }
    try {
      final committedBrief = await ProjectBriefRepository(
        directoryPath,
        mutationProtocol: _mutationProtocol,
      ).write(
        requestedBrief,
        expectedRevision: 0,
        baseMetadata: project.toJson(),
        projectId: project.id,
      );
      project.briefRevision = committedBrief.revision;
    } catch (error) {
      if (zvec != null) {
        try {
          await zvec.delete('projects', project.id);
        } catch (_) {}
      }
      rethrow;
    }
    // R1 修复：消费模板 — 按 genreId 预填创作资料骨架，
    // 使新项目"打开即有用"，并为引导流程 / AI 续写提供上下文。
    if (requestedBrief.genreId.isNotEmpty) {
      await _templateSeeder.seedProject(
        projectDir: directoryPath,
        genreId: requestedBrief.genreId,
      );
    }
    await zvec?.upsert('projects', project.id, project.toJson());
    return project;
  }

  /// 从目录打开便携项目 — 读取 .lingbi/project.json（若不存在则从目录名推断），
  /// 扫描磁盘 .md 文件重建文档列表。不要求 ZVec 可用。
  ///
  /// MP-09: legacy 元数据（无 schemaVersion）只读打开，绝不改写；
  /// 返回身份分类（unique / moved / duplicateCopy）。
  Future<
      ({
        Project project,
        List<Document> documents,
        ProjectIdentity identity,
      })> openPortableProject(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw FileSystemException('项目目录不存在', directoryPath);
    }

    final kind = await LegacyCanonicalReader.inspect(directoryPath);
    Project project;
    if (kind == ProjectMetadataKind.legacy) {
      // 只读打开：legacy 元数据不经修改、不索引（Task 9）。
      final legacy = LegacyCanonicalReader.projectFromLegacy(directoryPath);
      if (legacy == null) {
        throw FileSystemException('项目元数据不可读', directoryPath);
      }
      project = legacy;
      final docs = await scanDocumentsFromDisk(directoryPath, project.id);
      return (
        project: project,
        documents: docs,
        identity: classifyIdentity(
          project,
          knownProjects: await _knownProjects(),
        ),
      );
    }

    final sep = Platform.pathSeparator;
    final metaFile = File('$directoryPath$sep.lingbi${sep}project.json');
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

    // Classify BEFORE any index write: the pre-open registry still carries
    // the original location, which distinguishes move from duplicate copy.
    final known = await _knownProjects();
    final identity = classifyIdentity(project, knownProjects: known);
    // Block: a duplicate copy is never silently registered under the
    // original id; the user must explicitly adopt a new identity.
    if (identity.kind != ProjectIdentityKind.duplicateCopy) {
      await _zvec?.upsert('projects', project.id, project.toJson());
    }
    final docs = await scanDocumentsFromDisk(directoryPath, project.id);
    return (project: project, documents: docs, identity: identity);
  }

  /// 分类项目身份（MP-09）：
  /// - 同一 id 未在已知项目中 → unique
  /// - 同一 id 的原注册目录已不存在 → moved（目录重绑）
  /// - 同一 id 的原注册目录仍在 → duplicateCopy（必须显式采纳新身份）
  ProjectIdentity classifyIdentity(
    Project project, {
    required List<Project> knownProjects,
  }) {
    Project? sameId;
    for (final known in knownProjects) {
      if (known.id == project.id) {
        sameId = known;
        break;
      }
    }
    if (sameId == null) {
      return ProjectIdentity(
          kind: ProjectIdentityKind.unique, project: project);
    }
    if (p.equals(p.normalize(sameId.directoryPath),
        p.normalize(project.directoryPath))) {
      return ProjectIdentity(
          kind: ProjectIdentityKind.unique, project: project);
    }
    if (Directory(sameId.directoryPath).existsSync()) {
      return ProjectIdentity(
        kind: ProjectIdentityKind.duplicateCopy,
        project: project,
        existingDirectory: sameId.directoryPath,
      );
    }
    return ProjectIdentity(
      kind: ProjectIdentityKind.moved,
      project: project,
      existingDirectory: sameId.directoryPath,
    );
  }

  /// 把重复副本采纳为独立项目：分配新 ID 与 provenance，
  /// 并经 MutationProtocol 重写 .lingbi/project.json（fail-closed）。
  Future<Result<Project>> adoptIndependentCopy(String directoryPath) async {
    final raw = await LegacyCanonicalReader.readRawMetadata(directoryPath);
    final current = LegacyCanonicalReader.projectFromLegacy(directoryPath);
    if (current == null || raw == null) {
      return Result.failure(FileError(
        '项目元数据不可读: $directoryPath',
        code: 'NOT_FOUND',
      ));
    }
    final protocol = _mutationProtocol;
    if (protocol == null) {
      return Result.failure(FileError(
        'MutationProtocol required for identity adoption (fail-closed)',
        code: 'PROTOCOL_REQUIRED',
      ));
    }

    final copy = Project(
      name: current.name,
      description: current.description,
      directoryPath: directoryPath,
      targetPlatform: current.targetPlatform,
      genre: current.genre,
      audience: current.audience,
      templateId: current.templateId,
      targetLength: current.targetLength,
      premise: current.premise,
      provenance: 'copy-of:${current.id}',
    );
    final zvec = _zvec;
    if (zvec != null) {
      await zvec.upsert('projects', copy.id, copy.toJson());
    }
    final nested = raw['projectBrief'];
    final brief = nested is Map<String, dynamic>
        ? ProjectBrief.fromJson(nested)
        : ProjectBrief(
            title: current.name,
            genreId: current.genre,
            templateId: current.templateId,
            premise: current.premise,
          );

    try {
      await ProjectBriefRepository(
        directoryPath,
        mutationProtocol: protocol,
      ).write(
        brief,
        expectedRevision: current.briefRevision,
        baseMetadata: {
          ...raw,
          'schemaVersion': SchemaVersions.project,
          'id': copy.id,
          'name': copy.name,
          'directoryPath': directoryPath,
          if (copy.provenance != null) 'provenance': copy.provenance,
        },
        projectId: copy.id,
      );
    } catch (error) {
      if (zvec != null) {
        try {
          await zvec.delete('projects', copy.id);
        } catch (_) {}
      }
      return Result.failure(FileError(
        '身份采纳失败: $error',
        code: 'ADOPT_FAILED',
      ));
    }
    return Result.success(copy);
  }

  Future<List<Project>> _knownProjects() async {
    final zvec = _zvec;
    if (zvec == null) return const [];
    final results = await zvec.query('projects');
    return results
        .map((json) {
          try {
            return Project.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<Project>()
        .toList();
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
