import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_popover.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/core/di/service_locator.dart';

class WgEditorPage extends StatefulWidget {
  const WgEditorPage({super.key});
  @override
  State<WgEditorPage> createState() => _WgEditorPageState();
}

class _WgEditorPageState extends State<WgEditorPage> {
  final _settings = ServiceLocator.instance.settingsService;
  @override
  void initState() { super.initState(); _settings.addListener(_onSettingsChanged); }
  final quill.QuillController _quillCtrl = quill.QuillController.basic();
  final TextEditingController _aiCtrl = TextEditingController();

  final List<Map<String, dynamic>> _toc = const [
    {'level': 1, 'text': '一、旧档案室的味道'},
    {'level': 2, 'text': '失火的痕迹'},
    {'level': 2, 'text': '匿名来信'},
    {'level': 1, 'text': '二、闪回'},
    {'level': 2, 'text': '海边的童年'},
    {'level': 2, 'text': '陌生女人的脸'},
    {'level': 1, 'text': '三、沈确'},
    {'level': 2, 'text': '第一次见面'},
    {'level': 2, 'text': '他知道的太多'},
  ];
  final List<Map<String, dynamic>> _metrics = const [
    {'label': '总体质量', 'score': '92', 'percent': 92.0, 'level': WgQualityLevel.high},
    {'label': '语句流畅', 'score': '88', 'percent': 88.0, 'level': WgQualityLevel.high},
    {'label': '节奏张力', 'score': '74', 'percent': 74.0, 'level': WgQualityLevel.med},
    {'label': '情感浓度', 'score': '61', 'percent': 61.0, 'level': WgQualityLevel.med},
    {'label': '病句预警', 'score': '3 处', 'percent': 30.0, 'level': WgQualityLevel.low},
  ];
  final List<Map<String, String>> _aiSuggestions = const [
    {'title': '续写建议', 'body': '可从“匿名来信”切入，用一句环境描写收束本段，制造悬念。'},
    {'title': '对话润色', 'body': '沈确的台词偏书面，建议口语化以拉近人物距离。'},
  ];

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _quillCtrl.dispose();
    _aiCtrl.dispose();
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
        WgSidebar(items: wgNavItems(context, 'editor')),
        _tocPanel(d),
        Expanded(child: Column(children: [
          _topbar(d),
          _toolbar(d),
          Expanded(child: _editorArea(d)),
        ])),
        _rightPanel(d),
      ]),
    );
  }

  Widget _railItem(IconData ic, Color f2) {
    return Container(width: 40, height: 40, margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: IconButton(icon: Icon(ic, size: 18, color: f2), onPressed: () {}, padding: EdgeInsets.zero));
  }

  Widget _tocPanel(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SizedBox(width: 240, child: Container(height: double.infinity,
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.92),
        border: Border(right: BorderSide(color: WgTokens.borderFor(context)))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('目录', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
            Text('${_toc.length} 节', style: TextStyle(fontSize: 12, color: f2)),
          ])),
        Divider(height: 1, color: WgTokens.border),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _toc.length,
          itemBuilder: (ctx, i) {
            final item = _toc[i];
            final lvl = item['level'] as int;
            return InkWell(onTap: () {}, child: Container(
              padding: EdgeInsets.only(left: 14.0 + (lvl - 1) * 16, right: 14, top: 7, bottom: 7),
              child: Row(children: [
                if (lvl == 1) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: WgTokens.accent, borderRadius: BorderRadius.circular(2))),
                Expanded(child: Text(item['text'], style: TextStyle(fontSize: lvl == 1 ? 13.5 : 12.5, fontWeight: lvl == 1 ? FontWeight.w600 : FontWeight.w400, color: lvl == 1 ? (d ? WgTokens.darkFg : WgTokens.fg) : f2))),
              ])));
          },
        )),
      ]),
    ));
  }

  Widget _rightPanel(bool d) {
    return SizedBox(width: 300, child: Container(height: double.infinity,
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.92),
        border: Border(left: BorderSide(color: WgTokens.borderFor(context)))),
      child: Column(children: [
        _qualityPanel(d),
        Divider(height: 1, color: WgTokens.border),
        Expanded(child: _aiPanel(d)),
      ]),
    ));
  }

  Widget _qualityPanel(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.analytics_outlined, size: 16, color: WgTokens.accent),
        const SizedBox(width: 6),
        Text('写作质量', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: d ? WgTokens.darkFg : WgTokens.fg)),
      ]),
      const SizedBox(height: 12),
      for (final m in _metrics) ...[
        WgQualityBar(percent: m['percent'], label: m['label'], score: m['score'], level: m['level']),
        const SizedBox(height: 10),
      ],
    ]));
  }

  Widget _aiPanel(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_awesome, size: 16, color: WgTokens.accent),
        const SizedBox(width: 6),
        Text('AI 助手', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: d ? WgTokens.darkFg : WgTokens.fg)),
      ]),
      const SizedBox(height: 12),
      WgInput(hintText: '向 AI 提问或下达指令…', controller: _aiCtrl, maxLines: 2),
      const SizedBox(height: 10),
      Row(children: [
        WgButton(label: '发送', icon: Icons.send, small: true, onTap: () {}),
        const SizedBox(width: 8),
        WgGhostButton(label: '润色', small: true, onTap: () {}),
      ]),
      const SizedBox(height: 14),
      Text('智能建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: f2)),
      const SizedBox(height: 10),
      Expanded(child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _aiSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final s = _aiSuggestions[i];
          return WgCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['title']!, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: d ? WgTokens.darkFg : WgTokens.fg)),
            const SizedBox(height: 6),
            Text(s['body']!, style: TextStyle(fontSize: 12.5, color: f2, height: 1.6)),
          ]));
        },
      )),
    ]));
  }

  Widget _topbar(bool d) {
    return Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        Text('第 1 章', style: TextStyle(fontSize: 13, color: d ? WgTokens.darkFg2 : WgTokens.fg2)),
        const SizedBox(width: 12),
        Text('开篇', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC', color: d ? WgTokens.darkFg : WgTokens.fg)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: WgTokens.accentSoft, borderRadius: BorderRadius.circular(6)),
          child: const Text('1,234 字', style: TextStyle(fontSize: 12, color: WgTokens.accent))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0x0D3D3529), borderRadius: BorderRadius.circular(6)),
          child: const Text('AI', style: TextStyle(fontSize: 12, color: WgTokens.fg2))),
      ]),
    );
  }

  Widget _toolbar(bool d) {
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        _toolBtn(Icons.title, f2),
        _toolBtn(Icons.format_size, f2),
        _toolBtn(Icons.format_quote, f2),
        Container(width: 1, height: 18, color: WgTokens.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
        _toolBtn(Icons.format_bold, f2), _toolBtn(Icons.format_italic, f2), _toolBtn(Icons.format_underline, f2),
        Container(width: 1, height: 18, color: WgTokens.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
        _toolBtn(Icons.format_align_left, f2), _toolBtn(Icons.format_align_center, f2), _toolBtn(Icons.format_align_right, f2),
        Container(width: 1, height: 18, color: WgTokens.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
        _toolBtn(Icons.format_list_bulleted, f2), _toolBtn(Icons.format_list_numbered, f2),
        Container(width: 1, height: 18, color: WgTokens.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
        _toolBtn(Icons.comment_outlined, f2),
        const Spacer(),
        _toolBtn(Icons.image, f2), _toolBtn(Icons.link, f2),
      ]),
    );
  }

  Widget _toolBtn(IconData ic, Color f2) {
    return Container(height: 32, margin: const EdgeInsets.only(right: 2),
      child: IconButton(icon: Icon(ic, size: 16, color: f2), onPressed: () {}, padding: const EdgeInsets.symmetric(horizontal: 6), constraints: const BoxConstraints(minWidth: 32)));
  }

  Widget _editorArea(bool d) {
    return Container(
      color: d ? WgTokens.darkSurface : WgTokens.surface,
      child: quill.QuillEditor.basic(
        controller: _quillCtrl,
        config: const quill.QuillEditorConfig(
          placeholder: '开始写作...',
          padding: EdgeInsets.all(24),
        ),
      ),
    );
  }
}
