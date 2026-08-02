import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/project_storage_migration.dart';
import 'package:lingbi/shared/errors/result.dart';

/// 项目管理服务接口
abstract class IProjectService {
  Future<Project> createProject({
    required String name,
    required String directoryPath,
    String description = '',
  });

  Future<List<Project>> getProjects();
  Future<Project?> getProject(String id);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(String id);

  /// Move portable projects between user-selected storage roots.
  Future<Result<ProjectStorageMigrationResult>> migratePortableProjects({
    required String oldRoot,
    required String newRoot,
  });
}
