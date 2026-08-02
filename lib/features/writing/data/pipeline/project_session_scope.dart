/// 项目级服务作用域
///
/// 管理绑定到特定项目的有状态服务实例。
/// 打开项目时创建，切换项目时切换，关闭项目时销毁。
/// 不注册为全局单例。
library;

import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';

import 'novel_application_service.dart';
import 'project_scope_api.dart';

/// 项目级会话作用域
///
/// 每个打开的项目对应一个实例。
/// 持有 NovelApplicationService 及其依赖的项目级服务。
class ProjectSessionScope implements ProjectScopeApi {
  ProjectSessionScope({
    required String projectId,
    required String projectDir,
    required DocumentService documentService,
    required CanonService canonService,
    required AIService aiService,
  })  : _projectId = projectId,
        _projectDir = projectDir,
        novelService = NovelApplicationService(
          projectDir: projectDir,
          projectId: projectId,
          documentService: documentService,
          canonService: canonService,
          aiService: aiService,
        );

  final String _projectId;
  final String _projectDir;

  /// 小说写作应用服务（项目级）
  @override
  final NovelApplicationService novelService;

  @override
  String get projectId => _projectId;
  String get projectDir => _projectDir;

  /// 当前绑定的章节 ID
  @override
  String? boundChapterId;

  /// 当前绑定的章节文件路径
  @override
  String? boundFilePath;

  /// 绑定当前章节
  @override
  void bindChapter({required String chapterId, required String filePath}) {
    boundChapterId = chapterId;
    boundFilePath = filePath;
  }

  /// 解绑章节
  void unbindChapter() {
    boundChapterId = null;
    boundFilePath = null;
  }

  /// 是否可以开始写作（有绑定章节 + 服务空闲 + 无结算阻塞）
  bool get canWrite =>
      boundChapterId != null && novelService.canStartWriting();

  /// 释放资源
  @override
  void dispose() {
    unbindChapter();
  }
}
