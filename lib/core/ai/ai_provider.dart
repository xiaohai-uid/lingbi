/// AI Provider 抽象接口
///
/// 所有 AI 模型提供商必须实现此接口。
abstract class AIProvider {
  String get name;
  String get displayName;
  bool get isAvailable;

  /// 当前使用的模型 ID
  String get currentModelId => '';

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

  /// 取消当前正在进行的请求
  void cancel() {}

  /// 测试连接可用性
  ///
  /// 返回 [ConnectionTestResult]，包含延迟和状态信息。
  Future<ConnectionTestResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      await chatSync(
        messages: [const ChatMessage(role: 'user', content: 'Hi')],
        maxTokens: 5,
      );
      stopwatch.stop();
      return ConnectionTestResult(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        modelId: currentModelId,
        message: '连接成功',
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        modelId: currentModelId,
        message: _classifyConnectionError(e),
      );
    }
  }

  /// 获取可用模型列表（调用 /v1/models 端点）
  ///
  /// 不支持时返回空列表。
  Future<List<String>> listModels() async => [];

  /// 释放资源
  Future<void> dispose();

  /// 将连接错误转换为用户可理解的消息
  String _classifyConnectionError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('403') || msg.contains('unauthorized')) {
      return 'API Key 无效，请检查是否复制完整';
    }
    if (msg.contains('429')) {
      return '请求过于频繁，请稍后重试';
    }
    if (msg.contains('socket') || msg.contains('timeout') || msg.contains('connection')) {
      return '网络连接失败，请检查网络设置';
    }
    if (msg.contains('404')) {
      return 'API 端点不存在，请检查 Base URL 配置';
    }
    return '连接失败，请检查网络和配置';
  }
}

/// 连接测试结果
class ConnectionTestResult {
  const ConnectionTestResult({
    required this.success,
    required this.latencyMs,
    this.modelId = '',
    required this.message,
    this.providerId = '',
    this.responsePreview,
    this.errorCategory,
  });

  /// 是否连接成功
  final bool success;

  /// 响应延迟（毫秒）
  final int latencyMs;

  /// 响应的模型 ID
  final String modelId;

  /// 结果消息（成功或错误描述）
  final String message;

  /// 供应商 ID
  final String providerId;

  /// 响应预览（仅成功时生成，最多 80 字符，去换行控制字符）
  final String? responsePreview;

  /// 错误分类（失败时的中文分类）
  final String? errorCategory;

  /// 延迟（Duration 形式）
  Duration get latency => Duration(milliseconds: latencyMs);

  @override
  String toString() => success
      ? '连接成功 (${latencyMs}ms, 模型: $modelId)'
      : message;
}

class ChatMessage {

  const ChatMessage({required this.role, required this.content});
  final String role; // 'user', 'assistant', 'system'
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
