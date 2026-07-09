import 'package:lingbi/core/ai/ai_provider.dart' show ChatMessage;
import 'package:lingbi/core/ai/llm_models.dart';
import 'package:lingbi/core/ai/think_stream_filter.dart';

/// LLM 客户端抽象基类
///
/// 所有 LLM 服务商客户端必须实现此接口。
/// 提供三个核心方法：
/// - [generateText]: 非流式文本生成
/// - [streamText]: 流式文本生成
/// - [generateStructured]: 结构化输出（JSON Schema）
///
/// 内置 [ThinkStreamFilter] 用于过滤流式响应中的思考标签内容。
abstract class BaseLLMClient {
  BaseLLMClient({required this.providerName});
  final String providerName;
  final ThinkStreamFilter _filter = ThinkStreamFilter();

  String get name => providerName;
  bool get isAvailable => true;
  String get displayName => providerName;

  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    final llmMessages = messages
        .map((m) => LLMMessage(role: m.role, content: m.content))
        .toList();
    final request = LLMRequest(
      messages: llmMessages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    yield* streamText(request);
  }

  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final llmMessages = messages
        .map((m) => LLMMessage(role: m.role, content: m.content))
        .toList();
    final request = LLMRequest(
      messages: llmMessages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return generateText(request);
  }

  Future<void> dispose() async {}

  /// 嵌入向量
  Future<List<double>> embed(String text) async => [];

  /// 非流式文本生成
  Future<String> generateText(LLMRequest request);

  /// 流式文本生成（返回 Stream）
  Stream<String> streamText(LLMRequest request);

  /// 结构化输出生成
  ///
  /// [request] 中包含 responseSchema 指定期望的 JSON 格式，
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  );

  /// 过滤流式响应中的思考标签
  ///
  /// 用于 [streamText] 实现中，对每个 chunk 进行过滤。
  /// 返回过滤后的文本，空字符串表示当前 chunk 全部被过滤。
  String filterChunk(String chunk) => _filter.feed(chunk);

  /// 完成过滤，返回剩余文本
  String finishFilter() => _filter.finish();

  /// 重置过滤器
  void resetFilter() => _filter.reset();
}
