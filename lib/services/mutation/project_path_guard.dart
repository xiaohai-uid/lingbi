/// Deterministic rejection of unsafe canonical target paths.
///
/// A project-relative path is normalized to forward-slash segments and
/// rejected instead of sanitized (ADR-009/ADR-010). Filesystem-aware
/// containment checks resolve real paths so symlink/junction escapes are
/// detected even when the target path itself looks safe.
library;

import 'dart:io';

final class ProjectPathGuard {
  ProjectPathGuard._();

  /// Normalize a project-relative path to forward-slash form.
  ///
  /// Returns null when the path must be rejected: empty, absolute, drive or
  /// UNC prefixed, containing `..`/`.` segments, empty or NUL segments, or a
  /// trailing separator.
  static String? normalizeRelativePath(String relativePath) {
    if (relativePath.isEmpty) return null;
    if (relativePath.contains('\u0000')) return null;

    final path = relativePath.replaceAll(r'\', '/');
    if (path.startsWith('/')) return null;
    if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return null;

    final segments = path.split('/');
    final normalized = <String>[];
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.' || segment == '..') return null;
      normalized.add(segment);
    }

    return normalized.join('/');
  }

  /// True when [normalizedRelativePath] resolves outside [rootPath].
  ///
  /// Every existing ancestor is resolved to its real path; a symlink or
  /// junction pointing outside the root, or a missing root, fails closed.
  static Future<bool> escapesRoot({
    required String rootPath,
    required String normalizedRelativePath,
  }) async {
    final normalized = normalizeRelativePath(normalizedRelativePath);
    if (normalized == null) return true;

    final rootReal = await _resolveReal(rootPath);
    if (rootReal == null) return true;

    final builder = StringBuffer(rootPath);
    for (final segment in normalized.split('/')) {
      builder.write('/');
      builder.write(segment);
      final current = builder.toString();
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.notFound) break;
      if (type == FileSystemEntityType.link ||
          type == FileSystemEntityType.directory) {
        final resolved = await _resolveReal(current);
        if (resolved == null) return true;
        if (!_isWithin(rootReal, resolved)) return true;
      }
    }

    return false;
  }

  static Future<String?> _resolveReal(String path) async {
    try {
      return await File(path).resolveSymbolicLinks();
    } catch (_) {
      return null;
    }
  }

  static bool _isWithin(String rootReal, String candidateReal) {
    String norm(String value) => value.replaceAll(r'\', '/').toLowerCase();
    final root = norm(rootReal);
    final candidate = norm(candidateReal);
    return candidate == root || candidate.startsWith('$root/');
  }
}
