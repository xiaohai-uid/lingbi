import 'package:flutter/material.dart';

import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/pages/wg_dashboard_page.dart';
import 'package:lingbi/ui/pages/wg_workspace_page.dart';
import 'package:lingbi/ui/pages/wg_editor_page.dart';
import 'package:lingbi/ui/pages/canon_page.dart';
import 'package:lingbi/ui/pages/story_canvas_page.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'package:lingbi/ui/components/wg_nav.dart';

/// 浮层内容构造：提供 [close] 回调用于关闭浮层（如点击跳转前）。
typedef WgPopoverContentBuilder = Widget Function(BuildContext context, void Function() close);

/// 顶部栏图标按钮，用作弹出层触发器。
Widget wgIconButton(IconData icon, {required bool d, Color? color}) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: d ? WgTokens.darkSurface : WgTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: d ? WgTokens.darkBorder : WgTokens.border),
      ),
      child: Icon(icon, size: 18, color: color ?? (d ? WgTokens.darkFg2 : WgTokens.fg2)),
    );

/// 锚定在触发器下方的浮层下拉（搜索 / 通知等）。
class WgPopover extends StatefulWidget {
  final Widget trigger;
  final WgPopoverContentBuilder contentBuilder;
  final double width;
  final double verticalOffset;
  const WgPopover({
    super.key,
    required this.trigger,
    required this.contentBuilder,
    this.width = 320,
    this.verticalOffset = 8,
  });

  @override
  State<WgPopover> createState() => _WgPopoverState();
}

class _WgPopoverState extends State<WgPopover> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() => _open ? _close() : _openMenu();

  void _openMenu() {
    _entry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: Offset(0, widget.verticalOffset),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.width, maxHeight: 420),
              child: SizedBox(
                width: widget.width,
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: widget.contentBuilder(context, _close),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
        link: _link,
        child: GestureDetector(onTap: _toggle, child: widget.trigger),
      );
}

/// 通知下拉面板。
class WgNotificationPanel extends StatelessWidget {
  final bool d;
  const WgNotificationPanel({super.key, required this.d});

  static const _notes = [
    ('AI 续写', '生成了新章节的候选段落', '14 分钟前'),
    ('自动保存', '修订版已同步', '1 小时前'),
    ('角色卡', '更新了角色信息', '3 小时前'),
    ('导出', 'Markdown 包已就绪', '昨天 18:32'),
  ];

  @override
  Widget build(BuildContext context) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(children: [
          const Text('通知', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text('全部已读', style: TextStyle(fontSize: 12, color: WgTokens.accent)),
        ]),
      ),
      Divider(height: 1, color: WgTokens.border),
      for (final n in _notes)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(color: WgTokens.accent, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(n.$2, style: TextStyle(fontSize: 12, color: f2)),
                Text(n.$3, style: TextStyle(fontSize: 11, color: f2)),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

class _SearchItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _SearchItem(this.label, this.icon, this.onTap);
}

/// 搜索下拉面板：页面 + 作品，按关键词过滤，点击跳转。
class WgSearchPanel extends StatefulWidget {
  final bool d;
  final VoidCallback onClose;
  const WgSearchPanel({super.key, required this.d, required this.onClose});

  @override
  State<WgSearchPanel> createState() => _WgSearchPanelState();
}

class _WgSearchPanelState extends State<WgSearchPanel> {
  final _ctrl = TextEditingController();
  List<World> _worlds = [];
  List<_SearchItem> _items = [];
  List<_SearchItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_apply);
    _load();
  }

  Future<void> _load() async {
    try {
      _worlds = await ServiceLocator.instance.worldService.listWorlds();
    } catch (_) {
      _worlds = [];
    }
    _rebuild();
  }

  void _rebuild() {
    _items = [
      _SearchItem('仪表盘', Icons.dashboard_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WgDashboardPage()))),
      _SearchItem('工作区', Icons.folder_copy_outlined, () => openFirstWorkspace(context)),
      _SearchItem('编辑器', Icons.edit_note_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WgEditorPage()))),
      _SearchItem('知识库', Icons.auto_stories_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanonPage()))),
      _SearchItem('故事画布', Icons.hub_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryCanvasPage()))),
      _SearchItem('设置', Icons.settings_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      for (final w in _worlds)
        _SearchItem('作品 · ${w.name}', Icons.book_outlined,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => WgWorkspacePage(world: w)))),
    ];
    _apply();
  }

  void _apply() {
    final q = _ctrl.text.trim();
    setState(() => _filtered = q.isEmpty ? _items : _items.where((e) => e.label.contains(q)).toList());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f2 = widget.d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SizedBox(
      height: 360,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '搜索页面或作品…',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: InputBorder.none,
            ),
          ),
        ),
        Divider(height: 1, color: WgTokens.border),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final e in _filtered)
                ListTile(
                  dense: true,
                  leading: Icon(e.icon, size: 18, color: f2),
                  title: Text(e.label, style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    widget.onClose();
                    e.onTap();
                  },
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
