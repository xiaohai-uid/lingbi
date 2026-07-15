/// MemoryContextBuilder — 记忆上下文构建器
///
/// 负责从 SceneSummaries / ChapterSummaries / VolumeSummaries 表中
/// 提取相关摘要，格式化为 AI 生成时可注入的上下文文本。
library;

import '../../data/database/world_database.dart';

/// 上下文构建结果
class BuildContextResult {

  const BuildContextResult({
    required this.text,
    required this.summaryCount,
    required this.totalWords,
  });
  final String text;
  final int summaryCount;
  final int totalWords;
}

/// 记忆上下文构建器
class MemoryContextBuilder {
  /// 构建生成上下文文本
  ///
  /// [sceneSummaries] — 当前章节的前序场景摘要（按顺序）
  /// [chapterSummaries] — 前几章的摘要
  /// [volumeSummary] — 当前卷的摘要（可选）
  /// [previousChaptersLimit] — 最多包含前几章的摘要
  static BuildContextResult build({
    required List<SceneSummary> sceneSummaries,
    required List<ChapterSummary> chapterSummaries,
    VolumeSummary? volumeSummary,
    int previousChaptersLimit = 5,
  }) {
    final parts = <String>[];
    int summaryCount = 0;
    int totalWords = 0;

    // 1. 卷摘要（可选）
    if (volumeSummary != null && volumeSummary.summary.isNotEmpty) {
      parts.add('【卷摘要】\n${volumeSummary.summary}');
      summaryCount++;
      totalWords += volumeSummary.summary.length;
    }

    // 2. 前章摘要
    final recentChapters = chapterSummaries.take(previousChaptersLimit);
    for (final ch in recentChapters) {
      final lines = <String>['【前章回顾】\n${ch.summary}'];
      if (ch.hook.isNotEmpty) {
        lines.add('章末钩子：${ch.hook}');
      }
      if (ch.unansweredQuestions.isNotEmpty) {
        lines.add('未解答悬念：${ch.unansweredQuestions}');
      }
      parts.add(lines.join('\n'));
      summaryCount++;
      totalWords += ch.summary.length;
    }

    // 3. 前序场景摘要
    for (final scene in sceneSummaries) {
      final lines = <String>['【前序场景】\n${scene.summary}'];

      if (scene.characterEmotions.isNotEmpty) {
        lines.add('角色状态：${scene.characterEmotions}');
      }
      if (scene.suspenseTags.isNotEmpty) {
        lines.add('悬念：${scene.suspenseTags}');
      }
      if (scene.mood.isNotEmpty) {
        lines.add('氛围：${scene.mood}');
      }

      parts.add(lines.join('\n'));
      summaryCount++;
      totalWords += scene.summary.length;
    }

    if (parts.isEmpty) {
      return const BuildContextResult(text: '', summaryCount: 0, totalWords: 0);
    }

    const header = '【记忆上下文 — AI 自动注入，用于保持故事一致性】';
    return BuildContextResult(
      text: '$header\n\n${parts.join('\n\n---\n\n')}',
      summaryCount: summaryCount,
      totalWords: totalWords,
    );
  }

  /// 构建精简版上下文（用于 token 受限场景）
  static BuildContextResult buildCompact({
    required List<SceneSummary> sceneSummaries,
    required List<ChapterSummary> chapterSummaries,
    VolumeSummary? volumeSummary,
    int maxTokens = 2000,
  }) {
    // 先构建完整版本，再截断
    final full = build(
      sceneSummaries: sceneSummaries,
      chapterSummaries: chapterSummaries,
      volumeSummary: volumeSummary,
    );

    if (full.totalWords <= maxTokens) return full;

    // 从最新的场景开始截断，保留章节摘要
    final parts = <String>[];
    int wordCount = 0;

    if (volumeSummary != null && volumeSummary.summary.isNotEmpty) {
      final text = '【卷摘要】\n${volumeSummary.summary}';
      parts.add(text);
      wordCount += volumeSummary.summary.length;
    }

    // 优先保留前章摘要
    for (final ch in chapterSummaries.reversed) {
      final text = '【前章回顾】\n${ch.summary}';
      if (wordCount + ch.summary.length > maxTokens) break;
      parts.add(text);
      wordCount += ch.summary.length;
    }

    // 按场景重要性加入
    for (final scene in sceneSummaries.reversed) {
      if (wordCount + scene.summary.length > maxTokens) break;
      parts.add('【前序场景】\n${scene.summary}');
      wordCount += scene.summary.length;
    }

    const header = '【记忆上下文 — 精简版】';
    return BuildContextResult(
      text: '$header\n\n${parts.join('\n\n---\n\n')}',
      summaryCount: parts.length,
      totalWords: wordCount,
    );
  }
}
