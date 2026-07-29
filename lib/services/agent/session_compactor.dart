/// SessionCompactor — 会话级上下文压缩。
///
/// Agent 工具循环会不断追加 assistant/tool 消息，长对话可能逼近模型
/// 上下文窗口。逼近预算时，把**较早的消息**折叠成一条"早期对话摘要"，
/// 保留系统指令与最近若干条消息，从而在不丢关键上下文的前提下腾出空间。
///
/// 采用**确定性摘要**（不额外调用 LLM）：折叠区消息按角色浓缩为要点，
/// 因此稳定、可测、对免费模型友好。压缩时严格保持 function-calling 的
/// `assistant(tool_calls) → tool` 配对：绝不让尾部以孤立的 tool 消息开头。
library;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/modules/context/context_compiler.dart';

class SessionCompactor {
  const SessionCompactor({
    this.tokenBudget = 8000,
    this.keepRecent = 6,
    this.perMessageCap = 600,
  });

  /// 依据 Provider 当前模型窗口推导压缩阈值（与 [CompilerConfig.forModel] 同源）。
  factory SessionCompactor.forProvider(
    AIProvider provider, {
    int keepRecent = 6,
  }) {
    final info = ModelRegistry.instance.findModel(provider.currentModelId);
    final cfg = CompilerConfig.forModel(
      contextWindow: info?.contextWindow,
      maxOutputTokens: info?.maxOutputTokens,
    );
    return SessionCompactor(tokenBudget: cfg.tokenBudget, keepRecent: keepRecent);
  }

  /// 触发压缩的 token 阈值。
  final int tokenBudget;

  /// 保留末尾的消息条数（连同系统消息永不折叠）。
  final int keepRecent;

  /// 折叠区单条消息浓缩后的最大字符数。
  final int perMessageCap;

  /// 估算消息列表的总 token 数。
  int estimateTokens(List<ChatMessage> messages) =>
      messages.fold(0, (s, m) => s + ModelRegistry.estimateTokens(m.content));

  /// 是否需要压缩（估算 token 超过预算）。
  bool shouldCompact(List<ChatMessage> messages) =>
      estimateTokens(messages) > tokenBudget;

  /// 返回压缩后的消息列表；无需压缩或无法安全切分时原样返回。
  List<ChatMessage> compact(List<ChatMessage> messages) {
    if (messages.length <= keepRecent + 2) return messages;
    if (!shouldCompact(messages)) return messages;

    final hasSystem = messages.first.role == 'system';
    final headCount = hasSystem ? 1 : 0;

    var cut = messages.length - keepRecent;
    if (cut <= headCount) return messages;

    // 保持 tool_calls 配对：尾部不能以孤立的 tool 消息开头
    // （其 assistant(tool_calls) 父消息会被折叠 → 破坏协议）。
    while (cut < messages.length && messages[cut].role == 'tool') {
      cut++;
    }
    if (cut >= messages.length) return messages; // 无法安全切分

    final folded = messages.sublist(headCount, cut);
    if (folded.isEmpty) return messages;

    final summary = ChatMessage(role: 'system', content: _digest(folded));
    return [
      if (hasSystem) messages.first,
      summary,
      ...messages.sublist(cut),
    ];
  }

  String _digest(List<ChatMessage> msgs) {
    final b = StringBuffer()
      ..writeln('[早期对话摘要（已折叠 ${msgs.length} 条消息以节省上下文）]');
    for (final m in msgs) {
      switch (m.role) {
        case 'user':
          b.writeln('· 用户：${_cap(m.content)}');
        case 'assistant':
          if (m.toolCalls != null && m.toolCalls!.isNotEmpty) {
            final names = m.toolCalls!.map((t) => t.name).join('、');
            b.writeln('· 助手请求工具：$names');
            if (m.content.trim().isNotEmpty) {
              b.writeln('  说明：${_cap(m.content)}');
            }
          } else {
            b.writeln('· 助手：${_cap(m.content)}');
          }
        case 'tool':
          final tag = m.name != null ? '（${m.name}）' : '';
          b.writeln('· 工具$tag结果：${_cap(m.content)}');
        default:
          b.writeln('· ${m.role}：${_cap(m.content)}');
      }
    }
    return b.toString().trim();
  }

  String _cap(String s) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= perMessageCap) return t;
    return '${t.substring(0, perMessageCap)}…';
  }
}
