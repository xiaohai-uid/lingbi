/// 质量审查管线 — 从 AI_NovelGenerator 移植
///
/// 模块：
/// - CharacterConsistency: 角色一致性检测
/// - HookDensity: 爽点密度分析
/// - FormatReview: 格式审查
/// - ReviewPipeline: 综合审查编排
library review_pipeline;

import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../../core/ai/retry_handler.dart';
import '../prompt_service.dart';

// ═══════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════

/// 角色一致性问题
class ConsistencyIssue {
  // 1-10

  const ConsistencyIssue({
    required this.type,
    required this.description,
    required this.currentBehavior,
    required this.conflictingHistory,
    this.severity = 5,
  });
  final String type; // personality, motivation, dialogue_style, emotion
  final String description;
  final String currentBehavior;
  final String conflictingHistory;
  final int severity;
}

/// 角色一致性结果
class CharacterConsistencyResult {
  const CharacterConsistencyResult({
    this.isConsistent = true,
    this.deviationScore = 0,
    this.reason = '',
    this.issues = const [],
  });

  factory CharacterConsistencyResult.fromJson(Map<String, dynamic> json) =>
      CharacterConsistencyResult(
        isConsistent: json['isConsistent'] as bool? ?? true,
        deviationScore: json['deviationScore'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        issues: (json['issues'] as List?)
                ?.map((i) => ConsistencyIssue(
                      type: i['type'] as String? ?? 'unknown',
                      description: i['description'] as String? ?? '',
                      currentBehavior: i['currentBehavior'] as String? ?? '',
                      conflictingHistory:
                          i['conflictingHistory'] as String? ?? '',
                      severity: i['severity'] as int? ?? 5,
                    ))
                .toList() ??
            [],
      );
  final bool isConsistent;
  final int deviationScore; // 0=完全一致, 100=完全偏离
  final String reason;
  final List<ConsistencyIssue> issues;
}

/// 爽点事件
class HookEvent {
  // 1-10

  const HookEvent(
      {required this.type, required this.description, this.intensity = 5});
  final String type; // 打脸、反转、升级、获得、装逼、复仇、保护、揭秘
  final String description;
  final int intensity;
}

/// 爽点密度结果
class HookDensityResult {
  const HookDensityResult({
    this.hookEvents = const [],
    this.density = 0,
    this.wordCount = 0,
    this.meetsRequirement = false,
  });
  final List<HookEvent> hookEvents;
  final double density; // 点数/1000字
  final int wordCount;
  final bool meetsRequirement;
}

/// 格式问题
class FormatIssue {
  const FormatIssue(
      {required this.type, required this.description, this.lineNumber});
  final String type; // long_paragraph, no_dialogue, prohibited_content
  final String description;
  final int? lineNumber;
}

/// 格式审查结果
class FormatReviewResult {
  const FormatReviewResult({
    this.isValid = true,
    this.issues = const [],
    this.hasProhibitedContent = false,
  });
  final bool isValid;
  final List<FormatIssue> issues;
  final bool hasProhibitedContent;
}

/// 综合审查报告
class ReviewReport {
  const ReviewReport({
    this.overallScore = 5.0,
    this.consistency,
    this.hookDensity,
    this.format,
    this.needsRewrite = false,
    this.rewriteReason = '',
    this.suggestions = const [],
  });
  final double overallScore; // 0-10
  final CharacterConsistencyResult? consistency;
  final HookDensityResult? hookDensity;
  final FormatReviewResult? format;
  final bool needsRewrite;
  final String rewriteReason;
  final List<String> suggestions;
}

// ═══════════════════════════════════════════════
// 审查模块
// ═══════════════════════════════════════════════

/// 角色一致性检测
class CharacterConsistency {
  CharacterConsistency({
    PromptService? promptService,
    RetryHandler? retryHandler,
    String? providerName,
  })  : _promptService = promptService,
        _retryHandler = retryHandler {
    if (providerName != null) _providerName = providerName;
  }
  final PromptService? _promptService;
  final RetryHandler? _retryHandler;
  String _providerName = 'free';

  /// 设置使用的 LLM Provider 名称
  set providerName(String name) => _providerName = name;

