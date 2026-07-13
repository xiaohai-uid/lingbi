/// 质量审查报告模型(本地启发式)
library quality_report;

/// 单维度评分
class QualityDimension {
  const QualityDimension({
    required this.label,
    required this.score,
  });

  final String label;

  /// 0-10
  final double score;

  /// 进度条百分比(0-100)
  double get pct => (score * 10).clamp(0, 100);

  /// high / med / low
  String get level {
    if (score >= 7) return 'high';
    if (score >= 4) return 'med';
    return 'low';
  }

  String get display => '${score.toStringAsFixed(1)}/10';
}

/// 质量审查报告
class QualityReport {
  const QualityReport({
    required this.dimensions,
    this.suggestions = const [],
  });

  final List<QualityDimension> dimensions;
  final List<String> suggestions;

  /// 按 label 取维度
  QualityDimension? byLabel(String label) {
    try {
      return dimensions.firstWhere((d) => d.label == label);
    } catch (_) {
      return null;
    }
  }
}
