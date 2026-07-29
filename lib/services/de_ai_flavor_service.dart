/// 去AI味引擎
///
/// 检测生成文本中的 AI 写作痕迹并改写：
/// - 基于规则库（高频词/句式/结构模式）标记可疑段落
/// - 规则库可扩展（用户自定义 + 社区贡献）
/// - 分场景改写：调用 AI 对标记段落进行去AI味改写
/// - 批量去AI味：对整章/整文一键处理
library;

import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── 数据模型 ───

/// 检测规则类型
enum RuleType {
  word,
  phrase,
  pattern,
  structure;

  static RuleType fromString(String s) {
    return RuleType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RuleType.word,
    );
  }
}

/// 检测规则
class DetectionRule {
  const DetectionRule({
    required this.id,
    required this.type,
    required this.pattern,
    this.description = '',
    this.severity = 'medium',
    this.category = 'general',
  });

  factory DetectionRule.fromJson(Map<String, dynamic> json) {
    return DetectionRule(
      id: json['id'] as String? ?? '',
      type: RuleType.fromString(json['type'] as String? ?? 'word'),
      pattern: json['pattern'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'general',
    );
  }

  final String id;
  final RuleType type;

  /// 匹配模式（词/短语/正则）
  final String pattern;
  final String description;
  final String severity;
  final String category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'pattern': pattern,
        'description': description,
        'severity': severity,
        'category': category,
      };
}

/// 检测命中
class DetectionHit {
  const DetectionHit({
    required this.rule,
    required this.paragraphIndex,
    required this.matchedText,
    this.position = 0,
  });

  final DetectionRule rule;
  final int paragraphIndex;
  final String matchedText;
  final int position;
}

/// 检测结果
class DetectionResult {
  const DetectionResult({
    this.hits = const [],
    this.suspiciousParagraphs = const [],
    this.aiScore = 0,
  });

  final List<DetectionHit> hits;

  /// 可疑段落索引列表
  final List<int> suspiciousParagraphs;

  /// AI 味评分（0-100，越高越像 AI）
  final int aiScore;

  bool get hasIssues => hits.isNotEmpty;
}

/// 改写结果
class RewriteResult {
  const RewriteResult({
    required this.paragraphIndex,
    required this.original,
    required this.rewritten,
    this.reason = '',
  });

  final int paragraphIndex;
  final String original;
  final String rewritten;
  final String reason;
}

// ─── 服务 ───

/// 去AI味引擎服务
class DeAiFlavorService {
  DeAiFlavorService({
    required AIProvider aiProvider,
    List<DetectionRule>? customRules,
  })  : _aiProvider = aiProvider,
        _rules = [..._builtinRules, ...?customRules];

  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;
  final List<DetectionRule> _rules;

  // ─── 1. 规则管理 ───

  /// 获取所有规则
  List<DetectionRule> get rules => List.unmodifiable(_rules);

  /// 添加自定义规则
  void addRule(DetectionRule rule) {
    _rules.add(rule);
  }

