/// 项目作用域 API 抽象
///
/// 定义项目级会话的公共接口。
/// ProjectSessionScope 实现此接口。
/// UI 协调层依赖此抽象而非具体实现。
library;

import 'novel_application_service.dart';

/// 项目作用域 API
abstract class ProjectScopeApi {
  /// 项目 ID
  String get projectId;

  /// 当前绑定的章节 ID
  String? get boundChapterId;

  /// 当前绑定的章节文件路径
  String? get boundFilePath;

  /// 小说写作应用服务（项目级）
  NovelApplicationService get novelService;

  /// 绑定当前章节
  void bindChapter({required String chapterId, required String filePath});

  /// 释放资源
  void dispose();
}
