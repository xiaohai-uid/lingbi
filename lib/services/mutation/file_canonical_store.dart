/// Recoverable file commit transactions for canonical state.
///
/// Single-file replacement is atomic via [AtomicFileStore].
/// Multi-file changes are crash-recoverable through deterministic
/// lexical ordering and intent journaling.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/canonical_envelope.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/project_path_guard.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

/// A snapshot of a canonical file at a point in time.
final class CanonicalSnapshot {
  const CanonicalSnapshot({
    required this.relativePath,
    required this.content,
    required this.hash,
    this.revision,
  });

  final String relativePath;
  final String content;
  final String hash;

  /// Envelope revision for canonical JSON files; null for raw text, whose
  /// revision authority stays in the mutation journal (ADR-009).
  final int? revision;
}

/// A single target within a commit plan.
final class CommitTarget {
  const CommitTarget({
    required this.relativePath,
    required this.newContent,
    this.expectedHash,
    this.expectedRevision,
  });

  final String relativePath;
  final String newContent;

  /// If non-null, prepare fails with REVISION_CONFLICT when the current
  /// file hash does not match.
  final String? expectedHash;

  /// Envelope revision expected on disk for canonical JSON targets.
  final int? expectedRevision;
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
    this.beforeRevision,
    this.afterRevision,
  });

  final String relativePath;
  final String beforeHash;
  final String afterHash;
  final String newContent;
  final bool existed;
  final int? beforeRevision;
  final int? afterRevision;
}

/// Result of a successful commit apply.
final class CommitResult {
  const CommitResult({
    required this.transactionId,
    required this.affectedPaths,
    required this.committedAt,
    required this.afterHashes,
    required this.afterRevisions,
  });

  final String transactionId;
  final List<String> affectedPaths;
  final DateTime committedAt;

  /// Actual content hash per affected path after replacement.
  final Map<String, String> afterHashes;

  /// Actual envelope revision per affected canonical JSON path after
  /// replacement; absent for raw text targets.
  final Map<String, int> afterRevisions;
}

/// File-based canonical store with crash-recoverable commits.
final class FileCanonicalStore {
  FileCanonicalStore({
    required this.projectRoot,
    required AtomicFileStore atomicStore,
  }) : _atomicStore = atomicStore;

  /// A store bound to one resolved project root (ADR-012).
  FileCanonicalStore.projectOwned(
    ResolvedProjectRoot root, {
    required AtomicFileStore atomicStore,
  }) : this(projectRoot: root.rootPath, atomicStore: atomicStore);

  final String projectRoot;
  final AtomicFileStore _atomicStore;

  /// Read a canonical file by project-relative path.
  ///
  /// Canonical JSON targets are verified against their envelope content hash;
  /// raw text targets use the normalized text hash.
  Future<Result<CanonicalSnapshot>> read(String relativePath) async {
    final normalized = ProjectPathGuard.normalizeRelativePath(relativePath);
    if (normalized == null || await _escapes(normalized)) {
      return Result.failure(_pathEscape(relativePath));
    }
    final file = File('$projectRoot/$normalized');
    if (!await file.exists()) {
      return Result.failure(
          FileError('File not found: $relativePath', code: 'NOT_FOUND'));
    }
    final content = await file.readAsString();
    if (normalized.toLowerCase().endsWith('.json')) {
      final envelope = _verifyEnvelope(content);
      if (envelope == null) {
        return Result.failure(FileError(
          'INVALID_CANONICAL: $relativePath is not a verified canonical file',
          code: 'INVALID_CANONICAL',
        ));
      }
      return Result.success(CanonicalSnapshot(
        relativePath: normalized,
        content: content,
        hash: envelope.contentHash,
        revision: envelope.revision,
      ));
    }
    return Result.success(CanonicalSnapshot(
      relativePath: normalized,
      content: content,
      hash: _hashText(content),
    ));
  }

