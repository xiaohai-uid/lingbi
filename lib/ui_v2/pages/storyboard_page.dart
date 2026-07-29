import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/story_beat.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class StoryboardPage extends StatefulWidget {

  const StoryboardPage({super.key, this.projectId});
  final String? projectId;

  @override
  State<StoryboardPage> createState() => _StoryboardPageState();
}

class _StoryboardPageState extends State<StoryboardPage> {
  List<StoryBeat> _beats = [];
  bool _loading = false;

  static const _beatColors = [
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) _loadData();
  }

  @override
  void didUpdateWidget(covariant StoryboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId && widget.projectId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final pid = widget.projectId;
    if (pid == null) return;
    setState(() => _loading = true);
    try {
      final beats = await ServiceLocator.instance.storyBeatsRepository
          .getBeats(pid);
      if (mounted) {
        setState(() {
          _beats = beats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBeatGrid(c),
        ),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Row(
        children: [
          Text(
            '故事画板',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: -0.625 / 26 * 26,
            ),
          ),
          const Spacer(),
          _buildActionChip(c, LingBiIcons.add, '添加节拍', _showAddDialog),
          const SizedBox(width: LingBiTokens.space2),
          _buildActionChip(c, LingBiIcons.filter, '筛选', null),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    LingBiColors c,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.fgSecondary,
        side: BorderSide(color: c.borderOpaque),
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBeatGrid(LingBiColors c) {
    if (_beats.isEmpty) {
      return Center(
        child: Text(
          '暂无节拍，点击"添加节拍"开始',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        0,
        LingBiTokens.space6,
        LingBiTokens.space6,
      ),
      itemCount: _beats.length,
      itemBuilder: (context, index) =>
          _buildBeatCard(_beats[index], index, c),
    );
  }

  Color _colorForBeat(StoryBeat beat) {
    return _beatColors[beat.colorIndex % _beatColors.length];
  }

  String _phaseForBeat(int index, int total) {
    if (index == 0) return '开端';
    if (index == total - 1) return '结尾';
    return '发展';
  }

  Widget _buildBeatCard(StoryBeat beat, int index, LingBiColors c) {
    final color = _colorForBeat(beat);
    final phase = _phaseForBeat(index, _beats.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: LingBiTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LingBiIcons.dragHandle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (index < _beats.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: c.borderOpaque.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: LingBiTokens.space3),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(LingBiTokens.space4),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
                border: Border.all(
                  color: c.borderOpaque.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              beat.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.fg,
                              ),
                            ),
                            const SizedBox(width: LingBiTokens.space2),
                            _buildTag(c, phase, color),
                          ],
                        ),
                        const SizedBox(height: LingBiTokens.space1),
                        Text(
                          beat.description,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: c.fgSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LingBiIcons.dragHandle, size: 18, color: c.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(LingBiColors c, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showAddDialog() {
    final pid = widget.projectId;
    if (pid == null) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int selectedColor = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加节拍'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：英雄登场',
                ),
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
                    onTap: () =>
                        setDialogState(() => selectedColor = i),
                    child: Container(
                      width: 32,
                      height: 32,
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final beat = StoryBeat(
                  projectId: pid,
                  title: title,
                  description: descCtrl.text.trim(),
                  colorIndex: selectedColor,
                  sequence: _beats.length,
                );
                try {
                  await ServiceLocator.instance.storyBeatsRepository
                      .saveBeat(beat);
                  if (mounted) await _loadData();
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
