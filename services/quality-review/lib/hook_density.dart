/// 爽点密度分析模块
library hook_density;

import 'dart:convert';
import 'package:lingbi_quality_review/models/review_models.dart';
import 'llm_client.dart';

/// 分析文本中的爽点密度
class HookDensity {
  final LLMClient? llmClient;

  // 爽点关键词模式
  static const _hookPatterns = {
    '打脸': ['打脸', '震惊', '难以置信', '目瞪口呆'],
    '反转': ['竟然', '原来', '真相是', '出乎意料'],
    '升级': ['突破', '晋级', '领悟', '觉醒'],
    '获得': ['获得', '得到', '捡到', '传承'],
    '装逼': ['淡然', '不屑', '随手', '轻易'],
  };

  HookDensity({this.llmClient});

  /// 执行爽点分析（规则引擎 + LLM 增强）
  Future<ReviewModuleResult> analyze(String text,
      {double targetDensity = 2.0}) async {
    final events = <HookEvent>[];
    final issues = <Issue>[];

    // 1. 规则引擎：关键词匹配
    for (final entry in _hookPatterns.entries) {
      for (final keyword in entry.value) {
        int start = 0;
        while (true) {
          final index = text.indexOf(keyword, start);
          if (index == -1) break;
          events.add(HookEvent(
            type: entry.key,
            description: '检测到"$keyword"(${entry.key})',
            intensity: _calcIntensity(entry.key),
          ));
          start = index + 1;
        }
      }
    }

    // 2. 规则引擎评分
    final wordCount = text.length;
    final ruleDensity =
        wordCount > 0 ? (events.length / wordCount * 1000) : 0.0;

    if (ruleDensity < targetDensity * 0.5) {
      issues.add(Issue(
        type: 'low_hook_density',
        description:
            '爽点密度过低: ${ruleDensity.toStringAsFixed(1)}点/千字，目标 $targetDensity',
        severity: 7,
        suggestion: '建议增加冲突反转、打脸、升级等爽点情节',
      ));
    }

    // 3. LLM 增强分析
    if (llmClient != null) {
      try {
        final llmResult = await _llmAnalyze(text, events);
        issues.addAll(llmResult['issues'] as List<Issue>);
        events.addAll(llmResult['events'] as List<HookEvent>);
      } catch (e) {
        // LLM 调用失败，降级到规则引擎结果
      }
    }

    final density = wordCount > 0 ? (events.length / wordCount * 1000) : 0.0;
    final score = (density / targetDensity * 10).clamp(0, 10);

    return ReviewModuleResult(
      name: '爽点密度',
      score: double.parse(score.toStringAsFixed(1)),
      issues: issues,
    );
  }

  /// 调用 LLM 进行爽点密度深度分析
  Future<Map<String, List<dynamic>>> _llmAnalyze(
      String text, List<HookEvent> existingEvents) async {
    final prompt = '''你是一位专业的小说编辑。请分析以下文本的爽点密度。

## 爽点类型
- 打脸：主角或盟友反击，反派受挫
- 反转：情节转折，出乎意料
- 升级：主角实力提升
- 获得：主角获得宝物/技能/信息
- 装逼：主角低调行事却令人震惊

## 待分析文本
$text

## 输出要求
请严格按以下 JSON 格式输出：
{
  "events": [
    {"type": "打脸", "description": "...", "intensity": 7}
  ],
  "issues": [
    {
      "type": "low_hook_density|missing_hook_type",
      "description": "...",
      "severity": 5,
      "suggestion": "..."
    }
  ]
}

只输出 JSON，不要包含其他内容。''';

    final content = await llmClient!.chat(
      messages: [
        {'role': 'system', 'content': prompt}
      ],
      temperature: 0.5,
      maxTokens: 1024,
    );

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (jsonMatch == null)
      return {'events': <HookEvent>[], 'issues': <Issue>[]};

    final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    final eventsJson = result['events'] as List? ?? [];
    final issuesJson = result['issues'] as List? ?? [];

    final events = eventsJson
        .map((e) => HookEvent(
              type: e['type'] as String? ?? '打脸',
              description: e['description'] as String? ?? '',
              intensity: e['intensity'] as int? ?? 5,
            ))
        .toList();

    final issues = issuesJson
        .map((i) => Issue(
              type: i['type'] as String? ?? 'low_hook_density',
              description: i['description'] as String? ?? '',
              severity: i['severity'] as int? ?? 5,
              suggestion: i['suggestion'] as String?,
            ))
        .toList();

    return {'events': events, 'issues': issues};
  }

  int _calcIntensity(String type) {
    switch (type) {
      case '反转':
        return 8;
      case '打脸':
        return 7;
      case '升级':
        return 6;
      case '获得':
        return 5;
      case '装逼':
        return 4;
      default:
        return 5;
    }
  }
}
