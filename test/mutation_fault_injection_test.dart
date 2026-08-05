/// MP-11: P0 fault-injection evidence.
///
/// Covers path escape, external edit, crash windows, indeterminate freeze,
/// recovery center surfacing, and missing-root fail-closed behavior.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/services/recovery_center_service.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

import 'support/mutation_test_harness.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_p0_fault_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('path escape is rejected without writing or receipt', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-escape';
    final protocol = boundProtocol(projectId, root);

    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: projectId,
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: '../escape.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: 'must not escape',
    ));
    expect(proposeResult, isA<Failure>());
    expect(
      (proposeResult as Failure).error.typedCode,
      MutationErrorCode.pathEscape,
    );
    expect(File('${tempDir.path}/escape.md').existsSync(), isFalse);
    expect(File('$root/../escape.md').existsSync(), isFalse);

    final journal = journalForProject(projectId, root);
    expect(await journal.readAll(), isEmpty);
  });

  test('external edit between propose and commit fails closed', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-external';
    const targetPath = 'chapters/conflict.md';
    File('$root/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync('V1');
    final protocol = boundProtocol(projectId, root);

    final (candidate, approval) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: 'V2',
      action: ChangeAction.replaceText,
      baseRevision: 0,
    );
    File('$root/$targetPath').writeAsStringSync('V1.5');

    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: 'p0-external-commit',
      projectId: projectId,
    ));
    expect(commitResult, isA<Failure>());
    expect(
      (commitResult as Failure).error.typedCode,
      MutationErrorCode.revisionConflict,
    );
    expect(await File('$root/$targetPath').readAsString(), 'V1.5');

    final journal = journalForProject(projectId, root);
    final events = await journal.readByAggregate(candidate.id);
    expect(
      events.map((event) => event.eventType),
      isNot(contains('candidate_committed')),
    );
  });

  test('crash before apply abandons intent without touching target', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-crash-before';
    final protocol = boundProtocol(projectId, root);
    const payload = 'expected payload';
    const targetPath = 'chapters/before.md';
    final (candidate, _) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
    );
    final journal = journalForProject(projectId, root);
    await journal.appendCommitIntent(makeIntent(
      candidateId: candidate.id,
      projectId: projectId,
      targetPath: targetPath,
      expectedContentHash: canonicalTextHash(payload),
      idempotencyKey: 'p0-crash-before',
    ));

    final outcomes = await protocol.reconcilePending(projectId);
    expect(outcomes, isA<Success<List<RecoveryOutcome>>>());
    expect(
      (outcomes as Success<List<RecoveryOutcome>>).value.single.outcome,
      RecoveryOutcomeType.intentAbandoned,
    );
    expect(File('$root/$targetPath').existsSync(), isFalse);
    expect(
      (await journal.readAll())
          .where((event) => event.eventType == 'recovery_outcome'),
      hasLength(1),
    );
  });

  test('crash after apply completes receipt on reopen', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-crash-after';
    final protocol = boundProtocol(projectId, root);
    const payload = 'landed payload';
    const targetPath = 'chapters/after.md';
    final (candidate, _) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
    );
    final journal = journalForProject(projectId, root);
    await journal.appendCommitIntent(makeIntent(
      candidateId: candidate.id,
      projectId: projectId,
      targetPath: targetPath,
      expectedContentHash: canonicalTextHash(payload),
      idempotencyKey: 'p0-crash-after',
    ));
    File('$root/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(payload);

    final outcomes = await protocol.reconcilePending(projectId);
    expect(outcomes, isA<Success<List<RecoveryOutcome>>>());
    expect(
      (outcomes as Success<List<RecoveryOutcome>>).value.single.outcome,
      RecoveryOutcomeType.receiptCompleted,
    );
    expect(await File('$root/$targetPath').readAsString(), payload);
    expect(
      (await journal.readByAggregate(candidate.id))
          .map((event) => event.eventType),
      contains('candidate_committed'),
    );
  });

  test('indeterminate bytes surface in recovery center and can be approved',
      () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-frozen';
    final protocol = boundProtocol(projectId, root);
    const payload = 'expected payload';
    const targetPath = 'chapters/frozen.md';
    final (candidate, _) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
    );
    final journal = journalForProject(projectId, root);
    await journal.appendCommitIntent(makeIntent(
      candidateId: candidate.id,
      projectId: projectId,
      targetPath: targetPath,
      expectedContentHash: canonicalTextHash(payload),
      baseContentHash: canonicalTextHash('base payload'),
      idempotencyKey: 'p0-frozen',
    ));
    File('$root/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync('indeterminate bytes');

    final store = FileCanonicalStore.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
      atomicStore: AtomicFileStore(),
    );
    final service = RecoveryCenterService(
      mutationProtocol: protocol,
      journal: journal,
      canonicalStore: store,
      rootResolver: SingleRootResolver(projectId, root),
    );
    final incidents = await service.scanIncidents();
    expect(incidents.errorOrNull(), isNull);
    expect(incidents.getOrNull(), hasLength(1));
    final incident = incidents.getOrNull()!.single;
    expect(incident.targetPath, targetPath);
    expect(incident.currentContent, 'indeterminate bytes');

    final decision = await service.decideIncident(
      incident: incident,
      approveCurrentBytes: true,
    );
    expect(decision.errorOrNull(), isNull);
    expect(
        await File('$root/$targetPath').readAsString(), 'indeterminate bytes');
    expect((await service.scanIncidents()).getOrNull(), isEmpty);
  });

  test('reconcilePending frozen intent is still visible to recovery center',
      () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-frozen-after-reconcile';
    final protocol = boundProtocol(projectId, root);
    const payload = 'expected payload after reconcile';
    const targetPath = 'chapters/frozen-after-reconcile.md';
    final (candidate, _) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: payload,
    );
    final journal = journalForProject(projectId, root);
    await journal.appendCommitIntent(makeIntent(
      candidateId: candidate.id,
      projectId: projectId,
      targetPath: targetPath,
      expectedContentHash: canonicalTextHash(payload),
      baseContentHash: canonicalTextHash('base payload'),
      idempotencyKey: 'p0-frozen-after-reconcile',
    ));
    File('$root/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync('indeterminate bytes after reconcile');

    final outcomes = await protocol.reconcilePending(projectId);
    expect(outcomes.errorOrNull(), isNull);
    expect(
      outcomes.getOrNull()!.single.outcome,
      RecoveryOutcomeType.targetFrozen,
    );

    final store = FileCanonicalStore.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
      atomicStore: AtomicFileStore(),
    );
    final service = RecoveryCenterService(
      mutationProtocol: protocol,
      journal: journal,
      canonicalStore: store,
      rootResolver: SingleRootResolver(projectId, root),
    );
    final incidents = await service.scanIncidents();
    expect(incidents.errorOrNull(), isNull);
    expect(
      incidents.getOrNull(),
      hasLength(1),
      reason: 'targetFrozen outcomes must still resolve their commit intent',
    );
    expect(incidents.getOrNull()!.single.targetPath, targetPath);
  });

  test('factory-bound recovery center can scan and decide incidents', () async {
    final root = '${tempDir.path}/project';
    Directory(root).createSync(recursive: true);
    const projectId = 'proj-p0-factory-decide';
    final protocol = boundProtocol(projectId, root);
    const expectedPayload = 'expected factory payload';
    const currentBytes = 'factory current bytes';
    const targetPath = 'chapters/factory-decide.md';
    final (candidate, _) = await proposeAndApprove(
      protocol,
      projectId: projectId,
      targetPath: targetPath,
      payload: expectedPayload,
    );
    final journal = journalForProject(projectId, root);
    await journal.appendCommitIntent(makeIntent(
      candidateId: candidate.id,
      projectId: projectId,
      targetPath: targetPath,
      expectedContentHash: canonicalTextHash(expectedPayload),
      baseContentHash: canonicalTextHash('base payload'),
      idempotencyKey: 'p0-factory-decide',
    ));
    File('$root/$targetPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(currentBytes);

    final resolver = SingleRootResolver(projectId, root);
    final service = RecoveryCenterService(
      mutationProtocol: protocol,
      journalFactory: ProjectMutationJournalFactory(resolver: resolver),
      storeForRoot: (root) => FileCanonicalStore.projectOwned(
        root,
        atomicStore: AtomicFileStore(),
      ),
      rootResolver: resolver,
      projectIdProvider: () async => [projectId],
    );

    final incidents = await service.scanIncidents();
    expect(incidents.errorOrNull(), isNull);
    expect(incidents.getOrNull(), hasLength(1));

    final decision = await service.decideIncident(
      incident: incidents.getOrNull()!.single,
      approveCurrentBytes: true,
    );
    expect(decision.errorOrNull(), isNull);
    expect(
      decision.getOrNull()!.outcome,
      RecoveryOutcomeType.receiptCompleted,
    );
    expect((await service.scanIncidents()).getOrNull(), isEmpty);
  });

  test('missing project root fails closed with typed ambiguity error',
      () async {
    final root = '${tempDir.path}/project';
    final resolver = FailureResolver(
      FileError(
        'no root for missing project',
        typedCode: MutationErrorCode.projectRootAmbiguity,
      ),
    );
    final protocol = boundProtocolWithResolver(resolver);

    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'missing',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: 'must not write',
    ));

    expect(proposeResult, isA<Failure>());
    expect(
      (proposeResult as Failure).error.typedCode,
      MutationErrorCode.projectRootAmbiguity,
    );
    expect(
      File('$root/.lingbi/mutations/events.jsonl').existsSync(),
      isFalse,
    );
  });
}
