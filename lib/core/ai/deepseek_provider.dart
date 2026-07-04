import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class DeepSeekProvider implements AIProvider {
  String? _apiKey;
  final String? _modelOverride;
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';

  DeepSeekProvider({String? apiKey, String? modelOverride})
      : _apiKey = apiKey,
        _modelOverride = modelOverride;

  set apiKey(String? key) => _apiKey = key;

  @override
  String get name => 'deepseek';

  @override
  String get displayName => 'DeepSeek';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'deepseek-chat';

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
      yield 'DeepSeek API 错误: $e';
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) return '请先在设置中配置 DeepSeek API Key';
    
    try {
      final response = await http.post(
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
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices']?[0]?['message']?['content'] ?? '';
      }
      return 'API 错误: ${response.statusCode}';
    } catch (e) {
      return 'DeepSeek API 错误: $e';
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(768, 0.0);
  }

  @override
  Future<void> dispose() async {}
}
