import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_client.dart';
import 'llm_models.dart';
import 'llm_errors.dart';
import 'schema_processor.dart';

/// OpenAI 兼容客户端
///
/// 支持 OpenAI 及所有 OpenAI 兼容 API（如 OpenRouter）。
class OpenAIProvider extends BaseLLMClient {
  OpenAIProvider({
    String? apiKey,
    String? modelOverride,
    String name = 'openai',
  })  : _apiKey = apiKey,
        _modelOverride = modelOverride,
        super(providerName: name);
  String? _apiKey;
  String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String? _modelOverride;

  set apiKey(String? key) => _apiKey = key;
  set baseUrl(String url) => _baseUrl = url;

  @override
  String get displayName => 'OpenAI';
  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;
  String get _modelId => _modelOverride ?? 'gpt-4o-mini';

  Map<String, dynamic> _buildBody(LLMRequest request, {bool stream = false}) {
    return {
      'model': _modelId,
      'messages': request.messages.map((m) => m.toJson()).toList(),
      'temperature': request.temperature ?? 0.7,
      'max_tokens': request.maxTokens ?? 2048,
      if (request.topP != null) 'top_p': request.topP,
      if (request.presencePenalty != null)
        'presence_penalty': request.presencePenalty,
      if (request.frequencyPenalty != null)
        'frequency_penalty': request.frequencyPenalty,
      if (request.stop != null) 'stop': request.stop,
      'stream': stream,
    };
  }

  @override
  Future<String> generateText(LLMRequest request) async {
    if (!isAvailable) return '请先在设置中配置 OpenAI API Key';
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(_buildBody(request)),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['choices']?[0]?['message']?['content'] ?? '';
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
          message: 'OpenAI API error: $e', provider: providerName);
    }
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    if (!isAvailable) {
      yield '请先在设置中配置 OpenAI API Key';
      return;
    }
    try {
      final httpRequest = http.Request('POST', Uri.parse(_baseUrl));
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'text/event-stream',
      });
      httpRequest.body = jsonEncode(_buildBody(request, stream: true));
      final streamedResponse = await httpRequest.send();
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;
            try {
              final jsonData = jsonDecode(data);
              final content =
                  jsonData['choices']?[0]?['delta']?['content'] ?? '';
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

  /// 文本嵌入（向后兼容）
  @override
  Future<List<double>> embed(String text) async {
    if (!isAvailable) return List.filled(768, 0);
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'model': 'text-embedding-3-small', 'input': text}),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final embedding = jsonData['data']?[0]?['embedding'] as List?;
        if (embedding != null) return embedding.cast<double>();
      }
      return List.filled(768, 0);
    } catch (_) {
      return List.filled(768, 0);
    }
  }
}
