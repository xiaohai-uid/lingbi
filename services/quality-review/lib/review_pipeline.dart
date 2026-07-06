/// 质量审查编排器
library review_pipeline;

import 'package:lingbi_quality_review/models/review_models.dart';
import 'character_consistency.dart';
import 'hook_density.dart';
import 'format_review.dart';

/// 综合质量审查编排
class ReviewPipeline {
  final CharacterConsistency characterConsistency;
  final HookDensity hookDensity;
  final FormatReview formatReview;

  ReviewPipeline({
    CharacterConsistency? characterConsistency,
    HookDensity? hookDensity,
    FormatReview? formatReview,
  })  : characterConsistency = characterConsistency ?? CharacterConsistency(),
        hookDensity = hookDensity ?? HookDensity(),
        formatReview = formatReview ?? FormatReview();

  /// 执行全量审查
  Future<ReviewReport> analyze(String text) async {
    // 使用 pipeline 自身配置的三个审查模块
    final consistencyResult = await characterConsistency.analyze(text);
    final hookResult = await hookDensity.analyze(text);
    final formatResult = await formatReview.analyze(text);

    final modules = [consistencyResult, hookResult, formatResult];

    // 综合评分 (加权平均)
    final weights = <String, double>{'角色一致性': 0.4, '爽点密度': 0.35, '格式审查': 0.25};
    double totalWeight = 0;
    double weightedScore = 0;

    for (final module in modules) {
      final w = weights[module.name] ?? 0.33;
      weightedScore += module.score * w;
      totalWeight += w;
    }

    final overallScore = totalWeight > 0
        ? double.parse((weightedScore / totalWeight).toStringAsFixed(1))
        : 0.0;

    return ReviewReport(
      overallScore: overallScore,
      wordCount: text.length,
      modules: modules,
    );
  }
}
