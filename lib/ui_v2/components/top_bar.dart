import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/project/data/project_tab_controller.dart' as svc;
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class TopBar extends StatefulWidget {

  const TopBar({
    super.key,
    required this.isDarkMode,
    required this.aiPanelVisible,
    required this.sidebarVisible,
    required this.onToggleTheme,
    required this.onToggleAiPanel,
    required this.onToggleSidebar,
    required this.onSkillMarket,
    this.onSearch,
    this.onProjectSwitch,
    this.onCloseTab,
  });
  final bool isDarkMode;
  final bool aiPanelVisible;
  final bool sidebarVisible;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleAiPanel;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSkillMarket;
  final ValueChanged<String>? onSearch;
  final ValueChanged<int>? onProjectSwitch;
  final ValueChanged<int>? onCloseTab;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool _searchActive = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) _searchController.clear();
    });
  }

  void _submitSearch() {
    final q = _searchController.text.trim();
    if (q.isNotEmpty) widget.onSearch?.call(q);
    setState(() {
      _searchActive = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final tabCtrl = ServiceLocator.instance.projectTabController;

    return Container(
      height: LingBiTokens.topBarHeight,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(
          bottom: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: LingBiTokens.space3),
                _buildLogo(c),
                const SizedBox(width: LingBiTokens.space4),
                Expanded(child: _buildProjectTabs(c, tabCtrl)),
                _buildActionButtons(c),
              ],
            ),
          ),
          if (_searchActive) _buildSearchBar(c),
        ],
      ),
    );
  }

  Widget _buildLogo(LingBiColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          ),
          child: const Center(
            child: Text(
              '灵',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '灵笔',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.fg,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTabs(LingBiColors c, svc.ProjectTabController tabCtrl) {
    return ListenableBuilder(
      listenable: tabCtrl,
      builder: (context, _) {
        final tabs = tabCtrl.tabs;
        if (tabs.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space2),
          itemBuilder: (context, index) {
            final isActive = index == tabCtrl.activeIndex;
            final tab = tabs[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LingBiTokens.space1),
              child: InkWell(
                onTap: () => widget.onProjectSwitch?.call(index),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space3,
                    vertical: LingBiTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? c.accent.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.project.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? c.accent : c.fgSecondary,
                        ),
                      ),
                      const SizedBox(width: LingBiTokens.space1),
                      InkWell(
                        onTap: () => widget.onCloseTab?.call(index),
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            LingBiIcons.close,
                            size: 12,
                            color: isActive ? c.muted : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.only(right: LingBiTokens.space3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tooltipButton(
            '搜索',
            Icons.search,
            _searchActive,
            c,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 2),
          _tooltipButton(
            'AI 助手',
            LingBiIcons.aiAssistant,
            widget.aiPanelVisible,
            c,
            onTap: widget.onToggleAiPanel,
          ),
          const SizedBox(width: 2),
          _tooltipButton(
            '侧栏',
            LingBiIcons.menu,
            widget.sidebarVisible,
            c,
            onTap: widget.onToggleSidebar,
          ),
          const SizedBox(width: 2),
          _tooltipButton(
            '技能市场',
            LingBiIcons.skillMarket,
            false,
            c,
            onTap: widget.onSkillMarket,
          ),
          const SizedBox(width: 2),
          _tooltipButton(
            widget.isDarkMode ? '浅色模式' : '深色模式',
            widget.isDarkMode ? LingBiIcons.moon : LingBiIcons.sun,
            false,
            c,
            onTap: widget.onToggleTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LingBiColors c) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: c.muted),
          const SizedBox(width: LingBiTokens.space2),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onSubmitted: (_) => _submitSearch(),
              decoration: InputDecoration(
                hintText: '搜索文档…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
                hintStyle: TextStyle(fontSize: 13, color: c.muted),
              ),
              style: TextStyle(fontSize: 13, color: c.fg),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          InkWell(
            onTap: _toggleSearch,
            child: Icon(Icons.close, size: 16, color: c.muted),
          ),
        ],
      ),
    );
  }

  Widget _tooltipButton(
    String tooltip,
    IconData icon,
    bool active,
    LingBiColors c, {
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(LingBiTokens.space2),
            child: Icon(
              icon,
              size: 20,
              color: active ? c.accent : c.fgSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
