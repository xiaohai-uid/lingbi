/// 六维审稿面板 - 从爽点、一致性、节奏、OOC、连续性、追读力六个维度审稿
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/six_dimension_review_service.dart';

class SixDimensionReviewPanel extends StatefulWidget {
  const SixDimensionReviewPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<SixDimensionReviewPanel> createState() =>
      _SixDimensionReviewPanelState();
}

class _SixDimensionReviewPanelState extends State<SixDimensionReviewPanel> {
  bool _loading = true;
  bool _reviewing = false;
  final TextEditingController _contentController = TextEditingController();
  ReviewReport? _report;

  static const _accentColor = Color(0xFFEA580C);

  static const List<_DimensionInfo> _dimensions = [
    _DimensionInfo(ReviewDimension.satisfaction, '爽点', Icons.favorite_rounded,
        Color(0xFFEC4899)),
    _DimensionInfo(ReviewDimension.consistency, '一致性', Icons.sync_alt_rounded,
        Color(0xFF2563EB)),
    _DimensionInfo(
        ReviewDimension.pacing, '节奏', Icons.speed_rounded, Color(0xFFD97706)),
    _DimensionInfo(
        ReviewDimension.ooc, 'OOC', Icons.person_off_rounded, Color(0xFFDC2626)),
    _DimensionInfo(ReviewDimension.continuity, '连续性', Icons.link_rounded,
        Color(0xFF0891B2)),
    _DimensionInfo(ReviewDimension.readability, '追读力',
        Icons.trending_up_rounded, Color(0xFF7C3AED)),
  ];

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

  Future<void> _runReview() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _reviewing = true);
    try {
      final report = await ServiceLocator.instance.sixDimensionReviewService
          .review(
        chapterId: widget.projectId,
        content: _contentController.text,
      );
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 8) return const Color(0xFF059669);
    if (score >= 5) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PanelHeader(
          icon: Icons.rate_review_rounded,
          title: '六维审稿',
          accentColor: _accentColor,
        ),
        const SizedBox(height: 14),
        _PanelSection(
          title: '章节内容',
          icon: Icons.text_fields_rounded,
          accentColor: _accentColor,
          child: TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '粘贴待审稿的章节内容',
              hintText: '将章节全文粘贴到此处...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _reviewing ? null : _runReview,
            icon: _reviewing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rate_review_rounded),
            label: Text(_reviewing ? '审稿中...' : '开始审稿'),
          ),
        ),
        if (_report != null) ...[
          const SizedBox(height: 24),
          _PanelSection(
            title: '综合评分',
            icon: Icons.emoji_events_rounded,
            accentColor: _scoreColor(_report!.overallScore),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      '${_report!.overallScore}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(_report!.overallScore),
                        height: 1,
                        letterSpacing: -0.02,
                      ),
                    ),
                    Text(
                      '/ 10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _scoreColor(_report!.overallScore),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                if (_report!.summary.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scoreColor(_report!.overallScore)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _report!.summary,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionSubheader('六维度评分'),
          const SizedBox(height: 10),
          ..._dimensions.map((dim) {
            final score = _report!.scores
                .where((s) => s.dimension == dim.dimension)
                .firstOrNull;
            if (score == null) return const SizedBox.shrink();
            return _DimensionScoreRow(dimension: dim, score: score);
          }),
          if (_report!.fixSuggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            _PanelSection(
              title: '修改建议',
              icon: Icons.lightbulb_rounded,
              accentColor: const Color(0xFF2563EB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _report!.fixSuggestions.asMap().entries.map(
                  (entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF2563EB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
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

class _DimensionScoreRow extends StatelessWidget {
  const _DimensionScoreRow({
    required this.dimension,
    required this.score,
  });

  final _DimensionInfo dimension;
  final DimensionScore score;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(score.score);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(dimension.icon, size: 18, color: dimension.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dimension.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                '${score.score}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: scoreColor,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '/ 10',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.score / 10).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),
          if (score.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              score.comment,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (score.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...score.issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: _issueColor(issue.severity),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.description,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                            if (issue.suggestion.isNotEmpty)
                              Text(
                                '建议: ${issue.suggestion}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 8) return const Color(0xFF059669);
    if (score >= 5) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _issueColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class _DimensionInfo {
  const _DimensionInfo(this.dimension, this.label, this.icon, this.color);

  final ReviewDimension dimension;
  final String label;
  final IconData icon;
  final Color color;
}
