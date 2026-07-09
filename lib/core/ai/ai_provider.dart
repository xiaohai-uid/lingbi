import 'package:lingbi/core/ai/llm_models.dart' show LLMMessage;

/// AI Provider 抽象接口（已废弃）
///
/// 请使用 `BaseLLMClient` 替代。
@Deprecated('Use BaseLLMClient from llm_client.dart instead')
abstract class AIProvider {
  String get name;
  String get displayName;
  bool get isAvailable;

  /// 流式聊天
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  });

  /// 非流式聊天
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  });

  /// 文本嵌入（向量化）
  Future<List<double>> embed(String text);

  /// 释放资源
  Future<void> dispose();
}

/// 聊天消息（兼容旧接口）
///
/// 新代码请使用 [LLMMessage]。
class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
