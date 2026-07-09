/// ContextInjector — 分层 Prompt 组装
library context_injector;

import 'writing_context.dart';
import '../../data/database/world_database.dart';

/// 分层 Prompt 注入器
class ContextInjector {
  /// Token 预算上限
  static const int maxTokens = 1500;

  /// 组装写作 Prompt
  String buildWritingPrompt({
    required WritingContext context,
    String userInput = '',
  }) {
    final parts = <String>[];

    // Layer 0: 场景摘要（~200 tokens）
    parts.add(_buildSceneHeader(context));

    // Layer 1: 核心角色（~500 tokens）
    final topChars = context.topCharacters(5);
    parts.add(_buildCharacterSection(topChars, context.activeIdentities));

    // Layer 2: 世界观规则（~300 tokens）
    if (context.relevantRules.isNotEmpty) {
      parts.add(_buildRulesSection(context.relevantRules));
    }

    // Layer 3: 时间线上下文（~400 tokens）
    if (context.recentEvents.isNotEmpty) {
      parts.add(_buildTimelineSection(context.recentEvents));
    }

    // 用户输入
    if (userInput.isNotEmpty) {
      parts.add('\n## 用户指令\n$userInput');
    }

    return parts.join('\n\n');
  }

  String _buildSceneHeader(WritingContext context) {
    final buf = StringBuffer('## 当前场景\n');
    buf.writeln('卷: ${context.volumeTitle}');
    buf.writeln('章: ${context.chapterTitle}');
    buf.writeln('场景: ${context.scene.title}');

    if (context.location != null) {
      buf.writeln('地点: ${context.location!.name}');
      buf.writeln('地点描述: ${context.location!.description}');
    }

    return buf.toString();
  }

  String _buildCharacterSection(
    List<ScopedCharacter> characters,
    Map<String, List<Identity>> activeIdentities,
  ) {
    final buf = StringBuffer('## 出场角色\n');

    for (final sc in characters) {
      buf.writeln('---');
      buf.writeln('角色: ${sc.character.name}');
      buf.writeln('角色类型: ${sc.character.role}');
      buf.writeln('性格: ${sc.character.personality}');
      buf.writeln('权重: ${sc.effectiveWeight}');

      if (sc.primaryIdentity != null) {
        buf.writeln('当前身份: ${sc.primaryIdentity!.name}');
      }

      if (sc.character.backstory.isNotEmpty) {
        buf.writeln('背景: ${sc.character.backstory}');
      }
      if (sc.character.motivation.isNotEmpty) {
        buf.writeln('动机: ${sc.character.motivation}');
      }
    }

    return buf.toString();
  }

  String _buildRulesSection(List<WorldRule> rules) {
    final buf = StringBuffer('## 世界观规则\n');
    for (final rule in rules) {
      buf.writeln('- ${rule.name}: ${rule.description}');
    }
    return buf.toString();
  }

  String _buildTimelineSection(List<TimelineEvent> events) {
    final buf = StringBuffer('## 时间线上下文\n');
    for (final event in events.take(5)) {
      buf.writeln(
          '- ${event.title}${event.inStoryDate.isNotEmpty ? " (${event.inStoryDate})" : ""}');
      if (event.description.isNotEmpty) {
        buf.writeln('  ${event.description}');
      }
    }
    return buf.toString();
  }

  /// 预估 token 数（粗略估算：1 token ≈ 4 中文字符）
  int estimateTokens(String prompt) {
    return (prompt.length / 4).ceil();
  }
}

/// Token 计数器
class TokenCounter {
  /// 预估 token 数
  static int estimate(String text) {
    return (text.length / 4).ceil();
  }

  /// 计算费用
  static double estimateCost({
    required int tokens,
    required double pricePer1M, // 如 8.0 = ¥8/1M tokens
  }) {
    return tokens / 1000000 * pricePer1M;
  }

  /// 格式化费用显示
  static String formatCost(double cost) {
    if (cost < 0.01) return '¥${cost.toStringAsFixed(4)}';
    if (cost < 1) return '¥${cost.toStringAsFixed(3)}';
    return '¥${cost.toStringAsFixed(2)}';
  }
}
