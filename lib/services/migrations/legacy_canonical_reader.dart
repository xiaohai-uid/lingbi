/// Side-effect-free legacy project metadata reading (MP-09).
///
/// Distinguishes canonical (schema-versioned), legacy (metadata without a
/// schema version) and absent project metadata without ever rewriting the
/// project. Legacy upgrade decisions are owned by MigrationCandidateService.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../migrations/schema_versions.dart';
import '../../shared/models/project.dart';

enum ProjectMetadataKind { canonical, legacy, none, future }

/// Lossless description of a legacy project's metadata.
final class LegacyProjectDescriptor {
  const LegacyProjectDescriptor({
    required this.directoryPath,
    this.name,
    this.genre,
    this.hasBrief = false,
  });

  final String directoryPath;
  final String? name;
  final String? genre;

  /// True when the legacy metadata carries enough structured data for a
  /// lossless upgrade (id + name + timestamps); false for ambiguous/lossy
  /// metadata that must be refused, not guessed.
  final bool hasBrief;
}

final class LegacyCanonicalReader {
  LegacyCanonicalReader._();

  /// Classify the project metadata at [directoryPath] without writing.
  /// A metadata file that exists but cannot be parsed is classified legacy
  /// (it must be decided manually, never rewritten). A schema version newer
  /// than this build is classified future and never downgraded.
  static Future<ProjectMetadataKind> inspect(String directoryPath) async {
    final file = File(p.join(directoryPath, '.lingbi', 'project.json'));
    if (!await file.exists()) return ProjectMetadataKind.none;
    final metadata = await _readMetadataFile(directoryPath);
    if (metadata == null) return ProjectMetadataKind.legacy;
    final schemaVersion = metadata['schemaVersion'];
    if (schemaVersion is int) {
      if (schemaVersion == SchemaVersions.project) {
        return ProjectMetadataKind.canonical;
      }
      if (schemaVersion > SchemaVersions.project) {
        return ProjectMetadataKind.future;
      }
      // 旧于当前版本（如 v1 扁平元数据）→ legacy，可显式升级。
      return ProjectMetadataKind.legacy;
    }
    return ProjectMetadataKind.legacy;
  }

  /// Read the raw metadata map; null when absent or not an object.
  static Future<Map<String, dynamic>?> readRawMetadata(
    String directoryPath,
  ) async {
    return _readMetadataFile(directoryPath);
  }

  /// Read a canonical project's metadata. Returns null when the directory is
  /// not canonical. Never writes.
  static Future<Project?> readCanonical(String directoryPath) async {
    if (await inspect(directoryPath) != ProjectMetadataKind.canonical) {
      return null;
    }
    final metadata = await _readMetadataFile(directoryPath);
    if (metadata == null) return null;
    try {
      return Project.fromJson(metadata);
    } catch (_) {
      return null;
    }
  }

  /// Describe legacy metadata for a migration decision. Never writes.
  static Future<LegacyProjectDescriptor> readLegacy(
    String directoryPath,
  ) async {
    final metadata = await _readMetadataFile(directoryPath);
    if (metadata == null) {
      // No metadata: fall back to the directory name, mirroring the
      // open-without-metadata path. Lossless only as a name.
      return LegacyProjectDescriptor(
        directoryPath: directoryPath,
        name: _nameFromDirectory(directoryPath),
      );
    }

    final name = metadata['name'] is String
        ? metadata['name'] as String
        : _nameFromDirectory(directoryPath);
    final genre = metadata['genre'] is String
        ? metadata['genre'] as String
        : (metadata['projectBrief'] is Map<String, dynamic> &&
                (metadata['projectBrief'] as Map<String, dynamic>)['genreId']
                    is String
            ? (metadata['projectBrief'] as Map<String, dynamic>)['genreId']
                as String
            : null);
    final hasBrief = metadata['id'] is String &&
        metadata['name'] is String &&
        metadata['createdAt'] is String &&
        metadata['updatedAt'] is String;

    return LegacyProjectDescriptor(
      directoryPath: directoryPath,
      name: name,
      genre: genre,
      hasBrief: hasBrief,
    );
  }

  /// Lossless legacy → Project projection for read-only open. When the
  /// metadata is ambiguous (no stable id), derives a deterministic id from
  /// the directory path so the session stays stable without rewriting.
  static Project? projectFromLegacy(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return null;
    final metadata = _readMetadataFileSync(directoryPath);
    if (metadata == null) {
      return Project(
        name: _nameFromDirectory(directoryPath),
        directoryPath: directoryPath,
      );
    }
    final id = metadata['id'] is String
        ? metadata['id'] as String
        : _deterministicId(directoryPath);
    final brief = metadata['projectBrief'] is Map<String, dynamic>
        ? metadata['projectBrief'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final name = brief['title'] ?? metadata['name'];
    return Project(
      id: id,
      name: name is String ? name : _nameFromDirectory(directoryPath),
      description: metadata['description'] is String
          ? metadata['description'] as String
          : '',
      directoryPath: directoryPath,
      targetPlatform: brief['targetPlatform'] is String
          ? brief['targetPlatform'] as String
          : (metadata['targetPlatform'] is String
              ? metadata['targetPlatform'] as String
              : ''),
      genre: brief['genreId'] is String
          ? brief['genreId'] as String
          : (metadata['genre'] is String ? metadata['genre'] as String : ''),
      audience: brief['audience'] is String
          ? brief['audience'] as String
          : (metadata['audience'] is String
              ? metadata['audience'] as String
              : ''),
      templateId: brief['templateId'] is String
          ? brief['templateId'] as String
          : '',
      targetLength: brief['targetLength'] is int
          ? brief['targetLength'] as int
          : null,
      premise: brief['premise'] is String
          ? brief['premise'] as String
          : (metadata['description'] is String
              ? metadata['description'] as String
              : ''),
      briefRevision: brief['revision'] is int ? brief['revision'] as int : 0,
      createdAt: _parseTime(metadata['createdAt']),
      updatedAt: _parseTime(metadata['updatedAt']),
    );
  }

  static DateTime _parseTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String _nameFromDirectory(String directoryPath) {
    final segments = p
        .normalize(directoryPath.replaceAll(r'\', '/'))
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    return segments.isEmpty ? '未命名项目' : segments.last;
  }

  /// Deterministic id for ambiguous legacy metadata: stable across sessions,
  /// never persisted.
  static String _deterministicId(String directoryPath) {
    final normalized = directoryPath.replaceAll(r'\', '/').toLowerCase();
    final bytes = utf8.encode(normalized);
    var hash = 0;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return 'legacy-$hash';
  }

  static Future<Map<String, dynamic>?> _readMetadataFile(
    String directoryPath,
  ) async {
    final file = File(p.join(directoryPath, '.lingbi', 'project.json'));
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _readMetadataFileSync(String directoryPath) {
    final file = File(p.join(directoryPath, '.lingbi', 'project.json'));
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
