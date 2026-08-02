/// 去AI味面板
///
/// 检测文本中的 AI 写作痕迹 + 一键改写。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/review/data/de_ai_flavor_service.dart';

class DeAiFlavorPanel extends StatefulWidget {
  const DeAiFlavorPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<DeAiFlavorPanel> createState() => _DeAiFlavorPanelState();
}

class _DeAiFlavorPanelState extends State<DeAiFlavorPanel> {
  final TextEditingController _textController = TextEditingController();
  DetectionResult? _detection;
  bool _rewriting = false;
  List<RewriteResult>? _rewrites;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _detect() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    final result = ServiceLocator.instance.deAiFlavorService.detect(text);
    setState(() {
      _detection = result;
      _rewrites = null;
    });
  }

  Future<void> _rewriteAll() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    setState(() => _rewriting = true);
    try {
      final results =
          await ServiceLocator.instance.deAiFlavorService.rewriteChapter(text);
      if (mounted) setState(() => _rewrites = results);
    } finally {
      if (mounted) setState(() => _rewriting = false);
    }
  }

  void _applyRewrites() {
    if (_rewrites == null || _rewrites!.isEmpty) return;
    final updated = ServiceLocator.instance.deAiFlavorService
        .applyRewrites(_textController.text, _rewrites!);
    setState(() {
      _textController.text = updated;
      _rewrites = null;
      _detection = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('改写已应用')),
    );
  }

  Color _severityColor(String severity) {
    return switch (severity) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('去AI味', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: '待检测文本',
            hintText: '粘贴需要检测的章节文本...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _detect,
              icon: const Icon(Icons.search),
              label: const Text('检测'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _rewriting ? null : _rewriteAll,
              icon: _rewriting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_rewriting ? '改写中...' : '一键改写'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_detection != null) ...[
          _buildScoreCard(),
          const SizedBox(height: 12),
          if (_detection!.hits.isNotEmpty) ...[
            Text('命中详情 · ${_detection!.hits.length} 处',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._detection!.hits.map((hit) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _severityColor(hit.rule.severity),
                      ),
                    ),
                    title: Text(hit.matchedText),
                    subtitle: Text(
                        '第${hit.paragraphIndex + 1}段 · ${hit.rule.description}'),
                    trailing: Text(hit.rule.category,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                )),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text('未检测到 AI 痕迹'),
                  ],
                ),
              ),
            ),
        ],
        if (_rewrites != null && _rewrites!.isNotEmpty) ...[
          const Divider(height: 24),
          Row(
            children: [
              Text('改写结果 · ${_rewrites!.length} 段',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              FilledButton(
                onPressed: _applyRewrites,
                child: const Text('应用改写'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._rewrites!.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('第${r.paragraphIndex + 1}段',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(r.original,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Theme.of(context).colorScheme.outline,
                          )),
                      const SizedBox(height: 4),
                      Text(r.rewritten,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildScoreCard() {
    final score = _detection!.aiScore;
    final color = score >= 60
        ? Colors.red
        : score >= 30
            ? Colors.orange
            : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text('$score',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 味评分',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    score >= 60
                        ? 'AI 痕迹明显，建议改写'
                        : score >= 30
                            ? '存在部分 AI 痕迹'
                            : '文本自然度良好',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '可疑段落: ${_detection!.suspiciousParagraphs.length} 个',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
