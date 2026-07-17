import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_client.dart';
import 'llm_models.dart';
import 'llm_errors.dart';
import 'schema_processor.dart';

/// Anthropic Claude 客户端
class ClaudeProvider extends BaseLLMClient {
  ClaudeProvider({
    String? apiKey,
    String? modelOverride,
    String name = 'claude',
  })  : _apiKey = apiKey,
        _modelOverride = modelOverride,
        super(providerName: name);
  String? _apiKey;
  final String? _modelOverride;
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  set apiKey(String? key) => _apiKey = key;

  @override
  String get displayName => 'Claude';
  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;
  String get _modelId => _modelOverride ?? 'claude-sonnet-4-20250514';

  List<Map<String, dynamic>> _convertMessages(List<LLMMessage> messages) {
    return messages
        .map((m) => {
              'role': m.role == 'system' ? 'user' : m.role,
              'content': m.content,
            })
        .toList();
  }

  Map<String, dynamic> _buildBody(LLMRequest request) {
    final systemMsgs = request.messages
        .where((m) => m.role == 'system')
        .map((m) => m.content)
        .join('\n');
    final userMsgs = request.messages.where((m) => m.role != 'system').toList();
    return {
      'model': _modelId,
      'max_tokens': request.maxTokens ?? 4096,
      if (systemMsgs.isNotEmpty) 'system': systemMsgs,
      'messages': _convertMessages(userMsgs),
      'temperature': request.temperature ?? 0.7,
    };
  }

  @override
  Future<String> generateText(LLMRequest request) async {
    if (!isAvailable) return '请先在设置中配置 Claude API Key';
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(_buildBody(request)),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return content.whereType<Map>().map((b) => b['text'] ?? '').join();
        }
        return '';
      }
      if (response.statusCode == 401) {
        throw LLMAuthException(
            message: 'Invalid API key', provider: providerName);
      }
      if (response.statusCode == 429) {
        throw LLMRateLimitException(
            message: 'Rate limited', provider: providerName);
      }
      throw LLMResponseException(
        message: 'API error: ${response.statusCode}',
        provider: providerName,
        statusCode: response.statusCode,
      );
    } on LLMException {
      rethrow;
    } catch (e) {
      throw LLMResponseException(
          message: 'Claude API error: $e', provider: providerName);
    }
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    if (!isAvailable) {
      yield '请先在设置中配置 Claude API Key';
      return;
    }
    final body = jsonEncode(_buildBody(request));
    try {
      final httpRequest = http.Request('POST', Uri.parse(_baseUrl));
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
        'Accept': 'text/event-stream',
      });
      httpRequest.body = body;

      final streamedResponse = await httpRequest.send();
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('
')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              // Support both OpenAI/DeepSeek (choices[0].delta.content)
              // and Anthropic (delta.text) streaming schemas.
              String? content;
              final choices = json['choices'];
              if (choices is List && choices.isNotEmpty) {
                content = choices[0]?['delta']?['content'];
              }
              content ??= json['delta']?['text'];
              if (content is String && content.isNotEmpty) yield content;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      throw LLMResponseException(
        message: 'Claude API error: $e',
        provider: providerName,
      );
    }
  }

  @override
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final text = await generateText(request);
    final processor = SchemaProcessor();
    final extracted = processor.extractJsonBlock(text);
    if (extracted != null) return fromJson(extracted);
    return fromJson({'result': text});
  }

  /// 嵌入向量（向后兼容）
  @override
  Future<List<double>> embed(String text) async {
    return List.filled(768, 0);
  }
}
