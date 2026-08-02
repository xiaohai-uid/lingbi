/// StagedRestoreService — verified apply pipeline tests.
///
/// Task E1: feat(backup): StagedRestoreService with verified apply pipeline
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/backup/staged_restore_service.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/backup_transport.dart';

/// In-memory fake BackupTransport for testing.
class _FakeTransport implements BackupTransport {
  final Map<String, List<int>> packages = {};

  @override
  Future<Result<String>> upload({
    required String packageId,
    required List<int> bytes,
    required String manifestHash,
  }) async {
    packages[packageId] = bytes;
    return Result.success(packageId);
  }

  @override
  Future<Result<List<int>>> download(String packageId) async {
    final data = packages[packageId];
    if (data == null) {
      return Result.failure(FileError('Not found: $packageId'));
    }
    return Result.success(data);
  }

  @override
  Future<Result<bool>> verifyRemote(
      String packageId, String expectedHash) async {
    final data = packages[packageId];
    if (data == null) return Result.success(false);
    return Result.success(sha256.convert(data).toString() == expectedHash);
  }

  @override
  Future<Result<List<String>>> listPackages() async {
    return Result.success(packages.keys.toList());
  }

  @override
  Future<Result<void>> deletePackage(String packageId) async {
    packages.remove(packageId);
    return Result.success(null);
  }
}

void main() {
  late Directory tempDir;
  late Directory journalDir;
  late Directory stagingDir;
  late _FakeTransport transport;
  late StagedRestoreService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_staged_restore_');
    journalDir = Directory('${tempDir.path}/journal')..createSync();
    stagingDir = Directory('${tempDir.path}/staging')..createSync();
    transport = _FakeTransport();
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: journalDir.path),
      store: FileCanonicalStore(
        projectRoot: tempDir.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    service = StagedRestoreService(
      transport: transport,
      mutationProtocol: protocol,
      stagingDir: stagingDir.path,
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('successful restore creates journal records and returns receipt',
      () async {
    // Prepare a package
    final fileMap = {
      'chapters/ch1.md': '# Chapter 1\n\nContent',
      'notes/outline.md': 'Outline here',
    };
    final bytes = utf8.encode(jsonEncode(fileMap));
    final hash = sha256.convert(bytes).toString();
    transport.packages['pkg-001'] = bytes;

    final result = await service.restore(
      packageId: 'pkg-001',
      expectedManifestHash: hash,
      projectId: 'proj-1',
    );

    final receipt = result.orThrow();
    expect(receipt.packageId, 'pkg-001');
    expect(receipt.manifestHash, hash);
    expect(receipt.appliedPaths, containsAll(['chapters/ch1.md', 'notes/outline.md']));

    // Verify journal has restore records (2 files × 3 events each)
    final journal = LocalMutationJournal(basePath: journalDir.path);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types.where((t) => t == 'candidate_proposed').length, 2);
    expect(types.where((t) => t == 'candidate_committed').length, 2);
  });

  test('hash mismatch rejects restore', () async {
    transport.packages['pkg-bad'] = utf8.encode('{"a.md":"x"}');

    final result = await service.restore(
      packageId: 'pkg-bad',
      expectedManifestHash: 'wrong-hash',
      projectId: 'proj-1',
    );

    expect(result, isA<Failure>());
  });

  test('missing package fails gracefully', () async {
    final result = await service.restore(
      packageId: 'nonexistent',
      expectedManifestHash: 'any',
      projectId: 'proj-1',
    );

    expect(result, isA<Failure>());
  });
}