  /// 使用 LLM 检测角色一致性
  Future<CharacterConsistencyResult> checkWithLLM(
    String text,
    Map<String, String> profiles,
  ) async {
    if (profiles.isEmpty || _promptService == null) {
      return check(text, profiles);
    }

    final prompt = _promptService.renderPrompt('character_check', {
      'text': text,
      'profiles':
          profiles.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.3,
      maxTokens: 1024,
    );

    final handler = _retryHandler ?? const RetryHandler();
    return handler.execute(() => LLMFactory.create(_providerName)
            .generateStructured<CharacterConsistencyResult>(
          request,
          CharacterConsistencyResult.fromJson,
        ));
  }

  /// 检查文本中的角色行为是否与人设一致（静态规则版）
  static CharacterConsistencyResult check(
    String text,
    Map<String, String> profiles,
  ) {
    if (profiles.isEmpty) {
      return const CharacterConsistencyResult();
    }

    final issues = <ConsistencyIssue>[];

    for (final entry in profiles.entries) {
      if (!text.contains(entry.key)) continue;

      final profile = entry.value;

      // 检查性格冲突
      if (_hasPersonalityConflict(text, entry.key, profile)) {
        issues.add(ConsistencyIssue(
          type: 'personality',
          description: '${entry.key}的行为与"$profile"的性格设定矛盾',
          currentBehavior: _extractBehavior(text, entry.key),
          conflictingHistory: profile,
          severity: 8,
        ));
      }
    }

    if (issues.isEmpty) {
      return CharacterConsistencyResult(
        deviationScore: _calculateScore(text, profiles),
      );
    }

    return CharacterConsistencyResult(
      isConsistent: false,
      deviationScore: issues.fold(0, (s, i) => s + i.severity * 10),
      reason: issues.map((i) => i.description).join('；'),
      issues: issues,
    );
  }

  static bool _hasPersonalityConflict(
      String text, String name, String profile) {
    // 简单规则：如果角色被描述为"坚毅"，但文本中有"颤抖/哭泣/害怕"等词
    if (profile.contains('坚毅') || profile.contains('果断')) {
      return _hasNegativeEmotionWords(text);
    }
    return false;
  }

  static bool _hasNegativeEmotionWords(String text) {
    const words = ['颤抖', '发抖', '哭泣', '流泪', '害怕', '恐惧', '退缩', '慌张', '怯懦', '胆怯', '懦弱', '软弱', '惊恐'];
    return words.any((w) => text.contains(w));
  }

  static int _calculateScore(String text, Map<String, String> profiles) {
    var score = 0;
    for (final entry in profiles.entries) {
      if (text.contains(entry.key)) score += 10;
    }
    return score.clamp(0, 100);
  }

  static String _extractBehavior(String text, String name) {
    final idx = text.indexOf(name);
    if (idx == -1) return '';
    final start = (idx - 20).clamp(0, text.length);
    final end = (idx + 30).clamp(0, text.length);
    return text.substring(start, end);
  }
}

/// 爽点密度分析
class HookDensity {
  static const _hookPatterns = [
    '突然',
    '猛然',
    '竟然',
    '原来',
    '冷笑',
    '震惊',
    '暴怒',
    '出手',
    '轰杀',
    '秒杀',
    '碾压',
    '逆袭',
    '爆发',
    '不可能',
    '怎么会',
    '惊呆了',
    '恐怖如斯',
  ];

  /// 平台爽点密度要求（点数/1000字）
  static const _platformRequirements = {
    'qidian': 0.5, // 起点
    'fanqie': 2.0, // 番茄
  };

  /// 计算爽点密度
  static HookDensityResult calculate(String text,
      {String platform = 'qidian'}) {
    if (text.isEmpty) return const HookDensityResult();

    final events = <HookEvent>[];
    for (final pattern in _hookPatterns) {
      final matches = _allMatches(text, pattern);
      for (final _ in matches) {
        events.add(HookEvent(
          type: _categorizeHook(pattern),
          description: pattern,
        ));
      }
    }

    final wordCount = text.length;
    final density = wordCount > 0 ? (events.length / wordCount) * 1000 : 0.0;
    final requirement = _platformRequirements[platform] ?? 0.5;

    return HookDensityResult(
      hookEvents: events,
      density: double.parse(density.toStringAsFixed(2)),
      wordCount: wordCount,
      meetsRequirement: density >= requirement,
    );
  }

  static List<int> _allMatches(String text, String pattern) {
    final matches = <int>[];
    var start = 0;
    while (true) {
      final idx = text.indexOf(pattern, start);
      if (idx == -1) break;
      matches.add(idx);
      start = idx + 1;
    }
    return matches;
  }

