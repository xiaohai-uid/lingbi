import 'package:flutter/material.dart';

import '../services/command_palette_service.dart';
import '../theme/tokens.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.onSelected});

  final ValueChanged<AppCommand> onSelected;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<AppCommand> onSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CommandPalette(onSelected: onSelected),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const _entries = <(AppCommand, String, String)>[
    (AppCommand.newProject, '新建项目', 'Ctrl+N'),
    (AppCommand.openProject, '打开项目', 'Ctrl+O'),
    (AppCommand.save, '保存当前文稿', 'Ctrl+S'),
    (AppCommand.toggleAi, '显示或隐藏 AI 助手', 'Ctrl+Shift+A'),
    (AppCommand.settings, '打开设置', 'Ctrl+,'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _select(AppCommand command) {
    Navigator.of(context).pop();
    widget.onSelected(command);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return Dialog(
      alignment: const Alignment(0, -0.55),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 440),
        child: Padding(
          padding: const EdgeInsets.all(LingBiTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '输入命令…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: LingBiTokens.space3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _entries
                      .where((entry) => entry.$2
                          .toLowerCase()
                          .contains(_controller.text.trim().toLowerCase()))
                      .map((entry) => ListTile(
                            title: Text(entry.$2,
                                style: TextStyle(color: colors.fg)),
                            trailing: Text(entry.$3,
                                style: TextStyle(color: colors.muted)),
                            onTap: () => _select(entry.$1),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
