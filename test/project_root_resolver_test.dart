import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_root_resolver.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/i_project_service.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/project_storage_migration.dart';

final class _InMemoryProjectService implements IProjectService {
  _InMemoryProjectService(Iterable<Project> projects)
      : projects = List<Project>.of(projects);

  final List<Project> projects;

  @override
  Future<Project> createProject({
    required String name,
    required String directoryPath,
    String description = '',
  }) async {
    final project = Project(
      name: name,
      directoryPath: directoryPath,
      description: description,
    );
    projects.add(project);
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    projects.removeWhere((project) => project.id == id);
  }

  @override
  Future<Project?> getProject(String id) async {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  @override
  Future<List<Project>> getProjects() async => List<Project>.of(projects);

  @override
  Future<Result<ProjectStorageMigrationResult>> migratePortableProjects({
    required String oldRoot,
    required String newRoot,
  }) async =>
      Result.success(
          const ProjectStorageMigrationResult(migrated: 0, failed: 0));

  @override
  Future<void> updateProject(Project project) async {}
}

Future<void> _writeProjectMetadata(Project project) async {
  final metadata = File('${project.directoryPath}/.lingbi/project.json');
  await metadata.parent.create(recursive: true);
  await metadata.writeAsString(jsonEncode(project.toJson()), flush: true);
}

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('lingbi_root_resolver_');
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('resolves the moved directory from the stable project ID', () async {
    final oldRoot = Directory('${sandbox.path}/old-project');
    final newRoot = Directory('${sandbox.path}/renamed-project');
    final project = Project(
      id: 'stable-project',
      name: '稳定身份',
      directoryPath: oldRoot.path,
    );
    await _writeProjectMetadata(project);
    await oldRoot.rename(newRoot.path);
    project.directoryPath = newRoot.path;
    final service = _InMemoryProjectService([project]);

    final result = await ProjectRootResolverAdapter(
      projectService: service,
    ).resolve(project.id);

    expect(result, isA<Success<ResolvedProjectRoot>>());
    expect(
        (result as Success<ResolvedProjectRoot>).value.rootPath, newRoot.path);
    expect(
        (result as Success<ResolvedProjectRoot>).value.projectId, project.id);
    expect(await oldRoot.exists(), isFalse);
  });

  test('fails closed when the registry has no matching root', () async {
    final result = await ProjectRootResolverAdapter(
      projectService: _InMemoryProjectService(const []),
    ).resolve('missing-project');

    expect(result, isA<Failure<ResolvedProjectRoot>>());
    expect(
      (result as Failure<ResolvedProjectRoot>).error.code,
      'PROJECT_ROOT_NOT_FOUND',
    );
  });

  test('fails closed when two roots claim the same stable project ID',
      () async {
    final first = Project(
      id: 'duplicate-project',
      name: '副本一',
      directoryPath: '${sandbox.path}/copy-a',
    );
    final second = Project(
      id: first.id,
      name: '副本二',
      directoryPath: '${sandbox.path}/copy-b',
    );
    await _writeProjectMetadata(first);
    await _writeProjectMetadata(second);

    final result = await ProjectRootResolverAdapter(
      projectService: _InMemoryProjectService([first, second]),
    ).resolve(first.id);

    expect(result, isA<Failure<ResolvedProjectRoot>>());
    expect(
      (result as Failure<ResolvedProjectRoot>).error.code,
      'PROJECT_ROOT_AMBIGUITY',
    );
    expect(
      result.errorOrNull()?.typedCode,
      MutationErrorCode.projectRootAmbiguity,
    );
  });

  test('fails closed when the registered root has no project metadata',
      () async {
    final project = Project(
      id: 'metadata-missing',
      name: '缺少元数据',
      directoryPath: '${sandbox.path}/without-metadata',
    );
    await Directory(project.directoryPath).create(recursive: true);

    final result = await ProjectRootResolverAdapter(
      projectService: _InMemoryProjectService([project]),
    ).resolve(project.id);

    expect(result, isA<Failure<ResolvedProjectRoot>>());
    expect(
      (result as Failure<ResolvedProjectRoot>).error.code,
      'PROJECT_ROOT_NOT_FOUND',
    );
  });

  test('uses the registry location and never falls back to an app-global root',
      () async {
    final appGlobalRoot = Directory('${sandbox.path}/app-global');
    final projectRoot = Project(
      id: 'project-root-only',
      name: '项目根',
      directoryPath: '${sandbox.path}/project-root',
    );
    await _writeProjectMetadata(projectRoot);
    await Directory('${appGlobalRoot.path}/.lingbi').create(recursive: true);
    await File('${appGlobalRoot.path}/.lingbi/project.json').writeAsString(
      jsonEncode(projectRoot.toJson()),
    );

    final result = await ProjectRootResolverAdapter(
      projectService: _InMemoryProjectService([projectRoot]),
    ).resolve(projectRoot.id);

    expect(result, isA<Success<ResolvedProjectRoot>>());
    expect((result as Success<ResolvedProjectRoot>).value.rootPath,
        projectRoot.directoryPath);
    expect((result as Success<ResolvedProjectRoot>).value.rootPath,
        isNot(appGlobalRoot.path));
  });
}
