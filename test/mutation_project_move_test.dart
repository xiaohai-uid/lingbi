/// MP-06: current-root resolution at commit time.
///
/// A project move between propose and commit must not detach the mutation:
/// commit resolves the current root again and writes there, and resolution
/// failure closes the commit.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

import 'support/mutation_test_harness.dart';

void main() {
  late Directory tempDir;
  late String rootA;
  late String rootB;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('project_move_test_');
    rootA = '${tempDir.path}/a';
    rootB = '${tempDir.path}/b';
    Directory(rootA).createSync(recursive: true);
    Directory(rootB).createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  LocalMutationProtocol buildProtocol(ProjectRootResolver resolver) =>
      boundProtocolWithResolver(resolver);

  test('move between propose and commit writes to the current root', () async {
    final resolver = _ScriptedResolver([
      _step(rootA), _step(rootA), // propose: resolve + journal factory
      _step(rootA), _step(rootA), // decide: resolve + journal factory
      _step(rootB), _step(rootB), // commit: current root — the project moved
    ]);
    final protocol = buildProtocol(resolver);

    const payload = '移动后的项目内容';
    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-move',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: payload,
    ));
    final candidate = proposeResult.getOrNull();
    expect(candidate, isNotNull);

    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate!.id,
      actorId: 'user-test',
      approved: true,
      policy: 'explicit_user',
      projectId: 'proj-move',
    ));
    final approval = approveResult.getOrNull();
    expect(approval, isNotNull);

    // Simulate the filesystem move: the whole project folder — including its
    // .lingbi mutation journal — is relocated from A to B.
    copyTree(Directory(rootA), Directory(rootB));

    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval!.id,
      idempotencyKey: 'idem-move',
      projectId: 'proj-move',
    ));
    expect(commitResult, isA<Success<CommitReceipt>>());

    expect(File('$rootB/chapters/ch01.md').existsSync(), isTrue);
    expect(await File('$rootB/chapters/ch01.md').readAsString(), payload);
    expect(File('$rootA/chapters/ch01.md').existsSync(), isFalse);

    // The authoritative journal traveled with the project: all four records
    // live in root B's journal.
    final journalB = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: 'proj-move', rootPath: rootB),
    );
    final events = await journalB.readByAggregate(candidate.id);
    final types = events.map((e) => e.eventType).toList();
    expect(
        types,
        containsAll([
          'candidate_proposed',
          'candidate_approved',
          'commit_intent',
          'candidate_committed',
        ]));
  });

  test('zero-root resolution at commit fails closed without writing', () async {
    final resolver = _ScriptedResolver([
      _step(rootA), _step(rootA), // propose
      _step(rootA), _step(rootA), // decide
      _failure('no root', code: MutationErrorCode.projectRootAmbiguity),
      _failure('no root',
          code:
              MutationErrorCode.projectRootAmbiguity), // commit — project gone
    ]);
    final protocol = buildProtocol(resolver);

    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-gone',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '内容',
    ));
    final candidate = proposeResult.getOrNull();

    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate!.id,
      actorId: 'user-test',
      approved: true,
      policy: 'explicit_user',
      projectId: 'proj-move',
    ));
    final approval = approveResult.getOrNull();

    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval!.id,
      idempotencyKey: 'idem-gone',
    ));
    expect(commitResult, isA<Failure>());
    final error = (commitResult as Failure).error;
    expect(error.typedCode, MutationErrorCode.projectRootAmbiguity);
    expect(File('$rootA/chapters/ch01.md').existsSync(), isFalse);
  });

  test('ambiguous root at commit fails closed without writing', () async {
    final resolver = _ScriptedResolver([
      _step(rootA),
      _step(rootA),
      _step(rootA),
      _step(rootA),
      _failure('two roots claim the same id',
          code: MutationErrorCode.projectRootAmbiguity),
      _failure('two roots claim the same id',
          code: MutationErrorCode.projectRootAmbiguity),
    ]);
    final protocol = buildProtocol(resolver);

    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-dup',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '内容',
    ));
    final candidate = proposeResult.getOrNull();

    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate!.id,
      actorId: 'user-test',
      approved: true,
      policy: 'explicit_user',
      projectId: 'proj-move',
    ));
    final approval = approveResult.getOrNull();

    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval!.id,
      idempotencyKey: 'idem-dup',
    ));
    expect(commitResult, isA<Failure>());
    expect(
      (commitResult as Failure).error.typedCode,
      MutationErrorCode.projectRootAmbiguity,
    );
    expect(File('$rootA/chapters/ch01.md').existsSync(), isFalse);
    expect(File('$rootB/chapters/ch01.md').existsSync(), isFalse);
  });
}

class _ScriptedResolver implements ProjectRootResolver {
  _ScriptedResolver(this.steps);

  final List<Result<ResolvedProjectRoot>> steps;
  int _index = 0;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async {
    final step = steps.length > _index ? steps[_index] : _failure('exhausted');
    _index++;
    return step;
  }
}

Result<ResolvedProjectRoot> _step(String rootPath) => Result.success(
      ResolvedProjectRoot(projectId: 'p', rootPath: rootPath),
    );

Result<ResolvedProjectRoot> _failure(
  String message, {
  MutationErrorCode? code,
}) =>
    Result.failure(FileError(message, typedCode: code));
