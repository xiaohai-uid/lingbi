import 'dart:math';
import 'base_client.dart';
import 'llm_models.dart';

/// Free Provider — 演示模式
///
/// 不消耗 API Key，但会提示用户配置真实 API Key。
/// 仅用于首次启动时的界面预览，不会生成真实 AI 内容。
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
    return '请在设置中配置 API Key 后使用（支持 DeepSeek / OpenAI / Claude）。\n'
        '当前为免费演示模式，仅作界面预览，不会生成真实 AI 内容。';
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    yield '请在设置中配置 API Key 后使用（支持 DeepSeek / OpenAI / Claude）。\n'
        '当前为免费演示模式，仅作界面预览，不会生成真实 AI 内容。';
  }
  @override
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    throw UnsupportedError(
      '演示模式不支持结构化生成。请在设置中配置真实的 API Key（DeepSeek / OpenAI / Claude）。',
    );
  }

  /// 模拟嵌入向量（向后兼容）
  @override
  Future<List<double>> embed(String text) async {
    final rng = Random(text.hashCode);
    return List.generate(128, (_) => rng.nextDouble());
  }
}
