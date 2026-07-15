import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/generation/controller.dart';
import 'package:lingbi/services/generation/state_machine.dart';
import 'package:lingbi/core/models/world.dart' show World;
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/ui/components/memory_panel.dart';
import 'package:lingbi/ui/components/style_panel.dart';
import 'package:lingbi/ui/pages/wg_editor_page.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'package:lingbi/ui/components/name_generator_dialog.dart';

/// WgWorkspacePage — 精确匹配 Open Design workspace.html
/// 已对接 v4.0 真实数据 (WorldService)
class WgWorkspacePage extends StatefulWidget {
  const WgWorkspacePage({super.key, required this.world});
  final World world;

  @override
  State<WgWorkspacePage> createState() => _WgWorkspacePageState();
}

class _WgWorkspacePageState extends State<WgWorkspacePage> {
  final WorldService _worldService = ServiceLocator.instance.worldService;
  final CanonService _canonService = ServiceLocator.instance.canonService;
  final AIService _aiService = ServiceLocator.instance.aiService;
  int _selectedTab = 0;
  List<Work> _works = [];
  final Map<String, List<Volume>> _volumes = {};
  final Map<String, List<Chapter>> _chapters = {};
  bool _loadingWorks = true;
  String? _expandedWorkId;
  String? _expandedVolumeId;

  List<Character> _characters = [];
  List<TimelineEvent> _timelineEvents = [];
  bool _loadingTabs = true;

  @override
  void initState() {
    super.initState();
    _loadWorks();
    _loadTabData();
  }

  Future<void> _loadTabData() async {
    setState(() => _loadingTabs = true);
    try {
      _characters = await _canonService.getCharacters(widget.world.id);
      final timelineRepo =
          ServiceLocator.instance.worldService.timelineRepository;
      _timelineEvents = await timelineRepo.getEvents(widget.world.id);
    } catch (_) {}
    if (mounted) setState(() => _loadingTabs = false);
  }

