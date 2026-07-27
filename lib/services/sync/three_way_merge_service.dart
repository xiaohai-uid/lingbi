/// Three-way merge service for WebDAV project sync.
///
/// Presents base/local/remote diff and never auto-resolves content
/// conflicts silently. The user must explicitly choose a resolution.
library;

/// Result of a three-way merge attempt.
class MergeResult {
  const MergeResult({
    required this.hasConflict,
    required this.base,
    required this.local,
    required this.remote,
    this.merged,
    this.autoResolved = false,
  });

  final bool hasConflict;
  final String base;
  final String local;
  final String remote;
  final String? merged;
  final bool autoResolved;
}

class ThreeWayMergeService {
  const ThreeWayMergeService();

  /// Attempt a three-way merge. Never silently resolves conflicts.
  MergeResult merge({
    required String base,
    required String local,
    required String remote,
  }) {
    // No changes at all
    if (local == base && remote == base) {
      return MergeResult(
        hasConflict: false,
        base: base,
        local: local,
        remote: remote,
        merged: base,
      );
    }

    // Only local changed
    if (remote == base && local != base) {
      return MergeResult(
        hasConflict: false,
        base: base,
        local: local,
        remote: remote,
        merged: local,
      );
    }

    // Only remote changed
    if (local == base && remote != base) {
      return MergeResult(
        hasConflict: false,
        base: base,
        local: local,
        remote: remote,
        merged: remote,
      );
    }

    // Both changed identically
    if (local == remote) {
      return MergeResult(
        hasConflict: false,
        base: base,
        local: local,
        remote: remote,
        merged: local,
      );
    }

    // Both changed differently: conflict, never auto-resolve
    return MergeResult(
      hasConflict: true,
      base: base,
      local: local,
      remote: remote,
      autoResolved: false,
    );
  }
}
