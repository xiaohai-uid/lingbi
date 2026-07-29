import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingbi/shared/database/story_beats_repository.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/story_beat.dart';

/// 故事画布 - 可视化情节编排
class StoryCanvasPage extends StatefulWidget {

  const StoryCanvasPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });
  final String projectId;
  final String projectName;

  @override
  State<StoryCanvasPage> createState() => _StoryCanvasPageState();
}

class _StoryCanvasPageState extends State<StoryCanvasPage> {
  final List<StoryBeat> _beats = [];
  StoryBeatsRepository? _repository;

  @override
  void initState() {
    super.initState();
    try {
      _repository = ServiceLocator.instance.storyBeatsRepository;
    } catch (_) {
      _repository = null;
    }
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    List<StoryBeat> beats = [];
    final repo = _repository;
    if (repo != null) {
      try {
        beats = await repo.getBeats(widget.projectId);
      } catch (_) {
        beats = [];
      }
    }

    if (beats.isEmpty) {
      // 播种默认 5 个 beat
      beats = [
        StoryBeat(
          projectId: widget.projectId,
          title: '开场',
          description: '引入主要角色和世界观',
        ),
        StoryBeat(
          projectId: widget.projectId,
          title: '冲突',
          description: '主要冲突浮现',
          colorIndex: 1,
          sequence: 1,
        ),
        StoryBeat(
          projectId: widget.projectId,
          title: '发展',
          description: '情节推进，角色成长',
          colorIndex: 2,
          sequence: 2,
        ),
        StoryBeat(
          projectId: widget.projectId,
          title: '高潮',
          description: '故事最高冲突点',
          colorIndex: 3,
          sequence: 3,
        ),
        StoryBeat(
          projectId: widget.projectId,
          title: '结局',
          description: '冲突解决，收尾',
          colorIndex: 4,
          sequence: 4,
        ),
      ];
      if (repo != null) {
        for (final beat in beats) {
          try {
            await repo.saveBeat(beat);
          } catch (_) {}
        }
      }
    }

    if (mounted) {
      setState(() => _beats.addAll(beats));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} - 故事画布'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加节拍',
            onPressed: _addBeat,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _beats.length,
        // ignore: deprecated_member_use
        onReorder: (oldI, newI) {
          setState(() {
            final item = _beats.removeAt(oldI);
            _beats.insert(newI, item);
          });
          _persistOrder();
        },
        itemBuilder: (ctx, i) {
          final beat = _beats[i];
          return Card(
            key: ValueKey(beat.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _beatColors[beat.colorIndex],
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(beat.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(beat.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editBeat(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteBeat(i),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addBeat() {
    _showBeatDialog(null, (beat) {
      setState(() => _beats.add(beat));
      final repo = _repository;
      if (repo != null) {
        unawaited(repo.saveBeat(beat));
      }
    });
  }

  void _editBeat(int index) {
    _showBeatDialog(_beats[index], (beat) {
      setState(() => _beats[index] = beat);
      final repo = _repository;
      if (repo != null) {
        unawaited(repo.saveBeat(beat));
      }
    });
  }

  void _deleteBeat(int index) {
    final beat = _beats[index];
    setState(() => _beats.removeAt(index));
    final repo = _repository;
    if (repo != null) {
      unawaited(repo.deleteBeat(beat.id));
    }
  }

  void _persistOrder() {
    final repo = _repository;
    if (repo == null) return;
    final beatIds = _beats.map((b) => b.id).toList();
    unawaited(repo.reorderBeats(widget.projectId, beatIds));
  }

  void _showBeatDialog(StoryBeat? existing, void Function(StoryBeat) onSave) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    int selectedColor = existing?.colorIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? '编辑节拍' : '添加节拍'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题', hintText: '例如：英雄登场'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(_beatColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = i),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _beatColors[i],
                        shape: BoxShape.circle,
                        border: selectedColor == i
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  onSave(StoryBeat(
                    id: existing?.id,
                    projectId: widget.projectId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    colorIndex: selectedColor,
                    sequence: existing?.sequence ?? _beats.length,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: Text(existing != null ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}

const _beatColors = [
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFF2196F3),
  Color(0xFFF44336),
  Color(0xFF9C27B0),
];
