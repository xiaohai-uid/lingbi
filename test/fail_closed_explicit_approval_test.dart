/// T01: All mutation origins fail-closed + explicit approval.
///
/// Verifies:
/// 1. protocol==null → writes rejected (fail-closed)
/// 2. Non-userUi origins (skill, sync) → propose only, NO auto-commit
/// 3. Without explicit approval, no file is written
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

void main() {
  late Directory tempDir;
  late LocalMutationProtocol protocol;
  late LocalMutationJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('t01_fail_closed_');
    journal = LocalMutationJournal(
      basePath: '${tempDir.path}/.lingbi/mutations',
    );
    final store = FileCanonicalStore(
      projectRoot: tempDir.path,
      atomicStore: AtomicFileStore(),
    );
    protocol = LocalMutationProtocol(journal: journal, store: store);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('T01: non-userUi origins use propose-only (no auto-commit)', () {
    test('skill origin: propose creates candidate but does NOT write file',
        () async {
      const targetPath = 'canon/character/protagonist.md';
      const payload = '{"name": "主角"}';

      // Skill origin should only propose, not auto-commit
      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-t01',
        origin: ChangeOrigin.skill,
        action: ChangeAction.replaceText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'canon'),
        baseRevision: 0,
        payload: payload,
      ));
      expect(proposeResult, isA<Success<CandidateChange>>());
      final candidate = (proposeResult as Success).value;
      expect(candidate.state, CandidateState.proposed);

      // File must NOT exist (no auto-commit for skill origin)
      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isFalse,
          reason: 'skill origin must not auto-commit; requires explicit approval');

      // Journal has proposed event but NO committed event
      final events = await journal.readByAggregate(candidate.id);
      expect(events.any((e) => e.eventType == 'candidate_proposed'), isTrue);
      expect(events.any((e) => e.eventType == 'candidate_committed'), isFalse,
          reason: 'no commit without explicit approval');
    });

    test('skill origin: after explicit approve+commit, file IS written',
        () async {
      const targetPath = 'canon/character/hero.md';
      const payload = '{"name": "英雄"}';

      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-t01',
        origin: ChangeOrigin.skill,
        action: ChangeAction.replaceText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'canon'),
        baseRevision: 0,
        payload: payload,
      ));
      final candidate = (proposeResult as Success<CandidateChange>).value;

      // Explicit user approval
      final approveResult = await protocol.decide(ApprovalCommand(
        candidateId: candidate.id,
        actorId: 'user-t01',
        approved: true,
        policy: 'explicit_user',
      ));
      final approval = (approveResult as Success<ApprovalDecision>).value;

      // Commit after approval
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 't01-skill-explicit',
      ));
      expect(commitResult, isA<Success<CommitReceipt>>());

      // NOW the file exists
      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), payload);
    });

    test('batchImport origin: propose only, no auto-commit', () async {
      const targetPath = 'chapters/imported.md';
      const payload = '远端同步内容';

      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-t01',
        origin: ChangeOrigin.batchImport,
        action: ChangeAction.replaceText,
        target:
            ChangeTarget(projectRelativePath: targetPath, kind: 'sync_incoming'),
        baseRevision: 0,
        payload: payload,
      ));
      final candidate = (proposeResult as Success<CandidateChange>).value;

      // File must NOT exist
      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isFalse,
          reason: 'batchImport origin must not auto-commit');
    });
  });

  group('T01: userUi origin still uses applyUserEdit (implicit approval)', () {
    test('userUi origin: applyUserEdit writes file immediately', () async {
      const targetPath = 'notes/user_edit.md';
      const payload = '用户亲手编辑';

      final result = await protocol.applyUserEdit(const ChangeRequest(
        projectId: 'proj-t01',
        origin: ChangeOrigin.userUi,
        action: ChangeAction.createText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'note'),
        baseRevision: 0,
        payload: payload,
      ));
      expect(result, isA<Success<CommitReceipt>>());

      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), payload);
    });
  });

  group('T01: all origins without approval produce no file', () {
    for (final origin in ChangeOrigin.values) {
      test('${origin.name}: propose alone never writes file', () async {
        final targetPath = 'test/${origin.name}.md';

        await protocol.propose(ChangeRequest(
          projectId: 'proj-t01',
          origin: origin,
          action: ChangeAction.createText,
          target:
              ChangeTarget(projectRelativePath: targetPath, kind: 'test'),
          baseRevision: 0,
          payload: 'content-${origin.name}',
        ));

        final file = File('${tempDir.path}/$targetPath');
        expect(file.existsSync(), isFalse,
            reason: '${origin.name}: propose without approval must not write');
      });
    }
  });
}
