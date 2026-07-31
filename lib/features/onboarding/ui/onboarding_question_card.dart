import 'package:flutter/material.dart';

import 'package:lingbi/features/onboarding/data/project_onboarding_workflow.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class OnboardingQuestionCard extends StatelessWidget {
  const OnboardingQuestionCard({
    super.key,
    required this.question,
    required this.controller,
    required this.isSaving,
    required this.onSubmit,
    required this.onSkip,
    this.genreLabel,
  });

  final OnboardingQuestion question;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final String? genreLabel;

  String get _title => switch (question) {
        OnboardingQuestion.protagonistGoal => '主角最想实现什么？',
        OnboardingQuestion.coreObstacle => '什么阻碍了主角？',
        OnboardingQuestion.openingEvent => '故事开场发生什么？',
      };

  String get _displayTitle => genreLabel == null ||
          genreLabel!.isEmpty ||
          question != OnboardingQuestion.protagonistGoal
      ? _title
      : '$genreLabel开局：$_title';

  String get _hint => switch (question) {
        OnboardingQuestion.protagonistGoal => '例：在七天内找到失踪的妹妹',
        OnboardingQuestion.coreObstacle => '例：这座城每天都会抹去所有人的记忆',
        OnboardingQuestion.openingEvent => '例：主角收到了一封自己的讣告',
      };

  /// 快捷选项按钮（对标 OpenWrite 的 question 选项）。
  /// 点击填入输入框，用户仍可修改后提交。
  List<String> get _quickOptions => switch (question) {
        OnboardingQuestion.protagonistGoal => const [
            '复仇雪恨',
            '守护至亲',
            '登顶最强',
            '探寻真相',
          ],
        OnboardingQuestion.coreObstacle => const [
            '强敌环伺',
            '身世成谜',
            '天道压制',
            '内心心魔',
          ],
        OnboardingQuestion.openingEvent => const [
            '惨遭灭门',
            '偶得金手指',
            '重生回起点',
            '卷入阴谋',
          ],
      };

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        border: Border.all(color: colors.borderOpaque),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayTitle,
            style: TextStyle(
              color: colors.fg,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LingBiTokens.space3),
          Wrap(
            spacing: LingBiTokens.space2,
            runSpacing: LingBiTokens.space2,
            children: [
              for (final opt in _quickOptions)
                InkWell(
                  onTap: isSaving ? null : () => controller.text = opt,
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LingBiTokens.space3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusPill),
                      border: Border.all(color: colors.borderOpaque),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(fontSize: 13, color: colors.fg),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LingBiTokens.space3),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(hintText: _hint),
          ),
          const SizedBox(height: LingBiTokens.space4),
          Row(
            children: [
              TextButton(
                onPressed: isSaving ? null : onSkip,
                child: const Text('跳过这题'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('保存并继续'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
