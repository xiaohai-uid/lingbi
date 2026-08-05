import 'package:flutter/material.dart';

import '../../theme/lingbi_icons.dart';
import '../../theme/tokens.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '输入消息…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.fg,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          IconButton(
            onPressed: isLoading ? onCancel : onSend,
            icon: Icon(
              isLoading ? Icons.stop_circle_outlined : LingBiIcons.send,
              size: 20,
            ),
            color: isLoading ? LingBiTokens.error : c.accent,
          ),
        ],
      ),
    );
  }
}

/// Agent 开放回答内联输入框（空选项时使用）
class AgentOpenInput extends StatefulWidget {
  const AgentOpenInput({
    super.key,
    required this.messageIndex,
    required this.answered,
    required this.onSubmitted,
  });

  final int messageIndex;
  final bool answered;
  final void Function(int, String) onSubmitted;

  @override
  State<AgentOpenInput> createState() => _AgentOpenInputState();
}

class _AgentOpenInputState extends State<AgentOpenInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.answered) return;
    widget.onSubmitted(widget.messageIndex, text);
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    if (widget.answered) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !widget.answered,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '输入回答...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                borderSide: BorderSide(color: c.borderOpaque),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: LingBiTokens.space2),
        InkWell(
          onTap: _submit,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
              border: Border.all(color: c.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '发送',
              style: TextStyle(fontSize: 12, color: c.accent),
            ),
          ),
        ),
        const SizedBox(width: LingBiTokens.space1),
        InkWell(
          onTap: () => widget.onSubmitted(widget.messageIndex, '跳过'),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
              border: Border.all(
                color: c.borderOpaque.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '跳过',
              style: TextStyle(fontSize: 12, color: c.fgSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