  Future<void> _loadWorks() async {
    setState(() => _loadingWorks = true);
    try {
      _works = await _worldService.getWorks(widget.world.id);
      if (_works.isNotEmpty) {
        _expandedWorkId = _works.first.id;
        await _loadVolumes(_works.first.id);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingWorks = false);
  }

  Future<void> _loadVolumes(String workId) async {
    try {
      final vols = await _worldService.volumeRepository
          .getVolumes(workId, worldId: widget.world.id);
      _volumes[workId] = vols;
      if (vols.isNotEmpty && _expandedVolumeId == null) {
        _expandedVolumeId = vols.first.id;
        await _loadChapters(vols.first.id);
      }
    } catch (_) {
      _volumes[workId] = [];
    }
  }

  Future<void> _loadChapters(String volumeId) async {
    try {
      _chapters[volumeId] = await _worldService.chapterRepository
          .getChapters(volumeId, worldId: widget.world.id);
    } catch (_) {
      _chapters[volumeId] = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF332C22) : const Color(0xFFF0EAE0);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1612) : const Color(0xFFFAF8F5),
      body: Column(
        children: [
          _buildTopbar(isDark),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(isDark, borderColor),
                _buildCenter(isDark),
                _buildRightPanel(isDark, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xD92C261E) : const Color(0xBFFFFFFF),
          border: Border(
              bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF332C22)
                      : const Color(0xFFF0EAE0)))),
      child: Row(children: [
        Text('项目',
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF7A6C5C)
                    : const Color(0xFF8A7B68))),
        SizedBox(width: 8),
        Text('/',
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFA89880)
                    : const Color(0xFF8B7D6B))),
        SizedBox(width: 8),
        Text(widget.world.name,
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFA89880)
                    : const Color(0xFF8B7D6B))),
        SizedBox(width: 16),
        Text('创作工作区',
            style: TextStyle(
                fontFamily: 'NotoSerifSC',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFE8DDD0)
                    : const Color(0xFF3D3529))),
        const Spacer(),
        InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WgEditorPage(world: widget.world))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('✍', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Text('全屏写作',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFFFFF))),
            ]),
          ),
        ),
        SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: const Color(0x1AE8A838),
              borderRadius: BorderRadius.circular(16)),
          child: Center(
              child: Text('吾',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8A838)))),
        ),
      ]),
    );
  }

  // ═══ 1.5.1 Sidebar 适配 World→Work 层次 ═══
  Widget _buildSidebar(bool isDark, Color border) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
          color: isDark ? const Color(0xD92C261E) : const Color(0xBFFFFFFF),
          border: Border(right: BorderSide(color: border))),
      child: _loadingWorks
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFE8A838)))
          : _works.isEmpty
              ? Center(
                  child: Text('暂无作品',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A7B68))))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _works.map((work) => _workTreeItem(work)).toList()
                    ..add(
                      InkWell(
                        onTap: _showAddChapterDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(children: [
                            Text('＋',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFFE8A838))),
                            SizedBox(width: 8),
                            Text('添加章节',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE8A838),
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                ),
    );
  }

  Widget _workTreeItem(Work work) {
    final isExpanded = _expandedWorkId == work.id;
    final vols = _volumes[work.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            if (isExpanded) {
              setState(() => _expandedWorkId = null);
            } else {
              setState(() => _expandedWorkId = work.id);
              if (_volumes[work.id] == null) await _loadVolumes(work.id);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Text(isExpanded ? '▼' : '▶',
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF8A7B68))),
              SizedBox(width: 8),
              const Text('📁', style: TextStyle(fontSize: 13)),
              SizedBox(width: 8),
              Expanded(
                  child: Text(work.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3D3529)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: const Color(0x1AE8A838),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('${vols.length} 卷',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFE8A838))),
              ),
            ]),
          ),
        ),
        if (isExpanded) ...vols.map((vol) => _volumeTreeItem(vol)),
      ],
    );
  }

  Widget _volumeTreeItem(Volume vol) {
    final isExpanded = _expandedVolumeId == vol.id;
    final chs = _chapters[vol.id] ?? [];
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              if (isExpanded) {
                setState(() => _expandedVolumeId = null);
              } else {
                setState(() => _expandedVolumeId = vol.id);
                if (_chapters[vol.id] == null) await _loadChapters(vol.id);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Text(isExpanded ? '▼' : '▶',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF8A7B68))),
                SizedBox(width: 8),
                const Text('📄', style: TextStyle(fontSize: 11)),
                SizedBox(width: 8),
                Expanded(
                    child: Text(vol.title,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8B7D6B)))),
                if (chs.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: const Color(0x1AE8A838),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('${chs.length} 章',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFE8A838))),
                  ),
              ]),
            ),
          ),
          if (isExpanded)
            ...chs.map((ch) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(children: [
                        const Text('📝', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(ch.title,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF8B7D6B)))),
                      ]),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ═══ Center ═══
  Widget _buildCenter(bool isDark) {
    return Expanded(
      child: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _selectedTab == 0
                  ? _buildOutlineTab()
                  : _selectedTab == 1
                      ? _buildCharactersTab()
                      : _selectedTab == 2
                          ? _buildChaptersTab()
                          : _selectedTab == 3
                              ? _buildTimelineTab()
                              : _buildGenerateTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final labels = ['大纲', '角色', '章节', '时间线', 'AI 生成'];
    final totalChapters =
        _chapters.values.fold(0, (sum, list) => sum + list.length);
    final badges = ['', '${_characters.length}', '$totalChapters', '', ''];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF332C22)
                      : const Color(0xFFF0EAE0)))),
      child: Row(
        children: List.generate(labels.length, (i) {
          return InkWell(
            onTap: () => setState(() {
              _selectedTab = i;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: _selectedTab == i
                              ? const Color(0xFFE8A838)
                              : Colors.transparent,
                          width: 2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _selectedTab == i
                            ? const Color(0xFFE8A838)
                            : const Color(0xFF8B7D6B))),
                if (badges[i].isNotEmpty) ...[
                  SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0x1AE8A838),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(badges[i],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE8A838))),
                  ),
                ],
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOutlineTab() {
    if (_loadingTabs) {
      return Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_works.isEmpty)
        Padding(
            padding: EdgeInsets.all(40),
            child: Text('暂无作品',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))))
      else
        ..._works.map((work) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  Text(work.title,
                      style: const TextStyle(
                          fontFamily: 'NotoSerifSC',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D3529))),
                  SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                        color: const Color(0x1AE8A838),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('${_volumes[work.id]?.length ?? 0} 卷',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFE8A838))),
                  ),
                ]),
              ),
              ...(_volumes[work.id] ?? []).expand((vol) => [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 8, 16, 4),
                      child: Text(vol.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8B7D6B))),
                    ),
                    ...(_chapters[vol.id] ?? []).map((ch) => _outlineItem(
                          '第${ch.chapterNumber}章',
                          ch.title,
                          ch.synopsis,
                          ch.id == (_chapters[vol.id]?.first.id ?? ''),
                          ch.synopsis.isNotEmpty ? ['◇ 已规划'] : ['○ 待整理'],
                        )),
                  ]),
            ])),
    ]);
  }

  Widget _outlineItem(
      String num, String title, String desc, bool active, List<String> meta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: Color(0xFFF0EAE0)),
          left: BorderSide(
              color: active ? const Color(0xFFE8A838) : Colors.transparent,
              width: 3),
        ),
        color: active ? const Color(0x1AE8A838) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(num,
            style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: Color(0xFF8A7B68))),
        SizedBox(height: 2),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D3529))),
        if (desc.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8B7D6B), height: 1.5)),
        ],
        if (meta.isNotEmpty) ...[
          SizedBox(height: 8),
          Wrap(
              spacing: 12,
              runSpacing: 4,
              children: meta
                  .map((m) => Text(m,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A7B68))))
                  .toList()),
        ],
      ]),
    );
  }

  Widget _buildCharactersTab() {
    if (_loadingTabs) {
      return Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('人物 · ${widget.world.name}',
            style: const TextStyle(
                fontFamily: 'NotoSerifSC',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3529))),
        InkWell(
          onTap: _showAddCharacterDialog,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('＋',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8B7D6B))),
              SizedBox(width: 4),
              Text('添加人物',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8B7D6B))),
            ]),
          ),
        ),
      ]),
      SizedBox(height: 16),
      if (_characters.isEmpty)
        Padding(
            padding: EdgeInsets.all(40),
            child: Text('暂无角色',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))))
      else
        Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _characters
                .map((c) => _charCard(
                      c.name.isNotEmpty ? c.name[0] : '?',
                      c.name,
                      '${c.role} · 权重${c.baseWeight}',
                      [c.role, c.personality]
                          .where((s) => s.isNotEmpty)
                          .toList(),
                      c.description.isNotEmpty ? c.description : '暂无背景',
                      onTap: () => setState(() {}),
                    ))
                .toList()),
    ]);
  }

  Widget _charCard(
      String avatar, String name, String role, List<String> tags, String arc,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
          width: 300,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0EAE0))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0x1AE8A838), Color(0xFFF5F0E8)]),
                      borderRadius: BorderRadius.circular(28)),
                  child: Center(
                      child: Text(avatar,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSerifSC',
                              color: Color(0xFFE8A838))))),
              SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D3529))),
                    SizedBox(height: 2),
                    Text(role,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A7B68))),
                    SizedBox(height: 8),
                    Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0x1AE8A838),
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text(t,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFE8A838))),
                                ))
                            .toList()),
                    if (arc.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Color(0xFFF0EAE0)))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('背景',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF8A7B68))),
                              SizedBox(height: 2),
                              Text(arc,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF3D3529),
                                      height: 1.5)),
                            ]),
                      ),
                    ],
                  ])),
            ]),
          )),
    );
  }

  Widget _buildChaptersTab() {
    if (_loadingTabs) {
      return Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('章节 · ${widget.world.name}',
            style: const TextStyle(
                fontFamily: 'NotoSerifSC',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3529))),
        InkWell(
            onTap: () => setState(() => _selectedTab = 4),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('✨ AI 生成下一章',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF))))),
      ]),
      SizedBox(height: 16),
      if (_works.isEmpty)
        Padding(
            padding: EdgeInsets.all(40),
            child: Text('暂无章节',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))))
      else
        ..._works.expand((work) => (_volumes[work.id] ?? [])
            .expand((vol) => (_chapters[vol.id] ?? []).map((ch) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0EAE0))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('第${ch.chapterNumber}章 · ${ch.title}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3D3529))),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: ch.synopsis.isNotEmpty
                                          ? const Color(0x1A5B8C5A)
                                          : const Color(0x1AE8A838),
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text(
                                      ch.synopsis.isNotEmpty ? '已规划' : '待编写',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: ch.synopsis.isNotEmpty
                                              ? const Color(0xFF5B8C5A)
                                              : const Color(0xFFE8A838)))),
                            ]),
                      ]),
                )))),
    ]);
  }

  Widget _buildTimelineTab() {
    if (_loadingTabs) {
      return Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('故事时间线',
              style: TextStyle(
                  fontFamily: 'NotoSerifSC',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3529)))),
      if (_timelineEvents.isEmpty)
        Padding(
            padding: EdgeInsets.all(40),
            child: Text('暂无时间线事件',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))))
      else
        ..._timelineEvents.asMap().entries.map((entry) => _TimelineItem(
              time: entry.value.createdAt.toIso8601String().substring(0, 10),
              title: entry.value.title,
              desc: entry.value.description,
              isLast: entry.key == _timelineEvents.length - 1,
            )),
    ]);
  }

  Widget _buildGenerateTab() {
    return SizedBox(
      width: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E0D6))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('输入灵感或指令',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF3D3529))),
              SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E0D6))),
                  child: const TextField(
                      maxLines: 4,
                      style: TextStyle(fontSize: 14, color: Color(0xFF3D3529)),
                      decoration: InputDecoration(
                          hintText: '描述你想生成的内容\n例如：继续写第三章…',
                          hintStyle: TextStyle(color: Color(0xFF8A7B68)),
                          border: InputBorder.none,
                          isDense: true))),
              SizedBox(height: 16),
              Row(children: [
                InkWell(
                    onTap: () {
                      _showGenerateDialog();
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('🚀 开始生成',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFFFFF))))),
                SizedBox(width: 12),
                InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const _SettingsPageProxy())),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E0D6))),
                        child: const Text('⚙ 生成设置',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3D3529))))),
              ]),
              SizedBox(height: 16),
              // ── 记忆上下文面板 ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E0D6)),
                ),
                padding: const EdgeInsets.all(12),
                child: const MemoryPanel(
                  entries: [],
                ),
              ),
              SizedBox(height: 12),
              // ── 文风分析面板 ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E0D6)),
                ),
                padding: const EdgeInsets.all(12),
                child: const StylePanel(),
              ),
              SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['悬疑风格', '心理描写', '快节奏']
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0x1A5A8CA0),
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5A8CA0))),
                          ))
                      .toList()),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══ Right Panel ═══
  Widget _buildRightPanel(bool isDark, Color border) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
          color: isDark ? const Color(0xD92C261E) : const Color(0xBFFFFFFF),
          border: Border(left: BorderSide(color: border))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('作品信息', [
            _field('书名', widget.world.name, bold: true),
            _field(
                '类型',
                widget.world.genres.isNotEmpty
                    ? widget.world.genres.join(' · ')
                    : '未分类'),
            _badgeField('创作状态', '连载中'),
          ]),
          SizedBox(height: 20),
          _section('AI 辅助', [
            InkWell(
              onTap: () => showNameGeneratorDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Text('🎭', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('AI 取名',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF3D3529))),
                  Spacer(),
                  Text('→',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF8A7B68))),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFF8A7B68)))),
      ...children,
    ]);
  }

  Widget _field(String label, String value, {bool bold = false}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
          SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF3D3529),
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        ]));
  }

  Widget _badgeField(String label, String badge) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
          SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0x1AE8A838),
                borderRadius: BorderRadius.circular(999)),
            child: Text(badge,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8A838))),
          ),
        ]));
  }

  void _showGenerateDialog() {
    final ideaCtrl = TextEditingController();
    String genre = '玄幻';
    String style = '起点爆款';
    bool showParams = false;
    double temperature = 0.8;
    double topP = 0.9;
    double repPenalty = 1.1;
    int maxTokens = 8192;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.s1),
                content: SizedBox(
                    width: 450,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('你的灵感',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          TextField(
                              controller: ideaCtrl,
                              decoration: const InputDecoration(
                                  hintText: '例如：一个修仙少年从废材崛起的故事',
                                  border: OutlineInputBorder()),
                              maxLines: 3,
                              autofocus: true),
                          SizedBox(height: 16),
                          const Text('小说类型',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: genre,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: [
                              '玄幻', '仙侠', '武侠', '奇幻', '都市',
                              '科幻', '悬疑', '历史', '言情', '轻小说'
                            ]
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDlgState(() => genre = v);
                            },
                          ),
                          SizedBox(height: 16),
                          const Text('写作风格',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: style,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: ['起点爆款', '番茄爽文', '传统文学', '轻小说']
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDlgState(() => style = v);
                            },
                          ),
                          SizedBox(height: 12),
                          // 参数设置折叠
          InkWell(
            onTap: () => setDlgState(() => showParams = !showParams),
            child: Row(children: [
              Text(showParams ? '▼' : '▶',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8A7B68))),
              SizedBox(width: 8),
              const Text('生成参数',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
            ]),
          ),
          if (showParams) ...[
            SizedBox(height: 8),
            _paramSlider('温度', temperature, 0, 2, (v) => setDlgState(() => temperature = v)),
            _paramSlider('Top-P', topP, 0, 1, (v) => setDlgState(() => topP = v)),
            _paramSlider('重复惩罚', repPenalty, 0, 2, (v) => setDlgState(() => repPenalty = v)),
            _paramSlider('最大长度', maxTokens.toDouble(), 100, 32000, (v) => setDlgState(() => maxTokens = v.toInt())),
          ],
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context)!.s33)),
                  FilledButton(
                      onPressed: () {
                        if (ideaCtrl.text.isNotEmpty) {
                          Navigator.pop(ctx);
                          _doGenerate(ideaCtrl.text.trim(), genre, style);
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.s78)),
                ],
              );
            }));
  }

  void _doGenerate(String idea, String genre, String style) {
    final ctrl = GenerationController();
    ctrl.setInput(GenerationInput(idea: idea, genre: genre, style: style));
    ctrl.startGeneration();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StreamBuilder<GenerationState>(
        stream: ctrl.stateStream,
        builder: (ctx, snapshot) {
          final state = snapshot.data ?? ctrl.currentState;
          final isStreaming = state is GeneratingSynopsisState ||
              state is GeneratingOutlineState ||
              state is GeneratingContentState;
          final content = state is GeneratingSynopsisState
              ? state.meta.streamedContent
              : state is GeneratingOutlineState
                  ? state.meta.streamedContent
                  : '';
          final wordCount = state.streamedWordCount;
          final progressText = state.progressLabel;

          return AlertDialog(
            title: Row(children: [
              if (isStreaming)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFE8A838)),
                ),
              if (isStreaming) SizedBox(width: 12),
              Text(state is CompletedState
                  ? '生成完成'
                  : state is ErrorState
                      ? '生成出错'
                      : 'AI 小说生成'),
            ]),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1AE8A838),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(progressText,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFE8A838))),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: content.isEmpty
                          ? Center(
                              child: Text('等待 AI 输出…',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8A7B68))))
                          : SingleChildScrollView(
                              child: Text(content,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.8)),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(children: [
                    _statChip('📝 $wordCount 字', const Color(0xFFE8A838)),
                    SizedBox(width: 8),
                    if (isStreaming)
                      _statChip('⏳ 生成中…', const Color(0xFF5B8C5A)),
                    if (state is CompletedState)
                      _statChip('✅ 完成', const Color(0xFF5B8C5A)),
                    if (state is ErrorState)
                      _statChip('❌ ${state.error.message}',
                          const Color(0xFFD4856B)),
                  ]),
                ],
              ),
            ),
            actions: [
              if (isStreaming)
                TextButton(
                  onPressed: () {
                    ctrl.cancel();
                    Navigator.pop(ctx);
                  },
                  child: const Text('取消生成',
                      style: TextStyle(color: Color(0xFFE8A838))),
                ),
              if (state is CompletedState)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showResultDialog(state.result.chapters.isNotEmpty
                        ? state.result.chapters.first.content
                        : '生成完成');
                  },
                  child: const Text('查看结果',
                      style: TextStyle(color: Color(0xFFE8A838))),
                ),
              if (state is ErrorState)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _doGenerate(idea, genre, style);
                  },
                  child: const Text('重试',
                      style: TextStyle(color: Color(0xFFE8A838))),
                ),
              if (state is CancelledState)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.s22),
                ),
            ],
          );
        },
      ),
    );

    _aiService.generateNovel(idea, genre: genre, style: style).then((result) {
      if (!mounted) return;
      final chunks = <String>[];
      for (var i = 0; i < result.length; i += 20) {
        chunks.add(result.substring(
            i, i + 20 > result.length ? result.length : i + 20));
      }
      var idx = 0;
      Future.doWhile(() async {
        if (idx >= chunks.length || ctrl.currentState is CancelledState) {
          return false;
        }
        ctrl.streamChunk(chunks[idx]);
        idx++;
        await Future.delayed(const Duration(milliseconds: 30));
        return true;
      }).then((_) {
        if (ctrl.currentState is! CancelledState &&
            ctrl.currentState is! ErrorState) {
          ctrl.phaseComplete(SynopsisResult(
            synopsis: result,
            characters: [
              const CharacterBrief(
                  name: '主角')
            ],
          ));
          ctrl.completeAll(NovelResult(
            synopsis: SynopsisResult(
              synopsis: result,
              characters: [
                const CharacterBrief(
                    name: '主角')
              ],
            ),
            outline: const OutlineResult(),
            chapters: [
              ChapterContent(
                  number: 1,
                  title: '第一章',
                  content: result,
                  wordCount: result.length,
                  generatedAt: DateTime.now().millisecondsSinceEpoch)
            ],
          ));
        }
      });
    }).catchError((e) {
      ctrl.error(GenerationError(
          code: 'UNKNOWN', message: e.toString(), retryable: true));
    });
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _paramSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 100,
            activeColor: const Color(0xFFE8A838),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(value.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE8A838),
                  fontFamily: 'JetBrainsMono')),
        ),
      ]),
    );
  }

  void _showResultDialog(String content) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.s2),
              content: SizedBox(
                  width: 600,
                  height: 400,
                  child: SingleChildScrollView(
                      child: Text(content,
                          style: const TextStyle(fontSize: 14, height: 1.6)))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.s22))
              ],
            ));
  }

  void _showAddCharacterDialog() {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.s63),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: '角色名称'),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.s33)),
                FilledButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        ServiceLocator.instance.canonService.createCharacter(
                            worldId: widget.world.id,
                            name: ctrl.text.trim(),
                            backstory: '',
                            motivation: '');
                        Navigator.pop(ctx);
                        setState(() => _loadTabData());
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.s24)),
              ],
            ));
  }

  void _showAddChapterDialog() {
    final firstWork = _works.isNotEmpty ? _works.first : null;
    final firstVolume = firstWork == null
        ? null
        : (_volumes[firstWork.id]?.isNotEmpty == true
            ? _volumes[firstWork.id]!.first
            : null);
    if (firstWork == null || firstVolume == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.s47)));
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.s62),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: '章节标题'),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.s33)),
                FilledButton(
                    onPressed: () async {
                      final title = ctrl.text.trim();
                      if (title.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await _worldService.createChapterWithDocument(
                          worldId: widget.world.id,
                          workId: firstWork.id,
                          volumeId: firstVolume.id,
                          title: title,
                        );
                        await _loadChapters(firstVolume.id);
                        if (mounted) setState(() {});
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('创建章节失败: $e')));
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.s24)),
              ],
            ));
  }
}

// ─── Timeline Item Widget ───
class _TimelineItem extends StatelessWidget {
  const _TimelineItem(
      {required this.time,
      required this.title,
      required this.desc,
      this.isLast = false});
  final String time;
  final String title;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 24,
              child: Column(children: [
                Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: const Color(0x1AE8A838),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE8A838), width: 2))),
                if (!isLast)
                  Expanded(
                      child:
                          Container(width: 2, color: const Color(0xFFE8E0D6))),
              ])),
          SizedBox(width: 12),
          Expanded(
              child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0EAE0))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(time,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
              SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D3529))),
              SizedBox(height: 4),
              Text(desc,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8B7D6B))),
            ]),
          )),
        ],
      ),
    );
  }
}

class _SettingsPageProxy extends StatelessWidget {
  const _SettingsPageProxy();
  @override
  Widget build(BuildContext context) => const SettingsPage();
}
