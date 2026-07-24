import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class DeepSeekProvider extends AIProvider {

  DeepSeekProvider({String? apiKey, String? modelOverride, http.Client? client})
      : _apiKey = apiKey,
        _modelOverride = modelOverride,
        _client = client ?? http.Client();
  String? _apiKey;
  final String? _modelOverride;
  final http.Client _client;
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';

  set apiKey(String? key) => _apiKey = key;

  @override
  String get name => 'deepseek';

  @override
  String get displayName => 'DeepSeek';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'deepseek-chat';

  String _friendlyError(Object e, [int? statusCode]) {
    if (e is TimeoutException) return '网络连接超时，请检查网络后重试';
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          return 'API Key 无效，请在设置中重新配置';
        case 429:
          return '请求过于频繁，请稍后再试';
        default:
          if (statusCode >= 500) return '服务暂时不可用，请稍后再试';
      }
    }
    return 'DeepSeek 请求失败: $e';
  }

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!isAvailable) {
      yield '请先在设置中配置 DeepSeek API Key';
      return;
    }

    final body = jsonEncode({
      'model': _modelId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'text/event-stream',
      });
      request.body = body;

      final streamedResponse = await _client.send(request).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('连接超时', const Duration(seconds: 30)),
          );
      if (streamedResponse.statusCode != 200) {
        yield _friendlyError(Exception('HTTP ${streamedResponse.statusCode}'), streamedResponse.statusCode);
        return;
      }
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
      yield _friendlyError(e);
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) return '请先在设置中配置 DeepSeek API Key';

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _modelId,
            'messages': messages.map((m) => m.toJson()).toList(),
            'temperature': temperature,
            'max_tokens': maxTokens,
            'stream': false,
          }),
        ).timeout(const Duration(seconds: 120));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['choices']?[0]?['message']?['content'] ?? '';
        }
        return _friendlyError(Exception('HTTP ${response.statusCode}'), response.statusCode);
      } on TimeoutException catch (e) {
        if (attempt == 0) continue;
        return _friendlyError(e);
      } on http.ClientException catch (e) {
        if (attempt == 0) continue;
        return _friendlyError(e);
      } catch (e) {
        return _friendlyError(e);
      }
    }
    return '请求失败，请重试';
  }

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(768, 0);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
