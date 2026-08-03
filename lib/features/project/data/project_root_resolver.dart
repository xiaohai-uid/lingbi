import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/i_project_service.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';
import 'package:lingbi/shared/models/project.dart';

/// Project-service adapter for the mutation root-resolution boundary.
///
/// The project registry is the only source of the current location. A path
/// supplied by a caller, the process working directory, or an application
/// support directory is never used as a fallback.
final class ProjectRootResolverAdapter implements ProjectRootResolver {
  ProjectRootResolverAdapter({required IProjectService projectService})
      : _projectService = projectService;

  final IProjectService _projectService;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async {
    if (projectId.trim().isEmpty) {
      return _notFound(projectId, 'project ID is empty');
    }

    final List<Project> registeredProjects;
    try {
      registeredProjects = await _projectService.getProjects();
    } catch (error) {
      return Result.failure(
        FileError(
          'Unable to read the project registry for $projectId',
          cause: error,
          typedCode: MutationErrorCode.storageFailure,
        ),
      );
    }

    final matches = registeredProjects
        .where((project) => project.id == projectId)
        .toList(growable: false);
    if (matches.isEmpty) {
      return _notFound(projectId, 'no registered project has this identity');
    }
    if (matches.length > 1) {
      return Result.failure(
        FileError(
          'Multiple project roots claim stable project ID $projectId',
          typedCode: MutationErrorCode.projectRootAmbiguity,
        ),
      );
    }

    final Project? registeredProject;
    try {
      registeredProject = await _projectService.getProject(projectId);
    } catch (error) {
      return Result.failure(
        FileError(
          'Unable to read project $projectId from the project registry',
          cause: error,
          typedCode: MutationErrorCode.storageFailure,
        ),
      );
    }

    // A registry implementation may expose a single record through
    // getProjects() while its point lookup is not available yet (for example,
    // during discovery). In that case the already-identified record is still
    // safe to validate; duplicates were rejected above.
    return _validateRegisteredRoot(
      registeredProject ?? matches.single,
      projectId,
    );
  }

  Future<Result<ResolvedProjectRoot>> _validateRegisteredRoot(
    Project project,
    String projectId,
  ) async {
    final rootPath = project.directoryPath.trim();
    if (rootPath.isEmpty) {
      return _notFound(projectId, 'registered project has no directory');
    }

    final root = Directory(rootPath);
    final metadata = File(p.join(rootPath, '.lingbi', 'project.json'));
    if (!await root.exists() || !await metadata.exists()) {
      return _notFound(projectId, 'registered project root is unavailable');
    }

    try {
      final decoded = jsonDecode(await metadata.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['id'] != projectId) {
        return Result.failure(
          FileError(
            'Project metadata does not match stable project ID $projectId',
            code: 'PROJECT_ROOT_METADATA_MISMATCH',
          ),
        );
      }
    } catch (error) {
      return Result.failure(
        FileError(
          'Project metadata cannot be read for $projectId',
          code: 'PROJECT_ROOT_METADATA_MISMATCH',
          cause: error,
        ),
      );
    }

    return Result.success(
      ResolvedProjectRoot(projectId: projectId, rootPath: rootPath),
    );
  }

  Result<ResolvedProjectRoot> _notFound(String projectId, String reason) {
    return Result.failure(
      FileError(
        'Project root not found for $projectId: $reason',
        code: 'PROJECT_ROOT_NOT_FOUND',
      ),
    );
  }
}
