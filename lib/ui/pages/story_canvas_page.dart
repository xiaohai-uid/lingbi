import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import '../../core/models/story_beat.dart';
import '../../core/database/story_beats_repository.dart';
import '../../core/di/service_locator.dart';


/// 故事画布 — 可视化情节节拍编排
class StoryCanvasPage extends StatefulWidget {
  final String projectId;

  const StoryCanvasPage({super.key, required this.projectId});

  @override
  State<StoryCanvasPage> createState() => _StoryCanvasPageState();
}

class _StoryCanvasPageState extends State<StoryCanvasPage> {
  late StoryBeatsRepository _repo;
  List<StoryBeat> _beats = [];
  bool _loading = true;

  static const _colors = [
    Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835),
    Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFF8E24AA),
    Color(0xFF00ACC1), Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    _repo = StoryBeatsRepository(storageService: ServiceLocator.instance.storageService);
    _load();
  }

  Future<void> _load() async {
    final beats = await _repo.getBeats(widget.projectId);
    setState(() { _beats = beats; _loading = false; });
  }

  Future<void> _addBeat() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
            SizedBox(height: 8),
            TextField(controller: descCtl, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.s33)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.s81)),
        ],
      ),
    );
    if (result != true || titleCtl.text.trim().isEmpty) return;
    final beat = StoryBeat(
      projectId: widget.projectId,
      title: titleCtl.text.trim(),
      description: descCtl.text.trim(),
      sequence: _beats.length,
      colorIndex: _beats.length % _colors.length,
    );
    await _repo.saveBeat(beat);
    await _load();
  }

  Future<void> _editBeat(StoryBeat beat) async {
    final titleCtl = TextEditingController(text: beat.title);
    final descCtl = TextEditingController(text: beat.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s91),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtl, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
            SizedBox(height: 8),
            TextField(controller: descCtl, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.s33)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.s17)),
        ],
      ),
    );
    if (result != true || titleCtl.text.trim().isEmpty) return;
    beat.title = titleCtl.text.trim();
    beat.description = descCtl.text.trim();
    await _repo.saveBeat(beat);
    await _load();
  }

  Future<void> _deleteBeat(StoryBeat beat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s26),
        content: Text('确定删除"${beat.title}"？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.s33)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(AppLocalizations.of(context)!.s25)),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deleteBeat(beat.id);
    await _load();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _beats.removeAt(oldIndex);
    _beats.insert(newIndex, item);
    for (var i = 0; i < _beats.length; i++) {
      _beats[i].sequence = i;
      await _repo.saveBeat(_beats[i]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.s58),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增节拍',
            onPressed: _addBeat,
          ),
        ],
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator())
        : _beats.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.s66))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _beats.length,
              onReorder: _onReorder,
              itemBuilder: (ctx, i) {
                final beat = _beats[i];
                return Card(
                  key: ValueKey(beat.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colors[beat.colorIndex % _colors.length],
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(beat.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: beat.description.isNotEmpty ? Text(beat.description, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editBeat(beat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _deleteBeat(beat),
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBeat,
        child: const Icon(Icons.add),
      ),
    );
  }
}
