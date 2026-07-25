/// StrandWeave 多线叙事节奏控制 — 数据模型
///
/// 用户设定主线/感情/世界观等叙事线的配比比例，
/// AI 生成时遵守配比约束并标注段落归属。
/// 支持红线约束（如连续 3 章不得无主线推进）。
library;

/// 单条叙事线定义
class Strand {
  const Strand({
    required this.name,
    required this.ratio,
    this.description = '',
    this.color = '',
  });

  factory Strand.fromJson(Map<String, dynamic> json) {
    return Strand(
      name: json['name'] as String? ?? '',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }

  /// 叙事线名称（如：主线、感情线、世界观线）
  final String name;

  /// 配比比例 (0.0 ~ 1.0)
  final double ratio;

  /// 描述
  final String description;

  /// 标注颜色（UI 用）
  final String color;

  Strand copyWith({
    String? name,
    double? ratio,
    String? description,
    String? color,
  }) {
    return Strand(
      name: name ?? this.name,
      ratio: ratio ?? this.ratio,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ratio': ratio,
        'description': description,
        'color': color,
      };
}

/// 红线约束 — 生成门禁规则
class RedLine {
  const RedLine({
    required this.id,
    required this.description,
    required this.strandName,
    this.maxConsecutiveAbsence = 3,
  });

  factory RedLine.fromJson(Map<String, dynamic> json) {
    return RedLine(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      strandName: json['strandName'] as String? ?? '',
      maxConsecutiveAbsence: json['maxConsecutiveAbsence'] as int? ?? 3,
    );
  }

  /// 唯一标识
  final String id;

  /// 约束描述（如：连续 3 章不得无主线推进）
  final String description;

  /// 关联的叙事线名称
  final String strandName;

  /// 最大连续缺席章节数
  final int maxConsecutiveAbsence;

  RedLine copyWith({
    String? description,
    String? strandName,
    int? maxConsecutiveAbsence,
  }) {
    return RedLine(
      id: id,
      description: description ?? this.description,
      strandName: strandName ?? this.strandName,
      maxConsecutiveAbsence:
          maxConsecutiveAbsence ?? this.maxConsecutiveAbsence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'strandName': strandName,
        'maxConsecutiveAbsence': maxConsecutiveAbsence,
      };
}

/// StrandWeave 配置 — 项目级多线叙事节奏控制
class StrandWeaveConfig {
  const StrandWeaveConfig({
    this.strands = const [],
    this.redLines = const [],
    this.enabled = true,
  });

  factory StrandWeaveConfig.fromJson(Map<String, dynamic> json) {
    return StrandWeaveConfig(
      strands: (json['strands'] as List<dynamic>?)
              ?.map((e) => Strand.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      redLines: (json['redLines'] as List<dynamic>?)
              ?.map((e) => RedLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// 叙事线列表
  final List<Strand> strands;

  /// 红线约束列表
  final List<RedLine> redLines;

  /// 是否启用
  final bool enabled;

  /// 所有比例之和
  double get totalRatio =>
      strands.fold(0.0, (sum, s) => sum + s.ratio);

  /// 比例是否合法（总和约等于 1.0）
  bool get isRatioValid =>
      strands.isEmpty || (totalRatio - 1.0).abs() < 0.01;

  StrandWeaveConfig copyWith({
    List<Strand>? strands,
    List<RedLine>? redLines,
    bool? enabled,
  }) {
    return StrandWeaveConfig(
      strands: strands ?? this.strands,
      redLines: redLines ?? this.redLines,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'strands': strands.map((s) => s.toJson()).toList(),
        'redLines': redLines.map((r) => r.toJson()).toList(),
        'enabled': enabled,
      };
}

/// 段落叙事线标注
class StrandAnnotation {
  const StrandAnnotation({
    required this.paragraphIndex,
    required this.strandName,
    this.confidence = 1.0,
  });

  factory StrandAnnotation.fromJson(Map<String, dynamic> json) {
    return StrandAnnotation(
      paragraphIndex: json['paragraphIndex'] as int? ?? 0,
      strandName: json['strandName'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// 段落索引
  final int paragraphIndex;

  /// 所属叙事线名称
  final String strandName;

  /// 标注置信度 (0.0 ~ 1.0)
  final double confidence;

  Map<String, dynamic> toJson() => {
        'paragraphIndex': paragraphIndex,
        'strandName': strandName,
        'confidence': confidence,
      };
}

/// 章节叙事线分布记录
class StrandDistribution {
  const StrandDistribution({
    this.distribution = const {},
    this.annotations = const [],
    this.totalParagraphs = 0,
  });

  factory StrandDistribution.fromJson(Map<String, dynamic> json) {
    return StrandDistribution(
      distribution: (json['distribution'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map(
                  (e) => StrandAnnotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalParagraphs: json['totalParagraphs'] as int? ?? 0,
    );
  }

  /// 各叙事线占比 { strandName: actualRatio }
  final Map<String, double> distribution;

  /// 段落级标注
  final List<StrandAnnotation> annotations;

  /// 总段落数
  final int totalParagraphs;

  /// 是否为空
  bool get isEmpty => distribution.isEmpty && annotations.isEmpty;

  Map<String, dynamic> toJson() => {
        'distribution': distribution,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'totalParagraphs': totalParagraphs,
      };
}

/// 红线违反记录
class RedLineViolation {
  const RedLineViolation({
    required this.redLine,
    required this.consecutiveAbsence,
    required this.lastPresentChapter,
  });

  /// 违反的红线
  final RedLine redLine;

  /// 连续缺席章节数
  final int consecutiveAbsence;

  /// 最后一次出现的章节
  final String lastPresentChapter;

  /// 违反描述
  String get message =>
      '「${redLine.strandName}」已连续 $consecutiveAbsence 章未推进'
      '（上限 ${redLine.maxConsecutiveAbsence} 章）。'
      '最后出现于：$lastPresentChapter';
}
