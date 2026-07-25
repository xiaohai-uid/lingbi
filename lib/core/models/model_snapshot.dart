/// 模型快照 — 任务执行时捕获的模型状态
///
/// 在任务点击执行时捕获，不受后续全局模型切换影响。
/// 嵌入现有任务结构中，不创建平行体系。
library;

import '../ai/model_registry.dart';

/// 任务执行时的模型快照
class ModelSnapshot {
  const ModelSnapshot({
    required this.providerId,
    required this.modelId,
    required this.displayName,
    this.contextWindow,
    this.maxOutputTokens,
    this.pricing = const ModelPricing(),
    this.metadataSource = MetadataSource.builtin,
    required this.capturedAt,
  });

  /// 从 ModelInfo 创建快照
  factory ModelSnapshot.fromModelInfo(ModelInfo info) {
    return ModelSnapshot(
      providerId: info.providerId,
      modelId: info.id,
      displayName: info.displayName,
      contextWindow: info.contextWindow,
      maxOutputTokens: info.maxOutputTokens,
      pricing: info.pricing,
      metadataSource: info.metadataSource,
      capturedAt: DateTime.now(),
    );
  }

  factory ModelSnapshot.fromJson(Map<String, dynamic> json) => ModelSnapshot(
        providerId: json['provider_id'] as String? ?? '',
        modelId: json['model_id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        contextWindow: json['context_window'] as int?,
        maxOutputTokens: json['max_output_tokens'] as int?,
        pricing: ModelPricing(
          inputPerMillion: (json['input_per_million'] as num?)?.toDouble() ?? 0,
          outputPerMillion:
              (json['output_per_million'] as num?)?.toDouble() ?? 0,
        ),
        metadataSource: MetadataSource.values.firstWhere(
          (s) => s.name == json['metadata_source'],
          orElse: () => MetadataSource.manual,
        ),
        capturedAt: json['captured_at'] != null
            ? DateTime.parse(json['captured_at'] as String)
            : DateTime.now(),
      );

  /// 供应商 ID
  final String providerId;

  /// 模型 ID（API 调用时使用）
  final String modelId;

  /// 显示名称
  final String displayName;

  /// 上下文窗口大小（token），null 表示未知
  final int? contextWindow;

  /// 最大输出 token 数，null 表示未知
  final int? maxOutputTokens;

  /// 价格信息
  final ModelPricing pricing;

  /// 元数据来源
  final MetadataSource metadataSource;

  /// 快照捕获时间
  final DateTime capturedAt;

  /// 上下文窗口显示标签
  String get contextWindowLabel {
    final w = contextWindow;
    if (w == null) return '未知';
    if (w >= 1000000) return '${w ~/ 1000000}M';
    if (w >= 1000) return '${w ~/ 1000}K';
    return '$w';
  }

  /// 输出上限显示标签
  String get maxOutputLabel {
    final t = maxOutputTokens;
    if (t == null) return '未知';
    if (t >= 1000) return '${t ~/ 1000}K';
    return '$t';
  }

  /// 费用显示
  String get pricingLabel {
    if (!pricing.isKnown) return '费用未知';
    return '输入 ¥${pricing.inputPerMillion}/M · 输出 ¥${pricing.outputPerMillion}/M';
  }

  /// 完整显示文本
  String get summary =>
      '$displayName ($modelId) · $contextWindowLabel 上下文 · $pricingLabel';

  Map<String, dynamic> toJson() => {
        'provider_id': providerId,
        'model_id': modelId,
        'display_name': displayName,
        if (contextWindow != null) 'context_window': contextWindow,
        if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
        'input_per_million': pricing.inputPerMillion,
        'output_per_million': pricing.outputPerMillion,
        'metadata_source': metadataSource.name,
        'captured_at': capturedAt.toIso8601String(),
      };

  @override
  String toString() => 'ModelSnapshot($providerId/$modelId @ $capturedAt)';
}
