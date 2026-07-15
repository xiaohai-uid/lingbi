/// 风格检测服务接口
library;

import '../../data/database/world_database.dart';

/// 风格漂移检测报告
class StyleDriftReport {

  const StyleDriftReport({
    required this.driftScore,
    this.driftedDimensions = const [],
    this.details = '',
    this.suggestions = '',
  });
  final double driftScore; // 0.0=完全一致, 1.0=完全不同
  final List<String> driftedDimensions;
  final String details;
  final String suggestions;
}

abstract class IStyleDetectionService {
  /// 分析场景文本生成风格画像
  Future<StyleProfile> analyzeScene(String sceneId, String text, String worldId);

  /// 聚合场景级分析生成章级风格画像
  Future<StyleProfile> analyzeChapter(String chapterId, String worldId);

  /// 分析作品整体风格
  Future<StyleProfile> analyzeWork(String workId, String worldId);

  /// 检测两段文本的风格漂移
  Future<StyleDriftReport> detectDrift(String textA, String textB);

  /// 获取当前风格上下文（供生成时注入）
  Future<String> buildStyleContext(String worldId, {String? chapterId, String? workId});
}