  /// Prepare a commit: validate paths, check revision conflicts, compute
  /// before/after hashes. Does NOT modify any target file.
  Future<Result<PreparedCommit>> prepare(CommitPlan plan) async {
    // Validate all paths first, then check every target against the current
    // filesystem state.
    for (final target in plan.targets) {
      final normalized =
          ProjectPathGuard.normalizeRelativePath(target.relativePath);
      if (normalized == null || await _escapes(normalized)) {
        return Result.failure(_pathEscape(target.relativePath));
      }
    }

    final entries = <PreparedEntry>[];

    for (final target in plan.targets) {
      final normalized =
          ProjectPathGuard.normalizeRelativePath(target.relativePath)!;
      final file = File('$projectRoot/$normalized');
      final exists = await file.exists();
      final beforeContent = exists ? await file.readAsString() : '';
      final isJson = normalized.toLowerCase().endsWith('.json');

      // A canonical JSON file's content authority is its verified envelope
      // content_hash; legacy/non-envelope JSON and raw text use the
      // normalized text hash until the explicit migration (Task 9).
      final beforeEnvelope =
          isJson && exists ? _verifyEnvelope(beforeContent) : null;
      final beforeRevision = beforeEnvelope?.revision;
      final newEnvelope = isJson ? _verifyEnvelope(target.newContent) : null;

      final beforeHash = beforeEnvelope != null
          ? beforeEnvelope.contentHash
          : _hashText(beforeContent);
      final newContentHash = newEnvelope != null
          ? newEnvelope.contentHash
          : _hashText(target.newContent);

      // Revision conflict checks.
      if (target.expectedHash != null && beforeHash != target.expectedHash) {
        return Result.failure(FileError(
            'REVISION_CONFLICT: $normalized '
            'expected=${target.expectedHash} actual=$beforeHash',
            typedCode: MutationErrorCode.revisionConflict));
      }
      if (target.expectedRevision != null &&
          beforeRevision != target.expectedRevision) {
        return Result.failure(FileError(
            'REVISION_CONFLICT: $normalized '
            'expected revision=${target.expectedRevision} '
            'actual=$beforeRevision',
            typedCode: MutationErrorCode.revisionConflict));
      }

      final afterRevision =
          newEnvelope != null ? (beforeRevision ?? 0) + 1 : null;

      entries.add(PreparedEntry(
        relativePath: normalized,
        beforeHash: beforeHash,
        afterHash: newContentHash,
        newContent: target.newContent,
        existed: exists,
        beforeRevision: beforeRevision,
        afterRevision: afterRevision,
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
  ///
  /// Every path is validated again at commit time, because the filesystem
  /// topology may have changed since prepare (ADR-010).
  Future<Result<CommitResult>> apply(PreparedCommit prepared) async {
    final affectedPaths = <String>[];
    final afterHashes = <String, String>{};
    final afterRevisions = <String, int>{};

    for (final entry in prepared.entries) {
      final normalized = ProjectPathGuard.normalizeRelativePath(entry.relativePath);
      if (normalized == null || await _escapes(normalized)) {
        return Result.failure(_pathEscape(entry.relativePath));
      }

      final fullPath = '$projectRoot/$normalized';
      await _atomicStore.writeString(fullPath, entry.newContent);

      // Verify complete payload equality after replacement.
      final onDisk = await File(fullPath).readAsString();
      if (onDisk != entry.newContent) {
        return Result.failure(FileError(
          'PAYLOAD_MISMATCH: $normalized differs after atomic replace',
          typedCode: MutationErrorCode.storageFailure,
        ));
      }

      affectedPaths.add(normalized);
      final isJson = normalized.toLowerCase().endsWith('.json');
      final envelope = isJson ? _verifyEnvelope(onDisk) : null;
      if (envelope != null) {
        afterHashes[normalized] = envelope.contentHash;
        afterRevisions[normalized] = envelope.revision;
      } else {
        afterHashes[normalized] = _hashText(onDisk);
      }
    }

    return Result.success(CommitResult(
      transactionId: prepared.transactionId,
      affectedPaths: affectedPaths,
      committedAt: DateTime.now().toUtc(),
      afterHashes: afterHashes,
      afterRevisions: afterRevisions,
    ));
  }

  FileError _pathEscape(String path) => FileError(
        'PATH_ESCAPE: $path',
        code: 'PATH_ESCAPE',
        typedCode: MutationErrorCode.pathEscape,
      );

  Future<bool> _escapes(String normalized) => ProjectPathGuard.escapesRoot(
        rootPath: projectRoot,
        normalizedRelativePath: normalized,
      );

  /// Verify a canonical JSON envelope; null when the content is not a valid
  /// envelope for the current schema.
  CanonicalJsonEnvelope? _verifyEnvelope(String content) {
    try {
      return CanonicalJsonEnvelope.decode(content);
    } on FormatException {
      return null;
    }
  }

  String _hashText(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}
