import 'package:flutter/material.dart';

class ChatEntry {
  final String role;
  final String content;
  final bool isStreaming;

  ChatEntry({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });
}

class ChatWidget extends StatelessWidget {
  final ChatEntry entry;

  const ChatWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = entry.role == 'user';
    final isAssistant = entry.role == 'assistant';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: isAssistant ? const Radius.circular(4) : null,
                ),
              ),
              child: entry.content.isEmpty && entry.isStreaming
                  ? const SizedBox(
                      width: 20,
                      height: 12,
                      child: LinearProgressIndicator(),
                    )
                  : Text(
                      entry.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, size: 14, color: theme.colorScheme.onPrimary),
            ),
          ],
        ],
      ),
    );
  }
}
