import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/agent/agent_tool_loop.dart';
import 'package:lingbi/services/agent/agent_tool_registry.dart';
import 'package:lingbi/services/agent/session_compactor.dart';

/// 脚本化的 function-calling Provider：按顺序返回预设的 [ToolTurn]。
class ScriptedToolProvider extends AIProvider {
  ScriptedToolProvider(this.turns, {this.support = true});

  final List<ToolTurn> turns;
  final bool support;
  int index = 0;
  final List<List<ChatMessage>> requests = [];

  @override
  bool get supportsTools => support;

  @override
  String get name => 'scripted';

  @override
  String get displayName => 'Scripted';

  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield await chatSync(
        messages: messages, temperature: temperature, maxTokens: maxTokens);
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      'sync-fallback';

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    requests.add(List.of(messages));
    if (index < turns.length) return turns[index++];
    return const ToolTurn(content: '（无更多脚本）', finishReason: 'stop');
  }

  @override
  Future<List<double>> embed(String text) async => const [];

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AgentToolLoop', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('lingbi-agent-loop-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('不支持工具时回退到普通对话（无 fallback）', () async {
      final provider = ScriptedToolProvider(const [], support: false);
      final loop = AgentToolLoop(
        provider: provider,
        registry: AgentToolRegistry(projectDir: dir.path),
        compactor: const SessionCompactor(),
      );
      final result = await loop.run(systemPrompt: 'sys', userGoal: '写一章');
      expect(result.usedFallback, isTrue);
      expect(result.finalText, 'sync-fallback');
      expect(result.steps.any((s) => s.kind == 'fallback'), isTrue);
    });

    test('多轮工具循环：执行工具并以 role:tool 回灌直到 stop', () async {
      final provider = ScriptedToolProvider([
        ToolTurn(toolCalls: [
          ToolCall(
            id: 'c1',
            name: 'file_write',
            argumentsJson: jsonEncode({'path': '章节内容/第1章.md', 'content': '# 第1章\n\n内容'}),
          ),
        ], finishReason: 'tool_calls'),
        const ToolTurn(content: '已完成第1章。', finishReason: 'stop'),
      ]);
      final loop = AgentToolLoop(
        provider: provider,
        registry: AgentToolRegistry(projectDir: dir.path),
        compactor: const SessionCompactor(),
      );
      final result = await loop.run(systemPrompt: 'sys', userGoal: '写第1章');

      expect(result.usedFallback, isFalse);
      expect(result.finalText, '已完成第1章。');
      expect(result.iterations, 2);
      expect(File('${dir.path}/章节内容/第1章.md').existsSync(), isTrue);
      expect(result.steps.any((s) => s.kind == 'tool'), isTrue);

      // 第二次请求应包含 assistant(tool_calls) + tool 结果回灌。
      final second = provider.requests[1];
      expect(second.any((m) => m.role == 'tool' && m.toolCallId == 'c1'), isTrue);
      expect(second.any((m) => m.role == 'assistant' && m.toolCalls != null), isTrue);
    });

    test('达到最大轮次时停止并给出提示', () async {
      final provider = ScriptedToolProvider(List.generate(
        5,
        (_) => ToolTurn(toolCalls: [
          ToolCall(
            id: 'x',
            name: 'list_dir',
            argumentsJson: jsonEncode({'path': ''}),
          ),
        ], finishReason: 'tool_calls'),
      ));
      final loop = AgentToolLoop(
        provider: provider,
        registry: AgentToolRegistry(projectDir: dir.path),
        compactor: const SessionCompactor(),
        maxIterations: 3,
      );
      final result = await loop.run(systemPrompt: 'sys', userGoal: 'g');
      expect(result.iterations, 3);
      expect(result.finalText, isEmpty);
      expect(result.steps.any((s) => s.kind == 'error'), isTrue);
    });
  });
}
