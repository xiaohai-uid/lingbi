/// ProGate — Pro 功能门禁组件
///
/// 包裹需要 Pro 权限的功能区域：
/// - Free 用户：内容灰显 + 锁图标 + 升级提示
/// - Pro 用户：正常展示子组件
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/subscription_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

/// Pro 功能门禁包装器
///
/// 用法：
/// ```dart
/// ProGate(
///   feature: ProFeature.cloudSync,
///   child: CloudSyncPanel(),
/// )
/// ```
class ProGate extends StatelessWidget {
  const ProGate({
    super.key,
    required this.feature,
    required this.child,
    this.message,
  });

  /// 需要检查的 Pro 功能
  final ProFeature feature;

  /// 被门禁保护的子组件
  final Widget child;

  /// 自定义升级提示文本
  final String? message;

  @override
  Widget build(BuildContext context) {
    final sub = ServiceLocator.instance.subscriptionService;
    final hasAccess = sub.canAccess(feature);

    if (hasAccess) return child;

    return Stack(
      children: [
        // 灰显的内容（不可交互）
        IgnorePointer(
          child: Opacity(
            opacity: 0.4,
            child: child,
          ),
        ),
        // 升级提示覆盖层
        Positioned.fill(
          child: Center(
            child: _UpgradePrompt(
              feature: feature,
              message: message,
            ),
          ),
        ),
      ],
    );
  }
}

/// 升级提示卡片
class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({
    required this.feature,
    this.message,
  });

  final ProFeature feature;
  final String? message;

  String get _featureName {
    switch (feature) {
      case ProFeature.cloudSync:
        return '云同步';
      case ProFeature.advancedExport:
        return '高级导出';
      case ProFeature.batchOperations:
        return '批量操作';
      case ProFeature.officialModelPlan:
        return '官方模型套餐';
      case ProFeature.localEditing:
      case ProFeature.basicSkills:
      case ProFeature.basicExport:
      case ProFeature.byoApiKey:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
        border: Border.all(color: LingBiTokens.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LingBiIcons.lock,
            size: 32,
            color: LingBiTokens.blue,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? '$_featureName 需要 Pro 许可证',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '在 设置 → 订阅 中激活 Pro 解锁全部功能',
            style: TextStyle(
              fontSize: 12,
              color: c.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pro 状态徽章 — 显示当前订阅层级
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = ServiceLocator.instance.subscriptionService;
    final isPro = sub.isPro;
    final c = LingBiColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPro
            ? LingBiTokens.blue.withValues(alpha: 0.15)
            : c.fgSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      ),
      child: Text(
        isPro ? 'Pro' : 'Free',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPro ? LingBiTokens.blue : c.fgSecondary,
        ),
      ),
    );
  }
}
