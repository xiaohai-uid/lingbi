import 'package:flutter/material.dart';

import '../../../../ui_v2/theme/tokens.dart';

class ShortcutsSettingsSection extends StatelessWidget {
  const ShortcutsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final shortcuts = [
      ('Ctrl + S', '保存当前章节'),
      ('Ctrl + Z', '撤销'),
      ('Ctrl + Shift + Z', '重做'),
      ('Ctrl + B', '粗体'),
      ('Ctrl + I', '斜体'),
      ('Ctrl + K', '插入链接'),
      ('Ctrl + Shift + K', '打开 AI 助手'),
      ('Ctrl + Shift + B', '切换侧栏'),
      ('Ctrl + Shift + T', '切换主题'),
      ('Ctrl + Shift + M', '技能市场'),
    ];

    return Padding(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷键',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.fg,
            ),
          ),
          const SizedBox(height: LingBiTokens.space4),
          ...shortcuts.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: LingBiTokens.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space4,
                  vertical: LingBiTokens.space3,
                ),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
                  border: Border.all(
                    color: c.borderOpaque.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: c.fg,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LingBiTokens.space2,
                        vertical: LingBiTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusSm),
                      ),
                      child: Text(
                        s.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.fgSecondary,
                          fontFamily: LingBiTokens.fontMono,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
