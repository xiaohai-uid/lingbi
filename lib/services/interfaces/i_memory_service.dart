/// 写作记忆服务接口
///
/// 定义长文本自动摘要 + 上下文管理的完整契约。
library;

import '../../data/database/world_database.dart';

/// 摘要类型
enum SummaryType { scene, chapter, volume }

/// 摘要元数据（用于列表展示）
class SummaryMeta {

  const SummaryMeta({
    required this.id,
    required this.type,
    required this.parentId,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final SummaryType type;
  final String parentId; // sceneId / chapterId / volumeId
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// 记忆上下文预览（用于 UI 展示）
class MemoryContextPreview {

  const MemoryContextPreview({
    required this.entries,
    required this.assembledText,
  });
  final List<ContextEntry> entries;
  final String assembledText;
}

/// 上下文条目
class ContextEntry {

  const ContextEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.summary,
    required this.autoInjected,
  });
  final String id;
  final SummaryType type;
  final String label; // 如 "第5章摘要"、"场景12摘要"
  final String summary;
  final bool autoInjected;
}

/// 写作记忆服务接口
abstract class IMemoryService {
  /// 对单个场景生成摘要（场景正文完成后调用）
  Future<SceneSummary> summarizeScene(String sceneId);

  /// 聚合本章所有场景摘要，生成章级摘要
  Future<ChapterSummary> summarizeChapter(String chapterId, String worldId);

  /// 聚合本卷所有章摘要，生成卷级摘要
  Future<VolumeSummary> summarizeVolume(String volumeId, String worldId);

  /// 为当前生成位置构建记忆上下文文本
  Future<String> buildMemoryContext({
    required String worldId,
    required String currentChapterId,
    String? currentSceneId,
    bool includeVolumeSummary = true,
    int previousChaptersLimit = 5,
    Set<String> excludeIds = const {},
  });

  /// 获取上下文预览（供 UI 编辑）
  Future<MemoryContextPreview> getContextPreview({
    required String worldId,
    required String chapterId,
    String? sceneId,
  });

  /// 更新指定摘要的内容（用户手动编辑）
  Future<void> updateSummary(SummaryType type, String id, String newContent);

  /// 获取最近摘要列表
  Future<List<SummaryMeta>> getRecentMemories(String worldId, {int limit = 20});

  /// 按关键词搜索摘要
  Future<List<SummaryMeta>> searchMemories(String worldId, String keyword);

  /// 语义搜索记忆（Phase 2）
  Future<List<SummaryMeta>> semanticSearchMemories(
    String worldId,
    String query, {
    int limit = 10,
  });
}
