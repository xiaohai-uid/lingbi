/// 风格蒸馏引擎 — StyleProfile 数据模型
///
/// 从用户已有作品中提取文笔 DNA（句式/用词/节奏/修辞偏好），
/// 生成可复用的 StyleProfile。风格档案跨项目使用，结果可编辑微调。
library;

/// 风格档案 — 文笔 DNA 结构化描述
class StyleProfile {
  const StyleProfile({
    required this.id,
    required this.name,
    this.sentencePatterns = const [],
    this.vocabulary = const [],
    this.rhythm = const RhythmProfile(),
    this.rhetoricPreferences = const [],
    this.samples = const [],
    this.description = '',
    this.sourceWordCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory StyleProfile.fromJson(Map<String, dynamic> json) {
    return StyleProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sentencePatterns: (json['sentencePatterns'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      vocabulary: (json['vocabulary'] as List<dynamic>?)
              ?.map((e) => VocabularyTrait.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rhythm: json['rhythm'] != null
          ? RhythmProfile.fromJson(json['rhythm'] as Map<String, dynamic>)
          : const RhythmProfile(),
      rhetoricPreferences: (json['rhetoricPreferences'] as List<dynamic>?)
              ?.map((e) => RhetoricPreference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      samples: (json['samples'] as List<dynamic>?)
              ?.map((e) => StyleSample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      sourceWordCount: json['sourceWordCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 唯一标识
  final String id;

  /// 档案名称（如：金庸武侠风、轻松都市风）
  final String name;

  /// 句式特征（如：短句为主、长短交替、倒装句多）
  final List<String> sentencePatterns;

  /// 用词特征
  final List<VocabularyTrait> vocabulary;

  /// 节奏特征
  final RhythmProfile rhythm;

  /// 修辞偏好
  final List<RhetoricPreference> rhetoricPreferences;

  /// 代表性文段样本
  final List<StyleSample> samples;

  /// 风格描述（AI 生成的总结）
  final String description;

  /// 源文本字数
  final int sourceWordCount;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  StyleProfile copyWith({
    String? name,
    List<String>? sentencePatterns,
    List<VocabularyTrait>? vocabulary,
    RhythmProfile? rhythm,
    List<RhetoricPreference>? rhetoricPreferences,
    List<StyleSample>? samples,
    String? description,
    int? sourceWordCount,
    DateTime? updatedAt,
  }) {
    return StyleProfile(
      id: id,
      name: name ?? this.name,
      sentencePatterns: sentencePatterns ?? this.sentencePatterns,
      vocabulary: vocabulary ?? this.vocabulary,
      rhythm: rhythm ?? this.rhythm,
      rhetoricPreferences: rhetoricPreferences ?? this.rhetoricPreferences,
      samples: samples ?? this.samples,
      description: description ?? this.description,
      sourceWordCount: sourceWordCount ?? this.sourceWordCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 生成 prompt 约束文本（供 ContextAssembler 注入）
  String toPromptText({int maxChars = 500}) {
    final buffer = StringBuffer();
    buffer.writeln('【风格约束 — 续写必须遵守】');

    if (description.isNotEmpty) {
      buffer.writeln('风格总述: $description');
    }
    if (sentencePatterns.isNotEmpty) {
      buffer.writeln('句式: ${sentencePatterns.join("、")}');
    }
    if (vocabulary.isNotEmpty) {
      final words = vocabulary.take(10).map((v) => v.trait).join('、');
      buffer.writeln('用词: $words');
    }
    if (rhythm.avgSentenceLength > 0) {
      buffer.writeln(
          '节奏: 平均句长${rhythm.avgSentenceLength}字, '
          '段落长度${rhythm.paragraphLength}');
    }
    if (rhetoricPreferences.isNotEmpty) {
      final rhetorics =
          rhetoricPreferences.take(5).map((r) => r.name).join('、');
      buffer.writeln('修辞偏好: $rhetorics');
    }

    var text = buffer.toString();
    if (maxChars > 0 && text.length > maxChars) {
      text = '${text.substring(0, maxChars)}…';
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sentencePatterns': sentencePatterns,
        'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
        'rhythm': rhythm.toJson(),
        'rhetoricPreferences':
            rhetoricPreferences.map((r) => r.toJson()).toList(),
        'samples': samples.map((s) => s.toJson()).toList(),
        'description': description,
        'sourceWordCount': sourceWordCount,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

/// 用词特征
class VocabularyTrait {
  const VocabularyTrait({
    required this.trait,
    this.examples = const [],
    this.frequency = '',
  });

  factory VocabularyTrait.fromJson(Map<String, dynamic> json) {
    return VocabularyTrait(
      trait: json['trait'] as String? ?? '',
      examples:
          (json['examples'] as List<dynamic>?)?.cast<String>() ?? const [],
      frequency: json['frequency'] as String? ?? '',
    );
  }

  /// 特征描述（如：偏好古风用词、口语化表达）
  final String trait;

  /// 示例词汇
  final List<String> examples;

  /// 频率描述（如：高频、偶尔）
  final String frequency;

  Map<String, dynamic> toJson() => {
        'trait': trait,
        'examples': examples,
        'frequency': frequency,
      };
}

/// 节奏特征
class RhythmProfile {
  const RhythmProfile({
    this.avgSentenceLength = 0,
    this.paragraphLength = '',
    this.pacing = '',
    this.tensionCurve = '',
  });

  factory RhythmProfile.fromJson(Map<String, dynamic> json) {
    return RhythmProfile(
      avgSentenceLength: json['avgSentenceLength'] as int? ?? 0,
      paragraphLength: json['paragraphLength'] as String? ?? '',
      pacing: json['pacing'] as String? ?? '',
      tensionCurve: json['tensionCurve'] as String? ?? '',
    );
  }

  /// 平均句长（字数）
  final int avgSentenceLength;

  /// 段落长度特征（如：短段落、长段落、混合）
  final String paragraphLength;

  /// 节奏特征（如：紧凑、舒缓、张弛有度）
  final String pacing;

  /// 张力曲线（如：渐进式、波浪式、爆发式）
  final String tensionCurve;

  Map<String, dynamic> toJson() => {
        'avgSentenceLength': avgSentenceLength,
        'paragraphLength': paragraphLength,
        'pacing': pacing,
        'tensionCurve': tensionCurve,
      };
}

/// 修辞偏好
class RhetoricPreference {
  const RhetoricPreference({
    required this.name,
    this.frequency = '',
    this.example = '',
  });

  factory RhetoricPreference.fromJson(Map<String, dynamic> json) {
    return RhetoricPreference(
      name: json['name'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      example: json['example'] as String? ?? '',
    );
  }

  /// 修辞名称（如：比喻、排比、拟人、通感）
  final String name;

  /// 使用频率
  final String frequency;

  /// 示例
  final String example;

  Map<String, dynamic> toJson() => {
        'name': name,
        'frequency': frequency,
        'example': example,
      };
}

/// 代表性文段样本
class StyleSample {
  const StyleSample({
    required this.text,
    this.source = '',
    this.highlight = '',
  });

  factory StyleSample.fromJson(Map<String, dynamic> json) {
    return StyleSample(
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
      highlight: json['highlight'] as String? ?? '',
    );
  }

  /// 文段内容
  final String text;

  /// 来源（章节/作品名）
  final String source;

  /// 亮点说明（为何选此段作为代表）
  final String highlight;

  Map<String, dynamic> toJson() => {
        'text': text,
        'source': source,
        'highlight': highlight,
      };
}
