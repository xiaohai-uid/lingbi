/// 变更传播面板
///
/// 设定变更后分析受影响章节 + 生成修复建议 + 批量应用。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/change_propagation_service.dart';

class ChangePropagationPanel extends StatefulWidget {
  const ChangePropagationPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ChangePropagationPanel> createState() =>
      _ChangePropagationPanelState();
}

class _ChangePropagationPanelState extends State<ChangePropagationPanel> {
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _changeDescController = TextEditingController();
  bool _analyzing = false;
  bool _generatingFixes = false;
  ChangeImpactReport? _report;
  List<FixSuggestion>? _suggestions;

  @override
  void dispose() {
    _settingNameController.dispose();
    _changeDescController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImpact() async {
    final name = _settingNameController.text.trim();
    final desc = _changeDescController.text.trim();
    if (name.isEmpty || desc.isEmpty) return;

    setState(() {
      _analyzing = true;
      _report = null;
      _suggestions = null;
    });
    try {
      final report =
          await ServiceLocator.instance.changePropagationService.analyzeImpact(
        projectId: widget.projectId,
        settingId: name.hashCode.toString(),
        settingName: name,
        changeDescription: desc,
      );
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _generateFixes() async {
    if (_report == null) return;
    setState(() => _generatingFixes = true);
    try {
      // 使用空 map — 实际章节内容需从编辑器获取
      final suggestions = await ServiceLocator
          .instance.changePropagationService
          .generateFixSuggestions(
        report: _report!,
        chapterContents: const {},
      );
      if (mounted) setState(() => _suggestions = suggestions);
    } finally {
      if (mounted) setState(() => _generatingFixes = false);
    }
  }

  Color _relevanceColor(double score) {
    if (score >= 0.7) return Colors.red;
    if (score >= 0.4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('变更传播', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _settingNameController,
          decoration: const InputDecoration(
            labelText: '设定名称',
            hintText: '如：主角性格、魔法体系...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _changeDescController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '变更描述',
            hintText: '描述你计划做出的修改...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _analyzing ? null : _analyzeImpact,
          icon: _analyzing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.analytics),
          label: Text(_analyzing ? '分析中...' : '分析影响'),
        ),
        const SizedBox(height: 16),
        if (_report != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        '影响 ${_report!.totalAffected} 个章节 · '
                        '${_report!.affectedLocations.length} 处位置',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_report!.affectedLocations.isEmpty)
                    const Text('未找到受影响的位置')
                  else
                    ..._report!.affectedLocations.take(10).map((loc) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _relevanceColor(loc.relevanceScore),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '章节 ${loc.chapterId} · '
                                      '第${loc.paragraphIndex + 1}段',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    if (loc.excerpt.isNotEmpty)
                                      Text(loc.excerpt,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                  ],
                                ),
                              ),
                              Text(
                                '${(loc.relevanceScore * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _relevanceColor(loc.relevanceScore),
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _generatingFixes ? null : _generateFixes,
            icon: _generatingFixes
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build_outlined),
            label: Text(_generatingFixes ? '生成中...' : '生成修复建议'),
          ),
        ],
        if (_suggestions != null) ...[
          const SizedBox(height: 12),
          Text('修复建议 · ${_suggestions!.length} 条',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_suggestions!.isEmpty)
            const Text('暂无修复建议')
          else
            ..._suggestions!.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '章节 ${s.chapterId} · 第${s.paragraphIndex + 1}段',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(s.originalText,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context).colorScheme.outline,
                            )),
                        const SizedBox(height: 4),
                        Text(s.suggestedText,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.primary)),
                        if (s.reason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(s.reason,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                )),
        ],
      ],
    );
  }
}
