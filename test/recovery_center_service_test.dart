import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/recovery_center_service.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

void main() {
  test('soft delete is discoverable and can be restored', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_recovery_');
    addTearDown(() => root.delete(recursive: true));
    final original = File('${root.path}/chapter.md');
    await original.writeAsString('chapter');
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '${root.path}/journal'),
      store: FileCanonicalStore(
        projectRoot: root.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final service = RecoveryCenterService(mutationProtocol: protocol);

    final deleted = (await service.softDelete(root.path, original.path));
    expect(deleted, isA<Success<File>>());
    final deletedFile = (deleted as Success<File>).value;
    expect(original.existsSync(), isFalse);

    final items = await service.scan(root.path);
    expect(items.map((item) => item.path), contains(deletedFile.path));
    final trash =
        items.firstWhere((item) => item.type == RecoveryItemType.trash);
    final restored = await service.restore(trash);
    expect(restored, isA<Success<File>>());

    expect(await original.readAsString(), 'chapter');
  });

  test('scan unifies candidates versions snapshots and trash', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_recovery_scan_');
    addTearDown(() => root.delete(recursive: true));
    for (final path in [
      '.lingbi/candidates/a.md',
      '.lingbi/versions/doc/v1.md',
      '.lingbi/snapshots/s1.md',
    ]) {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(path);
    }

    final scanService = RecoveryCenterService(
      mutationProtocol: LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: '${root.path}/.lingbi/journal'),
        store: FileCanonicalStore(
          projectRoot: root.path,
          atomicStore: AtomicFileStore(),
        ),
      ),
    );
    final types =
        (await scanService.scan(root.path)).map((item) => item.type).toSet();
    expect(
        types,
        containsAll(<RecoveryItemType>{
          RecoveryItemType.candidate,
          RecoveryItemType.version,
          RecoveryItemType.snapshot,
        }));
  });

  test('restore via MutationProtocol creates journal records', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_recovery_mut_');
    addTearDown(() => root.delete(recursive: true));
    final journalDir = Directory('${root.path}/journal')..createSync();
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: journalDir.path),
      store: FileCanonicalStore(
        projectRoot: root.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final service = RecoveryCenterService(mutationProtocol: protocol);

    // Create and soft-delete a file
    final original = File('${root.path}/chapter.md');
    await original.writeAsString('restore content');
    await service.softDelete(root.path, original.path);

    // Scan and restore
    final items = await service.scan(root.path);
    final trash2 =
        items.firstWhere((item) => item.type == RecoveryItemType.trash);
    final restored2 = await service.restore(trash2);
    expect(restored2, isA<Success<File>>());

    // Verify journal has propose + approve records.
    // Note: committed record is NOT produced because the target path
    // passed by RecoveryCenterService is an absolute path, which the
    // canonical store correctly rejects (PATH_ESCAPE). The physical
    // restore (file rename) still succeeds via the service's own logic.
    // TODO: migrate RecoveryCenterService to use project-relative paths.
    final journal = LocalMutationJournal(basePath: journalDir.path);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(
      types,
      containsAll(<String>[
        'candidate_proposed',
        'candidate_approved',
        'commit_intent',
        'candidate_committed',
      ]),
    );
    final receipts =
        events.where((e) => e.eventType == 'candidate_committed').toList();
    expect(receipts, hasLength(1));
    expect(
      CommitReceipt.fromJson(receipts.single.payload).afterContentHash,
      canonicalTextHash('restore content'),
    );
  });

  test('restore routes stable project id and relative path through protocol',
      () async {
    final root = await Directory.systemTemp.createTemp('lingbi_restore_id_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/.lingbi/trash/1.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('restore content');
    final item = RecoveryItem(
      id: 'item-1',
      type: RecoveryItemType.trash,
      path: source.path,
      title: '1.md',
      updatedAt: DateTime.utc(2026, 8, 5),
      originalPath: '${root.path}/chapters/ch01.md',
      projectId: 'proj-restore',
      projectRootPath: root.path,
    );
    final protocol = _CapturingMutationProtocol(root.path);
    final service = RecoveryCenterService(mutationProtocol: protocol);

    final restored = await service.restore(item);
    expect(restored.errorOrNull(), isNull);
    expect(protocol.lastRequest?.projectId, 'proj-restore');
    expect(
      protocol.lastRequest?.target.projectRelativePath,
      'chapters/ch01.md',
    );
    expect(protocol.lastRequest?.origin, ChangeOrigin.restore);
  });

  test('restore accepts a project-relative target path', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_restore_rel_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/.lingbi/trash/1.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('relative target content');
    final item = RecoveryItem(
      id: 'item-relative',
      type: RecoveryItemType.trash,
      path: source.path,
      title: '1.md',
      updatedAt: DateTime.utc(2026, 8, 5),
      projectId: 'proj-restore-relative',
      projectRootPath: root.path,
    );
    final protocol = _CapturingMutationProtocol(root.path);
    final service = RecoveryCenterService(mutationProtocol: protocol);

    final restored =
        await service.restore(item, targetPath: 'chapters/restored.md');
    expect(restored.errorOrNull(), isNull);
    expect(
      await File('${root.path}/chapters/restored.md').readAsString(),
      'relative target content',
    );
    expect(
      protocol.lastRequest?.target.projectRelativePath,
      'chapters/restored.md',
    );
  });
}

class _CapturingMutationProtocol implements MutationProtocol {
  _CapturingMutationProtocol(this.root);

  final String root;
  ChangeRequest? lastRequest;

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async {
    lastRequest = request;
    final target = File('$root/${request.target.projectRelativePath}');
    await target.parent.create(recursive: true);
    await target.writeAsString(request.payload);
    return Result.success(CommitReceipt(
      id: 'rcpt-capture',
      candidateId: 'cand-capture',
      approvalId: 'appr-capture',
      idempotencyKey: request.idempotencyKey ?? 'idem-capture',
      beforeRevision: 0,
      afterRevision: 1,
      affectedPaths: [request.target.projectRelativePath],
      committedAt: DateTime.now().toUtc(),
      receiptHash: 'capture',
    ));
  }

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      Result.failure(FileError('not used'));

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      Result.failure(FileError('not used'));

  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      Result.failure(FileError('not used'));

  @override
  Future<Result<void>> reject(RejectCommand command) async =>
      Result.failure(FileError('not used'));

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(
          String projectId) async =>
      Result.success(const []);
}
