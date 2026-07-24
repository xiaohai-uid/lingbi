import 'package:lingbi/core/models/project.dart';

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
}