  static String _categorizeHook(String word) {
    if (['突然', '猛然'].contains(word)) return '反转';
    if (['出手', '轰杀', '秒杀', '碾压'].contains(word)) return '打脸';
    if (['不可能', '怎么会', '惊呆了', '恐怖如斯'].contains(word)) return '震惊';
    if (['冷笑', '暴怒'].contains(word)) return '装逼';
    if (['竟然', '原来', '爆发'].contains(word)) return '揭秘';
    return '其他';
  }
}

/// 格式审查
class FormatReview {
  static int _allMatches(String text, String pattern) {
    var count = 0;
    var offset = 0;
    while (true) {
      final index = text.indexOf(pattern, offset);
      if (index == -1) break;
      count++;
      offset = index + pattern.length;
    }
    return count;
  }

  /// 检查文本格式
  static FormatReviewResult check(String text) {
    final issues = <FormatIssue>[];

    // 1. 检查段落长度
    final paragraphs = text.split('\n\n');
    for (var i = 0; i < paragraphs.length; i++) {
      if (paragraphs[i].length > 500) {
        issues.add(FormatIssue(
          type: 'long_paragraph',
          description: '第 ${i + 1} 段过长（${paragraphs[i].length} 字），建议不超过 500 字',
          lineNumber: i + 1,
        ));
      }
    }

    // 2. 检查禁止内容
    final hasProhibited = _hasProhibitedContent(text);

    // 3. 检查对话比例
    final dialogueLines = _allMatches(text, '"') ~/ 2;
    final dialogueRatio =
        text.isNotEmpty ? dialogueLines / (text.length / 100) : 0;

    if (dialogueRatio < 1) {
      issues.add(const FormatIssue(
        type: 'no_dialogue',
        description: '对话比例偏低，建议增加对话丰富节奏',
      ));
    }

    return FormatReviewResult(
      isValid: issues.isEmpty,
      issues: issues,
      hasProhibitedContent: hasProhibited,
    );
  }

  static bool _hasProhibitedContent(String text) {
    const patterns = [
      '```json',
      '```yaml',
      '```xml',
      '未完待续',
      '后续可扩展',
      '以下是结果',
      '故事梗概如下',
      '分析如下',
    ];
    return patterns.any((p) => text.contains(p));
  }
}

/// 审查管线编排器
class ReviewPipeline {
  /// 执行综合审查
  static Future<ReviewReport> review(
    String text, {
    Map<String, String> characterProfiles = const {},
    String platform = 'qidian',
  }) async {
    // 并行执行三个审查模块
    final results = await Future.wait([
      Future(() => CharacterConsistency.check(text, characterProfiles)),
      Future(() => HookDensity.calculate(text, platform: platform)),
      Future(() => FormatReview.check(text)),
    ]);

    final consistency = results[0] as CharacterConsistencyResult;
    final hookDensity = results[1] as HookDensityResult;
    final format = results[2] as FormatReviewResult;

    // 综合评分
    var score = 7.0; // 基础分
    score -= consistency.deviationScore / 20; // 一致性扣分
    if (!hookDensity.meetsRequirement) score -= 1.5; // 爽点扣分
    if (!format.isValid) score -= 1.0; // 格式扣分

    // 重复内容扣分
    final uniqueChars = text.split('').toSet().length;
    if (text.isNotEmpty && uniqueChars / text.length < 0.3) score -= 1.5;

    score = score.clamp(0, 10);

    // 重写决策
    final needsRewrite = score < 4.0 || !consistency.isConsistent;
    final suggestions = <String>[];

    if (!consistency.isConsistent) {
      suggestions.add('角色行为与人设不符：${consistency.reason}');
    }
    if (!hookDensity.meetsRequirement) {
      suggestions.add('爽点密度不足（当前 ${hookDensity.density}/1000字，'
          '${platform == 'fanqie' ? '番茄要求 2.0' : '起点要求 0.5'}），建议增加冲突和反转');
    }
    if (!format.isValid) {
      for (final issue in format.issues) {
        suggestions.add(issue.description);
      }
    }

    return ReviewReport(
      overallScore: double.parse(score.toStringAsFixed(1)),
      consistency: consistency,
      hookDensity: hookDensity,
      format: format,
      needsRewrite: needsRewrite,
      rewriteReason: needsRewrite
          ? '综合评分 $score/10，${suggestions.isNotEmpty ? suggestions.first : '需要改进'}'
          : '',
      suggestions: suggestions,
    );
  }
}
