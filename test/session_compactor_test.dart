import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/agent/session_compactor.dart';

void main() {
  group('SessionCompactor', () {
    test('未超预算时原样返回', () {
      const compactor = SessionCompactor(tokenBudget: 100000, keepRecent: 2);
      final msgs = [
        const ChatMessage(role: 'system', content: 'sys'),
        const ChatMessage(role: 'user', content: 'hi'),
        const ChatMessage(role: 'assistant', content: 'hello'),
      ];
      expect(compactor.compact(msgs), same(msgs));
    });

    test('超预算时折叠早期消息并保留系统与最近消息', () {
      const compactor = SessionCompactor(tokenBudget: 20, keepRecent: 2);
      final msgs = <ChatMessage>[
        const ChatMessage(role: 'system', content: 'sys'),
        const ChatMessage(role: 'user', content: '早期问题一早期问题一早期问题一早期问题一早期问题一'),
        const ChatMessage(role: 'assistant', content: '早期回答一早期回答一早期回答一早期回答一早期回答一'),
        const ChatMessage(role: 'user', content: '最近问题'),
        const ChatMessage(role: 'assistant', content: '最近回答'),
      ];
      final out = compactor.compact(msgs);

      expect(out.length, lessThan(msgs.length));
      expect(out.first.role, 'system');
      expect(out.first.content, 'sys');
      // 摘要消息
      expect(out.any((m) => m.content.contains('早期对话摘要')), isTrue);
      // 最近两条保留
      expect(out.last.content, '最近回答');
      expect(out[out.length - 2].content, '最近问题');
    });

    test('保持 tool_calls 配对：尾部不以孤立 tool 消息开头', () {
      const compactor = SessionCompactor(tokenBudget: 30, keepRecent: 2);
      final msgs = <ChatMessage>[
        const ChatMessage(role: 'system', content: 'sys'),
        const ChatMessage(role: 'user', content: '很长很长很长很长很长很长很长很长很长很长'),
        const ChatMessage(
          role: 'assistant',
          content: '',
          toolCalls: [ToolCall(id: 'c1', name: 'file_read', argumentsJson: '{}')],
        ),
        const ChatMessage(role: 'tool', content: 'tool-result', toolCallId: 'c1'),
        const ChatMessage(role: 'assistant', content: 'final'),
      ];
      final out = compactor.compact(msgs);

      // 找到第一个非 system 消息：若为 tool 则其父 assistant 必须也在尾部。
      for (var i = 0; i < out.length; i++) {
        if (out[i].role == 'tool') {
          expect(
            out.sublist(0, i).any((m) =>
                m.role == 'assistant' &&
                (m.toolCalls?.any((t) => t.id == out[i].toolCallId) ?? false)),
            isTrue,
            reason: 'tool 消息的父 assistant(tool_calls) 被折叠，破坏协议',
          );
        }
      }
    });
  });
}
