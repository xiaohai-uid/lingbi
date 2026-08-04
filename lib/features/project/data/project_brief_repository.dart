import 'dart:convert';
import 'dart:io';

import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

final class ProjectBriefConflict implements Exception {
  const ProjectBriefConflict(this.expectedRevision, this.actualRevision);

  final int expectedRevision;
  final int actualRevision;

  @override
  String toString() =>
      'ProjectBriefConflict(expected: $expectedRevision, actual: $actualRevision)';
}

/// Reads and writes the brief embedded in the portable `.lingbi/project.json`.
/// A recoverable backup prevents an interrupted replacement from hiding the
/// last committed project metadata.
final class ProjectBriefRepository {
  ProjectBriefRepository(this.projectDirectory,
      {MutationProtocol? mutationProtocol})
      : _mutationProtocol = mutationProtocol;

  final String projectDirectory;

  /// 变更协议：write 经由此接口创建三记录不变量（candidate + approval + receipt）。
  /// 为 null 时写入 fail-closed（拒绝物理写入，ADR-010）。
  final MutationProtocol? _mutationProtocol;

  File get _metadata => File(
        '$projectDirectory${Platform.pathSeparator}.lingbi'
        '${Platform.pathSeparator}project.json',
      );

  Future<ProjectBrief> read() async {
    await _recoverInterruptedReplace();
    if (!await _metadata.exists()) {
      throw FileSystemException('项目简报不存在', _metadata.path);
    }
    final metadata = await _readMap(_metadata);
    return _briefFromMetadata(metadata);
  }

  Future<ProjectBrief> write(
    ProjectBrief brief, {
    required int expectedRevision,
    Map<String, dynamic> baseMetadata = const {},
    String? projectId,
  }) async {
    await _metadata.parent.create(recursive: true);
    await _recoverInterruptedReplace();

    final existing = await _metadata.exists()
        ? await _readMap(_metadata)
        : <String, dynamic>{};
    final actualRevision =
        existing.isEmpty ? 0 : _briefFromMetadata(existing).revision;
    if (actualRevision != expectedRevision) {
      throw ProjectBriefConflict(expectedRevision, actualRevision);
    }

    final committed = brief.copyWith(revision: actualRevision + 1);

    final merged = <String, dynamic>{
      ...existing,
      ...baseMetadata,
      'schemaVersion': SchemaVersions.project,
      'name': committed.title,
      'description': committed.premise ?? '',
      'targetPlatform': committed.targetPlatform ?? '',
      'genre': committed.genreId,
      'audience': committed.audience ?? '',
      'projectBrief': committed.toJson(),
    };
    final encoded = jsonEncode(merged);

    // 经 MutationProtocol 路由（userUi origin — 隐式批准，ADR-010）。
    // 协议为 null 时 fail-closed：拒绝物理写入。
    final protocol = _mutationProtocol;
    if (protocol == null) {
      throw StateError(
        'ProjectBriefRepository.write requires MutationProtocol (fail-closed)',
      );
    }
    final editResult = await protocol.applyUserEdit(ChangeRequest(
      projectId: projectId ?? projectDirectory,
      origin: ChangeOrigin.userUi,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: '.lingbi/project.json',
        kind: 'project_brief',
      ),
      baseRevision: actualRevision,
      payload: encoded,
    ));
    if (editResult.errorOrNull() != null) {
      throw StateError(
        'ProjectBriefRepository.write failed: ${editResult.errorOrNull()}',
      );
    }
    return committed;
  }

  ProjectBrief _briefFromMetadata(Map<String, dynamic> metadata) {
    final nested = metadata['projectBrief'];
    if (nested is Map<String, dynamic>) return ProjectBrief.fromJson(nested);
    return ProjectBrief.fromJson(metadata);
  }

  Future<Map<String, dynamic>> _readMap(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('project.json must contain an object');
    }
    return decoded;
  }

  Future<void> _recoverInterruptedReplace() async {
    // The canonical store now owns atomic replacement (backup-based
    // recovery). This legacy tmp/bak recovery is kept as a no-op guard so
    // old interrupted writes from previous app versions still surface.
    if (!await _metadata.exists() &&
        await File('${_metadata.path}.bak').exists()) {
      await File('${_metadata.path}.bak').rename(_metadata.path);
    }
    final temporary = File('${_metadata.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
  }
}
