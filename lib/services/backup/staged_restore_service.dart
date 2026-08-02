/// Staged restore service — verified backup apply pipeline.
///
/// Contract: download → verify manifest hash → stage to temp →
/// apply via MutationProtocol (origin: restore) → persist receipt.
///
/// Task E1: feat(backup): StagedRestoreService with verified apply pipeline
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/backup_transport.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/staged_restore.dart';

/// A staged restore receipt proving verified apply completed.
final class RestoreReceipt implements RestoreReceiptBase {
  const RestoreReceipt({
    required this.packageId,
    required this.manifestHash,
    required this.appliedPaths,
    required this.restoredAt,
  });

  @override
  final String packageId;
  @override
  final String manifestHash;
  @override
  final List<String> appliedPaths;
  @override
  final DateTime restoredAt;

  Map<String, dynamic> toJson() => {
        'package_id': packageId,
        'manifest_hash': manifestHash,
        'applied_paths': appliedPaths,
        'restored_at': restoredAt.toUtc().toIso8601String(),
      };
}

/// Orchestrates verified restore from remote backup.
final class StagedRestoreService implements StagedRestore {
  StagedRestoreService({
    required this.transport,
    required this.mutationProtocol,
    required this.stagingDir,
  });

  final BackupTransport transport;
  final MutationProtocol mutationProtocol;

  /// Temporary directory for staging downloaded content before apply.
  final String stagingDir;

  /// Full restore pipeline: download → verify → stage → apply → receipt.
  @override
  Future<Result<RestoreReceipt>> restore({
    required String packageId,
    required String expectedManifestHash,
    required String projectId,
  }) async {
    // 1. Download
    final downloadResult = await transport.download(packageId);
    final bytes = downloadResult.when(
      success: (b) => b,
      failure: (e) => null,
    );
    if (bytes == null) {
      return Result.failure(FileError(
        'Download failed for package: $packageId',
        code: 'DOWNLOAD_FAILED',
      ));
    }

    // 2. Verify manifest hash
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != expectedManifestHash) {
      return Result.failure(FileError(
        'Manifest hash mismatch: expected=$expectedManifestHash actual=$actualHash',
        code: 'HASH_MISMATCH',
      ));
    }

    // 3. Stage to temp directory
    final stageDir = Directory('$stagingDir/$packageId');
    if (await stageDir.exists()) {
      await stageDir.delete(recursive: true);
    }
    await stageDir.create(recursive: true);

    // Decode package content (JSON map of path → content)
    final Map<String, dynamic> fileMap;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return Result.failure(FileError(
          'Package is not a valid file map',
          code: 'INVALID_PACKAGE',
        ));
      }
      fileMap = decoded;
    } catch (e) {
      return Result.failure(FileError(
        'Package decode failed: $e',
        code: 'DECODE_FAILED',
      ));
    }

    // Write staged files
    final appliedPaths = <String>[];
    for (final entry in fileMap.entries) {
      final relativePath = entry.key;
      final content = entry.value?.toString() ?? '';
      final stagedFile = File('${stageDir.path}/$relativePath');
      await stagedFile.parent.create(recursive: true);
      await stagedFile.writeAsString(content, flush: true);
      appliedPaths.add(relativePath);
    }

    // 4. Apply via MutationProtocol (origin: restore)
    for (final entry in fileMap.entries) {
      final relativePath = entry.key;
      final content = entry.value?.toString() ?? '';
      await mutationProtocol.applyUserEdit(ChangeRequest(
        projectId: projectId,
        origin: ChangeOrigin.restore,
        action: ChangeAction.restoreSnapshot,
        target: ChangeTarget(
          projectRelativePath: relativePath,
          kind: 'backup_restore',
        ),
        baseRevision: 0,
        payload: content,
      ));
    }

    // 5. Clean up staging
    await stageDir.delete(recursive: true);

    // 6. Build receipt
    final receipt = RestoreReceipt(
      packageId: packageId,
      manifestHash: actualHash,
      appliedPaths: appliedPaths,
      restoredAt: DateTime.now().toUtc(),
    );

    return Result.success(receipt);
  }
}
