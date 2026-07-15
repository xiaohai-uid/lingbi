/// SelectionEditPopup — 选中文本后的浮动操作菜单
///
/// 类似 Notion AI 的选中编辑体验。
/// 显示在选中文本附近，提供改写/扩写/润色/缩写/续写/换语调操作。
library;

import 'package:flutter/material.dart';
import '../../services/interfaces/i_retroactive_edit_service.dart';

/// 编辑模式定义
class _EditModeOption {

  const _EditModeOption({
    required this.mode,
    required this.icon,
    required this.label,
  }) : tone = null;
  final String mode;
  final String icon;
  final String label;
  final String? tone;
}

/// 选中文本编辑浮动菜单
class SelectionEditPopup extends StatefulWidget {
  const SelectionEditPopup({
    super.key,
    required this.onEdit,
    this.onUndo,
    this.selectedText = '',
    this.canUndo = false,
  });

  /// 执行编辑回调
  final Future<void> Function(EditMode mode, {String? targetTone}) onEdit;

  /// 撤销回调
  final VoidCallback? onUndo;

  /// 当前选中文本（用于显示预览）
  final String selectedText;

  /// 是否可以撤销
  final bool canUndo;

  @override
  State<SelectionEditPopup> createState() => _SelectionEditPopupState();
}

class _SelectionEditPopupState extends State<SelectionEditPopup> {
  bool _showTonePicker = false;

  static const _mainModes = [
    _EditModeOption(mode: 'rewrite', icon: '✏️', label: '改写'),
    _EditModeOption(mode: 'expand', icon: '📝', label: '扩写'),
    _EditModeOption(mode: 'polish', icon: '✨', label: '润色'),
    _EditModeOption(mode: 'shorten', icon: '📏', label: '缩写'),
    _EditModeOption(mode: 'continue_', icon: '▶️', label: '续写'),
  ];

  EditMode _modeFromString(String mode) {
    return switch (mode) {
      'rewrite' => EditMode.rewrite,
      'expand' => EditMode.expand,
      'polish' => EditMode.polish,
      'shorten' => EditMode.shorten,
      'continue_' => EditMode.continue_,
      'changeTone' => EditMode.changeTone,
      _ => EditMode.rewrite,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E3A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _showTonePicker ? _buildTonePicker() : _buildMainMenu(),
    );
  }

  Widget _buildMainMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 选中文本预览
        if (widget.selectedText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              widget.selectedText.length > 60
                  ? '${widget.selectedText.substring(0, 60)}...'
                  : widget.selectedText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // 编辑模式按钮网格
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            children: [
              Row(
                children: _mainModes.sublist(0, 3).map((m) => _buildModeButton(m)).toList(),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ..._mainModes.sublist(3).map((m) => _buildModeButton(m)),
                  _buildModeButton(const _EditModeOption(
                    mode: 'changeTone', icon: '🎭', label: '换语调',
                  )),
                ],
              ),
            ],
          ),
        ),

        // 撤销按钮
        if (widget.canUndo || widget.onUndo != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.undo, size: 14),
                label: const Text('撤销', style: TextStyle(fontSize: 12)),
                onPressed: widget.onUndo,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeButton(_EditModeOption option) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (option.mode == 'changeTone') {
            setState(() => _showTonePicker = true);
          } else {
            widget.onEdit(_modeFromString(option.mode));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(option.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[800],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTonePicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Text('🎭 选择目标语调',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _showTonePicker = false),
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 语调网格
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: toneOptions.map((tone) {
              return InkWell(
                onTap: () {
                  widget.onEdit(EditMode.changeTone, targetTone: tone);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tone, style: const TextStyle(fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
