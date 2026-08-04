import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_loop.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

/// Phase 1.3 测试：停止生成机制
///
/// 验证：
/// 1. AgentToolLoop 支持 cancel() 后中断循环
/// 2. cancel 后返回已收集的部分结果（不丢失已有步骤）
/// 3. cancel 不影响后续新的 run() 调用
void main() {
  group('AgentToolLoop cancel', () {
    test('cancel() 中断工具循环', () async {
      // 构造一个会无限调用工具的 mock provider
      final provider = _InfiniteToolProvider();
      final registry = AgentToolRegistry(
          projectDir: '/tmp/test',
          mutationProtocol: _cancelProtocol(),
        );
      final loop = AgentToolLoop(
        provider: provider,
        registry: registry,
        maxIterations: 100,
      );

      // 异步启动 run
      final future = loop.run(
        systemPrompt: 'test',
        userGoal: 'do something',
      );

      // 等一小段时间让循环开始
      await Future.delayed(const Duration(milliseconds: 50));

      // 取消
      loop.cancel();

      final result = await future;

      // 应该提前结束，不是跑满 100 轮
      expect(result.iterations, lessThan(100));
      // 应该有步骤记录（至少开始了一轮）
      expect(result.steps, isNotEmpty);
    });

    test('cancel 后新 run 正常工作', () async {
      final provider = _InfiniteToolProvider();
      final registry = AgentToolRegistry(
          projectDir: '/tmp/test',
          mutationProtocol: _cancelProtocol(),
        );
      final loop = AgentToolLoop(
        provider: provider,
        registry: registry,
        maxIterations: 100,
      );

      // 第一次 run + cancel
      final f1 = loop.run(systemPrompt: 'test', userGoal: 'first');
      await Future.delayed(const Duration(milliseconds: 50));
      loop.cancel();
      await f1;

      // 第二次 run 应该正常（不被上次的 cancel 影响）
      provider.callCount = 0;
      final f2 = loop.run(systemPrompt: 'test', userGoal: 'second');
      await Future.delayed(const Duration(milliseconds: 50));
      loop.cancel();
      final result2 = await f2;

      expect(result2.steps, isNotEmpty);
    });
  });
}

/// Mock provider：每次 chatWithTools 都返回一个工具调用（模拟无限循环）
class _InfiniteToolProvider extends AIProvider {
  int callCount = 0;

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;
  @override
  bool get supportsTools => true;
  @override
  String get currentModelId => 'mock-model';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield 'mock response';
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      'mock response';

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    callCount++;
    // 让出事件循环，使 cancel() 有机会在迭代间生效
    await Future.delayed(const Duration(milliseconds: 5));
    // 永远返回一个工具调用，让循环不停
    return ToolTurn(
      content: '',
      toolCalls: [
        ToolCall(
          id: 'call_$callCount',
          name: 'list_dir',
          argumentsJson: '{"path":""}',
        ),
      ],
    );
  }

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<void> dispose() async {}
}


LocalMutationProtocol _cancelProtocol() => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '/tmp/test/.lingbi/cj'),
      store: FileCanonicalStore(
        projectRoot: '/tmp/test',
        atomicStore: AtomicFileStore(),
      ),
    );
