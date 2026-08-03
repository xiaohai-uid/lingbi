import 'package:lingbi/shared/errors/result.dart';

/// Resolves a stable project identity to the one filesystem root that is
/// currently allowed to receive canonical mutations.
abstract interface class ProjectRootResolver {
  Future<Result<ResolvedProjectRoot>> resolve(String projectId);
}

/// The project location resolved for one mutation operation.
final class ResolvedProjectRoot {
  const ResolvedProjectRoot({
    required this.projectId,
    required this.rootPath,
  });

  final String projectId;
  final String rootPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedProjectRoot &&
          projectId == other.projectId &&
          rootPath == other.rootPath;

  @override
  int get hashCode => Object.hash(projectId, rootPath);
}
