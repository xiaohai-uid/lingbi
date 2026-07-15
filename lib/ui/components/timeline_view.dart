import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';

import 'package:lingbi/data/database/world_database.dart';

/// 时间线视图
///
/// 展示 [events]（Drift 持久化实体），按 orderKey 排序。
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.events,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });
  final List<TimelineEvent> events;
  final VoidCallback? onAdd;
  final void Function(TimelineEvent)? onEdit;
  final void Function(TimelineEvent)? onDelete;

  List<TimelineEvent> get _sorted {
    final list = [...events];
    list.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('暂无时间线事件', style: theme.textTheme.bodyMedium),
            if (onAdd != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.s59),
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      );
    }
    final sorted = _sorted;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) => _buildEventCard(sorted[i]),
    );
  }

  Widget _buildEventCard(TimelineEvent e) {
    final anchor = e.chapterAnchor.isNotEmpty ? e.chapterAnchor : e.orderKey;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8A838),
          child: Icon(Icons.event, color: Colors.white, size: 18),
        ),
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (anchor.isNotEmpty)
              Chip(
                label: Text(anchor, style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: const Color(0xFFE8A838),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            if (e.description.isNotEmpty)
              Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => onEdit!(e)),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => onDelete!(e),
              ),
          ],
        ),
      ),
    );
  }
}
