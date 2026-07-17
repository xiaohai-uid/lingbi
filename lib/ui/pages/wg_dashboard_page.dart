import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'package:lingbi/ui/pages/wg_workspace_page.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_popover.dart';

class WgDashboardPage extends StatefulWidget {
  const WgDashboardPage({super.key});
  @override
  State<WgDashboardPage> createState() => _WgDashboardPageState();
}

class _WgDashboardPageState extends State<WgDashboardPage> {
  final WorldService _worldService = ServiceLocator.instance.worldService;
  List<World> _worlds = [];
  bool _loading = true;
  int _totalWords = 0, _totalChapters = 0, _totalAiCalls = 0;
  DateTime? _earliestCreation;

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.settingsService.addListener(_onSettingsChanged);
    _loadWorlds();
  }

  @override
  void dispose() {
    ServiceLocator.instance.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadWorlds() async {
    setState(() => _loading = true);
    try {
      _worlds = await _worldService.listWorlds();
      int w = 0, c = 0;
      for (final world in _worlds) {
        try {
          final works = await _worldService.getWorks(world.id);
          for (final work in works) {
            final vols = await _worldService.volumeRepository.getVolumes(work.id, worldId: world.id);
            for (final vol in vols) {
              c += (await _worldService.chapterRepository.getChapters(vol.id, worldId: world.id)).length;
            }
          }
          final db = await _worldService.databaseManager.getDatabase(world.id);
          for (final doc in await db.select(db.documents).get()) {
            try { final f = File(doc.filePath); if (await f.exists()) w += (await f.readAsString()).length; } catch (_) {}
          }
        } catch (_) {}
        if (_earliestCreation == null || world.createdAt.isBefore(_earliestCreation!)) _earliestCreation = world.createdAt;
      }
      _totalWords = w; _totalChapters = c; _totalAiCalls = c * 2;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toggleTheme() {
    final s = ServiceLocator.instance.settingsService;
    s.setThemeMode(s.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      body: Row(children: [_sidebar(d), Expanded(child: Column(children: [_topbar(d), Expanded(child: _content(d))]))]),
    );
  }

  Widget _sidebar(bool d) => WgSidebar(items: wgNavItems(context, 'dashboard'));

  Widget _topbar(bool d) {
    return Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        const Text('灵笔', style: TextStyle(fontSize: 13, color: WgTokens.fg2)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('/', style: TextStyle(fontSize: 13, color: WgTokens.fg2))),
        const Text('仪表盘', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        WgPopover(trigger: _iconBtn(Icons.search), contentBuilder: (context, close) => WgSearchPanel(d: d, onClose: close)),
        WgPopover(trigger: _iconBtn(Icons.notifications_outlined), contentBuilder: (context, close) => WgNotificationPanel(d: d)),
        _iconBtn(Icons.dark_mode_outlined, _toggleTheme),
      ]),
    );
  }

  Widget _iconBtn(IconData ic, [VoidCallback? onTap]) {
    final bo = Theme.of(context).brightness == Brightness.dark;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: bo ? WgTokens.darkSurface : WgTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bo ? WgTokens.darkBorder : WgTokens.border)),
        child: Icon(ic, size: 18, color: bo ? WgTokens.darkFg2 : WgTokens.fg2)));
  }

  Widget _content(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final days = _earliestCreation != null ? DateTime.now().difference(_earliestCreation!).inDays + 1 : 0;
    return SingleChildScrollView(padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _statCard('??', '${_worlds.length}', '进行中作品', d),
          const SizedBox(width: 16),
          _statCard('?', '$_totalWords', '累计字数', d),
          const SizedBox(width: 16),
          _statCard('?', '$_totalAiCalls', 'AI 生成章节', d),
          const SizedBox(width: 16),
          _statCard('?', '$days', '创作天数', d),
        ]),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: WgTokens.surfaceStrong, borderRadius: BorderRadius.circular(14), border: Border.all(color: WgTokens.accent.withValues(alpha: 0.22))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('升级到高级版', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text('解锁无限制 AI 续写、角色卡、知识库与导出包。', style: TextStyle(fontSize: 13, color: f2)),
            ])),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
              child: const Text('查看方案', style: TextStyle(color: WgTokens.accent))),
          ])),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _panel('进行中的项目', '+ 新建', _projectList(d))),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _panel('最近活动', '查看全部', _activityFeed(d)),
            const SizedBox(height: 20), _goalCard(d),
          ])),
        ]),
      ]),
    );
  }

  Widget _statCard(String ic, String v, String lb, bool d) {
    return Expanded(child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: WgTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: WgTokens.border),
        boxShadow: [BoxShadow(color: WgTokens.fg.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ic, style: const TextStyle(fontSize: 20)), const SizedBox(height: 8),
        Text(v, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: d ? WgTokens.darkFg : WgTokens.fg, fontFamily: 'NotoSerifSC')),
        const SizedBox(height: 4), Text(lb, style: TextStyle(fontSize: 12, color: d ? WgTokens.darkFg3 : WgTokens.fg3)),
      ])));
  }

  Widget _panel(String t, String a, Widget b) {
    return Container(
      decoration: BoxDecoration(color: WgTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: WgTokens.border),
        boxShadow: [BoxShadow(color: WgTokens.fg.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSerifSC')),
            Text(a, style: const TextStyle(fontSize: 12, color: WgTokens.accent, fontWeight: FontWeight.w500)),
          ])),
        Divider(height: 1, color: WgTokens.border),
        Padding(padding: const EdgeInsets.all(16), child: b),
      ]));
  }

  Widget _projectList(bool d) {
    final f = d ? WgTokens.darkFg : WgTokens.fg;
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    if (_worlds.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Text('暂无项目', style: TextStyle(fontSize: 13, color: f2))));
    return Column(children: _worlds.map((w) => InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WgWorkspacePage(world: w))),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12), child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0x2EE8A838), WgTokens.warnSoft]),
            borderRadius: BorderRadius.circular(8), border: Border.all(color: WgTokens.accent.withValues(alpha: 0.18))),
          child: Center(child: Text(w.name.isNotEmpty ? w.name[0] : '?',
            style: const TextStyle(color: WgTokens.accent, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: f)),
          Text('连载中', style: TextStyle(fontSize: 12, color: f2)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: WgTokens.accentSoft, borderRadius: BorderRadius.circular(6)),
          child: const Text('连载中', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFB07D2A)))),
      ])))).toList());
  }

  Widget _activityFeed(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    final items = [
      ('AI 续写', '生成了新章节的候选段落', WgTokens.accent, '14 分钟前'),
      ('自动保存', '修订版已同步', WgTokens.success, '1 小时前'),
      ('角色卡', '更新了角色信息', WgTokens.fg2, '3 小时前'),
      ('导出', 'Markdown 包已就绪', WgTokens.warn, '昨天 18:32'),
    ];
    return Column(children: [for (final e in items) Container(padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: WgTokens.border.withValues(alpha: 0.5)))),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle),
          margin: const EdgeInsets.only(top: 7, right: 12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [TextSpan(text: e.$1, style: const TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: ' ${e.$2}')]), style: const TextStyle(fontSize: 13)),
          Text(e.$4, style: TextStyle(fontSize: 11, color: f2)),
        ])),
      ]))]);
  }

  Widget _goalCard(bool d) {
    return Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [WgTokens.accent.withValues(alpha: 0.08), WgTokens.bg.withValues(alpha: 0.6)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: WgTokens.accent.withValues(alpha: 0.16))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('本周写作目标', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSerifSC')),
          Text('$_totalWords / ${_totalWords + 2600} 字',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: WgTokens.accent)),
        ]), const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: Container(height: 6, color: WgTokens.fg.withValues(alpha: 0.08), child: FractionallySizedBox(alignment: Alignment.centerLeft,
            widthFactor: _totalWords > 0 ? (_totalWords / (_totalWords + 2600)).clamp(0.0, 1.0) : 0.0,
            child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [WgTokens.accent, WgTokens.warn])))))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('剩余 ${_totalWords > 0 ? 2600 : 0} 字',
            style: TextStyle(fontSize: 12, color: d ? WgTokens.darkFg3 : WgTokens.fg3)),
          const Text('截止：周日', style: TextStyle(fontSize: 12, color: WgTokens.fg3)),
        ]),
      ]));
  }
}
