import 'dart:convert';
import 'dart:io';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/project/data/project_service.dart';

/// 当前 schema 版本
const int currentMetaSchemaVersion = 1;

/// 项目元数据仓储
///
/// 管理项目目录下 project_meta/ 的结构化 JSON 文件。
/// 每次写入自动在 Canon 创建/更新索引条目。
/// 每次删除自动清理 Canon 索引。
class ProjectMetaRepository implements IProjectMetaRepository {
  ProjectMetaRepository({
    required ProjectService projectService,
    required CanonService canonService,
  })  : _projectService = projectService,
        _canonService = canonService;

  final ProjectService _projectService;
  final CanonService _canonService;

  /// Schema 版本字段，自动注入到每次写入
  static const String _schemaField = '_schemaVersion';

  @override
  Future<String> getMetaDirPath(String projectId) async {
    final project = await _projectService.getProject(projectId);
    if (project == null) {
      throw Exception('Project not found: $projectId');
    }
    final sep = Platform.pathSeparator;
    return '${project.directoryPath}${sep}project_meta';
  }

  /// 确保目录存在
  Future<Directory> _ensureMetaDir(String projectId) async {
    final dirPath = await getMetaDirPath(projectId);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 文件名到 Canon 条目类型的映射
  CanonEntryType? _fileNameToType(String fileName) {
    switch (fileName) {
      case 'worldbuilding.json':
        return CanonEntryType.lore;
      case 'characters.json':
        return CanonEntryType.character;
      case 'outline.json':
        return CanonEntryType.plotNode;
      default:
        return null;
    }
  }

  /// 生成 Canon 索引条目
  CanonEntry _buildCanonIndex(
    String projectId,
    String fileName,
    Map<String, dynamic> data,
  ) {
    final type = _fileNameToType(fileName);
    final summary = data['summary'] as String? ??
        data['description'] as String? ??
        fileName.replaceAll('.json', '');
    return CanonEntry(
      projectId: projectId,
      type: type ?? CanonEntryType.lore,
      name: 'meta: $fileName',
      description: summary,
      attributes: {
        'sourceFile': fileName,
        'sourcePath': 'project_meta/$fileName',
        'isMetaIndex': true,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async {
    final dir = await _ensureMetaDir(projectId);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    String projectId,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    // Work on a copy so callers never observe repository bookkeeping fields.
    final persisted = Map<String, dynamic>.from(data)
      ..[_schemaField] = currentMetaSchemaVersion;

    final dir = await _ensureMetaDir(projectId);
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}$sep$fileName');
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temp.writeAsString(jsonEncode(persisted), flush: true);
    try {
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) await file.rename(backup.path);
      await temp.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }

    // Keep exactly one Canon index per metadata file.
    final indexEntry = _buildCanonIndex(projectId, fileName, persisted);
    final entries = await _canonService.list(projectId, indexEntry.type);
    final existing = entries.where((entry) => entry.name == indexEntry.name);
    if (existing.isEmpty) {
      await _canonService.create(indexEntry);
    } else {
      await _canonService.update(
        existing.first.copyWith(
          description: indexEntry.description,
          attributes: indexEntry.attributes,
        ),
      );
      for (final duplicate in existing.skip(1)) {
        await _canonService.delete(duplicate);
      }
    }
  }

  @override
  Future<List<String>> list(String projectId) async {
    final dir = await _ensureMetaDir(projectId);
    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    final dir = await _ensureMetaDir(projectId);
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}$sep$fileName');
    if (await file.exists()) {
      await file.delete();
    }

    // 清理 Canon 索引
    final indexName = 'meta: $fileName';
    // Also check all types
    for (final type in CanonEntryType.values) {
      final entriesOfType = await _canonService.list(projectId, type);
      for (final entry in entriesOfType) {
        if (entry.name == indexName) {
          await _canonService.delete(entry);
        }
      }
    }
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async {
    final data = await read(projectId, 'constitution.json');
    if (data == null) return null;
    return WorldConstitution.fromJson(data);
  }

  @override
  Future<void> writeConstitution(
    String projectId,
    WorldConstitution constitution,
  ) async {
    // 先读取现有宪法，保留不可修改的 hardInvariants
    final existing = await readConstitution(projectId);
    if (existing != null && existing.hardInvariants.isNotEmpty) {
      // hardInvariants 不可通过普通 API 修改
      constitution = WorldConstitution(
        hardInvariants: existing.hardInvariants,
        softGuidance: constitution.softGuidance,
      );
    }
    await write(projectId, 'constitution.json', constitution.toJson());
  }
}
