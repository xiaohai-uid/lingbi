import 'package:flutter/material.dart';

import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/theme/tokens.dart';

/// Rebuilds a section when settings service state changes.
///
/// The sections are kept alive in an `IndexedStack`, so this listener preserves
/// the behavior previously owned by the settings page state.
mixin SettingsAwareState<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }
}

/// Shared scaffold for the settings sections extracted from `settings_page.dart`.
class SettingsSectionScaffold extends StatelessWidget {
  const SettingsSectionScaffold({
    super.key,
    required this.c,
    required this.items,
  });

  final LingBiColors c;
  final List<SettingsSectionItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: LingBiTokens.space3),
                child: _buildSettingItem(item, c),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSettingItem(SettingsSectionItem item, LingBiColors c) {
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        border: Border.all(
          color: c.borderOpaque.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: c.fgSecondary),
          const SizedBox(width: LingBiTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.fg,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          item.trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// A single settings row used by [SettingsSectionScaffold].
class SettingsSectionItem {
  const SettingsSectionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
}

/// Shared input decoration used by settings sections.
InputDecoration settingsInputDecoration(LingBiColors c, String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: c.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      borderSide: BorderSide(color: c.borderOpaque),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: LingBiTokens.space3,
      vertical: LingBiTokens.space2,
    ),
  );
}
