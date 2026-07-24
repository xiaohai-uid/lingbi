import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorToolbar extends StatelessWidget {

  const EditorToolbar({super.key, required this.controller, this.onSave});
  final QuillController controller;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolBtn(theme, Icons.format_bold, () => controller.formatSelection(Attribute.bold)),
            _toolBtn(theme, Icons.format_italic, () => controller.formatSelection(Attribute.italic)),
            _toolBtn(theme, Icons.format_underline, () => controller.formatSelection(Attribute.underline)),
            _toolBtn(theme, Icons.strikethrough_s, () => controller.formatSelection(Attribute.strikeThrough)),
            _sep(theme),
            _toolBtn(theme, Icons.format_list_bulleted, () => controller.formatSelection(Attribute.ol)),
            _toolBtn(theme, Icons.format_list_numbered, () => controller.formatSelection(Attribute.ul)),
            _sep(theme),
            _toolBtn(theme, Icons.format_quote, () => controller.formatSelection(Attribute.blockQuote)),
            _toolBtn(theme, Icons.code, () => controller.formatSelection(Attribute.codeBlock)),
            _toolBtn(theme, Icons.horizontal_rule, () {
              final i = controller.selection.start;
              controller.replaceText(i, 0, '---\n', null);
            }),
            if (onSave != null) ...[
              _sep(theme),
              _toolBtn(theme, Icons.save, onSave!, color: Colors.green, tooltip: '保存'),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _toolBtn(ThemeData theme, IconData icon, VoidCallback onTap, {Color? color, String? tooltip = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color ?? theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  static Widget _sep(ThemeData theme) {
    return Container(
      width: 1, height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: theme.dividerColor,
    );
  }
}
