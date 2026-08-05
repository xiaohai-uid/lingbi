import 'package:flutter/material.dart';

import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class EditorSettingsSection extends StatefulWidget {
  const EditorSettingsSection({super.key});

  @override
  State<EditorSettingsSection> createState() => _EditorSettingsSectionState();
}

class _EditorSettingsSectionState extends State<EditorSettingsSection> {
  bool _wordCount = true;
  bool _autoSave = true;
  String _editorWidth = 'medium';

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: LingBiIcons.wordCount,
          title: '字数统计',
          subtitle: '在状态栏显示实时字数',
          trailing: Switch(
            value: _wordCount,
            onChanged: (value) => setState(() => _wordCount = value),
            activeThumbColor: c.accent,
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.check,
          title: '自动保存',
          subtitle: '每 30 秒自动保存当前内容',
          trailing: Switch(
            value: _autoSave,
            onChanged: (value) => setState(() => _autoSave = value),
            activeThumbColor: c.accent,
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.chapter,
          title: '默认编辑器宽度',
          subtitle: '编辑区域的最大宽度',
          trailing: SizedBox(
            width: 160,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'narrow', label: Text('窄')),
                ButtonSegment(value: 'medium', label: Text('中')),
                ButtonSegment(value: 'wide', label: Text('宽')),
              ],
              selected: {_editorWidth},
              onSelectionChanged: (value) =>
                  setState(() => _editorWidth = value.first),
            ),
          ),
        ),
      ],
    );
  }
}
