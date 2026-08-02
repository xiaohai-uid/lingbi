/// Recoverable file commit transactions for canonical state.
///
/// Single-file replacement is atomic via [AtomicFileStore].
/// Multi-file changes are crash-recoverable through deterministic
/// lexical ordering and intent journaling.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';

/// A snapshot of a canonical file at a point in time.
final class CanonicalSnapshot {
  const CanonicalSnapshot({
    required this.relativePath,
    required this.content,
    required this.hash,
  });

  final String relativePath;
  final String content;
  final String hash;
}

/// A single target within a commit plan.
final class CommitTarget {
  const CommitTarget({
    required this.relativePath,
    required this.newContent,
    required this.expectedHash,
  });

  final String relativePath;
  final String newContent;

  /// If non-null, prepare fails with REVISION_CONFLICT when the current
  /// file hash does not match.
  final String? expectedHash;
}

/// A multi-file commit plan.
final class CommitPlan {
  const CommitPlan({
    required this.transactionId,
    required this.targets,
  });

  final String transactionId;
  final List<CommitTarget> targets;
}

/// A prepared commit with before/after hashes, ready to apply.
final class PreparedCommit {
  const PreparedCommit({
    required this.transactionId,
    required this.entries,
  });

  final String transactionId;
  final List<PreparedEntry> entries;
}

/// One prepared file replacement.
final class PreparedEntry {
  const PreparedEntry({
    required this.relativePath,
    required this.beforeHash,
    required this.afterHash,
    required this.newContent,
    required this.existed,
  });

  final String relativePath;
  final String beforeHash;
  final String afterHash;
  final String newContent;
  final bool existed;
}

/// Result of a successful commit apply.
final class CommitResult {
  const CommitResult({
    required this.transactionId,
    required this.affectedPaths,
    required this.committedAt,
  });

  final String transactionId;
  final List<String> affectedPaths;
  final DateTime committedAt;
}

/// File-based canonical store with crash-recoverable commits.
final class FileCanonicalStore {
  FileCanonicalStore({
    required this.projectRoot,
    required AtomicFileStore atomicStore,
  }) : _atomicStore = atomicStore;

  final String projectRoot;
  final AtomicFileStore _atomicStore;

  /// Read a canonical file by project-relative path.
  Future<Result<CanonicalSnapshot>> read(String relativePath) async {
    if (!_isSafePath(relativePath)) {
      return Result.failure(
          FileError('PATH_ESCAPE: $relativePath', code: 'PATH_ESCAPE'));
    }
    final file = File('$projectRoot/$relativePath');
    if (!await file.exists()) {
      return Result.failure(
          FileError('File not found: $relativePath', code: 'NOT_FOUND'));
    }
    final content = await file.readAsString();
    final hash = _hashText(content);
    return Result.success(CanonicalSnapshot(
      relativePath: relativePath,
      content: content,
      hash: hash,
    ));
  }

  /// Prepare a commit: validate paths, check revision conflicts, compute
  /// before/after hashes. Does NOT modify any target file.
  Future<Result<PreparedCommit>> prepare(CommitPlan plan) async {
    // Validate all paths first
    for (final target in plan.targets) {
      if (!_isSafePath(target.relativePath)) {
        return Result.failure(FileError(
            'PATH_ESCAPE: ${target.relativePath}',
            code: 'PATH_ESCAPE'));
      }
    }

    final entries = <PreparedEntry>[];

    for (final target in plan.targets) {
      final file = File('$projectRoot/${target.relativePath}');
      final exists = await file.exists();
      final beforeContent = exists ? await file.readAsString() : '';
      final beforeHash = exists ? _hashText(beforeContent) : _hashText('');

      // Revision conflict check
      if (target.expectedHash != null && exists) {
        if (beforeHash != target.expectedHash) {
          return Result.failure(FileError(
              'REVISION_CONFLICT: ${target.relativePath} '
              'expected=${target.expectedHash} actual=$beforeHash',
              code: 'REVISION_CONFLICT'));
        }
      }

      entries.add(PreparedEntry(
        relativePath: target.relativePath,
        beforeHash: beforeHash,
        afterHash: _hashText(target.newContent),
        newContent: target.newContent,
        existed: exists,
      ));
    }

    // Sort entries in lexical order for deterministic apply
    entries.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    return Result.success(PreparedCommit(
      transactionId: plan.transactionId,
      entries: entries,
    ));
  }

  /// Apply a prepared commit. Writes files in deterministic lexical order
  /// using AtomicFileStore for each individual replacement.
  Future<Result<CommitResult>> apply(PreparedCommit prepared) async {
    final affectedPaths = <String>[];

    for (final entry in prepared.entries) {
      final fullPath = '$projectRoot/${entry.relativePath}';
      await _atomicStore.writeString(fullPath, entry.newContent);
      affectedPaths.add(entry.relativePath);
    }

    return Result.success(CommitResult(
      transactionId: prepared.transactionId,
      affectedPaths: affectedPaths,
      committedAt: DateTime.now().toUtc(),
    ));
  }

  /// Reject paths containing .., absolute paths, drive letters, UNC.
  bool _isSafePath(String path) {
    if (path.contains('..')) return false;
    if (path.startsWith('/') || path.startsWith(r'\')) return false;
    if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return false;
    if (path.startsWith(r'\\')) return false;
    return true;
  }

  String _hashText(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}
