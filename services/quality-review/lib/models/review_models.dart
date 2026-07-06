/// 质量审查 — 共享数据模型
library review_models;

/// 审查请求
class ReviewRequest {
  final String text;
  final String genre;
  final List<Map<String, dynamic>> characters;

  const ReviewRequest({
    required this.text,
    this.genre = 'fantasy',
    this.characters = const [],
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'genre': genre,
    'characters': characters,
  };

  factory ReviewRequest.fromJson(Map<String, dynamic> json) => ReviewRequest(
    text: json['text'] as String,
    genre: json['genre'] as String? ?? 'fantasy',
    characters: (json['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [],
  );
}

/// 审查报告
class ReviewReport {
  final double overallScore;     // 0-10
  final int wordCount;
  final List<ReviewModuleResult> modules;

  const ReviewReport({
    required this.overallScore,
    this.wordCount = 0,
    this.modules = const [],
  });

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'wordCount': wordCount,
    'modules': modules.map((m) => m.toJson()).toList(),
  };
}

/// 单个审查模块结果
class ReviewModuleResult {
  final String name;
  final double score;            // 0-10
  final List<Issue> issues;

  const ReviewModuleResult({
    required this.name,
    required this.score,
    this.issues = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'issues': issues.map((i) => i.toJson()).toList(),
  };
}

/// 问题项
class Issue {
  final String type;
  final String description;
  final int severity;    // 1-10
  final String? suggestion;

  const Issue({
    required this.type,
    required this.description,
    this.severity = 5,
    this.suggestion,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'severity': severity,
    if (suggestion != null) 'suggestion': suggestion,
  };
}

/// 角色一致性问题
class ConsistencyIssue extends Issue {
  final String currentBehavior;
  final String conflictingHistory;

  const ConsistencyIssue({
    required super.type,
    required super.description,
    required this.currentBehavior,
    required this.conflictingHistory,
    super.severity,
    super.suggestion,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'currentBehavior': currentBehavior,
    'conflictingHistory': conflictingHistory,
  };
}

/// 爽点事件
class HookEvent {
  final String type;     // face_slap / reversal / upgrade / acquire / etc.
  final String description;
  final int intensity;   // 1-10

  const HookEvent({
    required this.type,
    required this.description,
    this.intensity = 5,
  });
}