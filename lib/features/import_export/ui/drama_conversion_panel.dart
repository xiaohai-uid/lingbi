/// 一键成剧面板 - 将小说章节内容转换为分镜剧本
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/import_export/data/drama_conversion_service.dart';

class DramaConversionPanel extends StatefulWidget {
  const DramaConversionPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<DramaConversionPanel> createState() => _DramaConversionPanelState();
}

class _DramaConversionPanelState extends State<DramaConversionPanel> {
  bool _loading = true;
  bool _generating = false;
  VisualStyle _selectedStyle = VisualStyle.guoman;
  final TextEditingController _contentController = TextEditingController();
  DramaConversionResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _generate() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final result = await ServiceLocator.instance.dramaConversionService
          .convert(
        novelText: _contentController.text,
        style: _selectedStyle,
      );
      if (mounted) setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<VisualStyle>(
          initialValue: _selectedStyle,
          decoration: const InputDecoration(
              labelText: '视觉风格', border: OutlineInputBorder()),
          items: VisualStyle.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedStyle = v);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: '源章节内容',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_generating ? '生成中...' : '生成分镜'),
        ),
        if (_result != null && !_result!.isSuccess)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '错误: ${_result!.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_result != null && _result!.isSuccess) ...[
          const SizedBox(height: 24),
          Text('角色卡 (${_result!.characterCards.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._result!.characterCards.map((card) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(card.name[0])),
                  title: Text(card.name),
                  subtitle: Text(card.appearance),
                ),
              )),
          const SizedBox(height: 16),
          Text('分镜 (${_result!.storyboardShots.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._result!.storyboardShots.map((shot) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${shot.shotNumber} ${shot.description}',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(shot.cameraAnnotation),
                      if (shot.dialogue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '对白: ${shot.dialogue}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          Text('场景 (${_result!.scenes.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._result!.scenes.map((scene) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                      '场景${scene.sceneNumber}: ${scene.location}'),
                  subtitle: Text(
                      '${scene.timeOfDay} · ${scene.atmosphere}'),
                ),
              )),
        ],
      ],
    );
  }
}
