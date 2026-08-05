import 'package:flutter/material.dart';

import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class PrivacySettingsSection extends StatefulWidget {
  const PrivacySettingsSection({super.key});

  @override
  State<PrivacySettingsSection> createState() => _PrivacySettingsSectionState();
}

class _PrivacySettingsSectionState extends State<PrivacySettingsSection> {
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: LingBiIcons.privacy,
          title: '匿名数据贡献',
          subtitle: '仅传送不可逆聚合统计（题材/字数/技能使用次数），不含任何个人内容',
          trailing: Switch(
            value: _analyticsEnabled,
            onChanged: (v) => setState(() => _analyticsEnabled = v),
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.privacy,
          title: '数据范围',
          subtitle: '题材分布、章节数、总字数、Skill 使用频次',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LingBiTokens.space2,
              vertical: LingBiTokens.space1,
            ),
            decoration: BoxDecoration(
              color: _analyticsEnabled
                  ? LingBiTokens.success.withValues(alpha: 0.1)
                  : c.surfaceContainer,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
            ),
            child: Text(
              _analyticsEnabled ? '已开启' : '已关闭',
              style: TextStyle(
                fontSize: 12,
                color: _analyticsEnabled ? LingBiTokens.success : c.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
