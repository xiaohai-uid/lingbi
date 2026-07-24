import 'package:flutter/material.dart';
import '../../services/update_checker.dart';

/// 更新通知横幅 — 当有新版本时显示在顶部
class UpdateBanner extends StatelessWidget {

  const UpdateBanner({
    super.key,
    required this.result,
    required this.onDismiss,
    this.onOpenUrl,
  });
  final UpdateResult result;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    if (!result.hasUpdate || result.latestRelease == null) {
      return const SizedBox.shrink();
    }

    final release = result.latestRelease!;
    final theme = Theme.of(context);

    return MaterialBanner(
      backgroundColor: theme.colorScheme.primaryContainer,
      leading: Icon(Icons.system_update, color: theme.colorScheme.primary),
      content: Text(
        '新版本 ${release.version} 可用！${release.name.isNotEmpty ? " — ${release.name}" : ""}',
      ),
      actions: [
        TextButton(
          onPressed: onOpenUrl,
          child: const Text('查看详情'),
        ),
        TextButton(
          onPressed: onDismiss,
          child: const Text('稍后'),
        ),
      ],
    );
  }
}
