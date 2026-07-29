/// 六维审稿面板 - 从爽点、一致性、节奏、OOC、连续性、追读力六个维度审稿
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/services/chapter_review_workspace.dart';
import 'package:lingbi/services/six_dimension_review_service.dart';

class SixDimensionReviewPanel extends StatefulWidget {
  const SixDimensionReviewPanel({
    super.key,
    required this.projectId,
    this.projectDirectoryPath,
    this.workspace,
  });

  final String projectId;
  final String? projectDirectoryPath;
  final ChapterReviewWorkspace? workspace;

  @override
  State<SixDimensionReviewPanel> createState() =>
      _SixDimensionReviewPanelState();
}

class _SixDimensionReviewPanelState extends State<SixDimensionReviewPanel> {
  bool _loading = true;
  bool _reviewing = false;
  final TextEditingController _contentController = TextEditingController();
  late ChapterReviewWorkspace? _workspace;
  List<Document> _documents = const [];
  Document? _selectedDocument;
  ReviewReport? _report;
  String? _reportPath;
  String? _error;

  static const _accentColor = Color(0xFFEA580C);

  static const List<_DimensionInfo> _dimensions = [
    _DimensionInfo(ReviewDimension.satisfaction, '爽点', Icons.favorite_rounded,
        Color(0xFFEC4899)),
    _DimensionInfo(ReviewDimension.consistency, '一致性', Icons.sync_alt_rounded,
        Color(0xFF2563EB)),
    _DimensionInfo(
        ReviewDimension.pacing, '节奏', Icons.speed_rounded, Color(0xFFD97706)),
    _DimensionInfo(ReviewDimension.ooc, 'OOC', Icons.person_off_rounded,
        Color(0xFFDC2626)),
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
  void didUpdateWidget(covariant SixDimensionReviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId ||
        oldWidget.projectDirectoryPath != widget.projectDirectoryPath ||
        oldWidget.workspace != widget.workspace) {
      _load();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _report = null;
        _reportPath = null;
      });
    }
    final projectDir = widget.projectDirectoryPath;
    if (widget.workspace == null &&
        (projectDir == null ||
            projectDir.isEmpty ||
            widget.projectId.isEmpty)) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '请先打开一个项目';
        });
      }
      return;
    }
    if (widget.workspace != null) {
      _workspace = widget.workspace;
    } else {
      final locator = ServiceLocator.instance;
      _workspace = ChapterReviewWorkspace(
        projectId: widget.projectId,
        projectDir: projectDir!,
        fileService: locator.fileService,
        reviewService: locator.sixDimensionReviewService,
        store: locator.atomicFileStore,
      );
    }
    try {
      final documents = await _workspace!.listDocuments();
      final selected = documents.firstOrNull;
      final content =
          selected == null ? '' : await _workspace!.readDocument(selected);
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _selectedDocument = selected;
        _contentController.text = content;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载项目文稿失败: $error';
        });
      }
    }
  }

  Future<void> _selectDocument(Document? document) async {
    if (document == null || _reviewing) return;
    setState(() {
      _selectedDocument = document;
      _report = null;
      _reportPath = null;
      _error = null;
    });
    try {
      final content = await _workspace!.readDocument(document);
      if (mounted && _selectedDocument?.id == document.id) {
        setState(() => _contentController.text = content);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '读取文稿失败: $error');
    }
  }

  Future<void> _runReview() async {
    final document = _selectedDocument;
    if (document == null || _contentController.text.trim().isEmpty) return;
    setState(() {
      _reviewing = true;
      _error = null;
    });
    try {
      final result = await _workspace!.reviewSelectedDocument(
        document,
        content: _contentController.text,
      );
      if (mounted) {
        setState(() {
          _report = result.report;
          _reportPath = result.reportPath;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '审稿失败: $error');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Document>(
                key: ValueKey(_selectedDocument?.id),
                initialValue: _selectedDocument,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '选择项目文稿',
                  border: OutlineInputBorder(),
                ),
                items: _documents
                    .map(
                      (document) => DropdownMenuItem(
                        value: document,
                        child: Text(
                          document.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _reviewing ? null : _selectDocument,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '审稿内容',
                  hintText: '项目中尚无可审稿的 Markdown 文稿',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _reviewing ||
                    _selectedDocument == null ||
                    _contentController.text.trim().isEmpty
                ? null
                : _runReview,
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.save_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '报告已保存：${_reportPath ?? ''}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.12),
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
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
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
