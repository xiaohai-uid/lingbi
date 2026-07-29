/// 伏笔管理面板 - 跟踪小说中埋设与回收的伏笔
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/writing/data/foreshadowing_service.dart';

class ForeshadowingPanel extends StatefulWidget {
  const ForeshadowingPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ForeshadowingPanel> createState() => _ForeshadowingPanelState();
}

class _ForeshadowingPanelState extends State<ForeshadowingPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<ForeshadowingEntry> _entries = [];
  ForeshadowingStatus? _filterStatus;

  static const _accentColor = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filterStatus = _statusForIndex(_tabController.index);
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ForeshadowingStatus? _statusForIndex(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return ForeshadowingStatus.active;
      case 2:
        return ForeshadowingStatus.resolved;
      case 3:
        return ForeshadowingStatus.overdue;
      default:
        return null;
    }
  }

  Future<void> _load() async {
    try {
      final entries = await ServiceLocator.instance.foreshadowingService
          .listAll(widget.projectId);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ForeshadowingEntry> get _filteredEntries {
    if (_filterStatus == null) return _entries;
    return _entries.where((e) => e.status == _filterStatus).toList();
  }

  int _countByStatus(ForeshadowingStatus status) {
    return _entries.where((e) => e.status == status).length;
  }

  Future<void> _addEntry() async {
    final descriptionController = TextEditingController();
    final plantedController = TextEditingController();
    final payoffController = TextEditingController();
    final weightController = TextEditingController(text: '5');
    final charactersController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.add_circle_outline_rounded,
            color: _accentColor, size: 28),
        title: const Text('添加伏笔'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '伏笔描述',
                    hintText: '这条伏笔的具体内容...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plantedController,
                        decoration: const InputDecoration(
                          labelText: '埋设章节',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: payoffController,
                        decoration: const InputDecoration(
                          labelText: '预期回收章节',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '重要程度 (1-10)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: charactersController,
                  decoration: const InputDecoration(
                    labelText: '相关角色 (逗号分隔)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认添加'),
          ),
        ],
      ),
    );

    if (result == true && descriptionController.text.trim().isNotEmpty) {
      await ServiceLocator.instance.foreshadowingService.create(
        projectId: widget.projectId,
        description: descriptionController.text.trim(),
        plantedChapter: plantedController.text.trim(),
        expectedPayoffChapter: payoffController.text.trim().isNotEmpty
            ? payoffController.text.trim()
            : null,
        relatedCharacters: charactersController.text.trim().isNotEmpty
            ? charactersController.text
                .trim()
                .split(',')
                .map((s) => s.trim())
                .toList()
            : const [],
        notes: notesController.text.trim(),
        weight: int.tryParse(weightController.text.trim()) ?? 5,
      );
      await _load();
    }
  }

  Future<void> _resolveEntry(ForeshadowingEntry entry) async {
    final chapterController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline_rounded,
            color: Color(0xFF059669), size: 28),
        title: const Text('回收伏笔'),
        content: TextField(
          controller: chapterController,
          decoration: const InputDecoration(
            labelText: '回收章节',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认回收'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ServiceLocator.instance.foreshadowingService.resolve(
        projectId: widget.projectId,
        entryId: entry.id,
        resolvedChapter: chapterController.text.trim(),
      );
      await _load();
    }
  }

  Future<void> _deleteEntry(ForeshadowingEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFDC2626), size: 28),
        title: const Text('确认删除'),
        content: Text('确定要删除伏笔「${entry.description}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ServiceLocator.instance.foreshadowingService
          .delete(widget.projectId, entry.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _PanelHeader(
                icon: Icons.auto_stories_rounded,
                title: '伏笔管理',
                accentColor: _accentColor,
                count: _entries.length,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4)
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: _accentColor,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    Tab(text: '全部 (${_entries.length})'),
                    Tab(
                        text:
                            '活跃 (${_countByStatus(ForeshadowingStatus.active)})'),
                    Tab(
                        text:
                            '已回收 (${_countByStatus(ForeshadowingStatus.resolved)})'),
                    Tab(
                        text:
                            '逾期 (${_countByStatus(ForeshadowingStatus.overdue)})'),
                  ],
                ),
              ),
              Expanded(
                child: _filteredEntries.isEmpty
                    ? const _EmptyState(
                        icon: Icons.auto_stories_outlined,
                        message: '暂无伏笔',
                        hint: '点击右下角按钮添加第一条伏笔',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 16),
                        children: _filteredEntries
                            .map((entry) => _EntryCard(
                                  entry: entry,
                                  onResolve: () => _resolveEntry(entry),
                                  onDelete: () => _deleteEntry(entry),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _addEntry,
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加伏笔'),
            backgroundColor: _accentColor,
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.count,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.01,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count 条',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onResolve,
    required this.onDelete,
  });

  final ForeshadowingEntry entry;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                _StatusChip(status: entry.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.bookmark_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '第 ${entry.plantedChapter} 章埋设',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (entry.expectedPayoffChapter != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.flag_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '预期第 ${entry.expectedPayoffChapter} 章回收',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final filled = i < (entry.weight / 2).clamp(0, 5).toInt();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 15,
                  color: filled
                      ? const Color(0xFFD97706)
                      : Theme.of(context).colorScheme.outline,
                );
              }),
            ),
            if (entry.relatedCharacters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.relatedCharacters
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(entry.notes, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (entry.status == ForeshadowingStatus.active ||
                    entry.status == ForeshadowingStatus.overdue) ...[
                  OutlinedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('回收'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: onDelete,
                  tooltip: '删除',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ForeshadowingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(ForeshadowingStatus status) {
    switch (status) {
      case ForeshadowingStatus.active:
        return const Color(0xFF2563EB);
      case ForeshadowingStatus.resolved:
        return const Color(0xFF059669);
      case ForeshadowingStatus.overdue:
        return const Color(0xFFDC2626);
    }
  }

  String _statusLabel(ForeshadowingStatus status) {
    switch (status) {
      case ForeshadowingStatus.active:
        return '活跃';
      case ForeshadowingStatus.resolved:
        return '已回收';
      case ForeshadowingStatus.overdue:
        return '逾期';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  final IconData icon;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
