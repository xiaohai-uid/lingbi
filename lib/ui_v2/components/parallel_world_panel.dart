/// 平行世界面板 - 管理小说分支剧情线
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/parallel_world_service.dart';

class ParallelWorldPanel extends StatefulWidget {
  const ParallelWorldPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ParallelWorldPanel> createState() => _ParallelWorldPanelState();
}

class _ParallelWorldPanelState extends State<ParallelWorldPanel> {
  bool _loading = true;
  List<StoryBranch> _branches = [];
  String? _expandedBranchId;
  String? _compare1Id;
  String? _compare2Id;
  List<BranchDiffEntry>? _diffResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final branches = await ServiceLocator.instance.parallelWorldService
          .listBranches(widget.projectId);
      if (mounted) {
        setState(() {
          _branches = branches;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBranch() async {
    final nameController = TextEditingController();
    final forkController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建分支'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '分支名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: forkController,
              decoration: const InputDecoration(
                labelText: '分叉点（章节标识）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认创建')),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await ServiceLocator.instance.parallelWorldService.createBranch(
        projectId: widget.projectId,
        name: nameController.text.trim(),
        forkPoint: forkController.text.trim(),
      );
      await _load();
    }
  }

  Future<void> _deleteBranch(StoryBranch branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分支「${branch.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ServiceLocator.instance.parallelWorldService
          .deleteBranch(widget.projectId, branch.id);
      await _load();
    }
  }

  void _showCompareDialog() {
    _compare1Id = null;
    _compare2Id = null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('对比分支'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _compare1Id,
                  decoration: const InputDecoration(
                      labelText: '分支 A', border: OutlineInputBorder()),
                  items: _branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => _compare1Id = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _compare2Id,
                  decoration: const InputDecoration(
                      labelText: '分支 B', border: OutlineInputBorder()),
                  items: _branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => _compare2Id = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('关闭')),
            FilledButton(
              onPressed: _compare1Id != null &&
                      _compare2Id != null &&
                      _compare1Id != _compare2Id
                  ? () {
                      Navigator.of(ctx).pop();
                      _performCompare();
                    }
                  : null,
              child: const Text('开始对比'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCompare() async {
    if (_compare1Id == null || _compare2Id == null) return;
    final diffs = await ServiceLocator.instance.parallelWorldService
        .diffBranches(widget.projectId, _compare1Id!, _compare2Id!);
    if (mounted) setState(() => _diffResult = diffs);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('平行世界 · ${_branches.length} 条分支',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._branches.map((branch) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(branch.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '分叉点: ${branch.forkPoint} · ${branch.status.label}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(branch.createdAt.substring(0, 10),
                                style: Theme.of(context).textTheme.bodySmall),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteBranch(branch),
                            ),
                            IconButton(
                              icon: Icon(
                                _expandedBranchId == branch.id
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  _expandedBranchId =
                                      _expandedBranchId == branch.id
                                          ? null
                                          : branch.id;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_expandedBranchId == branch.id)
                        _buildBranchDetail(branch),
                    ],
                  ),
                )),
            if (_diffResult != null) ...[
              const Divider(),
              Text('差异对比结果',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._diffResult!.map((d) => ListTile(
                    dense: true,
                    leading: Icon(
                      d.type == DiffType.added
                          ? Icons.add_circle_outline
                          : d.type == DiffType.removed
                              ? Icons.remove_circle_outline
                              : d.type == DiffType.modified
                                  ? Icons.edit_outlined
                                  : Icons.check_circle_outline,
                      color: d.type == DiffType.added
                          ? Colors.green
                          : d.type == DiffType.removed
                              ? Colors.red
                              : d.type == DiffType.modified
                                  ? Colors.orange
                                  : Colors.grey,
                    ),
                    title: Text('第 ${d.chapterIndex + 1} 章 · ${d.type.label}'),
                  )),
            ],
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'compare',
                onPressed:
                    _branches.length >= 2 ? _showCompareDialog : null,
                tooltip: '对比分支',
                child: const Icon(Icons.compare_arrows),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'create',
                onPressed: _createBranch,
                tooltip: '创建分支',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchDetail(StoryBranch branch) {
    final snap = branch.snapshot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text('上下文快照',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (snap.characters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('角色: ${snap.characters.join('、')}'),
            ),
          if (snap.settings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('设定: ${snap.settings.join('、')}'),
            ),
          if (snap.plotPoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('剧情节点: ${snap.plotPoints.join(' → ')}'),
            ),
          if (snap.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('摘要: ${snap.summary}'),
            ),
          Text('章节数: ${branch.chapters.length}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
