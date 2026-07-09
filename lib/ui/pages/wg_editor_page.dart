import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/settings_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/data/database/world_database.dart' as db_model;
import 'package:lingbi/ui/layout/editor/editor_panel.dart';

/// WgEditorPage — 精确匹配 Open Design editor.html
/// 已集成 flutter_quill 真实编辑器
class WgEditorPage extends StatefulWidget {
  const WgEditorPage({super.key, required this.world});
  final World world;

  @override
  State<WgEditorPage> createState() => _WgEditorPageState();
}

class _WgEditorPageState extends State<WgEditorPage> {
  final DocumentService _documentService =
      ServiceLocator.instance.documentService;
  final SettingsService _settings = ServiceLocator.instance.settingsService;
  final WorldService _worldService = ServiceLocator.instance.worldService;

  int _currentChapter = 0;
  bool _focusMode = false;
  bool _isDark = false;
  bool _showGenFloat = false;
  bool _showShortcuts = false;
  bool _showFind = false;
  String _genMode = 'continue';
  bool _isGenerating = false;
  String _saveStatus = '已自动保存';
  String _editorContent = '';
  db_model.Document? _currentDocument;

  List<db_model.Chapter> _chapters = [];
  bool _loadingChapters = true;

  @override
  void initState() {
    super.initState();
    _isDark = _settings.themeMode == ThemeMode.dark;
    _loadDocument();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _loadingChapters = true);
    try {
      final works = await _worldService.getWorks(widget.world.id);
      if (works.isNotEmpty) {
        final vols = await _worldService.volumeRepository
            .getVolumes(works.first.id, worldId: widget.world.id);
        final allChapters = <db_model.Chapter>[];
        for (final vol in vols) {
          final chs = await _worldService.chapterRepository
              .getChapters(vol.id, worldId: widget.world.id);
          allChapters.addAll(chs);
        }
        allChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        if (mounted) {
          setState(() {
            _chapters = allChapters;
            _loadingChapters = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingChapters = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChapters = false);
    }
  }

  Future<void> _loadDocument() async {
    try {
      final db = await ServiceLocator.instance.databaseManager
          .getDatabase(widget.world.id);
      final docs = await db.select(db.documents).get();
      if (docs.isNotEmpty) {
        final doc = docs.first;
        final content = await _documentService.readContent(doc.filePath);
        if (mounted) {
          setState(() {
            _currentDocument = doc;
            _editorContent = content;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveDocument(String content) async {
    setState(() => _saveStatus = '保存中…');
    try {
      if (_currentDocument != null) {
        await _documentService.writeDocumentContent(
            _currentDocument!.filePath, content);
      } else {
        throw StateError('当前世界没有可保存的文档');
      }
      setState(() => _saveStatus = '已保存');
    } catch (_) {
      setState(() => _saveStatus = '保存失败');
    }
  }

  void _toggleDarkMode() {
    setState(() => _isDark = !_isDark);
    _settings.setThemeMode(_isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final surface = isDark ? const Color(0xFF2C261E) : const Color(0xFFFFFFFF);
    final fg = isDark ? const Color(0xFFE8DDD0) : const Color(0xFF3D3529);
    final fg2 = isDark ? const Color(0xFFA89880) : const Color(0xFF8B7D6B);
    final fg3 = isDark ? const Color(0xFF7A6C5C) : const Color(0xFF8A7B68);
    final border = isDark ? const Color(0xFF332C22) : const Color(0xFFF0EAE0);
    final glassBg = isDark ? const Color(0xD92C261E) : const Color(0xBFFFFFFF);

    return Material(
      child: Stack(
        children: [
          Row(
            children: [
              // TOC left panel
              if (!_focusMode) _buildToc(isDark, fg, fg2, fg3, border, surface),
              // Editor center
              Expanded(
                child: Column(
                  children: [
                    _buildToolbar(isDark, fg2, border, glassBg, surface),
                    _buildVersionBar(),
                    Expanded(
                      child: EditorPanel(
                        initialContent: _editorContent,
                        documentTitle: _currentDocument == null
                            ? '新文档'
                            : (_chapters.isNotEmpty
                                ? _chapters[_currentChapter.clamp(
                                        0, _chapters.length - 1)]
                                    .title
                                : '第一章'),
                        onSave: _saveDocument,
                      ),
                    ),
                    _buildSaveIndicator(isDark, fg3),
                  ],
                ),
              ),
              // Right panel
              if (!_focusMode)
                _buildRightPanel(isDark, fg, fg2, fg3, border, glassBg),
            ],
          ),
          if (_showGenFloat) _buildGenFloat(isDark, fg, border),
          if (_showShortcuts) _buildShortcuts(fg, fg2),
          if (_showFind) _buildFindModal(isDark, border, fg, fg2, fg3),
        ],
      ),
    );
  }

  Widget _buildToc(bool isDark, Color fg, Color fg2, Color fg3, Color border,
      Color surface) {
    return SizedBox(
      width: 220,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
            color: surface, border: Border(right: BorderSide(color: border))),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border))),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                const Text('←',
                    style: TextStyle(color: Color(0xFF8B7D6B), fontSize: 14)),
                const SizedBox(width: 4),
                Text('返回工作区', style: TextStyle(fontSize: 13, color: fg2)),
              ]),
            ),
          ),
          Expanded(
              child: _loadingChapters
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFE8A838))))
                  : _chapters.isEmpty
                      ? const Center(
                          child: Text('暂无章节',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF8A7B68))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _chapters.length,
                          itemBuilder: (_, i) {
                            final c = _chapters[i];
                            final hasSynopsis = c.synopsis.isNotEmpty;
                            final dotColor = hasSynopsis
                                ? const Color(0xFF5B8C5A)
                                : const Color(0xFFE8A838);
                            final label = hasSynopsis ? '已规划' : '待编写';
                            return InkWell(
                              onTap: () => setState(() => _currentChapter = i),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                    color: _currentChapter == i
                                        ? const Color(0x1AE8A838)
                                        : null,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '第${_toChineseNum(c.chapterNumber)}章',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: fg3,
                                              letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text(c.title,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _currentChapter == i
                                                  ? const Color(0xFFE8A838)
                                                  : fg)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                                color: dotColor,
                                                borderRadius:
                                                    BorderRadius.circular(3))),
                                        const SizedBox(width: 6),
                                        Text(label,
                                            style: TextStyle(
                                                fontSize: 11, color: fg3)),
                                      ]),
                                    ]),
                              ),
                            );
                          },
                        )),
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: border))),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Center(
                      child: Text('＋ 添加章节',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8B7D6B))))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildToolbar(
      bool isDark, Color fg2, Color border, Color glassBg, Color surface) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
          color: glassBg, border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        _toolBtn('↩'),
        _toolBtn('↪'),
        _divider(),
        _toolBtn('H1'),
        _toolBtn('H2'),
        _divider(),
        _toolBtn('B'),
        _toolBtn('I'),
        _toolBtn('"'),
        _divider(),
        _toolBtn('—'),
        _toolBtn('✦', color: const Color(0xFFE8A838)),
        const Spacer(),
        InkWell(
          onTap: () => setState(() => _showGenFloat = !_showGenFloat),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('✦',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE8A838))),
              SizedBox(width: 4),
              Text('AI 生成',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3D3529))),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        _toolBtn(_isDark ? '☀' : '☽', onTap: _toggleDarkMode),
        _toolBtn('?', onTap: () => setState(() => _showShortcuts = true)),
        InkWell(
          onTap: () => setState(() => _focusMode = !_focusMode),
          child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: const Text('◻',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A7B68)))),
        ),
      ]),
    );
  }

  Widget _toolBtn(String text, {Color? color, VoidCallback? onTap}) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: color ?? const Color(0xFF8B7D6B)))));
  }

  Widget _divider() => Container(
      width: 1,
      height: 20,
      color: const Color(0xFFE8E0D6),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _buildVersionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      color: const Color(0x1AE8A838),
      child: Row(children: [
        const Text('版本 ',
            style: TextStyle(fontSize: 12, color: Color(0xFF8B7D6B))),
        Text(_saveStatus,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3529))),
        const Spacer(),
        const InkWell(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text('对比历史版本',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B7D6B)))),
        ),
      ]),
    );
  }

  Widget _buildSaveIndicator(bool isDark, Color fg3) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF231E18) : const Color(0xFFF5F0E8),
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? const Color(0xFF332C22)
                      : const Color(0xFFF0EAE0)))),
      child: Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: _saveStatus == '保存中…'
                    ? const Color(0xFFE8A838)
                    : const Color(0xFF5B8C5A),
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(_saveStatus, style: TextStyle(fontSize: 11, color: fg3)),
        const Spacer(),
        Text('字数：${_editorContent.length}',
            style: TextStyle(fontSize: 11, color: fg3)),
      ]),
    );
  }

  Widget _buildRightPanel(bool isDark, Color fg, Color fg2, Color fg3,
      Color border, Color glassBg) {
    return SizedBox(
        width: 280,
        child: Container(
          decoration: BoxDecoration(
              color: glassBg, border: Border(left: BorderSide(color: border))),
          child: SingleChildScrollView(
              child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: border))),
              child: Row(children: [
                _miniStat('${_editorContent.length}', '本章字数'),
                _miniStat('${_editorContent.length ~/ 100}', '全卷总字'),
                _miniStat('${_editorContent.split('\n').length}', '段落'),
                _miniStat('-', 'AI辅助率'),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF231E18)
                      : const Color(0xFFF5F0E8),
                  border: Border(bottom: BorderSide(color: border))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('质量面板'),
                    const SizedBox(height: 12),
                    _qualityBar('情节密度', '-/10', 0, 'low'),
                    const SizedBox(height: 12),
                    _qualityBar('人物深度', '-/10', 0, 'low'),
                    const SizedBox(height: 12),
                    _qualityBar('节奏控制', '-/10', 0, 'low'),
                    const SizedBox(height: 12),
                    _qualityBar('钩子密度', '-/10', 0, 'low'),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: border))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('优化建议'),
                    const SizedBox(height: 12),
                    _suggestion('💡 增加悬念钩子', '本章钩子密度偏低', 'accent'),
                    _suggestion('✍ 人物时刻建议', '陈曦的背景回忆可以再展开', 'info'),
                    _suggestion('📊 风格一致', '第三人称有限视角保持稳定', 'neutral'),
                  ]),
            ),
            Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('AI 操作'),
                      const SizedBox(height: 12),
                      ...[
                        ('✦', '续写'),
                        ('↺', '改写'),
                        ('↗', '扩充'),
                        ('↙', '精简'),
                        ('💬', '对话')
                      ].map((item) => InkWell(
                            onTap: () => setState(() => _showGenFloat = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(children: [
                                Text(item.$1,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0x998B7D6B))),
                                const SizedBox(width: 12),
                                Text(item.$2,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF8B7D6B))),
                              ]),
                            ),
                          )),
                    ])),
          ])),
        ));
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: const TextStyle(
              fontFamily: 'NotoSerifSC',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D3529))),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8A7B68))),
    ]));
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Color(0xFF8A7B68)));

  Widget _qualityBar(String label, String score, double pct, String level) {
    final color = level == 'high'
        ? const Color(0xFF5B8C5A)
        : level == 'med'
            ? const Color(0xFFE8A838)
            : const Color(0xFFC45A5A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B7D6B))),
        Text(score,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrainsMono',
                color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 4,
          color: const Color(0xFFF5F0E8),
          child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Container(color: color)),
        ),
      ),
    ]);
  }

  Widget _suggestion(String title, String desc, String type) {
    final bg = type == 'accent'
        ? const Color(0x1AE8A838)
        : type == 'info'
            ? const Color(0x1A5A8CA0)
            : const Color(0xFFF5F0E8);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3529))),
        const SizedBox(height: 2),
        Text(desc,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF8B7D6B), height: 1.5)),
      ]),
    );
  }

  String _toChineseNum(int n) {
    const cn = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    if (n <= 10) return cn[n];
    if (n < 20) return '十${cn[n - 10]}';
    return n.toString();
  }

  // AI Float, Shortcuts, Find - same as before
  Widget _buildGenFloat(bool isDark, Color fg, Color border) {
    return Positioned(
      right: _focusMode ? 24.0 : 304.0,
      bottom: 24,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C261E) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A3D3529),
                  blurRadius: 48,
                  offset: Offset(0, 12))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('✦ AI 生成',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF3D3529))),
                InkWell(
                    onTap: () => setState(() => _showGenFloat = false),
                    child: const Text('×',
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF8A7B68)))),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _genChip('续写'),
                  _genChip('改写'),
                  _genChip('扩写'),
                  _genChip('对话'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border)),
                  child: const TextField(
                      maxLines: 3,
                      style: TextStyle(fontSize: 13, color: Color(0xFF3D3529)),
                      decoration: InputDecoration(
                          hintText: '输入续写方向（可选）…',
                          hintStyle:
                              TextStyle(fontSize: 13, color: Color(0xFF8A7B68)),
                          border: InputBorder.none,
                          isDense: true))),
              const SizedBox(height: 12),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _genButton('生成', true, _startGeneration),
                    const SizedBox(width: 8),
                    _genButton('取消', false,
                        () => setState(() => _showGenFloat = false)),
                  ]),
              if (_isGenerating) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0x1AE8A838),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFE8A838))),
                    SizedBox(width: 12),
                    Text('AI 正在生成中…',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF8B7D6B))),
                  ]),
                ),
              ],
            ]),
      ),
    );
  }

  Widget _buildShortcuts(Color fg, Color fg2) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showShortcuts = false),
        child: Container(
          color: const Color(0x593D3529),
          child: Center(
              child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('快捷键参考',
                        style: TextStyle(
                            fontFamily: 'NotoSerifSC',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D3529))),
                    const SizedBox(height: 16),
                    ...[
                      (
                        '编辑',
                        [
                          ('粗体', 'Ctrl+B'),
                          ('斜体', 'Ctrl+I'),
                          ('保存', 'Ctrl+S'),
                          ('撤销', 'Ctrl+Z'),
                          ('重做', 'Ctrl+Shift+Z')
                        ]
                      ),
                      ('AI', [('打开 AI 生成', 'Ctrl+.'), ('关闭浮窗', 'Esc')]),
                      (
                        '导航',
                        [
                          ('查找与替换', 'Ctrl+F'),
                          ('专注模式', 'Ctrl+Shift+F'),
                          ('快捷键帮助', 'Ctrl+/')
                        ]
                      ),
                    ].map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.$1,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF8A7B68))),
                              const SizedBox(height: 8),
                              ...g.$2.map((s) => Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: const BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Color(0xFFF0EAE0)))),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(s.$1,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF3D3529))),
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF5F0E8),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFF0EAE0))),
                                              child: Text(s.$2,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily:
                                                          'JetBrainsMono',
                                                      color:
                                                          Color(0xFF8B7D6B)))),
                                        ]),
                                  )),
                            ]))),
                    const SizedBox(height: 16),
                    Center(
                      child: InkWell(
                          onTap: () => setState(() => _showShortcuts = false),
                          child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('关闭',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A7B68))))),
                    ),
                  ]),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildFindModal(
      bool isDark, Color border, Color fg, Color fg2, Color fg3) {
    return Positioned(
      right: 20,
      top: 80,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C261E) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: _findField('查找…')),
            const SizedBox(width: 8),
            Row(
                children: ['▲', '▼', '✕']
                    .map((s) => InkWell(
                          onTap: s == '✕'
                              ? () => setState(() => _showFind = false)
                              : null,
                          child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  border: Border.all(color: border),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(s,
                                  style: TextStyle(fontSize: 11, color: fg2))),
                        ))
                    .toList()),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _findField('替换为…')),
            const SizedBox(width: 8),
            InkWell(
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('替换',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)))),
            ),
          ]),
          const SizedBox(height: 8),
          Text('输入关键词开始查找', style: TextStyle(fontSize: 11, color: fg3)),
        ]),
      ),
    );
  }

  Widget _findField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E0D6))),
      child: TextField(
          style: const TextStyle(fontSize: 13, color: Color(0xFF3D3529)),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF8A7B68)),
              border: InputBorder.none,
              isDense: true)),
    );
  }

  Widget _genChip(String label) {
    final active = _genMode == label;
    return InkWell(
      onTap: () => setState(() => _genMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: active ? const Color(0x1AE8A838) : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: active
                    ? const Color(0xFFE8A838)
                    : const Color(0xFFE8E0D6))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xFFE8A838)
                    : const Color(0xFF8B7D6B))),
      ),
    );
  }

  Widget _genButton(String label, bool primary, VoidCallback onTap) {
    return Expanded(
        child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: primary
            ? BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                borderRadius: BorderRadius.circular(8))
            : BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8E0D6))),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: primary ? FontWeight.w500 : FontWeight.normal,
                color: primary
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF3D3529))),
      ),
    ));
  }

  void _startGeneration() {
    setState(() => _isGenerating = true);
    final aiService = ServiceLocator.instance.aiService;
    aiService.generateNovel('续写当前段落').then((result) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _showGenFloat = false;
        _saveStatus = '已生成';
      });
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('AI 生成结果'),
                content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                        child: Text(result,
                            style:
                                const TextStyle(fontSize: 14, height: 1.6)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('关闭'))
                ],
              ));
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('生成失败: $e')));
    });
  }
}
