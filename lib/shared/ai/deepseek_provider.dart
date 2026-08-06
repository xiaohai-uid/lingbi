import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../errors/ai_error.dart';

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

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!isAvailable) {
      throw const AIException(
        type: AIExceptionType.noApiKey,
        message: '请先在设置中配置 DeepSeek API Key',
      );
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
            onTimeout: () =>
                throw TimeoutException('连接超时', const Duration(seconds: 30)),
          );
      if (streamedResponse.statusCode != 200) {
        final errBody = await streamedResponse.stream.bytesToString();
        throw aiExceptionFromHttp(streamedResponse.statusCode, errBody);
      }
      bool isReasoning = false;
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              if (isReasoning) yield '</think>';
              return;
            }
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              final reasoning = delta?['reasoning_content'] ?? '';
              final content = delta?['content'] ?? '';

              if (reasoning.isNotEmpty) {
                if (!isReasoning) {
                  isReasoning = true;
                  yield '<think>';
                }
                yield reasoning;
              } else if (content.isNotEmpty) {
                if (isReasoning) {
                  isReasoning = false;
                  yield '</think>';
                }
                yield content;
              }
            } catch (_) {}
          }
        }
      }
      if (isReasoning) yield '</think>';
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
      throw const AIException(
        type: AIExceptionType.noApiKey,
        message: '请先在设置中配置 DeepSeek API Key',
      );
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .post(
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
            )
            .timeout(const Duration(seconds: 120));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final message = json['choices']?[0]?['message'];
          final reasoning = message?['reasoning_content'] ?? '';
          final content = message?['content'] ?? '';
          if (reasoning.isNotEmpty) {
            return '<think>$reasoning</think>$content';
          }
          return content;
        }
        throw aiExceptionFromHttp(response.statusCode, response.body);
      } on TimeoutException catch (e) {
        if (attempt == 0) continue;
        throw aiExceptionFromObject(e);
      } on http.ClientException catch (e) {
        if (attempt == 0) continue;
        throw aiExceptionFromObject(e);
      } catch (e) {
        throw aiExceptionFromObject(e);
      }
    }
    throw aiExceptionFromObject(TimeoutException('请求失败，请重试'));
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
    return List.filled(768, 0);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
