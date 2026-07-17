import 'package:flutter/material.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_popover.dart';
import 'package:lingbi/core/di/service_locator.dart';

class CanonPage extends StatefulWidget {
  const CanonPage({super.key});
  @override
  State<CanonPage> createState() => _CanonPageState();
}

class _CanonPageState extends State<CanonPage> {
  final _settings = ServiceLocator.instance.settingsService;
  @override
  void initState() { super.initState(); _settings.addListener(_onSettingsChanged); }
  @override
  void dispose() { _settings.removeListener(_onSettingsChanged); super.dispose(); }
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }
  int _filterIndex = 0;
  final _filters = ['全部', '角色', '地点', '事件', '关系'];

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      body: Row(children: [
        _sidebar(d),
        Expanded(child: Column(children: [
          _topbar(d),
          Expanded(child: _content(d)),
        ])),
      ]),
    );
  }

  Widget _sidebar(bool d) => WgSidebar(items: wgNavItems(context, 'canon'));
  Widget _topbar(bool d) {
    return Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        const Text('知识库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC')),
        const Spacer(),
        WgPopover(trigger: wgIconButton(Icons.search, d: d), contentBuilder: (context, close) => WgSearchPanel(d: d, onClose: close)),
        const SizedBox(width: 4),
        WgPopover(trigger: wgIconButton(Icons.notifications_outlined, d: d), contentBuilder: (context, close) => WgNotificationPanel(d: d)),
        const SizedBox(width: 4),
        IconButton(icon: const Icon(Icons.add, color: WgTokens.fg2), onPressed: () {}),
      ]),
    );
  }

  Widget _content(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SingleChildScrollView(padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Filter toolbar
        Row(children: [
          for (int i = 0; i < _filters.length; i++)
            Padding(padding: const EdgeInsets.only(right: 8), child: _filterBtn(_filters[i], i == _filterIndex, () => setState(() => _filterIndex = i))),
        ]),
        const SizedBox(height: 24),
        // Entity + Relations panels
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _panel('实体', '+ 新建', Column(children: [
            _entityRow('沈', '沈亦', '角色', '主角', 'tag-role', const Color(0xFFB07D2A)),
            _entityRow('旧', '旧码头', '地点', '第 127 章', 'tag-place', WgTokens.success),
            _entityRow('桥', '桥下对话', '事件', '第 128 章', 'tag-event', WgTokens.fg2),
          ]))),
          const SizedBox(width: 20),
          Expanded(child: _panel('关系', '+ 新建', Column(children: [
            _relationRow('沈亦', '遇见 →', '周沉', '旧码头 / 第 128 章'),
            _relationRow('陈素', '提及 →', '渡船计划', '旧码头 / 第 127 章'),
            _relationRow('沈亦', '卷入 →', '匿名短信', '信号塔 / 第 126 章'),
          ]))),
        ]),
      ]),
    );
  }

  Widget _filterBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? WgTokens.accent : WgTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: WgTokens.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : WgTokens.fg))));
  }

  Widget _panel(String title, String action, Widget body) {
    return Container(
      decoration: BoxDecoration(color: WgTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: WgTokens.border),
        boxShadow: [BoxShadow(color: WgTokens.fg.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSerifSC')),
            Text(action, style: const TextStyle(fontSize: 12, color: WgTokens.accent, fontWeight: FontWeight.w500)),
          ])),
        Divider(height: 1, color: WgTokens.border),
        Padding(padding: const EdgeInsets.all(16), child: body),
      ]));
  }

  Widget _entityRow(String thumb, String name, String type, String meta, String tagType, Color tagColor) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0x2EE8A838), WgTokens.warnSoft]),
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(thumb, style: const TextStyle(color: WgTokens.accent, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(meta, style: const TextStyle(fontSize: 12, color: WgTokens.fg2)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tagColor))),
      ]));
  }

  Widget _relationRow(String from, String arrow, String to, String meta) {
    return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: WgTokens.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: WgTokens.border)),
      child: Column(children: [
        Row(children: [Text(from, style: const TextStyle(fontSize: 13)), Text(' $arrow ', style: const TextStyle(fontSize: 12, color: WgTokens.fg2)), Text(to, style: const TextStyle(fontSize: 13))]),
        Padding(padding: const EdgeInsets.only(top: 2), child: Text(meta, style: const TextStyle(fontSize: 12, color: WgTokens.fg2))),
      ]));
  }
}
