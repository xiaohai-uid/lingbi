import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';

import 'package:lingbi/data/database/world_database.dart';

/// 势力视图
///
/// 展示 [factions]（Drift 持久化实体），含类型、实力、领地、描述。
/// 通过回调支持新增/编辑/删除。
class FactionView extends StatelessWidget {
  const FactionView({
    super.key,
    required this.factions,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });
  final List<Faction> factions;
  final VoidCallback? onAdd;
  final void Function(Faction)? onEdit;
  final void Function(Faction)? onDelete;

  static const Map<String, String> _typeLabels = {
    'sect': '宗门',
    'nation': '国家',
    'clan': '家族',
    'organization': '组织',
  };

  static const Map<String, Color> _typeColors = {
    'sect': Color(0xFF7E57C2),
    'nation': Color(0xFFEF6C00),
    'clan': Color(0xFF26A69A),
    'organization': Color(0xFF42A5F5),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (factions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('暂无势力', style: theme.textTheme.bodyMedium),
            if (onAdd != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.s61),
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: factions.length,
      itemBuilder: (ctx, i) => _buildFactionCard(factions[i]),
    );
  }

  Widget _buildFactionCard(Faction f) {
    final color = _typeColors[f.type] ?? Colors.grey;
    final label = _typeLabels[f.type] ?? f.type;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.flag, color: Colors.white, size: 18),
        ),
        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: color,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text('实力 ${f.power}${f.territory.isNotEmpty ? ' · ${f.territory}' : ''}',
                style: const TextStyle(color: Colors.grey)),
            if (f.description.isNotEmpty)
              Text(f.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => onEdit!(f)),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => onDelete!(f),
              ),
          ],
        ),
      ),
    );
  }
}
