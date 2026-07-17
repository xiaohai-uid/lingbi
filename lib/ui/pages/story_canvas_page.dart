import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_popover.dart';
import 'package:lingbi/core/di/service_locator.dart';

class StoryCanvasPage extends StatefulWidget {
  const StoryCanvasPage({super.key});
  @override
  State<StoryCanvasPage> createState() => _StoryCanvasPageState();
}

class _StoryCanvasPageState extends State<StoryCanvasPage> {
  final _settings = ServiceLocator.instance.settingsService;
  @override
  void initState() { super.initState(); _settings.addListener(_onSettingsChanged); }
  int _selectedView = 0;
  String? _selectedNode;
  final TransformationController _transformCtrl = TransformationController();

  final _nodes = [
    {'id': 'n1', 'title': '沈亦', 'meta': '主角 · 第 126 章', 'desc': '前调查记者', 'x': 120.0, 'y': 120.0},
    {'id': 'n2', 'title': '旧码头', 'meta': '地点 · 第 127 章', 'desc': '第 127 章核心场景', 'x': 420.0, 'y': 160.0},
    {'id': 'n3', 'title': '桥下对话', 'meta': '事件 · 第 128 章', 'desc': '第 128 章关键事件', 'x': 260.0, 'y': 340.0},
  ];

  @override
  @override
  void dispose() { _settings.removeListener(_onSettingsChanged); _transformCtrl.dispose(); super.dispose(); }
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      body: Column(children: [
        _topbar(d),
        Expanded(child: Row(children: [
          _sidebar(d),
          Expanded(child: _content(d)),
        ])),
      ]),
    );
  }

  Widget _sidebar(bool d) => WgSidebar(items: wgNavItems(context, 'story_canvas'));
  Widget _topbar(bool d) {
    return Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        const Text('故事画布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC')),
        const Spacer(),
        WgPopover(trigger: wgIconButton(Icons.search, d: d), contentBuilder: (context, close) => WgSearchPanel(d: d, onClose: close)),
        const SizedBox(width: 4),
        WgPopover(trigger: wgIconButton(Icons.notifications_outlined, d: d), contentBuilder: (context, close) => WgNotificationPanel(d: d)),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _content(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
        child: Row(children: [
          _toolBtn('关系图', _selectedView == 0, () => setState(() => _selectedView = 0)),
          const SizedBox(width: 8), _toolBtn('时间线', _selectedView == 1, () => setState(() => _selectedView = 1)),
          const SizedBox(width: 8), _toolBtn('看板', _selectedView == 2, () => setState(() => _selectedView = 2)),
          const Spacer(),
          Text('良${_nodes.length} 个节拍', style: TextStyle(fontSize: 12, color: f2)),
        ]),
      ),
      Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
        return InteractiveViewer(
          transformationController: _transformCtrl,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.25, maxScale: 4.0,
          child: SizedBox(width: constraints.maxWidth * 2, height: constraints.maxHeight * 2,
            child: Stack(children: [
              CustomPaint(size: Size.infinite, painter: _GridPainter(gridColor: WgTokens.border)),
              for (final n in _nodes) Positioned(
                left: n['x'] as double, top: n['y'] as double,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedNode = n['id'] as String),
                  child: Container(width: 220, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WgTokens.surfaceStrong, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedNode == n['id'] ? WgTokens.accent : WgTokens.border, width: _selectedNode == n['id'] ? 2 : 1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
                      const SizedBox(height: 6),
                      Text(n['meta'] as String, style: const TextStyle(fontSize: 12, color: WgTokens.fg2)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        );
      })),
      Container(padding: const EdgeInsets.all(16), width: double.infinity,
        decoration: BoxDecoration(color: WgTokens.surface, border: Border(top: BorderSide(color: WgTokens.border))),
        child: _selectedNode == null
          ? Text('选择一个节点查看场景关系', style: TextStyle(fontSize: 13, color: f2))
          : Text('已选择节点', style: const TextStyle(fontSize: 13)),
      ),
    ]);
  }

  Widget _toolBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? WgTokens.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: WgTokens.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w500 : FontWeight.w400, color: active ? WgTokens.accent : WgTokens.fg2))));
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.gridColor});
  final Color gridColor;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = gridColor..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += 24) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y <= size.height; y += 24) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override
  bool shouldRepaint(covariant _GridPainter old) => old.gridColor != gridColor;
}
