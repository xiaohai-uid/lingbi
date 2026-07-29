/// 角色关系图谱面板 - 管理小说角色之间的关系网络
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/character_relation_graph_service.dart';

class CharacterRelationPanel extends StatefulWidget {
  const CharacterRelationPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<CharacterRelationPanel> createState() =>
      _CharacterRelationPanelState();
}

class _CharacterRelationPanelState extends State<CharacterRelationPanel> {
  bool _loading = true;
  RelationGraph _graph = const RelationGraph();
  String? _expandedCharacterId;
  final TextEditingController _chapterController = TextEditingController();
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final graph = await ServiceLocator
          .instance.characterRelationGraphService
          .loadGraph(widget.projectId);
      if (mounted) {
        setState(() {
          _graph = graph;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addRelation() async {
    final fromController = TextEditingController();
    final toController = TextEditingController();
    String selectedType = RelationType.family.name;
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加关系'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fromController,
                  decoration: const InputDecoration(
                    labelText: '角色 A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: '角色 B',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: '关系类型',
                    border: OutlineInputBorder(),
                  ),
                  items: RelationType.values
                      .map((t) => DropdownMenuItem(
                          value: t.name, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '关系描述',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
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
      ),
    );

    if (result == true &&
        fromController.text.trim().isNotEmpty &&
        toController.text.trim().isNotEmpty) {
      await ServiceLocator.instance.characterRelationGraphService.addRelation(
        widget.projectId,
        CharacterRelation(
          fromId: fromController.text.trim(),
          toId: toController.text.trim(),
          relationType: RelationType.fromString(selectedType),
          description: descriptionController.text.trim(),
        ),
      );
      await _load();
    }
  }

  Future<void> _extractRelations() async {
    if (_chapterController.text.trim().isEmpty) return;
    setState(() => _extracting = true);
    try {
      final relations = await ServiceLocator
          .instance.characterRelationGraphService
          .extractRelationsFromChapter(
        chapterText: _chapterController.text.trim(),
        chapterIndex: _graph.lastUpdatedChapter + 1,
        knownCharacters: _graph.nodes.map((n) => n.label).toList(),
      );
      if (relations.isNotEmpty) {
        await ServiceLocator.instance.characterRelationGraphService
            .updateFromChapter(
          projectId: widget.projectId,
          chapterIndex: _graph.lastUpdatedChapter + 1,
          newRelations: relations,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 提取完成，发现 ${relations.length} 条关系')),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _deleteRelation(CharacterRelation relation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此关系吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
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
      await ServiceLocator.instance.characterRelationGraphService
          .removeRelation(
        widget.projectId,
        fromId: relation.fromId,
        toId: relation.toId,
      );
      await _load();
    }
  }

  int _relationCount(String characterId) {
    return _graph.edges
        .where((e) => e.relation.involves(characterId))
        .length;
  }

  List<GraphEdge> _characterEdges(String characterId) {
    return _graph.edges
        .where((e) => e.relation.involves(characterId))
        .toList();
  }

  String _nodeLabel(String id) {
    return _graph.nodes
        .where((n) => n.id == id)
        .map((n) => n.label)
        .firstOrNull ??
        id;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chapterController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '输入章节内容以提取关系',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _extracting ? null : _extractRelations,
              icon: _extracting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_extracting ? '提取中...' : 'AI提取关系'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '角色图谱 · ${_graph.nodes.length} 个角色',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _addRelation,
              icon: const Icon(Icons.add_link),
              label: const Text('添加关系'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._graph.nodes.map((node) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child:
                          Text(node.label.isNotEmpty ? node.label[0] : '?'),
                    ),
                    title: Text(node.label,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: node.isProtagonist
                        ? const Text('主角')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_relationCount(node.id)} 条关系',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _expandedCharacterId == node.id
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _expandedCharacterId =
                                  _expandedCharacterId == node.id
                                      ? null
                                      : node.id;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_expandedCharacterId == node.id)
                    _buildRelationList(node.id),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRelationList(String characterId) {
    final edges = _characterEdges(characterId);
    if (edges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text('暂无关系'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          ...edges.map((edge) {
            final r = edge.relation;
            final targetName = r.fromId == characterId
                ? _nodeLabel(r.toId)
                : _nodeLabel(r.fromId);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('$targetName · ${r.relationType.label}'),
              subtitle: r.description.isNotEmpty ? Text(r.description) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _deleteRelation(r),
              ),
            );
          }),
        ],
      ),
    );
  }
}
