import 'package:flutter/material.dart';
import 'package:lingbi/core/models/world.dart';

import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/core/di/service_locator.dart';

class WgWorkspacePage extends StatefulWidget {
  final World world;
  const WgWorkspacePage({super.key, required this.world});
  @override
  State<WgWorkspacePage> createState() => _WgWorkspacePageState();
}

class _WgWorkspacePageState extends State<WgWorkspacePage> {
  final _settings = ServiceLocator.instance.settingsService;
  @override
  void initState() { super.initState(); _settings.addListener(_onSettingsChanged); }
  final List<String> _tabs = const ['大纲', '角色', '章节', '时间线', 'AI'];
  int _selectedTab = 0;
  int _selectedChapter = 0;
  final TextEditingController _promptCtrl = TextEditingController();

  final List<Map<String, dynamic>> _outline = const [
    {'act': '第一幕', 'title': '日常崩塌', 'summary': '主角在平静生活中发现异常，旧记忆的碎片开始浮现。', 'beats': 4, 'done': 3},
    {'act': '第二幕', 'title': '暗流涌动', 'summary': '调查引出家族秘辛，盟友与敌人的界限开始模糊。', 'beats': 6, 'done': 2},
    {'act': '第三幕', 'title': '归处', 'summary': '真相揭晓，主角在记忆与现实中做出艰难抉择。', 'beats': 5, 'done': 0},
  ];
  final List<Map<String, dynamic>> _characters = const [
    {'name': '林溪', 'role': '主角', 'desc': '记忆紊乱的档案管理员，理性而孤独。', 'tag': '主角'},
    {'name': '沈确', 'role': '盟友', 'desc': '神秘的调查员，掌握部分真相。', 'tag': '盟友'},
    {'name': '余溟', 'role': '对手', 'desc': '家族利益捍卫者，手段冷硬。', 'tag': '对手'},
    {'name': '阿橦', 'role': '伙伴', 'desc': '少年时期的记忆投影，主角的另一种可能。', 'tag': '伙伴'},
  ];
  final List<Map<String, dynamic>> _chapters = const [
    {'no': '第 1 章', 'title': '开篇', 'status': 'done', 'words': 3210, 'date': '07-12'},
    {'no': '第 2 章', 'title': '零星记忆', 'status': 'review', 'words': 2870, 'date': '07-13'},
    {'no': '第 3 章', 'title': '暗流涌动', 'status': 'draft', 'words': 1540, 'date': '07-15'},
    {'no': '第 4 章', 'title': '旧识重逢', 'status': 'draft', 'words': 980, 'date': '07-15'},
    {'no': '第 5 章', 'title': '迷雾', 'status': 'planned', 'words': 0, 'date': '—'},
  ];
  final List<Map<String, dynamic>> _timeline = const [
    {'time': '童年', 'title': '档案室失火', 'desc': '一场火灾带走了林溪的部分童年记忆。'},
    {'time': '十年前', 'title': '沈确入职', 'desc': '调查员进入机构，开始暗中记录异常。'},
    {'time': '现在', 'title': '记忆碎片', 'desc': '主角频繁闪回陌生而真实的场景。'},
    {'time': '三天后', 'title': '家族会议', 'desc': '一场对峙在长桌两端爆发。'},
  ];
  final List<Map<String, dynamic>> _aiItems = const [
    {'title': '下一章钩子', 'body': '让阿橦在雨夜出现，留下半张被烧焦的合影。', 'tag': '情节'},
    {'title': '角色动机', 'body': '余溟的冷硬源于一次未竟的救援，至今无法释怀。', 'tag': '人物'},
    {'title': '环境描写', 'body': '用潮湿的霉味与昏黄台灯，暗示记忆的不可靠。', 'tag': '文风'},
  ];

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _promptCtrl.dispose();
    super.dispose();
  }
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      body: Row(children: [
        WgSidebar(items: wgNavItems(context, 'workspace')),
        _outlinePanel(d),
        Expanded(child: Column(children: [
          _tabbar(d),
          Expanded(child: _tabContent(d)),
        ])),
        _contextPanel(d),
      ]),
    );
  }

  Widget _outlinePanel(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SizedBox(width: 260, child: Container(height: double.infinity,
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.92),
        border: Border(right: BorderSide(color: WgTokens.borderFor(context)))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('章节目录', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
            Text('12 章', style: TextStyle(fontSize: 12, color: f2)),
          ])),
        Divider(height: 1, color: WgTokens.border),
        for (final tab in ['提纲', '角色', '章节', '时间线', 'AI 生成'])
          InkWell(onTap: () => setState(() => _selectedTab = _tabs.indexOf(tab == 'AI 生成' ? 'AI' : tab)),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), width: double.infinity,
              child: Text(tab == 'AI 生成' ? 'AI 生成' : tab, style: TextStyle(fontSize: 13, color: f2)))),
        Expanded(child: ListView(padding: const EdgeInsets.all(10), children: [
          for (int i = 0; i < _chapters.length; i++)
            _chapterItem(_chapters[i]['no'], _chapters[i]['title'], i == _selectedChapter, d, () => setState(() => _selectedChapter = i)),
        ])),
      ]),
    ));
  }

  Widget _chapterItem(String num, String name, bool active, bool d, VoidCallback onTap) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(color: active ? WgTokens.surface : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            SizedBox(width: 30, child: Text(num, style: TextStyle(fontSize: 12, color: active ? WgTokens.accent : f2, fontWeight: FontWeight.w500))),
            Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: active ? (d ? WgTokens.darkFg : WgTokens.fg) : (d ? WgTokens.darkFg2 : WgTokens.fg2)))),
          ]))));
  }

  Widget _tabbar(bool d) {
    return Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        for (int i = 0; i < _tabs.length; i++)
          Padding(padding: const EdgeInsets.only(right: 2), child: _tab(_tabs[i], i == _selectedTab, () => setState(() => _selectedTab = i))),
        const Spacer(),
        Text(widget.world.name, style: TextStyle(fontSize: 12, color: d ? WgTokens.darkFg2 : WgTokens.fg2)),
      ]),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? WgTokens.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: WgTokens.fg.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))] : null),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w500 : FontWeight.w400, color: active ? (d ? WgTokens.darkFg : WgTokens.fg) : (d ? WgTokens.darkFg2 : WgTokens.fg2)))));
  }

  Widget _tabContent(bool d) {
    return Padding(padding: const EdgeInsets.all(24),
      child: IndexedStack(index: _selectedTab, children: [
        _outlineTab(d),
        _charactersTab(d),
        _chaptersTab(d),
        _timelineTab(d),
        _aiTab(d),
      ]),
    );
  }

  Widget _outlineTab(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _outline.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final o = _outline[i];
        final pct = (o['done'] as int) / (o['beats'] as int);
        return WgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: WgTokens.accentSoft, borderRadius: BorderRadius.circular(6)),
              child: Text(o['act'], style: const TextStyle(fontSize: 12, color: WgTokens.accent, fontWeight: FontWeight.w600))),
            const SizedBox(width: 10),
            Expanded(child: Text(o['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg))),
            Text('${o['done']}/${o['beats']} 节拍', style: TextStyle(fontSize: 12, color: f2)),
          ]),
          const SizedBox(height: 10),
          Text(o['summary'], style: TextStyle(fontSize: 13, color: f2, height: 1.6)),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 6,
              backgroundColor: d ? WgTokens.darkBorder : WgTokens.border,
              valueColor: const AlwaysStoppedAnimation<Color>(WgTokens.accent))),
        ]));
      },
    );
  }

  Widget _charactersTab(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SingleChildScrollView(child: Wrap(spacing: 16, runSpacing: 16, children: [
      for (final c in _characters) _characterCard(c, d, f2),
    ]));
  }

  Widget _characterCard(Map<String, dynamic> c, bool d, Color f2) {
    return SizedBox(width: 260, child: WgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 22, backgroundColor: WgTokens.accentSoft, child: Text(c['name'].substring(0, 1), style: const TextStyle(color: WgTokens.accent, fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Expanded(child: Text(c['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: d ? WgTokens.darkFg : WgTokens.fg))),
        WgBadge(c['tag'], type: WgBadgeType.neutral),
      ]),
      const SizedBox(height: 10),
      Text(c['desc'], style: TextStyle(fontSize: 13, color: f2, height: 1.6)),
    ])));
  }

  Widget _chaptersTab(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final ch = _chapters[i];
        final active = i == _selectedChapter;
        return InkWell(onTap: () => setState(() => _selectedChapter = i),
          borderRadius: BorderRadius.circular(WgTokens.radiusLg),
          child: WgCard(borderColor: active ? WgTokens.accent : null, child: Row(children: [
            SizedBox(width: 56, child: Text(ch['no'], style: TextStyle(fontSize: 12, color: f2, fontWeight: FontWeight.w500))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ch['title'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
              const SizedBox(height: 4),
              Text('${ch['words']} 字 · ${ch['date']}', style: TextStyle(fontSize: 12, color: f2)),
            ])),
            _statusBadge(ch['status']),
          ])));
      },
    );
  }

  Widget _timelineTab(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _timeline.length,
      itemBuilder: (ctx, i) {
        final t = _timeline[i];
        final last = i == _timeline.length - 1;
        return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: WgTokens.accent, shape: BoxShape.circle, border: Border.all(color: WgTokens.accentSoft, width: 3))),
            if (!last) Expanded(child: Container(width: 2, color: d ? WgTokens.darkBorder : WgTokens.border)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['time'], style: const TextStyle(fontSize: 12, color: WgTokens.accent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(t['title'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
            const SizedBox(height: 4),
            Text(t['desc'], style: TextStyle(fontSize: 13, color: f2, height: 1.6)),
          ]))),
        ]));
      },
    );
  }

  Widget _aiTab(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return ListView(padding: EdgeInsets.zero, children: [
      WgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI 创作助手', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: d ? WgTokens.darkFg : WgTokens.fg)),
        const SizedBox(height: 6),
        Text('描述你想要的情节、人物或文风，让 AI 给出可落笔的灵感。', style: TextStyle(fontSize: 13, color: f2, height: 1.6)),
        const SizedBox(height: 12),
        WgInput(hintText: '例如：为第 3 章设计一个反转钩子', controller: _promptCtrl),
        const SizedBox(height: 12),
        Row(children: [
          WgButton(label: '生成灵感', icon: Icons.auto_awesome, onTap: () {}),
          const SizedBox(width: 10),
          WgGhostButton(label: '续写本章', icon: Icons.edit_note, onTap: () {}),
        ]),
      ])),
      const SizedBox(height: 16),
      Text('推荐灵感', style: TextStyle(fontSize: 13, color: f2, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      for (final a in _aiItems) ...[
        _aiCard(a, d, f2),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _aiCard(Map<String, dynamic> a, bool d, Color f2) {
    return WgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(a['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: d ? WgTokens.darkFg : WgTokens.fg))),
        WgBadge(a['tag'], type: WgBadgeType.info),
      ]),
      const SizedBox(height: 8),
      Text(a['body'], style: TextStyle(fontSize: 13, color: f2, height: 1.6)),
      const SizedBox(height: 10),
      Row(children: [
        WgGhostButton(label: '采用', small: true, onTap: () {}),
        const SizedBox(width: 8),
        WgGhostButton(label: '改写', small: true, onTap: () {}),
      ]),
    ]));
  }

  Widget _contextPanel(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    final ch = _chapters[_selectedChapter];
    final involved = ['林溪', '沈确', '余溟'];
    final locations = ['旧档案室', '滨海公寓', '家族老宅'];
    return SizedBox(width: 300, child: Container(height: double.infinity,
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.92),
        border: Border(left: BorderSide(color: WgTokens.borderFor(context)))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Row(children: [
            Text('本章上下文', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: d ? WgTokens.darkFg : WgTokens.fg)),
            const Spacer(),
            _statusBadge(ch['status']),
          ])),
        Divider(height: 1, color: WgTokens.border),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          _sectionTitle('当前章节', f2),
          const SizedBox(height: 8),
          Text('${ch['no']} · ${ch['title']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
          const SizedBox(height: 6),
          Text('${ch['words']} 字 · 更新于 ${ch['date']}', style: TextStyle(fontSize: 12, color: f2)),
          const SizedBox(height: 18),
          _sectionTitle('出场人物', f2),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final n in involved) _chip(n, d)]),
          const SizedBox(height: 18),
          _sectionTitle('场景地点', f2),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final n in locations) _chip(n, d)]),
          const SizedBox(height: 18),
          _sectionTitle('写作笔记', f2),
          const SizedBox(height: 8),
          WgCard(child: Text('注意节奏：本章需在结尾埋下反转，但不要过早暴露沈确的身份。', style: TextStyle(fontSize: 13, color: f2, height: 1.6))),
        ])),
      ]),
    ));
  }

  Widget _sectionTitle(String t, Color f2) => Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: f2));

  Widget _chip(String label, bool d) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: d ? WgTokens.darkSurface : WgTokens.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: d ? WgTokens.darkBorderLight : WgTokens.borderLight)),
    child: Text(label, style: TextStyle(fontSize: 12, color: d ? WgTokens.darkFg : WgTokens.fg)));

  Widget _statusBadge(String s) {
    switch (s) {
      case 'done':
        return const WgBadge('已完成', type: WgBadgeType.success);
      case 'review':
        return const WgBadge('审核中', type: WgBadgeType.info);
      case 'draft':
        return const WgBadge('草稿', type: WgBadgeType.accent);
      default:
        return const WgBadge('待写', type: WgBadgeType.neutral);
    }
  }
}