  /// 移除规则
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
  }

  // ─── 2. 检测 ───

  /// 检测文本中的 AI 痕迹
  DetectionResult detect(String text) {
    final paragraphs =
        text.split('\n').where((p) => p.trim().isNotEmpty).toList();
    final hits = <DetectionHit>[];
    final suspiciousSet = <int>{};

    for (var i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      for (final rule in _rules) {
        final matches = _matchRule(rule, para);
        for (final match in matches) {
          hits.add(DetectionHit(
            rule: rule,
            paragraphIndex: i,
            matchedText: match,
            position: para.indexOf(match),
          ));
          suspiciousSet.add(i);
        }
      }
    }

    // 计算 AI 味评分
    final aiScore = _calculateAiScore(paragraphs.length, hits.length);

    return DetectionResult(
      hits: hits,
      suspiciousParagraphs: suspiciousSet.toList()..sort(),
      aiScore: aiScore,
    );
  }

  // ─── 3. 改写 ───

  /// 对单个段落进行去AI味改写
  Future<RewriteResult> rewriteParagraph({
    required int paragraphIndex,
    required String original,
    String context = '',
  }) async {
    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system',
              content: '你是文学编辑，擅长消除AI写作痕迹。改写时保持原意，'
                  '去除套话和模板化表达，使文本更自然、更有个人风格。'
                  '只输出改写后的文本，不要解释。'),
          ChatMessage(role: 'user', content: '请改写以下段落，去除AI味：\n\n$original'),
        ],
      );
      return RewriteResult(
        paragraphIndex: paragraphIndex,
        original: original,
        rewritten: result.trim(),
        reason: '去AI味改写',
      );
    } catch (e) {
      return RewriteResult(
        paragraphIndex: paragraphIndex,
        original: original,
        rewritten: original,
        reason: '改写失败: $e',
      );
    }
  }

  /// 批量去AI味：对整章可疑段落进行改写
  Future<List<RewriteResult>> rewriteChapter(String text) async {
    final detection = detect(text);
    if (!detection.hasIssues) return [];

    final paragraphs =
        text.split('\n').where((p) => p.trim().isNotEmpty).toList();
    final results = <RewriteResult>[];

    for (final idx in detection.suspiciousParagraphs) {
      if (idx >= paragraphs.length) continue;
      final result = await rewriteParagraph(
        paragraphIndex: idx,
        original: paragraphs[idx],
      );
      results.add(result);
    }

    return results;
  }

  /// 应用改写结果到原文
  String applyRewrites(String text, List<RewriteResult> rewrites) {
    final paragraphs = text.split('\n');
    var paraIdx = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      if (paragraphs[i].trim().isEmpty) continue;
      final rewrite = rewrites.where((r) => r.paragraphIndex == paraIdx);
      if (rewrite.isNotEmpty) {
        paragraphs[i] = rewrite.first.rewritten;
      }
      paraIdx++;
    }

    return paragraphs.join('\n');
  }

  // ─── 辅助方法 ───

  List<String> _matchRule(DetectionRule rule, String text) {
    final matches = <String>[];
    switch (rule.type) {
      case RuleType.word:
      case RuleType.phrase:
        if (text.contains(rule.pattern)) {
          matches.add(rule.pattern);
        }
      case RuleType.pattern:
      case RuleType.structure:
        try {
          final regex = RegExp(rule.pattern);
          for (final m in regex.allMatches(text)) {
            matches.add(m.group(0) ?? '');
          }
        } catch (_) {}
    }
    return matches;
  }

  int _calculateAiScore(int totalParagraphs, int hitCount) {
    if (totalParagraphs == 0) return 0;
    // 基于命中密度计算
    final density = hitCount / totalParagraphs;
    final score = (density * 30).round();
    return score > 100 ? 100 : score;
  }

  /// 内置规则库
  static const _builtinRules = [
    DetectionRule(
      id: 'w_001',
      type: RuleType.phrase,
      pattern: '值得注意的是',
      description: 'AI高频过渡语',
      severity: 'high',
      category: 'transition',
    ),
    DetectionRule(
      id: 'w_002',
      type: RuleType.word,
      pattern: '不禁',
      description: 'AI高频情感词',
      category: 'emotion',
    ),
    DetectionRule(
      id: 'w_003',
      type: RuleType.word,
      pattern: '缓缓',
      description: 'AI高频动作修饰',
      severity: 'low',
      category: 'action',
    ),
    DetectionRule(
      id: 'w_004',
      type: RuleType.phrase,
      pattern: '在这一刻',
      description: 'AI时间过渡套话',
      category: 'transition',
    ),
    DetectionRule(
      id: 'w_005',
      type: RuleType.phrase,
      pattern: '仿佛一切都',
      description: 'AI总结性套话',
      category: 'summary',
    ),
    DetectionRule(
      id: 'w_006',
      type: RuleType.word,
      pattern: '宛如',
      description: 'AI高频比喻词',
      severity: 'low',
      category: 'rhetoric',
    ),
    DetectionRule(
      id: 'w_007',
      type: RuleType.phrase,
      pattern: '与此同时',
      description: 'AI并列过渡',
      severity: 'low',
      category: 'transition',
    ),
    DetectionRule(
      id: 'w_008',
      type: RuleType.phrase,
      pattern: '不由自主地',
      description: 'AI情感表达套话',
      category: 'emotion',
    ),
    DetectionRule(
      id: 'p_001',
      type: RuleType.pattern,
      pattern: '他[的]?眼[中神].*?[闪掠]过',
      description: 'AI眼神描写模板',
      category: 'description',
    ),
    DetectionRule(
      id: 'p_002',
      type: RuleType.pattern,
      pattern: '嘴角.*?[勾扬浮]起.*?[弧笑]',
      description: 'AI微笑描写模板',
      category: 'description',
    ),
  ];
}
