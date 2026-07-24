/// 模型状态栏
///
/// 显示：供应商·modelId / 上下文窗口或“未知” / 本次上下文 / 输出上限 / 费用估算或“费用未知”
/// 支持 ModelSnapshot 显示（运行中任务不受全局切换影响）
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/ai/model_registry.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/model_snapshot.dart';

/// 模型状态栏组件
class ModelStatusBar extends StatelessWidget {
  const ModelStatusBar({
    super.key,
    this.contextTokens = 0,
    this.compact = false,
    this.snapshot,
  });

  /// 本次上下文估算 token 数
  final int contextTokens;

  /// 紧凑模式（仅显示关键信息）
  final bool compact;

  /// 任务快照（运行中任务使用，不受全局切换影响）
  final ModelSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final aiService = ServiceLocator.instance.aiService;
    final modelInfo = aiService.currentModelInfo;
    final providerName = snapshot?.providerId ?? aiService.currentProviderName;
    final modelId = snapshot?.modelId ?? aiService.currentModelId;
    final displayName = snapshot?.displayName ?? modelInfo?.displayName ?? modelId;

    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
    );

    if (compact) {
      return _buildCompact(context, providerName, modelId, modelInfo);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _buildItem('供应商', _providerDisplayName(providerName), valueStyle, labelStyle),
          _buildItem('模型', displayName.isEmpty ? '未选择' : displayName, valueStyle, labelStyle),
          _buildItem(
            '上下文窗口',
            snapshot?.contextWindowLabel ?? modelInfo?.contextWindowLabel ?? '未知',
            valueStyle,
            labelStyle,
          ),
          _buildItem(
            '本次上下文',
            contextTokens > 0 ? '~$contextTokens tokens' : '-',
            valueStyle,
            labelStyle,
          ),
          _buildItem(
            '输出上限',
            snapshot?.maxOutputLabel ?? modelInfo?.maxOutputLabel ?? '未知',
            valueStyle,
            labelStyle,
          ),
          _buildItem(
            '费用',
            _estimateCost(modelInfo),
            valueStyle,
            labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    String providerName,
    String modelId,
    ModelInfo? modelInfo,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.smart_toy_outlined,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          modelId.isEmpty ? providerName : modelId,
          style: theme.textTheme.bodySmall,
        ),
        if (modelInfo != null) ...[
          const SizedBox(width: 8),
          Text(
            modelInfo.contextWindowLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItem(
    String label,
    String value,
    TextStyle? valueStyle,
    TextStyle? labelStyle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  String _providerDisplayName(String providerId) {
    final config = ModelRegistry.allPlatforms[providerId];
    return config?.name ?? providerId;
  }

  String _estimateCost(ModelInfo? modelInfo) {
    // 快照优先
    if (snapshot != null) {
      return snapshot!.pricingLabel;
    }
    if (modelInfo == null || !modelInfo.pricing.isKnown) {
      return '费用未知';
    }
    // 内置已知→估算
    return modelInfo.pricing.formatCost(
      inputTokens: contextTokens,
      outputTokens: 500,
    );
  }
}
