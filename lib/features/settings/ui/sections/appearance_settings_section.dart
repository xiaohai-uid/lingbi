import 'package:flutter/material.dart';

import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class AppearanceSettingsSection extends StatefulWidget {
  const AppearanceSettingsSection({super.key});

  @override
  State<AppearanceSettingsSection> createState() =>
      _AppearanceSettingsSectionState();
}

class _AppearanceSettingsSectionState extends State<AppearanceSettingsSection>
    with SettingsAwareState {
  double _fontSize = 16;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final settings = ServiceLocator.instance.settingsService;
    final themeModeValue = switch (settings.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: LingBiIcons.sun,
          title: '主题',
          subtitle: '选择应用外观',
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('浅色')),
              ButtonSegment(value: 'dark', label: Text('深色')),
              ButtonSegment(value: 'system', label: Text('跟随系统')),
            ],
            selected: {themeModeValue},
            onSelectionChanged: (value) {
              final mode = value.first;
              final service = ServiceLocator.instance.settingsService;
              if (mode == 'light') {
                service.setThemeMode(ThemeMode.light);
              } else if (mode == 'dark') {
                service.setThemeMode(ThemeMode.dark);
              } else {
                service.setThemeMode(ThemeMode.system);
              }
            },
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.palette,
          title: '强调色',
          subtitle: '自定义主色调',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _colorDot(c.accent, true, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(c.cinnabar, false, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(LingBiTokens.warning, false, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(LingBiTokens.success, false, c),
            ],
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.wordCount,
          title: '字体大小',
          subtitle: '编辑器字体大小',
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              onChanged: (value) => setState(() => _fontSize = value),
              activeColor: c.accent,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _colorDot(Color color, bool isActive, LingBiColors c) {
  return Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: isActive
          ? Border.all(color: c.accent, width: 2)
          : Border.all(color: Colors.transparent, width: 2),
    ),
  );
}
