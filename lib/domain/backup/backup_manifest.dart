/// Backup manifest domain model.
///
/// Domain-layer — no Flutter, no dart:io.
library;

/// A single file entry in a backup manifest.
final class BackupFileEntry {
  const BackupFileEntry({
    required this.relativePath,
    required this.sizeBytes,
    required this.hash,
    required this.schemaVersion,
    required this.classification,
  });

  factory BackupFileEntry.fromJson(Map<String, dynamic> json) =>
      BackupFileEntry(
        relativePath: json['relative_path'] as String? ?? '',
        sizeBytes: json['size_bytes'] as int? ?? 0,
        hash: json['hash'] as String? ?? '',
        schemaVersion: json['schema_version'] as int? ?? 1,
        classification: json['classification'] as String? ?? 'canonical',
      );

  final String relativePath;
  final int sizeBytes;
  final String hash;
  final int schemaVersion;
  final String classification;

  Map<String, dynamic> toJson() => {
        'relative_path': relativePath,
        'size_bytes': sizeBytes,
        'hash': hash,
        'schema_version': schemaVersion,
        'classification': classification,
      };
}

/// Portable backup manifest with integrity hashes.
final class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.projectId,
    required this.projectRevision,
    required this.projectHash,
    required this.createdAt,
    required this.files,
    required this.canonicalRootHash,
    required this.manifestHash,
    this.excludedProjections = const [],
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) =>
      BackupManifest(
        formatVersion: json['format_version'] as int? ?? 1,
        appVersion: json['app_version'] as String? ?? '',
        projectId: json['project_id'] as String? ?? '',
        projectRevision: json['project_revision'] as int? ?? 0,
        projectHash: json['project_hash'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        files: (json['files'] as List<dynamic>?)
                ?.map((f) =>
                    BackupFileEntry.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        canonicalRootHash: json['canonical_root_hash'] as String? ?? '',
        manifestHash: json['manifest_hash'] as String? ?? '',
        excludedProjections: (json['excluded_projections'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  final int formatVersion;
  final String appVersion;
  final String projectId;
  final int projectRevision;
  final String projectHash;
  final String createdAt;
  final List<BackupFileEntry> files;
  final String canonicalRootHash;
  final String manifestHash;
  final List<String> excludedProjections;

  Map<String, dynamic> toJson() => {
        'format_version': formatVersion,
        'app_version': appVersion,
        'project_id': projectId,
        'project_revision': projectRevision,
        'project_hash': projectHash,
        'created_at': createdAt,
        'files': files.map((f) => f.toJson()).toList(),
        'canonical_root_hash': canonicalRootHash,
        'manifest_hash': manifestHash,
        'excluded_projections': excludedProjections,
      };
}
