import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/core/models/world.dart' show World;
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/ui/pages/wg_editor_page.dart';
import 'package:lingbi/ui/pages/settings_page.dart';

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
        const SizedBox(width: 8),
        Text('/',
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFA89880)
                    : const Color(0xFF8B7D6B))),
        const SizedBox(width: 8),
        Text(widget.world.name,
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFA89880)
                    : const Color(0xFF8B7D6B))),
        const SizedBox(width: 16),
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
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
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
        const SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: const Color(0x1AE8A838),
              borderRadius: BorderRadius.circular(16)),
          child: const Center(
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
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFE8A838)))
          : _works.isEmpty
              ? const Center(
                  child: Text('暂无作品',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A7B68))))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _works.map((work) => _workTreeItem(work)).toList()
                    ..add(
                      InkWell(
                        onTap: _showAddChapterDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
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
              const SizedBox(width: 8),
              const Text('📁', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                const Text('📄', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
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
                  const SizedBox(width: 6),
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
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_works.isEmpty)
        const Padding(
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
                  const SizedBox(width: 8),
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
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D3529))),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8B7D6B), height: 1.5)),
        ],
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
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
      return const Center(
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
          child: const Padding(
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
      const SizedBox(height: 16),
      if (_characters.isEmpty)
        const Padding(
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
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D3529))),
                    const SizedBox(height: 2),
                    Text(role,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A7B68))),
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
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
                              const SizedBox(height: 2),
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
      return const Center(
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
      const SizedBox(height: 16),
      if (_works.isEmpty)
        const Padding(
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
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE8A838)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('故事时间线',
              style: TextStyle(
                  fontFamily: 'NotoSerifSC',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3529)))),
      if (_timelineEvents.isEmpty)
        const Padding(
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
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
                const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 2),
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
          const SizedBox(height: 4),
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
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
              return AlertDialog(
                title: const Text('AI 小说生成'),
                content: SizedBox(
                    width: 450,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('你的灵感',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                              controller: ideaCtrl,
                              decoration: const InputDecoration(
                                  hintText: '例如：一个修仙少年从废材崛起的故事',
                                  border: OutlineInputBorder()),
                              maxLines: 3,
                              autofocus: true),
                          const SizedBox(height: 16),
                          const Text('小说类型',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: genre,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: [
                              '玄幻',
                              '仙侠',
                              '武侠',
                              '奇幻',
                              '都市',
                              '科幻',
                              '悬疑',
                              '历史',
                              '言情',
                              '轻小说'
                            ]
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDlgState(() => genre = v);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('写作风格',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
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
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () {
                        if (ideaCtrl.text.isNotEmpty) {
                          Navigator.pop(ctx);
                          _doGenerate(ideaCtrl.text.trim(), genre, style);
                        }
                      },
                      child: const Text('生成小说')),
                ],
              );
            }));
  }

  void _doGenerate(String idea, String genre, String style) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI 正在创作…'), duration: Duration(seconds: 30)));
    _aiService.generateNovel(idea, genre: genre, style: style).then((result) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showResultDialog(result);
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('生成失败: $e'), backgroundColor: Colors.red.shade400));
      }
    });
  }

  void _showResultDialog(String content) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('AI 生成结果'),
              content: SizedBox(
                  width: 600,
                  height: 400,
                  child: SingleChildScrollView(
                      child: Text(content,
                          style: const TextStyle(fontSize: 14, height: 1.6)))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('关闭'))
              ],
            ));
  }

  void _showAddCharacterDialog() {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('新建角色'),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: '角色名称'),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消')),
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
                    child: const Text('创建')),
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
          .showSnackBar(const SnackBar(content: Text('当前世界还没有可添加章节的作品卷')));
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('新建章节'),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: '章节标题'),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消')),
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
                    child: const Text('创建')),
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
          const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D3529))),
              const SizedBox(height: 4),
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
