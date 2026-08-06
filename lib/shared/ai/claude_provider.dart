import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../errors/ai_error.dart';

class ClaudeProvider extends AIProvider {
  ClaudeProvider({String? apiKey, String? modelOverride, http.Client? client})
      : _apiKey = apiKey,
        _modelOverride = modelOverride,
        _client = client ?? http.Client();
  String? _apiKey;
  final String? _modelOverride;
  final http.Client _client;
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  set apiKey(String? key) => _apiKey = key;

  @override
  String get name => 'claude';

  @override
  String get displayName => 'Claude';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'claude-sonnet-4-20250514';

  List<Map<String, dynamic>> _convertMessages(List<ChatMessage> messages) {
    return messages
        .map((m) => {
              'role': m.role == 'system' ? 'user' : m.role,
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
      throw const AIException(
        type: AIExceptionType.noApiKey,
        message: '请先在设置中配置 Claude API Key',
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
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _modelId,
              'max_tokens': maxTokens,
              'system': systemMsg.isNotEmpty ? systemMsg : null,
              'messages': _convertMessages(userMsgs),
              'temperature': temperature,
            }),
          )
          .timeout(const Duration(seconds: 120));

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
    return List.filled(768, 0);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
