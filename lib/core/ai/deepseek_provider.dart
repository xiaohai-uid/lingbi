import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_client.dart';
import 'llm_models.dart';
import 'llm_errors.dart';
import 'schema_processor.dart';

class DeepSeekProvider extends BaseLLMClient {
  DeepSeekProvider(
      {String? apiKey, String? modelOverride, String name = 'deepseek'})
      : _apiKey = apiKey,
        _modelOverride = modelOverride,
        super(providerName: name);
  String? _apiKey;
  final String? _modelOverride;
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';

  set apiKey(String? key) => _apiKey = key;

  @override
  String get displayName => 'DeepSeek';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get _modelId => _modelOverride ?? 'deepseek-chat';

  @override
  Future<String> generateText(LLMRequest request) async {
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
          'messages': request.messages.map((m) => m.toJson()).toList(),
          'temperature': request.temperature ?? 0.7,
          'max_tokens': request.maxTokens ?? 2048,
          'stream': false,
        }),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices']?[0]?['message']?['content'] ?? '';
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
        message: 'DeepSeek API error: $e',
        provider: providerName,
      );
    }
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    if (!isAvailable) {
      yield '请先在设置中配置 DeepSeek API Key';
      return;
    }

    final body = jsonEncode({
      'model': _modelId,
      'messages': request.messages.map((m) => m.toJson()).toList(),
      'temperature': request.temperature ?? 0.7,
      'max_tokens': request.maxTokens ?? 2048,
      'stream': true,
    });

    try {
      final httpRequest = http.Request('POST', Uri.parse(_baseUrl));
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'text/event-stream',
      });
      httpRequest.body = body;

      final streamedResponse = await httpRequest.send();
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
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
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final text = await generateText(request);
    final schemaProcessor = SchemaProcessor();
    final extracted = schemaProcessor.extractJsonBlock(text);
    if (extracted != null) return fromJson(extracted);
    // 如果无法提取 JSON，尝试解析纯文本返回
    return fromJson({'result': text});
  }

  /// 嵌入向量（向后兼容）
  @override
  Future<List<double>> embed(String text) async {
    return List.filled(768, 0);
  }
}
