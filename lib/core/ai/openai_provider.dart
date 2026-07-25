import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class OpenAIProvider extends AIProvider {

  OpenAIProvider({String? apiKey, String? modelOverride, http.Client? client})
      : _apiKey = apiKey,
        _modelOverride = modelOverride,
        _client = client ?? http.Client();
  String? _apiKey;
  String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String? _modelOverride;
  final http.Client _client;

  set apiKey(String? key) => _apiKey = key;
  set baseUrl(String url) => _baseUrl = url;

  @override
  String get name => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'gpt-4o-mini';

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
    return 'OpenAI 请求失败: $e';
  }

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
              final jsonData = jsonDecode(data);
              final content = jsonData['choices']?[0]?['delta']?['content'] ?? '';
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
    if (!isAvailable) return '请先在设置中配置 OpenAI API Key';
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
          final jsonData = jsonDecode(response.body);
          return jsonData['choices']?[0]?['message']?['content'] ?? '';
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
  Future<List<String>> listModels() async {
    if (!isAvailable) return [];
    try {
      final modelsUrl = _baseUrl.replaceAll('/chat/completions', '/models');
      final response = await _client.get(
        Uri.parse(modelsUrl),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(const Duration(seconds: 10));
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
  Future<List<double>> embed(String text) async {
    if (!isAvailable) {
      return List.filled(768, 0);
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
      return List.filled(768, 0);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('OpenAI embed error: $e');
      return List.filled(768, 0);
    }
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
