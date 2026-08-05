/// MP-11: commercial P0 acceptance evidence.
///
/// Covers a real temporary project directory, project-owned journal,
/// full-file payload equality, close/reopen, project move, and duplicate
/// identity classification.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';
import 'package:lingbi/shared/models/project.dart';

import 'support/mutation_test_harness.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_p0_acceptance_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
      'candidate to commit writes the complete payload and project-owned '
      'journal', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-acceptance';
    final protocol = boundProtocol(projectId, root);
    const payload = '# Chapter 1\n\nLingBi accepted chapter payload.';
    const targetPath = 'chapters/ch01.md';

    final (candidate, approval, receipt) = await _commit(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
      idempotencyKey: 'p0-acceptance-commit',
    );

    final file = File('$root/$targetPath');
    expect(file.existsSync(), isTrue);
    expect(await file.readAsString(), payload);
    expect(
      canonicalTextHash(await file.readAsString()),
      candidate.payloadHash,
      reason: 'candidate, receipt, and final disk bytes must agree',
    );
    expect(receipt.affectedPaths, [targetPath]);
    expect(receipt.afterContentHash, candidate.payloadHash);
    expect(
      receipt.afterContentHash,
      canonicalTextHash(await file.readAsString()),
    );

    final journal = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
    );
    expect(journal.eventsFilePath, '$root/.lingbi/mutations/events.jsonl');
    final events = await journal.readByAggregate(candidate.id);
    expect(
      events.map((event) => event.eventType),
      containsAll(<String>[
        'candidate_proposed',
        'candidate_approved',
        'commit_intent',
        'candidate_committed',
      ]),
    );
    expect(await journal.validateChain(), isTrue);
  });

  test('close and reopen preserves payload and journal chain', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-reopen';
    final protocol = boundProtocol(projectId, root);
    const payload = 'Persisted content that survives restart.';
    const targetPath = 'chapters/restart.md';

    final (candidate, _, _) = await _commit(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
      idempotencyKey: 'p0-reopen-commit',
    );

    final reopenedJournal = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
    );
    expect(await reopenedJournal.validateChain(), isTrue);
    expect(await reopenedJournal.readByAggregate(candidate.id), isNotEmpty);

    final reopenedStore = FileCanonicalStore.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
      atomicStore: AtomicFileStore(),
    );
    final snapshot = await reopenedStore.read(targetPath);
    expect(snapshot.errorOrNull(), isNull);
    expect(snapshot.getOrNull()?.content, payload);
  });

  test('move between propose and commit writes to the current root', () async {
    final rootA = '${tempDir.path}/original';
    final rootB = '${tempDir.path}/moved';
    Directory(rootA).createSync(recursive: true);
    Directory(rootB).createSync(recursive: true);
    const projectId = 'proj-p0-move';
    final resolver = MutableRootResolver(projectId, rootA);
    final protocol = boundProtocolWithResolver(resolver);
    const payload = 'Moved project payload.';
    const targetPath = 'chapters/moved.md';

    final (candidate, approval) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
    );

    copyTree(Directory(rootA), Directory(rootB));
    resolver.rootPath = rootB;

    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: 'p0-move-commit',
      projectId: projectId,
    ));
    expect(commitResult, isA<Success<CommitReceipt>>());
    expect(File('$rootB/$targetPath').existsSync(), isTrue);
    expect(await File('$rootB/$targetPath').readAsString(), payload);
    expect(File('$rootA/$targetPath').existsSync(), isFalse);

    final journalB = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: rootB),
    );
    final eventTypes = await journalB.readByAggregate(candidate.id);
    expect(
      eventTypes.map((event) => event.eventType),
      containsAll(<String>[
        'candidate_proposed',
        'candidate_approved',
        'commit_intent',
        'candidate_committed',
      ]),
    );
  });

  test('duplicate project id is classified without silent rebind', () async {
    final originalDir = '${tempDir.path}/original';
    final copyDir = '${tempDir.path}/copy';
    Directory(originalDir).createSync(recursive: true);
    final original = Project(
      id: 'proj-p0-duplicate',
      name: 'Original',
      directoryPath: originalDir,
    );
    final copy = Project(
      id: original.id,
      name: original.name,
      directoryPath: copyDir,
    );

    final identity = ProjectService().classifyIdentity(
      copy,
      knownProjects: [original],
    );

    expect(identity.kind, ProjectIdentityKind.duplicateCopy);
    expect(identity.existingDirectory, originalDir);
    expect(copy.id, original.id, reason: 'duplicate open must not rebind id');
  });
}

Future<(CandidateChange, ApprovalDecision, CommitReceipt)> _commit(
  LocalMutationProtocol protocol, {
  required String projectId,
  required String targetPath,
  required String payload,
  required String idempotencyKey,
}) async {
  final (candidate, approval) = await proposeAndApprove(
    protocol,
    projectId: projectId,
    targetPath: targetPath,
    payload: payload,
  );
  final commitResult = await protocol.commit(CommitCommand(
    candidateId: candidate.id,
    approvalId: approval.id,
    idempotencyKey: idempotencyKey,
    projectId: projectId,
  ));
  expect(commitResult, isA<Success<CommitReceipt>>());
  return (candidate, approval, (commitResult as Success<CommitReceipt>).value);
}
