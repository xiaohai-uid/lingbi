import 'package:flutter/material.dart';

import '../../domain/project/project_asset.dart';
import '../theme/tokens.dart';

class ProjectAssetCard extends StatelessWidget {
  const ProjectAssetCard({
    super.key,
    required this.asset,
    this.onPressed,
  });

  final ProjectAsset asset;
  final VoidCallback? onPressed;

  String get _stateLabel => switch (asset.state) {
        ProjectAssetState.notStarted => '未开始',
        ProjectAssetState.generating => '生成中',
        ProjectAssetState.editable => '可编辑',
        ProjectAssetState.awaitingConfirmation => '待确认',
        ProjectAssetState.failed => '失败',
      };

  IconData get _icon => switch (asset.type) {
        ProjectAssetType.protagonist => Icons.person_outline_rounded,
        ProjectAssetType.worldRules => Icons.public_rounded,
        ProjectAssetType.outline => Icons.account_tree_outlined,
        ProjectAssetType.openingScene => Icons.movie_filter_outlined,
        ProjectAssetType.firstChapter => Icons.article_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    final stateColor = switch (asset.state) {
      ProjectAssetState.editable => LingBiTokens.success,
      ProjectAssetState.awaitingConfirmation => LingBiTokens.warning,
      ProjectAssetState.failed => LingBiTokens.error,
      ProjectAssetState.generating => colors.accent,
      ProjectAssetState.notStarted => colors.muted,
    };

    return Semantics(
      button: onPressed != null,
      label: '${asset.title}，$_stateLabel',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 116),
            padding: const EdgeInsets.all(LingBiTokens.space4),
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderOpaque),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_icon, size: 20, color: colors.fgSecondary),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LingBiTokens.space2,
                        vertical: LingBiTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusPill),
                      ),
                      child: Text(
                        _stateLabel,
                        style: TextStyle(
                          color: stateColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LingBiTokens.space4),
                Text(
                  asset.title,
                  style: TextStyle(
                    color: colors.fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: LingBiTokens.space1),
                Text(
                  asset.revision == 0 ? '尚未创建内容' : '版本 ${asset.revision}',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
