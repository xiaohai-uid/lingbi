import 'package:flutter/material.dart';

import 'package:lingbi/services/identity/identity_rules.dart';

/// 身份识别通知气泡
///
/// 覆盖在编辑器右上角，提示 AI 检测到 N 个潜在身份。
/// 点击后由父组件弹出确认对话框（通过 [onTap] 回调）。
class IdentityNotificationBubble extends StatelessWidget {
  const IdentityNotificationBubble({
    super.key,
    required this.candidates,
    required this.onTap,
    required this.onDismiss,
  });
  final List<IdentityCandidate> candidates;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final count = candidates.length;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFEDE7F6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: isDark ? const Color(0xFFB9A7FF) : const Color(0xFF6A4CC0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '检测到 $count 个潜在身份',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8E6F0)
                            : const Color(0xFF3A2E55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '点击查看并确认',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: onDismiss,
                tooltip: '忽略',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
