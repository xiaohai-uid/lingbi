import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../features/writing/services/agent/agent_tool_loop.dart';
import '../../theme/lingbi_icons.dart';
import '../../theme/tokens.dart';
import 'chat_input_bar.dart';
import 'chat_message.dart';

Widget buildAiMessage({
  required BuildContext context,
  required LingBiColors c,
  required String text,
  String processContent = '',
  bool isStreaming = false,
  bool isThinking = false,
  List<AgentStep> toolSteps = const [],
  VoidCallback? onConvertToCandidate,
  required int Function(String) countWords,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        child: Center(
          child: Icon(LingBiIcons.aiAssistant, size: 16, color: c.accent),
        ),
      ),
      const SizedBox(width: LingBiTokens.space2),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space3),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            border: Border.all(
              color: c.borderOpaque.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (processContent.isNotEmpty)
                buildProcessTile(
                  context,
                  c,
                  processContent,
                  isThinkingNow: isThinking && isStreaming,
                ),
              if (toolSteps.isNotEmpty) buildToolSteps(context, c, toolSteps),
              if (text.isEmpty && isStreaming)
                SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.accent.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: LingBiTokens.space2),
                      Text(
                        isThinking ? '思考中…' : '生成中…',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else if (text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isStreaming)
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: c.fg,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(text: text),
                            TextSpan(
                              text: ' ▍',
                              style: TextStyle(
                                color: c.accent.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      MarkdownBody(
                        data: text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 14,
                            color: c.fg,
                            height: 1.6,
                          ),
                          h1: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: c.fg),
                          h2: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: c.fg),
                          h3: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.fg),
                          listBullet: TextStyle(color: c.fgSecondary),
                          code: TextStyle(
                            fontSize: 13,
                            backgroundColor: c.surfaceContainer,
                          ),
                        ),
                      ),
                    if (!isStreaming && text.length > 20)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '共 ${countWords(text)} 字',
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ),
                  ],
                ),
              if (!isStreaming &&
                  text.isNotEmpty &&
                  onConvertToCandidate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: InkWell(
                    onTap: onConvertToCandidate,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_add_outlined,
                              size: 13, color: c.accent),
                          const SizedBox(width: 4),
                          Text(
                            '转为候选',
                            style: TextStyle(fontSize: 11, color: c.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildProcessTile(
  BuildContext context,
  LingBiColors c,
  String processContent, {
  bool isThinkingNow = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isThinkingNow,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        dense: true,
        leading: Icon(
          Icons.psychology_outlined,
          size: 14,
          color: c.muted,
        ),
        title: Text(
          isThinkingNow ? '思考中…' : '💭 思考过程',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.muted,
          ),
        ),
        trailing: Icon(
          isThinkingNow ? Icons.expand_more : Icons.chevron_right,
          size: 16,
          color: c.muted,
        ),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: Text(
                processContent,
                style: TextStyle(
                  fontSize: 12,
                  color: c.fgSecondary.withValues(alpha: 0.8),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildToolSteps(
  BuildContext context,
  LingBiColors c,
  List<AgentStep> steps,
) {
  final toolCount =
      steps.where((s) => s.kind == 'tool' || s.kind == 'error').length;
  final hasError = steps.any((s) => s.kind == 'error');
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        dense: true,
        leading: Icon(
          hasError ? Icons.build_circle_outlined : Icons.build_outlined,
          size: 14,
          color: hasError ? LingBiTokens.warning : c.muted,
        ),
        title: Text(
          '🛠 工具步骤（$toolCount）',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.muted,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            toolStepIcon(s.kind),
                            size: 12,
                            color: s.kind == 'error'
                                ? LingBiTokens.warning
                                : s.kind == 'final'
                                    ? LingBiTokens.success
                                    : c.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.fgSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

IconData toolStepIcon(String kind) => switch (kind) {
      'tool' => Icons.check_circle_outline,
      'error' => Icons.warning_amber_rounded,
      'final' => Icons.flag_outlined,
      'fallback' => Icons.swap_horiz,
      _ => Icons.more_horiz,
    };

/// A3: 字数统计（中文字符 + 英文单词）。
int countChatWords(String text) {
  final chineseChars =
      RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').allMatches(text).length;
  final englishWords = RegExp(r'[a-zA-Z]+').allMatches(text).length;
  return chineseChars + englishWords;
}

Widget buildClarificationCard({
  required LingBiColors c,
  required ChatMessage msg,
  required ValueChanged<String> onOptionSelected,
  required VoidCallback onSkipClarification,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        child: Center(
          child: Icon(Icons.help_outline, size: 16, color: c.accent),
        ),
      ),
      const SizedBox(width: LingBiTokens.space2),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space3),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            border: Border.all(
              color: c.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.clarifyQuestion,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.fg,
                  height: 1.4,
                ),
              ),
              if (msg.quickOptions.isNotEmpty) ...[
                const SizedBox(height: LingBiTokens.space2),
                Wrap(
                  spacing: LingBiTokens.space2,
                  runSpacing: LingBiTokens.space1,
                  children: [
                    for (final option in msg.quickOptions)
                      InkWell(
                        onTap: () => onOptionSelected(option),
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: option == '直接生成'
                                ? c.accent.withValues(alpha: 0.1)
                                : c.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(LingBiTokens.radiusPill),
                            border: Border.all(
                              color: option == '直接生成'
                                  ? c.accent.withValues(alpha: 0.4)
                                  : c.borderOpaque.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: option == '直接生成'
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color:
                                  option == '直接生成' ? c.accent : c.fgSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: LingBiTokens.space2),
              InkWell(
                onTap: onSkipClarification,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '跳过，直接生成 →',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildAgentQuestionCard({
  required LingBiColors c,
  required ChatMessage msg,
  required int messageIndex,
  required void Function(int, String) onAgentOptionSelected,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        child: Center(
          child: Icon(Icons.smart_toy_outlined, size: 16, color: c.accent),
        ),
      ),
      const SizedBox(width: LingBiTokens.space2),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space3),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            border: Border.all(
              color: c.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.agentQuestion,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.fg,
                  height: 1.4,
                ),
              ),
              if (msg.agentOptions.isNotEmpty) ...[
                const SizedBox(height: LingBiTokens.space2),
                Wrap(
                  spacing: LingBiTokens.space2,
                  runSpacing: LingBiTokens.space1,
                  children: [
                    for (final option in msg.agentOptions)
                      InkWell(
                        onTap: msg.agentAnswered
                            ? null
                            : () => onAgentOptionSelected(messageIndex, option),
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: msg.agentAnswered
                                ? c.surfaceContainer
                                : c.accent.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(LingBiTokens.radiusPill),
                            border: Border.all(
                              color: msg.agentAnswered
                                  ? c.borderOpaque.withValues(alpha: 0.2)
                                  : c.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: msg.agentAnswered ? c.muted : c.accent,
                            ),
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: msg.agentAnswered
                          ? null
                          : () => onAgentOptionSelected(messageIndex, '跳过'),
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(LingBiTokens.radiusPill),
                          border: Border.all(
                            color: c.borderOpaque.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '跳过',
                          style: TextStyle(
                            fontSize: 12,
                            color: msg.agentAnswered ? c.muted : c.fgSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: LingBiTokens.space2),
                AgentOpenInput(
                  messageIndex: messageIndex,
                  answered: msg.agentAnswered,
                  onSubmitted: onAgentOptionSelected,
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildUserMessage({
  required LingBiColors c,
  required String text,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space3),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: c.fg,
              height: 1.6,
            ),
          ),
        ),
      ),
      const SizedBox(width: LingBiTokens.space2),
      Icon(LingBiIcons.edit, size: 18, color: c.fgSecondary),
    ],
  );
}
