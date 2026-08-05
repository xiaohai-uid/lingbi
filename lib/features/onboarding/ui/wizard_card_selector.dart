/// 通用卡片选择器组件（B 型步骤的 UI 载体）
///
/// 支持单选/多选两种模式，多选上限可配置。
/// 题材模式：6 热门卡片 + "更多"展开全部 14 项。
/// 每组底部"+ 自定义"入口，与卡片选择共存。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

/// 卡片选项数据
class CardOption {
  const CardOption({
    required this.id,
    required this.label,
    this.emoji,
    this.description,
  });

  final String id;
  final String label;
  final String? emoji;
  final String? description;
}

/// 卡片选择器
class WizardCardSelector extends StatefulWidget {
  const WizardCardSelector({
    super.key,
    required this.options,
    required this.multiSelect,
    this.maxSelections,
    this.hotCount = 0,
    this.initialSelected = const [],
    this.initialCustomText,
    this.onChanged,
  });

  /// 全部选项列表
  final List<CardOption> options;

  /// 是否多选
  final bool multiSelect;

  /// 多选上限（null = 无限制）
  final int? maxSelections;

  /// 热门卡片数量（>0 时显示"更多"按钮展开全部）
  final int hotCount;

  /// 初始选中项
  final List<String> initialSelected;

  /// 初始自定义文本
  final String? initialCustomText;

  /// 选择变更回调：(选中 id 列表, 自定义文本)
  final void Function(List<String> selected, String? customText)? onChanged;

  @override
  State<WizardCardSelector> createState() => _WizardCardSelectorState();
}

class _WizardCardSelectorState extends State<WizardCardSelector> {
  late Set<String> _selected;
  bool _expanded = false;
  bool _showCustomField = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    if (widget.initialCustomText != null &&
        widget.initialCustomText!.trim().isNotEmpty) {
      _showCustomField = true;
      _customController.text = widget.initialCustomText!;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    final customText = _customController.text.trim();
    widget.onChanged?.call(
      _selected.toList(),
      customText.isEmpty ? null : customText,
    );
  }

  void _toggleOption(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (widget.multiSelect) {
          // 检查上限
          if (widget.maxSelections != null &&
              _selected.length >= widget.maxSelections!) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('最多选择 ${widget.maxSelections} 个'),
                duration: const Duration(seconds: 1),
              ),
            );
            return;
          }
          _selected.add(id);
        } else {
          // 单选：替换
          _selected.clear();
          _selected.add(id);
        }
      }
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final visibleOptions = (widget.hotCount > 0 && !_expanded)
        ? widget.options.take(widget.hotCount).toList()
        : widget.options;
    final hasMore =
        widget.hotCount > 0 && widget.options.length > widget.hotCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 卡片网格
        Wrap(
          spacing: LingBiTokens.space2,
          runSpacing: LingBiTokens.space2,
          children: visibleOptions.map((opt) => _buildCard(c, opt)).toList(),
        ),
        // "更多"按钮
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: LingBiTokens.space2),
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
              ),
              label: Text(_expanded ? '收起' : '更多'),
            ),
          ),
        // "+ 自定义"入口
        Padding(
          padding: const EdgeInsets.only(top: LingBiTokens.space2),
          child: _showCustomField
              ? _buildCustomField(c)
              : TextButton.icon(
                  onPressed: () => setState(() => _showCustomField = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('自定义'),
                ),
        ),
      ],
    );
  }

  Widget _buildCard(LingBiColors c, CardOption opt) {
    final isSelected = _selected.contains(opt.id);
    return InkWell(
      onTap: () => _toggleOption(opt.id),
      borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 140,
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space3,
        ),
        decoration: BoxDecoration(
          color: isSelected ? c.accent.withValues(alpha: 0.1) : c.surface,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
          border: Border.all(
            color: isSelected ? c.accent : c.borderOpaque,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (opt.emoji != null)
              Text(opt.emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              opt.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: c.fg,
                fontSize: 13,
              ),
            ),
            if (opt.description != null) ...[
              const SizedBox(height: 2),
              Text(
                opt.description!,
                style: TextStyle(fontSize: 11, color: c.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField(LingBiColors c) {
    return TextField(
      controller: _customController,
      decoration: InputDecoration(
        hintText: '输入自定义选项',
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () {
            setState(() {
              _showCustomField = false;
              _customController.clear();
            });
            _notifyChanged();
          },
        ),
      ),
      onChanged: (_) => _notifyChanged(),
    );
  }
}
