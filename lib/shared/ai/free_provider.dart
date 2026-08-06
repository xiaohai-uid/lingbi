import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/errors/ai_error.dart';

/// Free Provider - 只在存在合法匿名能力时提供体验模型。
///
/// 当前默认不假设 OpenCode Zen 或任何第三方端点免 Key 可用。
/// 没有匿名能力时，所有生成和连接测试都必须明确失败，
/// 并提示用户前往设置配置 API Key。
class FreeProvider extends AIProvider {
  FreeProvider({
    http.Client? client,
    this.anonymousCapability = false,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// 是否存在经过确认的合法匿名能力。
  ///
  /// 生产默认 false；接入经过授权的免费端点时显式打开。
  final bool anonymousCapability;

  static const _baseUrl = 'https://opencode.ai/zen/v1/chat/completions';
  static const _model = 'deepseek-v4-flash-free';
  static const _connectTimeout = Duration(seconds: 15);
  static const _requestTimeout = Duration(seconds: 120);

  @override
  String get name => 'free';

  @override
  String get displayName => '体验模型（免费）';

  @override
  bool get isAvailable => hasAnonymousCapability;

  bool get hasAnonymousCapability => anonymousCapability;

  @override
  bool get supportsTools => hasAnonymousCapability;

  @override
  String get currentModelId => _model;

  AIException _missingKeyError() => const AIException(
        type: AIExceptionType.noApiKey,
        message: '当前体验模型需要配置 API Key\n请前往设置完成配置',
      );

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    if (!isAvailable) throw _missingKeyError();

    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    try {
      final request = http.Request('POST', Uri.parse(_baseUrl))
        ..headers.addAll(_headers)
        ..body = body;

      final response = await _client.send(request).timeout(
            _connectTimeout,
            onTimeout: () => throw TimeoutException('连接超时', _connectTimeout),
          );
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw aiExceptionFromHttp(response.statusCode, errBody);
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(
            _requestTimeout,
            onTimeout: (eventSink) => eventSink.addError(
              TimeoutException('请求超时', _requestTimeout),
            ),
          );

      await for (final chunk in lines) {
        if (!chunk.startsWith('data: ')) continue;
        final data = chunk.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta'] as Map?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) yield content;
        } catch (_) {}
      }
    } on AIException {
      rethrow;
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (!isAvailable) throw _missingKeyError();

    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      final resp = await _client
          .post(Uri.parse(_baseUrl), headers: _headers, body: body)
          .timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException('请求超时', _requestTimeout),
          );

      if (resp.statusCode != 200) {
        throw aiExceptionFromHttp(resp.statusCode, resp.body);
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return json['choices']?[0]?['message']?['content'] as String? ?? '';
    } on AIException {
      rethrow;
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (!isAvailable) throw _missingKeyError();

    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'tools': tools.map((t) => t.toOpenAiJson()).toList(),
    });

    try {
      final resp = await _client
          .post(Uri.parse(_baseUrl), headers: _headers, body: body)
          .timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException('请求超时', _requestTimeout),
          );

      if (resp.statusCode != 200) {
        throw aiExceptionFromHttp(resp.statusCode, resp.body);
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final choice = json['choices']?[0] as Map? ?? {};
      final message = choice['message'] as Map? ?? {};
      final content = message['content'] as String? ?? '';
      final rawToolCalls = message['tool_calls'] as List?;

      if (rawToolCalls == null || rawToolCalls.isEmpty) {
        return ToolTurn(content: content);
      }

      final toolCalls = rawToolCalls.map((tc) {
        final fn = tc['function'] as Map? ?? {};
        return ToolCall(
          id: tc['id'] as String? ?? '',
          name: fn['name'] as String? ?? '',
          argumentsJson: fn['arguments'] as String? ?? '{}',
        );
      }).toList();

      return ToolTurn(content: content, toolCalls: toolCalls);
    } on AIException {
      rethrow;
    } catch (e) {
      throw aiExceptionFromObject(e);
    }
  }

  @override
  Future<ConnectionTestResult> testConnection() async {
    if (!isAvailable) {
      return ConnectionTestResult(
        success: false,
        latencyMs: 0,
        modelId: currentModelId,
        providerId: name,
        message: _missingKeyError().message,
        errorCategory: 'NO_API_KEY',
      );
    }
    return super.testConnection();
  }

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(128, 0);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
