/// Project sync manifest for WebDAV synchronization.
///
/// Covers all portable assets, excludes secrets, marks protected files
/// (candidates, versions), and supports manifest diffing for detecting
/// remote deletions.
library;

/// A single asset in the sync manifest.
class SyncAsset {
  const SyncAsset({
    required this.path,
    required this.hash,
    this.isProtected = false,
  });

  final String path;
  final String hash;
  final bool isProtected;

  Map<String, Object?> toJson() => {
        'path': path,
        'hash': hash,
        'is_protected': isProtected,
      };

  factory SyncAsset.fromJson(Map<String, dynamic> json) => SyncAsset(
        path: json['path'] as String,
        hash: json['hash'] as String,
        isProtected: json['is_protected'] as bool? ?? false,
      );
}

/// Diff between two manifests.
class ManifestDiff {
  const ManifestDiff({
    required this.addedLocally,
    required this.deletedRemotely,
    required this.modified,
  });

  final List<String> addedLocally;
  final List<String> deletedRemotely;
  final List<String> modified;
}

/// Patterns that are excluded from sync (secrets, keys).
const _excludedPatterns = [
  '.env',
  'api_keys',
  'secrets',
  'credentials',
  '.key',
  '.pem',
];

/// Patterns that mark a file as protected (never deleted during sync).
const _protectedPatterns = [
  'candidates/',
  'versions/',
  '.snapshot',
];

class ProjectSyncManifest {
  const ProjectSyncManifest({
    required this.projectId,
    required this.assets,
    required this.generatedAt,
    required this.schemaVersion,
  });

  final String projectId;
  final List<SyncAsset> assets;
  final DateTime generatedAt;
  final int schemaVersion;

  /// Generate a manifest from a list of assets, filtering secrets and
  /// marking protected files.
  static ProjectSyncManifest generate({
    required String projectId,
    required List<SyncAsset> assets,
  }) {
    final filtered = assets
        .where((a) => !_isExcluded(a.path))
        .map((a) => SyncAsset(
              path: a.path,
              hash: a.hash,
              isProtected: _isProtected(a.path),
            ))
        .toList();

    return ProjectSyncManifest(
      projectId: projectId,
      assets: filtered,
      generatedAt: DateTime.now().toUtc(),
      schemaVersion: 1,
    );
  }

  /// Compute the diff between a local and remote manifest.
  static ManifestDiff diff(
    ProjectSyncManifest local,
    ProjectSyncManifest remote,
  ) {
    final localPaths = local.assets.map((a) => a.path).toSet();
    final remotePaths = remote.assets.map((a) => a.path).toSet();
    final remoteHashMap = {for (final a in remote.assets) a.path: a.hash};
    final localHashMap = {for (final a in local.assets) a.path: a.hash};

    final deletedRemotely = localPaths.difference(remotePaths).toList();
    final addedLocally = remotePaths.difference(localPaths).toList();
    final modified = localPaths
        .intersection(remotePaths)
        .where((p) => localHashMap[p] != remoteHashMap[p])
        .toList();

    return ManifestDiff(
      addedLocally: addedLocally,
      deletedRemotely: deletedRemotely,
      modified: modified,
    );
  }

  static bool _isExcluded(String path) {
    final lower = path.toLowerCase();
    return _excludedPatterns.any((p) => lower.contains(p));
  }

  static bool _isProtected(String path) {
    final lower = path.toLowerCase();
    return _protectedPatterns.any((p) => lower.contains(p));
  }
}
