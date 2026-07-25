/// StrandWeave 配比设定面板
///
/// 滑块/输入框调整各叙事线比例，管理红线约束。
library;

import 'package:flutter/material.dart';

import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/strand_weave_config.dart';

/// StrandWeave 配比设定面板
class StrandWeavePanel extends StatefulWidget {
  const StrandWeavePanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<StrandWeavePanel> createState() => _StrandWeavePanelState();
}

class _StrandWeavePanelState extends State<StrandWeavePanel> {
  StrandWeaveConfig _config = const StrandWeaveConfig();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config =
        await ServiceLocator.instance.strandWeaveService.loadConfig(
      widget.projectId,
    );
    if (mounted) {
      setState(() {
        _config = config;
        _loading = false;
      });
    }
  }

  Future<void> _saveConfig(StrandWeaveConfig config) async {
    await ServiceLocator.instance.strandWeaveService.saveConfig(
      widget.projectId,
      config,
    );
    if (mounted) setState(() => _config = config);
  }

  Future<void> _updateRatio(String strandName, double newRatio) async {
    final updated =
        await ServiceLocator.instance.strandWeaveService.updateStrandRatio(
      widget.projectId,
      strandName: strandName,
      newRatio: newRatio,
    );
    if (mounted) setState(() => _config = updated);
  }

  Future<void> _addStrand() async {
    final nameController = TextEditingController();
    final ratioController = TextEditingController(text: '0.2');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加叙事线'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ratioController,
              decoration: const InputDecoration(labelText: '比例 (0~1)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      final ratio = double.tryParse(ratioController.text) ?? 0.2;
      final updated =
          await ServiceLocator.instance.strandWeaveService.addStrand(
        widget.projectId,
        name: nameController.text.trim(),
        ratio: ratio.clamp(0.0, 1.0),
      );
      if (mounted) setState(() => _config = updated);
    }
  }

  Future<void> _removeStrand(String name) async {
    final updated =
        await ServiceLocator.instance.strandWeaveService.removeStrand(
      widget.projectId,
      name,
    );
    if (mounted) setState(() => _config = updated);
  }

  Future<void> _addRedLine() async {
    final descController = TextEditingController();
    final strandController = TextEditingController();
    final absenceController = TextEditingController(text: '3');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加红线约束'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: strandController,
              decoration: const InputDecoration(labelText: '叙事线名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '约束描述'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: absenceController,
              decoration: const InputDecoration(labelText: '最大连续缺席章数'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed == true && strandController.text.isNotEmpty) {
      final maxAbsence = int.tryParse(absenceController.text) ?? 3;
      final updated =
          await ServiceLocator.instance.strandWeaveService.addRedLine(
        widget.projectId,
        strandName: strandController.text.trim(),
        description: descController.text.trim().isEmpty
            ? '连续 $maxAbsence 章不得无${strandController.text.trim()}推进'
            : descController.text.trim(),
        maxConsecutiveAbsence: maxAbsence,
      );
      if (mounted) setState(() => _config = updated);
    }
  }

  Future<void> _removeRedLine(String id) async {
    final updated =
        await ServiceLocator.instance.strandWeaveService.removeRedLine(
      widget.projectId,
      id,
    );
    if (mounted) setState(() => _config = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 启用开关
        SwitchListTile(
          title: const Text('启用多线叙事节奏控制'),
          subtitle: const Text('AI 生成时遵守叙事线配比约束'),
          value: _config.enabled,
          onChanged: (v) => _saveConfig(_config.copyWith(enabled: v)),
        ),
        const Divider(),

        // 叙事线配比
        Row(
          children: [
            const Text('叙事线配比',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (!_config.isRatioValid)
              Text(
                '比例总和: ${(_config.totalRatio * 100).round()}%（应为100%）',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '添加叙事线',
              onPressed: _addStrand,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 各叙事线滑块
        for (final strand in _config.strands)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(strand.name,
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Slider(
                    value: strand.ratio.clamp(0.0, 1.0),
                    divisions: 20,
                    label: '${(strand.ratio * 100).round()}%',
                    onChanged: (v) => _updateRatio(strand.name, v),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text('${(strand.ratio * 100).round()}%',
                      textAlign: TextAlign.center),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除',
                  onPressed: () => _removeStrand(strand.name),
                ),
              ],
            ),
          ),

        if (_config.strands.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无叙事线，点击 + 添加',
                style: TextStyle(color: Colors.grey)),
          ),

        const Divider(),

        // 红线约束
        Row(
          children: [
            const Text('红线约束',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '添加红线',
              onPressed: _addRedLine,
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (final rl in _config.redLines)
          ListTile(
            dense: true,
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            title: Text(rl.description),
            subtitle: Text(
                '${rl.strandName} · 最多连续 ${rl.maxConsecutiveAbsence} 章缺席'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeRedLine(rl.id),
            ),
          ),

        if (_config.redLines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无红线约束',
                style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}
