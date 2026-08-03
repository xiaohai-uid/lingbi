/// Binds the authoritative mutation journal to a resolved project root.
///
/// The journal path is derived only after project-root resolution and never
/// from a request-supplied absolute path (ADR-012). Callers pass a stable
/// project ID; the resolver locates the one current root.
library;

import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

/// Creates the project-owned journal for the current root of a project.
final class ProjectMutationJournalFactory {
  ProjectMutationJournalFactory({required this.resolver});

  final ProjectRootResolver resolver;

  /// Resolves [projectId] to its current root and returns the journal bound
  /// to `<root>/.lingbi/mutations/events.jsonl`.
  ///
  /// Zero-root and ambiguous-root resolutions fail closed with the typed
  /// error produced by the resolver; no journal and no directory are created.
  Future<Result<LocalMutationJournal>> forProject(String projectId) async {
    final resolution = await resolver.resolve(projectId);
    final root = resolution.getOrNull();
    if (root == null) {
      return Result.failure(resolution.errorOrNull()!);
    }
    return Result.success(LocalMutationJournal.projectOwned(root));
  }
}
