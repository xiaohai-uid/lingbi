import 'package:flutter/material.dart';
import 'package:lingbi/modules/pipeline/novel_application_service.dart';

class ChapterSettlementPanel extends StatefulWidget {
  const ChapterSettlementPanel({
    super.key,
    required this.proposal,
    required this.onConfirm,
    required this.onSkip,
  });

  final SettlementProposal proposal;
  final Future<void> Function(Set<int> selectedIndexes) onConfirm;
  final Future<void> Function() onSkip;

  @override
  State<ChapterSettlementPanel> createState() => _ChapterSettlementPanelState();
}

class _ChapterSettlementPanelState extends State<ChapterSettlementPanel> {
  late Set<int> _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectAll();
  }

  @override
  void didUpdateWidget(covariant ChapterSettlementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal.id != widget.proposal.id) _selectAll();
  }

  void _selectAll() {
    _selected = Set<int>.from(
      List<int>.generate(widget.proposal.items.length, (index) => index),
    );
  }

  Future<void> _confirm() async {
    if (_busy || _selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onConfirm(Set<int>.unmodifiable(_selected));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSkip();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '章节状态结算',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '确认后用于后续章节上下文',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_selected.length}/${widget.proposal.items.length}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (widget.proposal.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('本章没有提取到需要结算的状态变化。'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.proposal.items.length,
                itemBuilder: (context, index) {
                  final item = widget.proposal.items[index];
                  return CheckboxListTile(
                    key: ValueKey('settlement-item-$index'),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _selected.contains(index),
                    onChanged: _busy
                        ? null
                        : (checked) => setState(() {
                              if (checked ?? false) {
                                _selected.add(index);
                              } else {
                                _selected.remove(index);
                              }
                            }),
                    title: Text(
                      item.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      [
                        _categoryLabel(item.category),
                        if (item.entityName?.isNotEmpty ?? false)
                          item.entityName!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('skip-settlement'),
                  onPressed: _busy ? null : _skip,
                  child: const Text('暂不更新'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('confirm-settlement'),
                  onPressed: _busy || _selected.isEmpty ? null : _confirm,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('确认更新'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) => switch (category) {
        'character_position' => '人物位置',
        'item_change' => '物品变化',
        'relationship_change' => '关系变化',
        'new_character' => '新人物',
        'new_rule' => '新设定',
        'new_foreshadowing' => '新伏笔',
        'foreshadowing_resolved' => '伏笔回收',
        'plotline_change' => '剧情推进',
        _ => '状态变化',
      };
}
