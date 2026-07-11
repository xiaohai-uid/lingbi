/// MemoryPanel — 记忆上下文管理面板
///
/// 显示当前注入的记忆上下文条目列表，用户可开关/删除/编辑条目。
/// 嵌入在生成参数面板的「记忆上下文」标签页中。
library;

import 'package:flutter/material.dart';
import '../services/interfaces/i_memory_service.dart';

/// 记忆上下文面板
class MemoryPanel extends StatefulWidget {
  const MemoryPanel({
    super.key,
    required this.entries,
    this.customContext = '',
    this.disabledIds = const {},
    this.onToggleEntry,
    this.onRemoveEntry,
    this.onCustomContextChanged,
    this.onRefresh,
    this.onDisabledIdsChanged,
  });

  /// 当前上下文条目列表
  final List<ContextEntry> entries;

  /// 用户自定义上下文文本
  final String customContext;

  /// 切换条目的启用/禁用状态
  final void Function(String id, SummaryType type, bool enabled)? onToggleEntry;

  /// 删除条目
  final void Function(String id, SummaryType type)? onRemoveEntry;

  /// 自定义上下文变化回调
  final void Function(String text)? onCustomContextChanged;

  /// 禁用条目 ID 集合
  final Set<String> disabledIds;

  /// 刷新记忆列表
  final VoidCallback? onRefresh;

  /// 禁用状态变化回调
  final void Function(Set<String> disabledIds)? onDisabledIdsChanged;

  @override
  State<MemoryPanel> createState() => _MemoryPanelState();
}

class _MemoryPanelState extends State<MemoryPanel> {
  late TextEditingController _customController;
  Set<String> get _disabledIds => widget.disabledIds;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.customContext);
  }

  @override
  void didUpdateWidget(MemoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customContext != widget.customContext) {
      _customController.text = widget.customContext;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  IconData _typeIcon(SummaryType type) {
    switch (type) {
      case SummaryType.scene:
        return Icons.description_outlined;
      case SummaryType.chapter:
        return Icons.auto_stories_outlined;
      case SummaryType.volume:
        return Icons.menu_book_outlined;
    }
  }

  Color _typeColor(SummaryType type) {
    switch (type) {
      case SummaryType.scene:
        return Colors.blue;
      case SummaryType.chapter:
        return Colors.green;
      case SummaryType.volume:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoEntries = widget.entries.where((e) => e.autoInjected).toList();
    final manualEntries = widget.entries.where((e) => !e.autoInjected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题栏 ──
        Row(
          children: [
            const Text('📖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('记忆上下文',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (widget.onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: '刷新记忆',
                onPressed: widget.onRefresh,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '自动注入已生成的场景/章节摘要，保持故事一致性。可关闭不需要的条目。',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // ── 自动注入条目 ──
        if (autoEntries.isNotEmpty) ...[
          Text('自动注入', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          ...autoEntries.map((entry) => _buildEntryTile(entry)),
          const SizedBox(height: 12),
        ],

        // ── 手动添加条目 ──
        if (manualEntries.isNotEmpty) ...[
          Text('手动添加', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          ...manualEntries.map((entry) => _buildEntryTile(entry)),
          const SizedBox(height: 12),
        ],

        // ── 自定义上下文输入 ──
        const Text('自定义上下文',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _customController,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: '在此输入额外的上下文信息，将追加到 AI 提示中...',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(8),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: widget.onCustomContextChanged,
        ),
      ],
    );
  }

  Widget _buildEntryTile(ContextEntry entry) {
    final isDisabled = _disabledIds.contains(entry.id);
    final color = _typeColor(entry.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(_typeIcon(entry.type), size: 18, color: color),
        title: Text(
          entry.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDisabled ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          entry.summary.length > 80
              ? '${entry.summary.substring(0, 80)}...'
              : entry.summary,
          style: TextStyle(
            fontSize: 11,
            color: isDisabled ? Colors.grey[400] : Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 启用/禁用开关
            SizedBox(
              width: 36,
              child: Checkbox(
                value: !isDisabled,
                onChanged: (_) {
                  final updated = Set<String>.from(widget.disabledIds);
                  if (isDisabled) {
                    updated.remove(entry.id);
                  } else {
                    updated.add(entry.id);
                  }
                  widget.onDisabledIdsChanged?.call(updated);
                  widget.onToggleEntry
                      ?.call(entry.id, entry.type, isDisabled);
                },
              ),
            ),
            // 删除按钮
            if (widget.onRemoveEntry != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: () =>
                    widget.onRemoveEntry?.call(entry.id, entry.type),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
