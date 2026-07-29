import 'dart:convert';
import 'dart:io';

import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';

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
  ProjectBriefRepository(this.projectDirectory);

  final String projectDirectory;

  File get _metadata => File(
        '$projectDirectory${Platform.pathSeparator}.lingbi'
        '${Platform.pathSeparator}project.json',
      );
  File get _temporary => File('${_metadata.path}.tmp');
  File get _backup => File('${_metadata.path}.bak');

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

    await _temporary.writeAsString(jsonEncode(merged), flush: true);
    if (await _backup.exists()) await _backup.delete();
    if (await _metadata.exists()) await _metadata.rename(_backup.path);
    try {
      await _temporary.rename(_metadata.path);
      if (await _backup.exists()) await _backup.delete();
    } catch (_) {
      if (await _metadata.exists()) await _metadata.delete();
      if (await _backup.exists()) await _backup.rename(_metadata.path);
      rethrow;
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
    if (!await _metadata.exists() && await _backup.exists()) {
      await _backup.rename(_metadata.path);
    }
    if (await _temporary.exists()) await _temporary.delete();
  }
}
