import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:flutter/material.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/character_graph_view.dart';
import 'package:lingbi/ui/components/faction_view.dart';
import 'package:lingbi/ui/components/timeline_view.dart';
import 'package:lingbi/core/models/character_edge.dart';
import '../../data/database/world_database.dart';

/// 世界正典页 — Canon 知识库
///
/// v4.0 替代旧的 CanonPage。
/// 使用 CanonService 操作 Character / Location / Lore / WorldRule。
class CanonPage extends StatefulWidget {
  const CanonPage({
    super.key,
    required this.worldId,
    required this.worldName,
  });
  final String worldId;
  final String worldName;

  @override
  State<CanonPage> createState() => _CanonPageState();
}

class _CanonPageState extends State<CanonPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CanonService _canonService = ServiceLocator.instance.canonService;

  // 各类型条目缓存
  List<Character> _characters = [];
  List<Location> _locations = [];
  List<Lore> _lores = [];
  List<WorldRule> _rules = [];
  List<Faction> _factions = [];
  List<TimelineEvent> _timelineEvents = [];
  List<CharacterEdge> _edges = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _canonService.getCharacters(widget.worldId),
        _canonService.getLocations(widget.worldId),
        _canonService.getLores(widget.worldId),
        _canonService.getRulesForScene(widget.worldId),
      ]);
      if (mounted) {
        _characters = results[0] as List<Character>;
        _locations = results[1] as List<Location>;
        _lores = results[2] as List<Lore>;
        _rules = results[3] as List<WorldRule>;
        final more = await Future.wait([
          ServiceLocator.instance.factionRepository.getFactions(widget.worldId),
          ServiceLocator.instance.worldService.timelineRepository
              .getEvents(widget.worldId),
        ]);
        _factions = more[0] as List<Faction>;
        _timelineEvents = more[1] as List<TimelineEvent>;
        _loading = false;
      }
    } catch (_) {
      if (mounted) _loading = false;
    }
  }

  // ─── 搜索过滤 ───

  List<Character> _filteredCharacters() {
    if (_searchQuery.isEmpty) return _characters;
    final q = _searchQuery.toLowerCase();
    return _characters
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  List<Location> _filteredLocations() {
    if (_searchQuery.isEmpty) return _locations;
    final q = _searchQuery.toLowerCase();
    return _locations
        .where((l) =>
            l.name.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q))
        .toList();
  }

  List<Lore> _filteredLores() {
    if (_searchQuery.isEmpty) return _lores;
    final q = _searchQuery.toLowerCase();
    return _lores
        .where((l) =>
            l.name.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q))
        .toList();
  }

  List<WorldRule> _filteredRules() {
    if (_searchQuery.isEmpty) return _rules;
    final q = _searchQuery.toLowerCase();
    return _rules
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q))
        .toList();
  }

  // ─── 角色表单 ───

  void _showCharacterForm([Character? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '配角');
    final personalityCtrl =
        TextEditingController(text: existing?.personality ?? '');
    final backstoryCtrl =
        TextEditingController(text: existing?.backstory ?? '');
    final motivationCtrl =
        TextEditingController(text: existing?.motivation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑角色' : '新建角色'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '名称'),
                    autofocus: true),
                const SizedBox(height: 8),
                TextField(
                    controller: roleCtrl,
                    decoration:
                        const InputDecoration(labelText: '定位（主角/配角/反派/路人）')),
                const SizedBox(height: 8),
                TextField(
                    controller: personalityCtrl,
                    decoration: const InputDecoration(labelText: '性格'),
                    maxLines: 2),
                const SizedBox(height: 8),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: '描述'),
                    maxLines: 3),
                const SizedBox(height: 8),
                TextField(
                    controller: backstoryCtrl,
                    decoration: const InputDecoration(labelText: '背景故事'),
                    maxLines: 2),
                const SizedBox(height: 8),
                TextField(
                    controller: motivationCtrl,
                    decoration: const InputDecoration(labelText: '动机'),
                    maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (existing != null) {
                await _canonService.updateCharacter(
                  existing.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  personality: personalityCtrl.text.trim(),
                  backstory: backstoryCtrl.text.trim(),
                  motivation: motivationCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                );
              } else {
                await _canonService.createCharacter(
                  worldId: widget.worldId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  personality: personalityCtrl.text.trim(),
                  backstory: backstoryCtrl.text.trim(),
                  motivation: motivationCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(existing != null ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  // ─── 地点表单 ───

  void _showLocationForm([Location? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑地点' : '新建地点'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '名称'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (existing != null) {
                await _canonService.updateLocation(
                  existing.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
              } else {
                await _canonService.createLocation(
                  worldId: widget.worldId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(existing != null ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  // ─── 传说表单 ───

  void _showLoreForm([Lore? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑传说' : '新建传说'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '名称'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 4),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (existing != null) {
                await _canonService.updateLore(
                  existing.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
              } else {
                await _canonService.createLore(
                  worldId: widget.worldId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(existing != null ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  // ─── 世界观规则表单 ───

  void _showRuleForm([WorldRule? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final scopeCtrl = TextEditingController(text: existing?.scope ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑规则' : '新建世界观规则'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '规则名称'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '规则描述'),
                maxLines: 3),
            const SizedBox(height: 12),
            TextField(
                controller: scopeCtrl,
                decoration: const InputDecoration(labelText: '适用场景（可选，留空=全局）')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (existing != null) {
                await _canonService.updateWorldRule(
                  existing.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  scope: scopeCtrl.text.trim().isEmpty
                      ? null
                      : scopeCtrl.text.trim(),
                );
              } else {
                await _canonService.createRule(
                  worldId: widget.worldId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  scope: scopeCtrl.text.trim().isEmpty
                      ? null
                      : scopeCtrl.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(existing != null ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  // ─── 势力表单 ───

  void _showFactionForm([Faction? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    var type = existing?.type ?? 'sect';
    final powerCtrl =
        TextEditingController(text: (existing?.power ?? 50).toString());
    final terrCtrl = TextEditingController(text: existing?.territory ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing != null ? '编辑势力' : '新建势力'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '名称'),
                    autofocus: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'sect', child: Text('宗门')),
                    DropdownMenuItem(value: 'nation', child: Text('国家')),
                    DropdownMenuItem(value: 'clan', child: Text('家族')),
                    DropdownMenuItem(value: 'organization', child: Text('组织')),
                  ],
                  onChanged: (v) => setSt(() => type = v ?? 'sect'),
                  decoration: const InputDecoration(labelText: '类型'),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: powerCtrl,
                    decoration: const InputDecoration(labelText: '实力 (1-100)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                    controller: terrCtrl,
                    decoration: const InputDecoration(labelText: '领地')),
                const SizedBox(height: 8),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: '描述'),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final repo = ServiceLocator.instance.factionRepository;
                final now = DateTime.now();
                if (existing != null) {
                  await repo.updateFaction(
                    existing.id,
                    FactionsCompanion.insert(
                      id: existing.id,
                      worldId: existing.id,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      type: type,
                      power: int.tryParse(powerCtrl.text) ?? 50,
                      territory: terrCtrl.text.trim(),
                      createdAt: now,
                      updatedAt: now,
                    ),
                  );
                } else {
                  await repo.createFaction(
                    widget.worldId,
                    FactionsCompanion.insert(
                      id: 'fac-' + nameCtrl.text.trim().hashCode.toRadixString(16),
                      worldId: widget.worldId,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      type: type,
                      power: int.tryParse(powerCtrl.text) ?? 50,
                      territory: terrCtrl.text.trim(),
                      createdAt: now,
                      updatedAt: now,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: Text(existing != null ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFaction(Faction f) async {
    final confirm = await _showConfirm('确定要删除势力「${f.name}」吗？');
    if (confirm == true) {
      await ServiceLocator.instance.factionRepository
          .deleteFaction(f.id, worldId: widget.worldId);
      _loadData();
    }
  }

  Future<void> _deleteTimelineEvent(TimelineEvent e) async {
    final confirm = await _showConfirm('确定要删除事件「${e.title}」吗？');
    if (confirm == true) {
      final db = await ServiceLocator.instance.databaseManager
          .getDatabase(widget.worldId);
      await (db.delete(db.timelineEvents)..where((t) => t.id.equals(e.id)))
          .go();
      _loadData();
    }
  }

  // ─── 时间线表单 ───

  void _showTimelineForm([TimelineEvent? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final chapterCtrl =
        TextEditingController(text: existing?.chapterAnchor ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑事件' : '新增事件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题'),
                autofocus: true),
            const SizedBox(height: 8),
            TextField(
                controller: chapterCtrl,
                decoration: const InputDecoration(labelText: '章节'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ServiceLocator.instance.worldService.timelineRepository
                  .insertBetween(
                worldId: widget.worldId,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  // ─── 删除确认 ───

  Future<void> _deleteCharacter(Character c) async {
    final confirm = await _showConfirm('确定要删除角色「${c.name}」吗？');
    if (confirm == true) {
      await _canonService.deleteCharacter(c.id);
      _loadData();
    }
  }

  Future<void> _deleteLocation(Location l) async {
    final confirm = await _showConfirm('确定要删除地点「${l.name}」吗？');
    if (confirm == true) {
      await _canonService.deleteLocation(l.id);
      _loadData();
    }
  }

  Future<void> _deleteLore(Lore l) async {
    final confirm = await _showConfirm('确定要删除传说「${l.name}」吗？');
    if (confirm == true) {
      await _canonService.deleteLore(l.id);
      _loadData();
    }
  }

  Future<void> _deleteRule(WorldRule r) async {
    final confirm = await _showConfirm('确定要删除规则「${r.name}」吗？');
    if (confirm == true) {
      await _canonService.deleteWorldRule(r.id);
      _loadData();
    }
  }

  Future<bool?> _showConfirm(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ─── UI 构建 ───

  Widget _buildCharacterCard(Character c) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(c.role),
          child: Text(c.name[0], style: const TextStyle(color: Colors.white)),
        ),
        title:
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: c.description.isNotEmpty
            ? Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis)
            : Text('权重: ${c.baseWeight} | ${c.role}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showCharacterForm(c);
            if (v == 'delete') _deleteCharacter(c);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('编辑'),
                    dense: true)),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, size: 18, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    dense: true)),
          ],
        ),
        onTap: () => _showCharacterForm(c),
      ),
    );
  }

  Widget _buildLocationCard(Location l) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.place, size: 20)),
        title:
            Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: l.description.isNotEmpty
            ? Text(l.description, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showLocationForm(l);
            if (v == 'delete') _deleteLocation(l);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('编辑'),
                    dense: true)),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, size: 18, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    dense: true)),
          ],
        ),
        onTap: () => _showLocationForm(l),
      ),
    );
  }

  Widget _buildLoreCard(Lore l) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_stories, size: 20)),
        title:
            Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: l.description.isNotEmpty
            ? Text(l.description, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showLoreForm(l);
            if (v == 'delete') _deleteLore(l);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('编辑'),
                    dense: true)),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, size: 18, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    dense: true)),
          ],
        ),
        onTap: () => _showLoreForm(l),
      ),
    );
  }

  Widget _buildRuleCard(WorldRule r) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.gavel, size: 20)),
        title:
            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: r.description.isNotEmpty
            ? Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showRuleForm(r);
            if (v == 'delete') _deleteRule(r);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit, size: 18),
                    title: Text('编辑'),
                    dense: true)),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, size: 18, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)),
                    dense: true)),
          ],
        ),
        onTap: () => _showRuleForm(r),
      ),
    );
  }

  Widget _buildEntryList(List<Widget> cards) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories,
                size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text('暂无条目', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: cards.length,
      itemBuilder: (ctx, i) => cards[i],
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case '主角':
        return const Color(0xFF4CAF50);
      case '反派':
        return const Color(0xFFF44336);
      case '配角':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? WgTokens.darkBg : WgTokens.bg,
      appBar: AppBar(
        backgroundColor: isDark ? WgTokens.darkSurface : WgTokens.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('${widget.worldName} - 世界正典',
            style: TextStyle(
                color: isDark ? WgTokens.darkFg : WgTokens.fg,
                fontFamily: 'NotoSerifSC',
                fontWeight: FontWeight.w600)),
        iconTheme:
            IconThemeData(color: isDark ? WgTokens.darkFg2 : WgTokens.fg2),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh,
                  color: isDark ? WgTokens.darkFg2 : WgTokens.fg2),
              tooltip: '刷新',
              onPressed: _loadData),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? WgTokens.darkSurface : WgTokens.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isDark ? WgTokens.darkBorder : WgTokens.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索角色、地点、传说、规则...',
                      hintStyle: TextStyle(
                          color: isDark ? WgTokens.darkFg3 : WgTokens.fg3),
                      prefixIcon: Icon(Icons.search,
                          size: 20,
                          color: isDark ? WgTokens.darkFg2 : WgTokens.fg2),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  size: 18,
                                  color:
                                      isDark ? WgTokens.darkFg2 : WgTokens.fg2),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    style: TextStyle(
                        color: isDark ? WgTokens.darkFg : WgTokens.fg,
                        fontSize: 14),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: WgTokens.accent,
                labelColor: WgTokens.accent,
                unselectedLabelColor: isDark ? WgTokens.darkFg3 : WgTokens.fg3,
                tabs: const [
                  Tab(icon: Icon(Icons.person, size: 18), text: '角色'),
                  Tab(icon: Icon(Icons.hub, size: 18), text: '关系图谱'),
                  Tab(icon: Icon(Icons.flag, size: 18), text: '势力'),
                  Tab(icon: Icon(Icons.timeline, size: 18), text: '时间线'),
                  Tab(icon: Icon(Icons.place, size: 18), text: '地点'),
                  Tab(icon: Icon(Icons.auto_stories, size: 18), text: '传说'),
                  Tab(icon: Icon(Icons.gavel, size: 18), text: '规则'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: WgTokens.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEntryList(
                    _filteredCharacters().map(_buildCharacterCard).toList()),
                CharacterGraphView(
                  characters: _characters
                      .map((c) => CharacterLike(id: c.id, name: c.name, role: c.role))
                      .toList(),
                  edges: _edges,
                  onAddEdge: (s, t, type) =>
                      setState(() => _edges.add(CharacterEdge(
                          sourceId: s, targetId: t, type: type))),
                ),
                FactionView(
                  factions: _factions,
                  onAdd: () => _showFactionForm(),
                  onEdit: (f) => _showFactionForm(f),
                  onDelete: _deleteFaction,
                ),
                TimelineView(
                  events: _timelineEvents,
                  onAdd: () => _showTimelineForm(),
                  onEdit: (e) => _showTimelineForm(e),
                  onDelete: _deleteTimelineEvent,
                ),
                _buildEntryList(
                    _filteredLocations().map(_buildLocationCard).toList()),
                _buildEntryList(_filteredLores().map(_buildLoreCard).toList()),
                _buildEntryList(_filteredRules().map(_buildRuleCard).toList()),
              ],
            ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFE8A838), Color(0xFFD49530)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33E8A838), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            final tab = _tabController.index;
            switch (tab) {
              case 0:
                _showCharacterForm();
                break;
              case 1:
                _showFactionForm();
                break;
              case 2:
                _showTimelineForm();
                break;
              case 3:
                _showLocationForm();
                break;
              case 4:
                _showLoreForm();
                break;
              case 5:
                _showRuleForm();
                break;
            }
          },
        ),
      ),
    );
  }
}
