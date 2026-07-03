/// AI Provider 抽象接口
///
/// 所有 AI 模型提供商必须实现此接口。
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

class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
