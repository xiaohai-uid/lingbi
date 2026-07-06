/// 角色一致性检测模块
library character_consistency;

import 'dart:convert';
import 'package:lingbi_quality_review/models/review_models.dart';
import 'llm_client.dart';

/// 检测文本中的角色行为是否与设定一致
class CharacterConsistency {
  final List<Map<String, dynamic>> characterProfiles;
  final LLMClient? llmClient;

  const CharacterConsistency({
    this.characterProfiles = const [],
    this.llmClient,
  });

  /// 执行一致性检测（规则引擎 + LLM 兜底）
  Future<ReviewModuleResult> analyze(String text) async {
    final issues = <ConsistencyIssue>[];

    // 1. 先尝试规则引擎
    for (final profile in characterProfiles) {
      final name = profile['name'] as String? ?? '';
      if (name.isEmpty) continue;

      if (text.contains(name) && text.contains('愤怒')) {
        final personality = profile['personality'] as String? ?? '';
        if (personality.contains('温柔') || personality.contains('冷静')) {
          issues.add(ConsistencyIssue(
            type: 'personality',
            description: '角色"$name"性格设定为"$personality"，但当前行为表现出愤怒',
            currentBehavior: '表现出愤怒情绪',
            conflictingHistory: '性格设定为"$personality"',
            severity: 6,
          ));
        }
      }
    }

    // 2. 规则引擎未发现明显问题且配置了 LLM，调用 LLM 做深度分析
    if (issues.isEmpty && llmClient != null && characterProfiles.isNotEmpty) {
      try {
        final llmIssues = await _llmAnalyze(text, characterProfiles);
        issues.addAll(llmIssues);
      } catch (e) {
        // LLM 调用失败，静默降级到规则引擎结果
      }
    }

    final score = issues.isEmpty
        ? 10.0
        : (10.0 - issues.fold(0, (int sum, i) => sum + i.severity) / 10.0)
            .clamp(0, 10);

    return ReviewModuleResult(
      name: '角色一致性',
      score: double.parse(score.toStringAsFixed(1)),
      issues: issues,
    );
  }

  /// 调用 LLM 进行角色一致性深度分析
  Future<List<ConsistencyIssue>> _llmAnalyze(
    String text,
    List<Map<String, dynamic>> profiles,
  ) async {
    final profileText = profiles.map((p) {
      final name = p['name'] ?? '';
      final personality = p['personality'] ?? '';
      final backstory = p['backstory'] ?? '';
      return '- $name: 性格$personality，背景$backstory';
    }).join('\n');

    final prompt = '''你是一位专业的小说编辑。请分析以下文本中角色行为是否与设定一致。

## 角色设定
$profileText

## 待分析文本
$text

## 输出要求
请严格按以下 JSON 格式输出：
{
  "issues": [
    {
      "type": "personality|dialogue|behavior|background",
      "description": "问题描述",
      "currentBehavior": "当前行为",
      "conflictingHistory": "冲突的设定",
      "severity": 1-10
    }
  ]
}

如果角色行为一致，返回 {"issues": []}。
只输出 JSON，不要包含其他内容。''';

    final content = await llmClient!.chat(
      messages: [{'role': 'system', 'content': prompt}],
      temperature: 0.3,
      maxTokens: 1024,
    );

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (jsonMatch == null) return [];

    final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    final issuesJson = result['issues'] as List? ?? [];

    return issuesJson.map((issue) => ConsistencyIssue(
      type: issue['type'] as String? ?? 'personality',
      description: issue['description'] as String? ?? '',
      currentBehavior: issue['currentBehavior'] as String? ?? '',
      conflictingHistory: issue['conflictingHistory'] as String? ?? '',
      severity: issue['severity'] as int? ?? 5,
    )).toList();
  }
}
