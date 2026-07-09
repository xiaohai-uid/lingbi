/// 格式审查模块
library format_review;

import 'dart:convert';
import 'package:lingbi_quality_review/models/review_models.dart';
import 'llm_client.dart';

/// 分析文本格式质量
class FormatReview {
  final LLMClient? llmClient;

  FormatReview({this.llmClient});

  /// 执行格式审查（规则引擎 + LLM 增强）
  Future<ReviewModuleResult> analyze(String text) async {
    final issues = <Issue>[];
    final wordCount = text.length;

    // 1. 规则引擎检查
    final lines = text.split('\n');

    // 段落长度检查
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.length > 500) {
        issues.add(Issue(
          type: 'long_paragraph',
          description: '第${i + 1}段过长(${line.length}字)，建议分段',
          severity: 5,
          suggestion: '将长段落拆分为2-3个短段，每段不超过200字',
        ));
      }
    }

    // 对话比例分析
    final dialogueChars = text
        .split('')
        .where((c) => c == '"' || c == '"' || c == '「' || c == '」')
        .length;
    final dialogueRatio = wordCount > 0 ? dialogueChars / wordCount : 0.0;

    if (dialogueRatio > 0.5) {
      issues.add(Issue(
        type: 'high_dialogue_ratio',
        description: '对话占比过高(${(dialogueRatio * 100).toStringAsFixed(0)}%)',
        severity: 4,
        suggestion: '适当增加叙述和描写的比例',
      ));
    }

    // 标点检查
    if (!text.contains('。') && wordCount > 100) {
      issues.add(Issue(
        type: 'missing_period',
        description: '缺少句号，建议使用句号结束陈述句',
        severity: 3,
        suggestion: '在陈述句末尾添加句号',
      ));
    }

    // 2. LLM 增强分析
    if (llmClient != null && wordCount > 50) {
      try {
        final llmIssues = await _llmAnalyze(text);
        issues.addAll(llmIssues);
      } catch (e) {
        // LLM 调用失败，降级到规则引擎结果
      }
    }

    final score = issues.isEmpty
        ? 10.0
        : (10.0 - issues.fold(0, (int s, i) => s + i.severity) / 10.0)
            .clamp(0, 10);

    return ReviewModuleResult(
      name: '格式审查',
      score: double.parse(score.toStringAsFixed(1)),
      issues: issues,
    );
  }

  /// 调用 LLM 进行格式深度分析
  Future<List<Issue>> _llmAnalyze(String text) async {
    final prompt = '''你是一位专业的小说编辑。请分析以下文本的格式质量。

## 检查项
1. 段落结构：每段是否太长（建议不超过300字）
2. 对话格式：对话是否清晰可辨
3. 标点使用：标点是否规范
4. 节奏感：叙述节奏是否合理

## 待分析文本
$text

## 输出要求
请严格按以下 JSON 格式输出：
{
  "issues": [
    {
      "type": "long_paragraph|dialogue_format|punctuation|pacing",
      "description": "问题描述",
      "severity": 1-10,
      "suggestion": "改进建议"
    }
  ]
}

如果没有格式问题，返回 {"issues": []}。
只输出 JSON，不要包含其他内容。''';

    final content = await llmClient!.chat(
      messages: [
        {'role': 'system', 'content': prompt}
      ],
      temperature: 0.3,
      maxTokens: 1024,
    );

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (jsonMatch == null) return [];

    final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    final issuesJson = result['issues'] as List? ?? [];

    return issuesJson
        .map((i) => Issue(
              type: i['type'] as String? ?? 'format',
              description: i['description'] as String? ?? '',
              severity: i['severity'] as int? ?? 5,
              suggestion: i['suggestion'] as String?,
            ))
        .toList();
  }
}
