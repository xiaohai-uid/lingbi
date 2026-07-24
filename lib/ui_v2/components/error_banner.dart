/// 分级错误提示组件
///
/// 显示用户可理解的错误信息，包含：
/// - 错误标题和详细说明
/// - 已生成内容是否保留
/// - 可执行的下一步
/// - 重试按钮（在允许时）
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/errors/ai_error.dart';

/// 错误提示横幅
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.onOpenSettings,
  });

  /// 用户可见的错误信息
  final UserFacingError error;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 关闭回调
  final VoidCallback? onDismiss;

  /// 打开设置回调
  final VoidCallback? onOpenSettings;

  /// 从 AIServiceError 构建
  factory ErrorBanner.fromError(
    AIServiceError error, {
    Key? key,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    VoidCallback? onOpenSettings,
  }) {
    return ErrorBanner(
      key: key,
      error: AiErrorMapper.toUserFacing(error),
      onRetry: onRetry,
      onDismiss: onDismiss,
      onOpenSettings: onOpenSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorsFor(error.recoveryAction, theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.$2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              Icon(_iconFor(error.recoveryAction), size: 18, color: colors.$2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.$2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 详细说明
          Text(
            error.message,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          // 数据保留说明
          Text(
            error.dataRetentionNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          // 下一步
          Text(
            error.nextStep,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          // 操作按钮
          if (error.canRetry || error.recoveryAction == RecoveryAction.checkApiKey)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (error.canRetry && onRetry != null)
                    FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重试'),
                    ),
                  if (error.recoveryAction == RecoveryAction.checkApiKey) ...[
                    if (error.canRetry) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('检查设置'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color) _colorsFor(RecoveryAction action, ThemeData theme) {
    return switch (action) {
      RecoveryAction.checkApiKey => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.error
        ),
      RecoveryAction.retryLater ||
      RecoveryAction.retry ||
      RecoveryAction.checkNetwork => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.tertiary
        ),
      RecoveryAction.switchProvider ||
      RecoveryAction.checkStorage ||
      RecoveryAction.manualIntervention => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.secondary
        ),
    };
  }

  IconData _iconFor(RecoveryAction action) {
    return switch (action) {
      RecoveryAction.checkApiKey => Icons.key_off,
      RecoveryAction.retryLater => Icons.timer,
      RecoveryAction.checkNetwork => Icons.wifi_off,
      RecoveryAction.retry => Icons.refresh,
      RecoveryAction.switchProvider => Icons.swap_horiz,
      RecoveryAction.checkStorage => Icons.storage,
      RecoveryAction.manualIntervention => Icons.report_problem,
    };
  }
}
