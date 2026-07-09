import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'package:lingbi/ui/pages/wg_workspace_page.dart';

/// WgDashboardPage — 精确匹配 Open Design index.html
/// 类名/结构/视觉均与 HTML 一致
class WgDashboardPage extends StatefulWidget {
  const WgDashboardPage({super.key});

  @override
  State<WgDashboardPage> createState() => _WgDashboardPageState();
}

class _WgDashboardPageState extends State<WgDashboardPage> {
  final WorldService _worldService = ServiceLocator.instance.worldService;
  List<World> _worlds = [];
  bool _loading = true;
  bool _onboardingVisible = true;
  final TextEditingController _searchCtrl = TextEditingController();
  int _totalWords = 0;
  int _totalChapters = 0;
  DateTime? _earliestCreation;
  final Map<String, _WorldStat> _worldStats = {};
  final FileService _fileService = ServiceLocator.instance.fileService;

  @override
  void initState() {
    super.initState();
    _loadWorlds();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWorlds() async {
    setState(() => _loading = true);
    try {
      _worlds = await _worldService.listWorlds();
      await _computeStats();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _computeStats() async {
    int words = 0;
    int chapters = 0;
    DateTime? earliestCreated;
    _worldStats.clear();

    for (final world in _worlds) {
      int wChapters = 0;
      int wWords = 0;
      int wCharacters = 0;

      if (earliestCreated == null ||
          world.createdAt.isBefore(earliestCreated)) {
        earliestCreated = world.createdAt;
      }

      try {
        final works = await _worldService.getWorks(world.id);
        for (final work in works) {
          final vols = await _worldService.volumeRepository
              .getVolumes(work.id, worldId: world.id);
          for (final vol in vols) {
            final chs = await _worldService.chapterRepository
                .getChapters(vol.id, worldId: world.id);
            wChapters += chs.length;
          }
        }

        final db = await _worldService.databaseManager.getDatabase(world.id);
        final docs = await db.select(db.documents).get();
        for (final doc in docs) {
          try {
            final file = File(doc.filePath);
            if (await file.exists()) {
              final content = await file.readAsString();
              wWords += _fileService.countWords(content);
            }
          } catch (_) {}
        }

        final chars = await db.select(db.characters).get();
        wCharacters = chars.length;
      } catch (_) {}

      words += wWords;
      chapters += wChapters;
      _worldStats[world.id] = _WorldStat(
          chapters: wChapters, words: wWords, characters: wCharacters);
    }

    _totalWords = words;
    _totalChapters = chapters;
    _earliestCreation = earliestCreated;
  }

  int get _activeCount => _worlds.length;

  Future<void> _createNewWorld() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建项目'),
        content: TextField(
            controller: ctrl,
            decoration:
                const InputDecoration(labelText: '项目名称', hintText: '例如：星穹之下'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) Navigator.pop(ctx, ctrl.text);
              },
              child: const Text('创建')),
        ],
      ),
    );
    if (name != null && mounted) {
      try {
        final world = await _worldService.createWorld(name: name);
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => WgWorkspacePage(world: world)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('创建失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1612) : const Color(0xFFFAF8F5),
      body: Row(
        children: [
          // ═══ Sidebar（左侧栏）═══
          SizedBox(
            width: 240,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2C261E) : const Color(0xFFFFFFFF),
                border: Border(
                    right: BorderSide(
                        color: isDark
                            ? const Color(0xFF332C22)
                            : const Color(0xFFF0EAE0))),
              ),
              child: Column(
                children: [
                  // sidebar-header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: isDark
                                    ? const Color(0xFF332C22)
                                    : const Color(0xFFF0EAE0)))),
                    child: Row(
                      children: [
                        // sidebar-logo-icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33E8A838),
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: const Center(
                              child: Text('✧',
                                  style: TextStyle(
                                      color: Color(0xFFFFFFFF), fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        // sidebar-logo
                        Text('灵笔',
                            style: TextStyle(
                              fontFamily: 'NotoSerifSC',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFE8DDD0)
                                  : const Color(0xFF3D3529),
                            )),
                      ],
                    ),
                  ),
                  // sidebar-search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF231E18)
                            : const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: '搜索项目…',
                          hintStyle:
                              TextStyle(fontSize: 12, color: Color(0xFF8A7B68)),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF3D3529)),
                      ),
                    ),
                  ),
                  // sidebar-nav
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _navItem('◉', '项目总览', true, null),
                        _navItem('◐', '创作模板', false, _createNewWorld),
                        _navItem(
                            '⚙',
                            '设置',
                            false,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // bottom: btn btn-primary "＋ 新建项目"
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: _createNewWorld,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x33E8A838),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: const Center(
                            child: Text('＋ 新建项目',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFFFFFF)))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══ App Main（主区域）═══
          Expanded(
            child: Column(
              children: [
                // topbar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xD92C261E)
                        : const Color(0xBFFFFFFF),
                    border: Border(
                        bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF332C22)
                                : const Color(0xFFF0EAE0))),
                  ),
                  child: Row(
                    children: [
                      // topbar-title
                      Text('项目总览',
                          style: TextStyle(
                              fontFamily: 'NotoSerifSC',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFE8DDD0)
                                  : const Color(0xFF3D3529))),
                      const Spacer(),
                      // topbar-right
                      _iconBtn('🔔'),
                      _iconBtn('?'),
                      const SizedBox(width: 12),
                      // user avatar
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
                    ],
                  ),
                ),

                // app-content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // animate-in welcome
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('欢迎回来',
                                style: TextStyle(
                                    fontFamily: 'NotoSerifSC',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D3529))),
                            SizedBox(height: 4),
                            Text('你的 AI 写作工作室。今天想写什么故事？',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF8B7D6B))),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // stats-grid animate-stagger
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _statCard('📖', '$_activeCount', '进行中作品'),
                            _statCard(
                                '✍', _totalWords.toLocaleString(), '累计字数'),
                            _statCard('⭐', '$_totalChapters', 'AI 生成章节'),
                            _statCard(
                                '⏱',
                                _earliestCreation != null
                                    ? '${DateTime.now().difference(_earliestCreation!).inDays + 1}'
                                    : '0',
                                '创作天数'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // onboarding-bar
                        if (_onboardingVisible)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0x1AE8A838),
                                Color(0x0AFAF8F5)
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0x26E8A838)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFE8A838),
                                      Color(0xFFD49530)
                                    ]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                      child: Text('✦',
                                          style: TextStyle(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 20))),
                                ),
                                const SizedBox(width: 20),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('💡 新功能：AI 时间线生成',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3D3529))),
                                      SizedBox(height: 2),
                                      Text(
                                          '只需输入一句话灵感，灵笔就能自动展开为完整的时间线、人物网络和章节大纲。试试看 →',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF8B7D6B))),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(
                                      () => _onboardingVisible = false),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    child: Text('关闭',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF8B7D6B))),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // section-header + project-list
                        if (_loading)
                          const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(48),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE8A838))))
                        else if (_worlds.isEmpty)
                          _buildEmptyState()
                        else
                          _buildProjectList(isDark),

                        const SizedBox(height: 24),

                        // dashboard-grid: activity + goals
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // activity
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('最近活动',
                                      style: TextStyle(
                                          fontFamily: 'NotoSerifSC',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3D3529))),
                                  const SizedBox(height: 20),
                                  if (_worlds.isEmpty)
                                    const Text('还没有活动记录',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF8A7B68)))
                                  else
                                    ..._worlds
                                        .take(3)
                                        .map((w) => _activityItem(w)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // writing goals
                            SizedBox(
                              width: 320,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('写作目标',
                                      style: TextStyle(
                                          fontFamily: 'NotoSerifSC',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3D3529))),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2C261E)
                                          : const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF332C22)
                                              : const Color(0xFFF0EAE0)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('本周写作进度',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3D3529))),
                                            Text(
                                                '${_totalWords.toLocaleString()} / ${[
                                                  _totalWords,
                                                  5000
                                                ].reduce((a, b) => a > b ? a : b).toLocaleString()} 字',
                                                style: const TextStyle(
                                                    fontFamily: 'JetBrainsMono',
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFE8A838))),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          child: Container(
                                            height: 4,
                                            color: const Color(0xFFF5F0E8),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: _totalWords > 0
                                                  ? (_totalWords /
                                                          [
                                                            _totalWords,
                                                            5000
                                                          ].reduce((a, b) =>
                                                              a > b ? a : b))
                                                      .clamp(0.0, 1.0)
                                                  : 0,
                                              child: Container(
                                                  color:
                                                      const Color(0xFF5B8C5A)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                                child: _goalStat(
                                                    '$_totalChapters', '总章节数')),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: _goalStat(
                                                    _totalChapters > 0
                                                        ? '100%'
                                                        : '-',
                                                    'AI 辅助率')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 导航项 ───
  Widget _navItem(String icon, String label, bool active, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0x1AE8A838) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 16,
                    color: active
                        ? const Color(0xFFE8A838)
                        : const Color(0xFF8B7D6B))),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                  color: active
                      ? const Color(0xFFE8A838)
                      : const Color(0xFF8B7D6B),
                )),
          ],
        ),
      ),
    );
  }

  // ─── 顶栏图标按钮 ───
  Widget _iconBtn(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  // ─── 统计卡片 ───
  Widget _statCard(String icon, String value, String label) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0EAE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0x1AE8A838),
                borderRadius: BorderRadius.circular(8)),
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'NotoSerifSC',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D3529),
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
        ],
      ),
    );
  }

  // ─── 空状态 ───
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: const Column(
        children: [
          Text('📚', style: TextStyle(fontSize: 40)),
          SizedBox(height: 16),
          Text('还没有作品',
              style: TextStyle(
                  fontFamily: 'NotoSerifSC',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3529))),
          SizedBox(height: 8),
          Text('从一句话灵感开始你的第一个故事',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── 项目列表 ───
  Widget _buildProjectList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('你的作品',
                style: TextStyle(
                    fontFamily: 'NotoSerifSC',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3529))),
          ],
        ),
        const SizedBox(height: 20),
        ..._worlds.map((world) {
          return InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WgWorkspacePage(world: world))),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2C261E) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF332C22)
                        : const Color(0xFFF0EAE0)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F3D3529),
                      blurRadius: 24,
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
                        borderRadius: BorderRadius.circular(2),
                      )),
                  const SizedBox(height: 12),
                  Text(world.name,
                      style: const TextStyle(
                          fontFamily: 'NotoSerifSC',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D3529))),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('未分类',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
                    const SizedBox(width: 8),
                    const Text('·',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0x1AE8A838),
                          borderRadius: BorderRadius.circular(999)),
                      child: const Text('连载中',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE8A838))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statText('${_worldStats[world.id]?.chapters ?? 0}', '章'),
                    const SizedBox(width: 16),
                    _statText('${_worldStats[world.id]?.words ?? 0}', '字'),
                    const SizedBox(width: 16),
                    _statText(
                        '${_worldStats[world.id]?.characters ?? 0}', '人物'),
                    const SizedBox(width: 16),
                    _statText('-', '质量分'),
                  ]),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _statText(String value, String label) {
    return Text.rich(TextSpan(
      children: [
        TextSpan(
            text: value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3529),
                fontSize: 12)),
        TextSpan(
            text: ' $label',
            style: const TextStyle(color: Color(0xFF8B7D6B), fontSize: 12)),
      ],
    ));
  }

  // ─── 活动项 ───
  Widget _activityItem(World world) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: const Color(0x1AE8A838),
                    borderRadius: BorderRadius.circular(8)),
                child: const Center(
                    child: Text('📝', style: TextStyle(fontSize: 12))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(world.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D3529))),
                    const SizedBox(height: 2),
                    Text('未分类 · ${_worldStats[world.id]?.chapters ?? 0} 章',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8A7B68))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 写作目标统计 ───
  Widget _goalStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontFamily: 'NotoSerifSC',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3529))),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
      ]),
    );
  }
}

class _WorldStat {
  const _WorldStat(
      {required this.chapters, required this.words, required this.characters});
  final int chapters;
  final int words;
  final int characters;
}

extension on int {
  String toLocaleString() {
    final s = toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
