import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class OpenAIProvider implements AIProvider {
  String? _apiKey;
  String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String? _modelOverride;

  OpenAIProvider({String? apiKey, String? modelOverride})
      : _apiKey = apiKey,
        _modelOverride = modelOverride;

  set apiKey(String? key) => _apiKey = key;
  set baseUrl(String url) => _baseUrl = url;

  @override
  String get name => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'gpt-4o-mini';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!isAvailable) {
      yield 'Please configure OpenAI API Key in settings';
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
              final jsonData = jsonDecode(data);
              final content = jsonData['choices']?[0]?['delta']?['content'] ?? '';
              if (content.isNotEmpty) yield content;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      yield 'OpenAI API error: $e';
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isAvailable) return 'Please configure OpenAI API Key in settings';
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
        final jsonData = jsonDecode(response.body);
        return jsonData['choices']?[0]?['message']?['content'] ?? '';
      }
      return 'API error: ${response.statusCode}';
    } catch (e) {
      return 'OpenAI API error: $e';
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!isAvailable) {
      return List.filled(768, 0.0);
    }
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'text-embedding-3-small',
          'input': text,
          'dimensions': 768,
        }),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final embedding = json['data']?[0]?['embedding'] as List<dynamic>?;
        if (embedding != null) {
          return embedding.map((e) => (e as num).toDouble()).toList();
        }
      }
      return List.filled(768, 0.0);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('OpenAI embed error: $e');
      return List.filled(768, 0.0);
    }
  }

  @override
  Future<void> dispose() async {}
}
