import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';
import '../models/endpoint_config.dart';
import '../../errors/ai_error.dart';

/// Anthropic 协议 Provider
///
/// 支持 Anthropic 格式的 API 端点（/v1/messages）。
/// 适用于 Claude 及任何自定义 Anthropic 兼容端点。
class AnthropicProvider extends AIProvider {
  /// 创建 Anthropic Provider
  ///
  /// [config] 端点配置，必须为 anthropic 协议
  /// [client] 可选的 HTTP 客户端（用于测试注入）
  AnthropicProvider({
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

  /// 转换消息格式（Anthropic 不支持 system 角色，需单独提取）
  List<Map<String, dynamic>> _convertMessages(List<ChatMessage> messages) {
    return messages
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();
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

    final systemMsg = messages
        .where((m) => m.role == 'system')
        .map((m) => m.content)
        .join('\n');
    final userMsgs = messages.where((m) => m.role != 'system').toList();

    try {
      final response = await _client
          .post(
            Uri.parse(_config.chatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _config.apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': currentModelId,
              'max_tokens': maxTokens,
              if (systemMsg.isNotEmpty) 'system': systemMsg,
              'messages': _convertMessages(userMsgs),
              'temperature': temperature,
            }),
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () =>
                throw TimeoutException('请求超时', const Duration(seconds: 120)),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['content'] as List?;
        if (content != null && content.isNotEmpty) {
          for (final block in content) {
            if (block['type'] == 'text') {
              yield block['text'] as String;
            }
          }
        }
      } else {
        throw aiExceptionFromHttp(response.statusCode, response.body);
      }
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

    final buffer = StringBuffer();
    await chat(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    ).forEach(buffer.write);
    return buffer.toString();
  }

  @override
  Future<List<double>> embed(String text) async {
    // Anthropic 暂未开放 embedding 接口
    return List.filled(768, 0);
  }

  @override
  Future<List<String>> listModels() async {
    if (!isAvailable) return [];
    // Anthropic 标准 API 不提供 /v1/models 端点
    return [];
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
