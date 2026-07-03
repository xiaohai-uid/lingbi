import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lingbi/core/di/service_locator.dart';
import 'ai_provider.dart';

/// 内置免费的 SenseNova 模型
/// 使用商汤科技 SenseNova API
/// API Key 从 SettingsService 读取（用户配置）或环境变量 SENSENOVA_API_KEY
class FreeProvider implements AIProvider {
  static const String _baseUrl = 'https://token.sensenova.cn/v1/chat/completions';

  String get _apiKey {
    // 优先级: 1. 环境变量 2. SettingsService 用户配置
    final envKey = Platform.environment['SENSENOVA_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;
    try {
      return ServiceLocator.instance.settingsService.getApiKey('sensenova');
    } catch (_) {}
    return '';
  }

  @override
  String get name => 'free';

  @override
  String get displayName => 'SenseNova (商汤)';

  @override
  bool get isAvailable => _apiKey.isNotEmpty;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    final key = _apiKey;
    if (key.isEmpty) {
      yield '请先在设置中配置 SenseNova API Key 或设置 SENSENOVA_API_KEY 环境变量';
      return;
    }

    final body = jsonEncode({
      'model': 'sensenova-6.7-flash-lite',
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        'Accept': 'text/event-stream',
      });
      request.body = body;

      final streamedResponse = await request.send();
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'] ?? '';
              if (content.isNotEmpty) yield content;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      yield '【错误】AI 服务连接失败: $e\n\n请检查网络连接或切换到自配 API Key 模式。';
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in chat(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  @override
  Future<List<double>> embed(String text) async {
    // SenseNova 暂不支持向量嵌入
    return List.filled(768, 0.0);
  }

  @override
  Future<void> dispose() async {}
}