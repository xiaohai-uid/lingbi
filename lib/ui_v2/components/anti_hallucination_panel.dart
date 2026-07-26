/// 反幻觉面板 - 监督AI生成内容，检测事实性偏差与无根据推断
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/chapter_state_snapshot.dart';
import 'package:lingbi/services/anti_hallucination_service.dart';

class AntiHallucinationPanel extends StatefulWidget {
  const AntiHallucinationPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<AntiHallucinationPanel> createState() => _AntiHallucinationPanelState();
}

class _AntiHallucinationPanelState extends State<AntiHallucinationPanel> {
  bool _loading = true;
  bool _supervising = false;
  final TextEditingController _contentController = TextEditingController();
  SupervisionReport? _report;
  List<Invention>? _inventions;

  static const _accentColor = Color(0xFFDC2626);

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

  Future<void> _runSupervision() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _supervising = true);
    try {
      final report = await ServiceLocator.instance.antiHallucinationService
          .runSupervision(
        projectId: widget.projectId,
        generatedContent: _contentController.text,
      );
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _supervising = false);
    }
  }

  void _detectInventions() {
    if (_contentController.text.trim().isEmpty) return;
    final inventions = ServiceLocator.instance.antiHallucinationService
        .detectInventions(_contentController.text);
    setState(() => _inventions = inventions);
  }

  Color _severityColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.error:
        return const Color(0xFFDC2626);
      case IssueSeverity.warning:
        return const Color(0xFFD97706);
      case IssueSeverity.info:
        return const Color(0xFF2563EB);
    }
  }

  String _severityLabel(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.error:
        return '错误';
      case IssueSeverity.warning:
        return '警告';
      case IssueSeverity.info:
        return '提示';
    }
  }

  Color _consistencyColor(double value) {
    if (value >= 0.8) return const Color(0xFF059669);
    if (value >= 0.5) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PanelHeader(
          icon: Icons.verified_rounded,
          title: '反幻觉监督',
          accentColor: _accentColor,
        ),
        const SizedBox(height: 14),
        _PanelSection(
          title: 'AI 生成内容',
          icon: Icons.paste_rounded,
          accentColor: _accentColor,
          child: TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '粘贴 AI 生成的内容段落',
              hintText: '将需要监督的AI生成内容粘贴到此处...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _supervising ? null : _runSupervision,
                icon: _supervising
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(_supervising ? '监督中...' : '运行监督'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _detectInventions,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('检测虚构内容'),
              ),
            ),
          ],
        ),
        if (_report != null) ...[
          const SizedBox(height: 24),
          _PanelSection(
            title: '一致性评分',
            icon: Icons.donut_large_rounded,
            accentColor: _consistencyColor(_report!.overallConsistency),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _report!.overallConsistency,
                          strokeWidth: 10,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            _consistencyColor(_report!.overallConsistency),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_report!.overallConsistency * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _consistencyColor(
                                  _report!.overallConsistency),
                            ),
                          ),
                          Text(
                            '一致性',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _report!.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (_report!.issues.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionSubheader('发现 ${_report!.issues.length} 个问题'),
            const SizedBox(height: 10),
            ..._report!.issues.map((issue) => _IssueCard(
                  issue: issue,
                  severityColor: _severityColor(issue.severity),
                  severityLabel: _severityLabel(issue.severity),
                )),
          ],
        ],
        if (_inventions != null && _inventions!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _PanelSection(
            title: '虚构内容',
            icon: Icons.auto_fix_high_rounded,
            accentColor: const Color(0xFF7C3AED),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionSubheader(
                    '检测到 ${_inventions!.length} 处可能虚构的内容'),
                const SizedBox(height: 10),
                ..._inventions!
                    .map((invention) => _InventionCard(invention: invention)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.01,
          ),
        ),
      ],
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SectionSubheader extends StatelessWidget {
  const _SectionSubheader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.severityColor,
    required this.severityLabel,
  });

  final SupervisionIssue issue;
  final Color severityColor;
  final String severityLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: severityColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SeverityChip(label: severityLabel, color: severityColor),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    issue.type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (issue.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '位置: ${issue.location}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(issue.description,
                style: Theme.of(context).textTheme.bodyMedium),
            if (issue.suggestion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.suggestion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InventionCard extends StatelessWidget {
  const _InventionCard({required this.invention});

  final Invention invention;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_rounded,
              color: Color(0xFF7C3AED), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invention.content,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '分类: ${invention.category}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
