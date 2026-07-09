import 'package:lingbi/services/interfaces/i_project_service.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/database/zvec_service.dart';

@Deprecated(
    'Use WorldService instead. Project is being replaced by World + Work in v4.0')
class ProjectService implements IProjectService {
  @Deprecated('Use WorldService instead')
  ProjectService({required ZVecService zvecService}) : _zvec = zvecService;
  final ZVecService _zvec;

  /// 创建新项目
  @override
  Future<Project> createProject({
    required String name,
    required String directoryPath,
    String description = '',
  }) async {
    final project = Project(
      name: name,
      description: description,
      directoryPath: directoryPath,
    );
    await _zvec.upsert('projects', project.id, project.toJson());
    return project;
  }

  /// 获取所有项目
  @override
  Future<List<Project>> getProjects() async {
    final results = await _zvec.query('projects');
    return results.map((json) => Project.fromJson(json)).toList();
  }

  /// 根据 ID 获取项目
  @override
  Future<Project?> getProject(String id) async {
    final result = await _zvec.get<Map<String, dynamic>>('projects', id);
    if (result == null) return null;
    return Project.fromJson(result);
  }

  /// 更新项目
  @override
  Future<void> updateProject(Project project) async {
    project.updatedAt = DateTime.now();
    await _zvec.upsert('projects', project.id, project.toJson());
  }

  /// 删除项目
  @override
  Future<void> deleteProject(String id) async {
    await _zvec.delete('projects', id);
  }
}
