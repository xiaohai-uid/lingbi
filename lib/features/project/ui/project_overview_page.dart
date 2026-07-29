import 'package:flutter/material.dart';

import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/features/project/ui/project_asset_card.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class ProjectOverviewPage extends StatefulWidget {
  const ProjectOverviewPage({
    super.key,
    required this.project,
    required this.repository,
    this.onAssetSelected,
  });

  final Project project;
  final ProjectAssetRepository repository;
  final ValueChanged<ProjectAsset>? onAssetSelected;

  @override
  State<ProjectOverviewPage> createState() => _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends State<ProjectOverviewPage> {
  late Future<List<ProjectAsset>> _assets;

  @override
  void initState() {
    super.initState();
    _assets = widget.repository.ensureOverviewAssets(widget.project.id);
  }

  ProjectAsset _nextAction(List<ProjectAsset> assets) => assets.firstWhere(
        (asset) => asset.state == ProjectAssetState.failed,
        orElse: () => assets.firstWhere(
          (asset) => asset.state == ProjectAssetState.awaitingConfirmation,
          orElse: () => assets.firstWhere(
            (asset) => asset.state == ProjectAssetState.notStarted,
            orElse: () => assets.first,
          ),
        ),
      );

  String _actionLabel(ProjectAsset asset) => switch (asset.type) {
        ProjectAssetType.protagonist => '完善主角',
        ProjectAssetType.worldRules => '定义世界规则',
        ProjectAssetType.outline => '搭建故事大纲',
        ProjectAssetType.openingScene => '设计开场事件',
        ProjectAssetType.firstChapter => '开始第一章',
      };

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return FutureBuilder<List<ProjectAsset>>(
      future: _assets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(() {
                _assets =
                    widget.repository.ensureOverviewAssets(widget.project.id);
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('加载失败，重试'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final assets = snapshot.data!;
        final next = _nextAction(assets);
        return ColoredBox(
          color: colors.bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LingBiTokens.space8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.name,
                    style: TextStyle(
                      color: colors.fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: LingBiTokens.space2),
                  Text(
                    widget.project.premise.isEmpty
                        ? '随时可以补充一句话创意。'
                        : widget.project.premise,
                    style: TextStyle(color: colors.fgSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: LingBiTokens.space6),
                  Container(
                    padding: const EdgeInsets.all(LingBiTokens.space5),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusLg),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: colors.accent),
                        const SizedBox(width: LingBiTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('下一步',
                                  style: TextStyle(
                                      color: colors.fgSecondary, fontSize: 12)),
                              const SizedBox(height: LingBiTokens.space1),
                              Text(
                                _actionLabel(next),
                                style: TextStyle(
                                  color: colors.fg,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: widget.onAssetSelected == null
                              ? null
                              : () => widget.onAssetSelected!(next),
                          child: Text(_actionLabel(next)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LingBiTokens.space8),
                  Text(
                    '创作资产',
                    style: TextStyle(
                      color: colors.fg,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: LingBiTokens.space4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          (constraints.maxWidth - LingBiTokens.space4 * 2) / 3;
                      return Wrap(
                        spacing: LingBiTokens.space4,
                        runSpacing: LingBiTokens.space4,
                        children: assets
                            .map(
                              (asset) => SizedBox(
                                width: width,
                                child: ProjectAssetCard(
                                  asset: asset,
                                  onPressed: widget.onAssetSelected == null
                                      ? null
                                      : () => widget.onAssetSelected!(asset),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
