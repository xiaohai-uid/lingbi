/// 生成参数模型
library;

class GenerationParams {
  final double temperature;
  final int maxTokens;
  final double topP;
  final double repetitionPenalty;

  const GenerationParams({
    this.temperature = 0.8,
    this.maxTokens = 4096,
    this.topP = 0.9,
    this.repetitionPenalty = 1.1,
  });

  GenerationParams copyWith({
    double? temperature,
    int? maxTokens,
    double? topP,
    double? repetitionPenalty,
  }) =>
      GenerationParams(
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        topP: topP ?? this.topP,
        repetitionPenalty: repetitionPenalty ?? this.repetitionPenalty,
      );

  String? get validationError {
    if (temperature < 0.0 || temperature > 2.0) return '温度范围 0.0 ~ 2.0';
    if (maxTokens < 100 || maxTokens > 32000) return '长度范围 100 ~ 32000';
    if (topP < 0.0 || topP > 1.0) return 'Top-P 范围 0.0 ~ 1.0';
    if (repetitionPenalty < 0.0 || repetitionPenalty > 2.0) return '重复惩罚范围 0.0 ~ 2.0';
    return null;
  }
}