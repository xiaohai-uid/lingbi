import 'dart:ui';
import 'package:flutter/material.dart';

/// 灵笔主布局 — 毛玻璃三栏式
class MainScaffold extends StatefulWidget {
  final Widget sidebar;
  final Widget editor;
  final Widget aiPanel;
  final double sidebarWidth;

  const MainScaffold({
    super.key,
    required this.sidebar,
    required this.editor,
    required this.aiPanel,
    this.sidebarWidth = 260,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _aiPanelVisible = false;
  final double _aiPanelWidth = 340;

  void _toggleAiPanel() => setState(() => _aiPanelVisible = !_aiPanelVisible);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // ─── 左侧栏（毛玻璃） ───
        SizedBox(
          width: widget.sidebarWidth,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? Colors.white.withValues(alpha: 0.75)
                      : const Color(0xFF1A1A1A).withValues(alpha: 0.75),
                  border: Border(
                    right: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: widget.sidebar,
              ),
            ),
          ),
        ),
        // ─── 编辑区（含浮动按钮） ───
        Expanded(
          child: Stack(
            children: [
              widget.editor,
              // AI 切换钮
              Positioned(
                right: 16, top: 16,
                child: _AIFab(isActive: _aiPanelVisible, onPressed: _toggleAiPanel),
              ),
            ],
          ),
        ),
        // ─── AI 面板（毛玻璃） ───
        if (_aiPanelVisible) ...[
          SizedBox(
            width: _aiPanelWidth,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                    border: Border(
                      left: BorderSide(
                        color: theme.brightness == Brightness.light
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: widget.aiPanel,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 毛玻璃 AI 浮动按钮
class _AIFab extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;
  const _AIFab({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.9)
              : (theme.brightness == Brightness.light
                  ? Colors.white.withValues(alpha: 0.8)
                  : const Color(0xFF2A2A2A).withValues(alpha: 0.8)),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.brightness == Brightness.light
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? '关闭' : 'AI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}