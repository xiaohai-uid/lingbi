import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../models/endpoint_config.dart';
import '../../errors/ai_error.dart';

/// OpenAI 兼容协议 Provider
///
/// 支持所有 OpenAI 兼容格式的 API 端点（/v1/chat/completions）。
/// 适用于 OpenAI、DeepSeek、SenseNova 及任何自定义 OpenAI 兼容端点。
class OpenAICompatibleProvider extends AIProvider {
  /// 创建 OpenAI 兼容 Provider
  ///
  /// [config] 端点配置，必须为 openai 协议
  /// [client] 可选的 HTTP 客户端（用于测试注入）
  OpenAICompatibleProvider({
    required EndpointConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final EndpointConfig _config;
  final http.Client _client;
  String? _modelOverride;

  @override
  String get name => _config.id;

  @override
  String get displayName => _config.name;

  @override
  bool get isAvailable => _config.apiKey != null && _config.apiKey!.isNotEmpty;

  @override
  bool get supportsTools => true;

  @override
  String get currentModelId => _modelOverride ?? _config.modelId;

  /// 设置模型 ID（运行时切换）
  set modelOverride(String modelId) {
    _modelOverride = modelId;
  }

  /// 获取认证头
  Map<String, String> get _authHeaders {
    if (_config.apiKey == null) return {};
    final strategy = _config.authStrategy ?? 'bearer';
    return switch (strategy.toLowerCase()) {
      'x-api-key' => {'x-api-key': _config.apiKey!},
      _ => {'Authorization': 'Bearer ${_config.apiKey}'},
    };
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequestBody({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool stream = false,
  }) {
    return {
      'model': currentModelId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      if (stream) 'stream': true,
    };
  }

  /// 解析 SSE 流中的内容（支持 reasoning 思考模型）
  ///
  /// 返回 (content, isReasoning) 元组
  (String, bool)? _parseSseChunk(String line) {
    if (!line.startsWith('data: ')) return null;
    final data = line.substring(6).trim();
    if (data == '[DONE]') return null;

    try {
      final json = jsonDecode(data);
      final delta = json['choices']?[0]?['delta'];
      if (delta == null) return null;
      final reasoning = delta['reasoning'] ?? delta['reasoning_content'];
      if (reasoning != null && (reasoning as String).isNotEmpty) {
        return (reasoning, true);
      }
      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return (content, false);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!isAvailable) {
      throw AIException(
        type: AIExceptionType.noApiKey,
        message: '请先配置 ${_config.name} API Key',
      );
    }

    final body = _buildRequestBody(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: true,
    );

    try {
      final request = http.Request('POST', Uri.parse(_config.chatEndpoint));
      request.headers.addAll({
        'Content-Type': 'application/json',
        ..._authHeaders,
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(body);

      final streamedResponse = await _client.send(request).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('连接超时', const Duration(seconds: 15)),
          );

      if (streamedResponse.statusCode != 200) {
        final errBody = await streamedResponse.stream.bytesToString();
        throw aiExceptionFromHttp(streamedResponse.statusCode, errBody);
      }

      bool isReasoning = false;
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder).timeout(
                const Duration(seconds: 120),
                onTimeout: (eventSink) => eventSink.addError(
                  TimeoutException(
                    '请求超时',
                    const Duration(seconds: 120),
                  ),
                ),
              )) {
        for (final line in chunk.split('\n')) {
          final parsed = _parseSseChunk(line);
          if (parsed != null) {
            final (text, reasoning) = parsed;
            if (reasoning) {
              if (!isReasoning) {
                isReasoning = true;
                yield '<think>';
              }
              yield text;
            } else {
              if (isReasoning) {
                isReasoning = false;
                yield '</think>';
              }
              yield text;
            }
          }
        }
      }
      if (isReasoning) yield '</think>';
    } on AIException {
      rethrow;
    } on TimeoutException {
      throw aiExceptionFromObject(
        TimeoutException('请求超时，请检查网络连接'),
      );
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) {
      throw AIException(
        type: AIExceptionType.noApiKey,
        message: '请先配置 ${_config.name} API Key',
      );
    }

    final body = _buildRequestBody(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    try {
      final response = await _client
          .post(
            Uri.parse(_config.chatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              ..._authHeaders,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final message = json['choices']?[0]?['message'];
        final content = message?['content'] as String? ?? '';
        final reasoning = (message?['reasoning'] ??
                message?['reasoning_content']) as String? ??
            '';
        if (content.isNotEmpty) return content;
        if (reasoning.isNotEmpty) return '<think>$reasoning</think>';
        return '';
      }
      throw aiExceptionFromHttp(response.statusCode, response.body);
    } on AIException {
      rethrow;
    } on TimeoutException {
      throw aiExceptionFromObject(
        TimeoutException('请求超时，请检查网络连接'),
      );
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!isAvailable) return List.filled(768, 0);
    return List.filled(768, 0);
  }

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) {
      throw AIException(
        type: AIExceptionType.noApiKey,
        message: '请先配置 ${_config.name} API Key',
      );
    }

    final body = <String, dynamic>{
      'model': currentModelId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      if (tools.isNotEmpty)
        'tools': tools.map((t) => t.toOpenAiJson()).toList(),
      if (tools.isNotEmpty) 'tool_choice': 'auto',
    };

    try {
      final response = await _client
          .post(
            Uri.parse(_config.chatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              ..._authHeaders,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw aiExceptionFromHttp(response.statusCode, response.body);
      }

      // 用 bodyBytes + utf8 解码，避免中文乱码。
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final choice = json['choices']?[0];
      final message = choice?['message'];
      final content = message?['content'] as String? ?? '';
      final finishReason = choice?['finish_reason'] as String? ?? 'stop';

      final rawToolCalls = message?['tool_calls'] as List<dynamic>?;
      final toolCalls = <ToolCall>[];
      if (rawToolCalls != null) {
        for (final tc in rawToolCalls) {
          final fn = tc['function'];
          if (fn == null) continue;
          toolCalls.add(ToolCall(
            id: tc['id'] as String? ?? '',
            name: fn['name'] as String? ?? '',
            argumentsJson: fn['arguments'] as String? ?? '{}',
          ));
        }
      }

      return ToolTurn(
        content: content,
        toolCalls: toolCalls,
        finishReason: finishReason,
      );
    } on AIException {
      rethrow;
    } on TimeoutException {
      throw aiExceptionFromObject(
        TimeoutException('请求超时，请检查网络连接'),
      );
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<List<String>> listModels() async {
    if (!isAvailable) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(_config.modelsEndpoint),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body);
      final data = json['data'] as List<dynamic>?;
      if (data == null) return [];
      return data
          .map((item) => item['id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
