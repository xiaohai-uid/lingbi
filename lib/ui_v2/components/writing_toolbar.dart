import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Commands emitted by the toolbar; consumed by the editor layer.
abstract class FormatCommands {
  static const bold = 'bold';
  static const italic = 'italic';
  static const underline = 'underline';
  static const strikethrough = 'strikethrough';
  static const heading = 'heading';
  static const quote = 'quote';
  static const bulletList = 'bulletList';
  static const numberedList = 'numberedList';
  static const link = 'link';
  static const image = 'image';
  static const code = 'code';
  static const undo = 'undo';
  static const redo = 'redo';
  static const aiWriting = 'aiWriting';
}

class WritingToolbar extends StatelessWidget {

  const WritingToolbar({
    super.key,
    this.onFormatCommand,
    this.wordCount = 0,
  });
  /// Called when the user taps a formatting button. The string value is one of
  /// [FormatCommands] constants.
  final ValueChanged<String>? onFormatCommand;

  /// Current word count displayed at the right side of the toolbar.
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space3),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _toolGroup([
            const _ToolItem(Icons.format_bold, null, FormatCommands.bold),
            const _ToolItem(Icons.format_italic, null, FormatCommands.italic),
            const _ToolItem(Icons.format_underline, null, FormatCommands.underline),
            const _ToolItem(Icons.format_strikethrough_outlined, null,
                FormatCommands.strikethrough),
          ], c),
          _divider(c),
          _toolGroup([
            const _ToolItem(Icons.format_size, 'H', FormatCommands.heading),
            const _ToolItem(
                Icons.format_quote_outlined, null, FormatCommands.quote),
            const _ToolItem(Icons.format_list_bulleted_outlined, null,
                FormatCommands.bulletList),
            const _ToolItem(Icons.format_list_numbered_outlined, null,
                FormatCommands.numberedList),
          ], c),
          _divider(c),
          _toolGroup([
            const _ToolItem(Icons.link_outlined, null, FormatCommands.link),
            const _ToolItem(Icons.image_outlined, null, FormatCommands.image),
            const _ToolItem(Icons.code_outlined, null, FormatCommands.code),
          ], c),
          _divider(c),
          _toolGroup([
            const _ToolItem(Icons.undo, null, FormatCommands.undo),
            const _ToolItem(Icons.redo, null, FormatCommands.redo),
          ], c),
          _divider(c),
          // AI 写作按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFormatCommand != null
                  ? () => onFormatCommand!(FormatCommands.aiWriting)
                  : null,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: c.accent),
                    const SizedBox(width: 4),
                    Text(
                      'AI 写作',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$wordCount 字',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
          const SizedBox(width: LingBiTokens.space3),
        ],
      ),
    );
  }

  Widget _toolGroup(List<_ToolItem> items, LingBiColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) => _toolButton(item, c)).toList(),
    );
  }

  Widget _toolButton(_ToolItem item, LingBiColors c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFormatCommand != null
            ? () => onFormatCommand!(item.command)
            : null,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: item.label != null
              ? Text(
                  item.label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.fgSecondary,
                    fontFamily: LingBiTokens.fontDisplay,
                  ),
                )
              : Icon(item.icon, size: 18, color: c.fgSecondary),
        ),
      ),
    );
  }

  Widget _divider(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space1),
      child: Container(
        width: 1,
        height: 20,
        color: c.borderOpaque.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem(this.icon, this.label, this.command);
  final IconData icon;
  final String? label;
  final String command;
}
