/// 向量知识面板 - 搜索与管理向量化知识库
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/vector_knowledge_service.dart';

class VectorKnowledgePanel extends StatefulWidget {
  const VectorKnowledgePanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<VectorKnowledgePanel> createState() => _VectorKnowledgePanelState();
}

class _VectorKnowledgePanelState extends State<VectorKnowledgePanel> {
  bool _loading = true;
  bool _searching = false;
  bool _rebuilding = false;
  Map<String, int> _stats = {};
  List<RetrievalResult> _results = [];
  final _queryCtrl = TextEditingController();
  VectorEntryType? _typeFilter;

  static const _accentColor = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await ServiceLocator.instance.vectorKnowledgeService
          .getStats(widget.projectId);
      if (mounted) setState(() => _stats = stats);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await ServiceLocator.instance.vectorKnowledgeService
          .search(widget.projectId, q, typeFilter: _typeFilter);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _rebuildIndex() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重建索引'),
        content: const Text('确定要重建向量索引吗？这可能需要一些时间。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _accentColor),
              child: const Text('重建')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _rebuilding = true);
    try {
      await ServiceLocator.instance.vectorKnowledgeService
          .rebuildIndex(widget.projectId);
      await _loadStats();
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
  }

  Future<void> _removeEntry(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除条目'),
        content: const Text('确定要删除此知识条目吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _accentColor),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ServiceLocator.instance.vectorKnowledgeService
        .removeEntry(widget.projectId, id);
    setState(() => _results.removeWhere((r) => r.entry.id == id));
  }

  String _typeLabel(VectorEntryType t) {
    switch (t) {
      case VectorEntryType.canon:
        return '正典';
      case VectorEntryType.chapter:
        return '章节';
      case VectorEntryType.reference:
        return '参考';
      case VectorEntryType.foreshadowing:
        return '伏笔';
      case VectorEntryType.outline:
        return '大纲';
      case VectorEntryType.custom:
        return '自定义';
    }
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PanelHeader(
            icon: Icons.psychology_rounded,
            title: '向量知识库',
            accentColor: _accentColor),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _StatBox(
                  label: '总条目',
                  value: '${_stats['total'] ?? 0}',
                  icon: Icons.storage_rounded,
                  c: _accentColor)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  label: '正典',
                  value: '${_stats['canon'] ?? 0}',
                  icon: Icons.menu_book_rounded,
                  c: _accentColor)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  label: '参考',
                  value: '${_stats['reference'] ?? 0}',
                  icon: Icons.link_rounded,
                  c: _accentColor)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                      hintText: '搜索向量知识库...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search_rounded)),
                  onSubmitted: (_) => _search())),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _searching ? null : _search,
            style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: _searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('搜索'),
          ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              FilterChip(
                  label: const Text('全部'),
                  selected: _typeFilter == null,
                  selectedColor: _accentColor.withValues(alpha: 0.15),
                  checkmarkColor: _accentColor,
                  onSelected: (_) => setState(() => _typeFilter = null)),
              ...VectorEntryType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                        label: Text(_typeLabel(t)),
                        selected: _typeFilter == t,
                        selectedColor: _accentColor.withValues(alpha: 0.15),
                        checkmarkColor: _accentColor,
                        onSelected: (_) => setState(() => _typeFilter = t)),
                  )),
            ])),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _rebuilding ? null : _rebuildIndex,
              icon: _rebuilding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              label: Text(_rebuilding ? '重建中...' : '重建索引'),
            )),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('搜索结果 (${_results.length})',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          ..._results.map((r) {
            final sc = r.score;
            final scColor = sc >= 0.7
                ? const Color(0xFF059669)
                : sc >= 0.4
                    ? const Color(0xFFD97706)
                    : const Color(0xFF6B7280);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _chip(_typeLabel(r.entry.type), _accentColor),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            onPressed: () => _removeEntry(r.entry.id)),
                      ]),
                      const SizedBox(height: 8),
                      Text(r.entry.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.4)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text('相关度',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: sc,
                                    color: scColor,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    minHeight: 6))),
                        const SizedBox(width: 8),
                        Text('${(sc * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scColor)),
                      ]),
                    ]),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.c});

  final String label;
  final String value;
  final IconData icon;
  final Color c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader(
      {required this.icon, required this.title, required this.accentColor});

  final IconData icon;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 22, color: accentColor),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.01)),
    ]);
  }
}
