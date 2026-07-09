import 'package:flutter/material.dart';

import 'package:lingbi/services/butterfly_analyzer.dart';

/// 蝴蝶效应分析对话框可选事件
class ButterflySelectableEvent {
  const ButterflySelectableEvent({required this.id, required this.title});
  final String id;
  final String title;
}

/// 蝴蝶效应分析对话框
///
/// 流程：选择事件 → 填写变更描述 → 调用 [onAnalyze] → 展示结果
/// （剧情走向 + 角色影响列表，支持手动编辑）→ 完成。
class ButterflyAnalysisDialog extends StatefulWidget {
  const ButterflyAnalysisDialog({
    super.key,
    required this.events,
    required this.onAnalyze,
    this.worldName,
  });
  final List<ButterflySelectableEvent> events;
  final Future<ButterflyAnalysisResult> Function(
    String eventId,
    String changeDescription,
  ) onAnalyze;
  final String? worldName;

  @override
  State<ButterflyAnalysisDialog> createState() =>
      _ButterflyAnalysisDialogState();
}

class _ButterflyAnalysisDialogState extends State<ButterflyAnalysisDialog> {
  String? _selectedEventId;
  final TextEditingController _changeCtrl = TextEditingController();
  ButterflyAnalysisResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _changeCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    if (_selectedEventId == null || _changeCtrl.text.trim().isEmpty) {
      setState(() => _error = '请先选择事件并填写变更描述');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await widget.onAnalyze(
        _selectedEventId!,
        _changeCtrl.text.trim(),
      );
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = '分析失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flutter_dash, size: 20),
          const SizedBox(width: 8),
          const Text('蝴蝶效应分析'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: _result == null ? _buildInput() : _buildResult(),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    if (_result != null) {
      return [
        TextButton(
          onPressed: () => setState(() => _result = null),
          child: const Text('重新分析'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_result),
          child: const Text('完成'),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _loading ? null : _runAnalysis,
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('分析'),
      ),
    ];
  }

  Widget _buildInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.worldName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('世界：${widget.worldName}',
                style: Theme.of(context).textTheme.labelSmall),
          ),
        DropdownButtonFormField<String>(
          value: _selectedEventId,
          items: widget.events
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.title)))
              .toList(),
          onChanged: (v) => setState(() => _selectedEventId = v),
          decoration: const InputDecoration(labelText: '选择时间线事件'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _changeCtrl,
          decoration: const InputDecoration(
            labelText: '变更描述',
            hintText: '例如：主角提前得知反派阴谋，改变了原定计划',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('预估消耗',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text('Token: ${r.tokenCost} · 费用估算: \$${r.estimatedCost.toStringAsFixed(4)}'),
          const Divider(height: 20),
          const Text('剧情走向预测',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text(r.predictedDirection.isEmpty
              ? '（无）'
              : r.predictedDirection),
          const Divider(height: 20),
          const Text('角色影响',
              style: TextStyle(fontWeight: FontWeight.w600)),
          if (r.impacts.isEmpty)
            const Text('（无显著角色影响）')
          else
            ...r.impacts.map((impact) => _buildImpactTile(impact)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildImpactTile(CharacterImpact impact) {
    final color = impact.direction == 'positive'
        ? Colors.green
        : impact.direction == 'negative'
            ? Colors.red
            : Colors.grey;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${impact.weightDelta >= 0 ? '+' : ''}${impact.weightDelta}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(impact.characterName),
        subtitle: Text(impact.reason),
      ),
    );
  }
}
