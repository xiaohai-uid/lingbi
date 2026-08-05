import 'dart:async';

import '../../../features/writing/services/agent/agent_tool_loop.dart';

/// Message model rendered by the AI assistant panel.
class ChatMessage {
  ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.processContent = '',
    this.isThinking = false,
    this.isClarification = false,
    this.clarifyQuestion = '',
    this.quickOptions = const [],
    this.originalMessage = '',
    this.toolSteps = const [],
    this.isAgentQuestion = false,
    this.agentQuestion = '',
    this.agentOptions = const [],
    this.agentCompleter,
    this.agentAnswered = false,
  });

  final String content;
  final bool isUser;
  final bool isStreaming;
  final String processContent;
  final bool isThinking;

  /// 是否为确认卡消息（T4）
  final bool isClarification;

  /// 确认卡问题
  final String clarifyQuestion;

  /// 快速选项
  final List<String> quickOptions;

  /// 触发确认卡的原始消息（选择选项后拼接发送）
  final String originalMessage;

  /// Agent 工具循环的步骤时间线（供渲染）。
  final List<AgentStep> toolSteps;

  /// 是否为 Agent 提问卡（内联渲染选项按钮）
  final bool isAgentQuestion;

  /// Agent 提问内容
  final String agentQuestion;

  /// Agent 提问选项
  final List<String> agentOptions;

  /// 等待用户回答的 Completer
  final Completer<String>? agentCompleter;

  /// 是否已回答（用于禁用按钮）
  final bool agentAnswered;
}
