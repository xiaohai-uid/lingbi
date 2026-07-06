/// LLM 客户端 — 直接调用 LiteLLM Gateway
///
/// Quality Review 微服务通过 LiteLLM 统一调用 LLM。
/// LiteLLM 地址通过环境变量 LITELLM_URL 配置，默认 http://localhost:4000。
library llm_client;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// LiteLLM 配置
class LiteLLMConfig {
  final String baseUrl;
  final String apiKey;
  final String defaultModel;

  const LiteLLMConfig({
    this.baseUrl = 'http://localhost:4000',
    this.apiKey = '',
    this.defaultModel = 'deepseek-chat',
  });
}

/// LLM 客户端
class LLMClient {
  final LiteLLMConfig config;
  final http.Client _http;

  LLMClient({LiteLLMConfig? config, http.Client? httpClient})
      : config = config ?? const LiteLLMConfig(),
        _http = httpClient ?? http.Client();

  /// 调用 OpenAI 兼容的 Chat Completions API
  Future<String> chat({
    required List<Map<String, String>> messages,
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final url = Uri.parse('${config.baseUrl}/v1/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': false,
    });

    final response = await _http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('LiteLLM error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    if (choices.isEmpty) throw Exception('Empty response from LLM');

    return choices[0]['message']['content'] as String;
  }

  void close() {
    _http.close();
  }
}
