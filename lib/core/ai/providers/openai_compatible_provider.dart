import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../models/endpoint_config.dart';

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

  /// 解析 SSE 流中的内容
  String? _parseSseChunk(String line) {
    if (!line.startsWith('data: ')) return null;
    final data = line.substring(6).trim();
    if (data == '[DONE]') return null;

    try {
      final json = jsonDecode(data);
      return json['choices']?[0]?['delta']?['content'] as String?;
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
      yield '请先配置 $_config.name API Key';
      return;
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
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('连接超时'),
      );

      if (streamedResponse.statusCode != 200) {
        yield _friendlyHttpError(streamedResponse.statusCode);
        return;
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final content = _parseSseChunk(line);
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        }
      }
    } on TimeoutException {
      yield '请求超时，请检查网络连接';
    } catch (e) {
      yield '$_config.name API 错误: $e';
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) {
      return '请先配置 $_config.name API Key';
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
        return json['choices']?[0]?['message']?['content'] ?? '';
      }
      return _friendlyHttpError(response.statusCode);
    } on TimeoutException {
      return '请求超时，请检查网络连接';
    } catch (e) {
      return '$_config.name API 错误: $e';
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!isAvailable) return List.filled(768, 0);
    return List.filled(768, 0);
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

  /// 将 HTTP 状态码转换为用户友好的中文提示
  String _friendlyHttpError(int statusCode) {
    return switch (statusCode) {
      401 => 'API Key 无效，请检查是否复制完整',
      403 => '权限不足，请检查账户状态',
      404 => 'API 端点不存在，请检查 Base URL 配置',
      429 => '请求过于频繁，请稍后重试',
      _ when statusCode >= 500 => '服务端错误，请稍后重试',
      _ => 'HTTP 错误: $statusCode',
    };
  }
}
