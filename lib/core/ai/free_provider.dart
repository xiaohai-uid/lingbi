import 'package:lingbi/core/ai/ai_provider.dart';

/// Free Provider - 免费 AI 服务
class FreeProvider extends AIProvider {
  final String? _modelOverride;

  FreeProvider({String? modelOverride}) : _modelOverride = modelOverride;

  @override
  String get name => 'free';

  @override
  String get displayName => 'Free Provider';

  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    final lastMessage = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => messages.first,
    );
    yield 'Free provider simulation: ${lastMessage.content}';
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final lastMessage = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => messages.first,
    );
    return 'Free provider simulation: ${lastMessage.content}';
  }

  @override
  Future<List<double>> embed(String text) async {
    // 简单的模拟嵌入向量
    final bytes = text.codeUnits;
    final result = <double>[];
    for (var i = 0; i < 128; i++) {
      result.add((bytes.fold(0, (a, b) => a + b) + i) % 1000 / 1000);
    }
    return result;
  }

  @override
  Future<void> dispose() async {}
}
