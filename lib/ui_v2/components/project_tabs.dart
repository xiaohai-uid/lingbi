import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

enum ProjectTab {
  editor('写作', LingBiIcons.editor),
  canon('正典', LingBiIcons.canon),
  storyboard('故事画板', LingBiIcons.storyboard),
  history('版本历史', LingBiIcons.history),
  importExport('导入/导出', LingBiIcons.importExport),
  settings('设置', LingBiIcons.settings);

  const ProjectTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ProjectNavigationBar extends StatelessWidget {

  const ProjectNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.onCollapse,
  });
  final ProjectTab currentTab;
  final ValueChanged<ProjectTab> onTabChanged;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(
          bottom: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: LingBiTokens.space3),
          ...ProjectTab.values.map(
            (tab) => _buildTabItem(tab, c),
          ),
          const Spacer(),
          _buildCollapseButton(c),
        ],
      ),
    );
  }

  Widget _buildTabItem(ProjectTab tab, LingBiColors c) {
    final isActive = tab == currentTab;
    return Padding(
      padding: const EdgeInsets.only(right: LingBiTokens.space1),
      child: InkWell(
        onTap: () => onTabChanged(tab),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space3),
          decoration: BoxDecoration(
            color: isActive
                ? c.surfaceContainer.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 16,
                color: isActive ? c.accent : c.fgSecondary,
              ),
              const SizedBox(width: LingBiTokens.space1),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? c.fg : c.fgSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(LingBiColors c) {
    return Tooltip(
      message: '折叠导航',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCollapse,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(LingBiTokens.space2),
            child: Icon(
              LingBiIcons.chevronLeft,
              size: 16,
              color: c.muted,
            ),
          ),
        ),
      ),
    );
  }
}
