import 'package:flutter/material.dart';

import '../../../shared/di/service_locator.dart';
import '../../../ui_v2/theme/tokens.dart';
import 'sections/ai_model_settings_section.dart';
import 'sections/api_key_settings_section.dart';
import 'sections/appearance_settings_section.dart';
import 'sections/capability_settings_section.dart';
import 'sections/cloud_sync_settings_section.dart';
import 'sections/custom_endpoint_settings_section.dart';
import 'sections/editor_settings_section.dart';
import 'sections/privacy_settings_section.dart';
import 'sections/shortcuts_settings_section.dart';
import 'sections/storage_settings_section.dart';
import 'sections/subscription_settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = '外观';

  final _sections = [
    '外观',
    '编辑器',
    'AI 模型',
    'API 密钥',
    '能力',
    '自定义端点',
    '快捷键',
    '存储',
    '云同步',
    '隐私',
    '订阅',
  ];

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

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        Expanded(
          child: Row(
            children: [
              _buildSideNav(c),
              Container(
                width: 1,
                color: c.borderOpaque.withValues(alpha: 0.3),
              ),
              Expanded(child: _buildSectionContent(c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Text(
        '设置',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: c.fg,
          letterSpacing: -0.625 / 26 * 26,
        ),
      ),
    );
  }

  Widget _buildSideNav(LingBiColors c) {
    return SizedBox(
      width: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space2,
        ),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          final isActive = section == _selectedSection;
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => setState(() => _selectedSection = section),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space3,
                  vertical: LingBiTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? c.accent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                ),
                child: Text(
                  section,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? c.accent : c.fgSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent(LingBiColors c) {
    final selectedIndex = _sections.indexOf(_selectedSection);
    return IndexedStack(
      index: selectedIndex < 0 ? 0 : selectedIndex,
      children: const [
        AppearanceSettingsSection(),
        EditorSettingsSection(),
        AiModelSettingsSection(),
        ApiKeySettingsSection(),
        CapabilitySettingsSection(),
        CustomEndpointSettingsSection(),
        ShortcutsSettingsSection(),
        StorageSettingsSection(),
        CloudSyncSettingsSection(),
        PrivacySettingsSection(),
        SubscriptionSettingsSection(),
      ],
    );
  }
}
