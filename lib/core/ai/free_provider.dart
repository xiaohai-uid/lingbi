import 'dart:math';
import 'base_client.dart';
import 'llm_models.dart';

/// Free Provider - 免费 AI 服务（模拟实现）
///
/// 不消耗 API Key，返回模拟响应。用于测试和演示。
class FreeProvider extends BaseLLMClient {
  FreeProvider({String? modelOverride, String name = 'free'})
      : _modelOverride = modelOverride,
        super(providerName: name);
  final String? _modelOverride;

  @override
  String get displayName => 'Free Provider';

  @override
  bool get isAvailable => true;

  @override
  Future<String> generateText(LLMRequest request) async {
    final lastMessage = request.messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => request.messages.first,
    );
    return 'Free provider simulation: ${lastMessage.content}';
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    final lastMessage = request.messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => request.messages.first,
    );
    yield 'Free provider simulation: ';
    yield lastMessage.content;
  }

  @override
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final result = <String, dynamic>{
      'content': 'Free provider simulation',
      'model': _modelOverride ?? 'free',
    };
    return fromJson(result);
  }

  /// 模拟嵌入向量（向后兼容）
  @override
  Future<List<double>> embed(String text) async {
    final rng = Random(text.hashCode);
    return List.generate(128, (_) => rng.nextDouble());
  }
}
