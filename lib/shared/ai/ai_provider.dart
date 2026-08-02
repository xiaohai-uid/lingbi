import 'dart:convert';

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

  /// 是否支持 function-calling（工具调用）。
  ///
  /// 默认 false；支持 OpenAI tools 协议的 Provider 应覆盖为 true。
  bool get supportsTools => false;

  /// 带工具的对话（function-calling，非流式）。
  ///
  /// 传入工具规格 [tools]，模型可返回 [ToolTurn.toolCalls] 请求调用工具；
  /// 调用方执行工具后把结果作为 role:'tool' 消息回灌再次调用，直到
  /// [ToolTurn.finishReason] 为 'stop'。默认实现抛 [UnsupportedError]，
  /// 供上层能力探测后回退到确定性流程。
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) {
    throw UnsupportedError('$name 不支持 function-calling');
  }

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
  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  });
  final String role; // 'user', 'assistant', 'system', 'tool'
  final String content;

  /// assistant 消息携带的工具调用请求（function-calling）。
  final List<ToolCall>? toolCalls;

  /// role='tool' 时，对应的工具调用 ID。
  final String? toolCallId;

  /// role='tool' 时的工具名（可选）。
  final String? name;

  Map<String, dynamic> toJson() {
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      return {
        'role': role,
        'content': content.isEmpty ? null : content,
        'tool_calls': toolCalls!.map((t) => t.toRequestJson()).toList(),
      };
    }
    if (role == 'tool') {
      return {
        'role': 'tool',
        'tool_call_id': toolCallId ?? '',
        if (name != null) 'name': name,
        'content': content,
      };
    }
    return {'role': role, 'content': content};
  }
}

/// 模型请求调用的一个工具（function-calling）。
class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  final String id;
  final String name;

  /// 原始参数 JSON 字符串（模型输出，可能不完整）。
  final String argumentsJson;

  /// 解析后的参数；解析失败返回空 map。
  Map<String, dynamic> get arguments {
    try {
      final decoded = jsonDecode(argumentsJson);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> toRequestJson() => {
        'id': id,
        'type': 'function',
        'function': {'name': name, 'arguments': argumentsJson},
      };
}

/// 工具规格（OpenAI function schema）。
class ToolSpec {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON Schema 形式的参数定义。
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toOpenAiJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// 一次带工具能力的模型返回。
class ToolTurn {
  const ToolTurn({
    this.content = '',
    this.toolCalls = const [],
    this.finishReason = 'stop',
  });

  /// 模型文本输出（可能为空，若本轮只请求工具）。
  final String content;

  /// 模型请求调用的工具列表。
  final List<ToolCall> toolCalls;

  /// 结束原因：'stop' | 'tool_calls' | 'length' | ...
  final String finishReason;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}
