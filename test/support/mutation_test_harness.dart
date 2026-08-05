import 'dart:io';

import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

Future<(CandidateChange, ApprovalDecision)> proposeAndApprove(
  LocalMutationProtocol protocol, {
  required String projectId,
  required String targetPath,
  required String payload,
  ChangeAction action = ChangeAction.createText,
  int baseRevision = 0,
}) async {
  final proposeResult = await protocol.propose(ChangeRequest(
    projectId: projectId,
    origin: ChangeOrigin.agent,
    action: action,
    target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
    baseRevision: baseRevision,
    payload: payload,
  ));
  final candidate = proposeResult.getOrNull();
  if (candidate == null) {
    throw StateError('propose failed: ${proposeResult.errorOrNull()}');
  }

  final approveResult = await protocol.decide(ApprovalCommand(
    candidateId: candidate.id,
    actorId: 'user-p0',
    approved: true,
    policy: 'explicit_user',
    projectId: projectId,
  ));
  final approval = approveResult.getOrNull();
  if (approval == null) {
    throw StateError('approve failed: ${approveResult.errorOrNull()}');
  }
  return (candidate, approval);
}

CommitIntent makeIntent({
  required String candidateId,
  required String projectId,
  required String targetPath,
  required String expectedContentHash,
  String idempotencyKey = 'idem',
  String baseContentHash = '',
}) =>
    CommitIntent(
      id: 'intent-$idempotencyKey',
      projectId: projectId,
      candidateId: candidateId,
      targetPath: targetPath,
      baseRevision: 0,
      expectedRevision: 1,
      expectedContentHash: expectedContentHash,
      idempotencyKey: idempotencyKey,
      baseContentHash: baseContentHash,
    );

LocalMutationJournal journalForProject(String projectId, String root) =>
    LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: projectId, rootPath: root),
    );

LocalMutationProtocol boundProtocol(String projectId, String root) =>
    boundProtocolWithResolver(SingleRootResolver(projectId, root));

LocalMutationProtocol boundProtocolWithResolver(
  ProjectRootResolver resolver,
) =>
    LocalMutationProtocol.projectBound(
      resolver: resolver,
      journalFactory: ProjectMutationJournalFactory(resolver: resolver),
      storeForRoot: (root) => FileCanonicalStore.projectOwned(
        root,
        atomicStore: AtomicFileStore(),
      ),
    );

void copyTree(Directory source, Directory target) {
  for (final entity in source.listSync(recursive: true)) {
    final relative = entity.path.substring(source.path.length + 1);
    final destination = '${target.path}/$relative';
    if (entity is Directory) {
      Directory(destination).createSync(recursive: true);
    } else if (entity is File) {
      Directory(File(destination).parent.path).createSync(recursive: true);
      entity.copySync(destination);
    }
  }
}

class SingleRootResolver implements ProjectRootResolver {
  SingleRootResolver(this.projectId, this.rootPath);

  final String projectId;
  final String rootPath;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String id) async {
    if (id != projectId) {
      return Result.failure(FileError(
        'no root for $id',
        typedCode: MutationErrorCode.projectRootAmbiguity,
      ));
    }
    return Result.success(
      ResolvedProjectRoot(projectId: id, rootPath: rootPath),
    );
  }
}

class MutableRootResolver implements ProjectRootResolver {
  MutableRootResolver(this.projectId, this.rootPath);

  final String projectId;
  String rootPath;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String id) async {
    if (id != projectId) {
      return Result.failure(FileError('no root for $id'));
    }
    return Result.success(
      ResolvedProjectRoot(projectId: projectId, rootPath: rootPath),
    );
  }
}

class FailureResolver implements ProjectRootResolver {
  FailureResolver(this.error);

  final FileError error;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async =>
      Result.failure(error);
}
