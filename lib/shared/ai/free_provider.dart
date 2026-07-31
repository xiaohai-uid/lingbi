import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lingbi/shared/ai/ai_provider.dart';

/// Free Provider — 内置体验模型，新用户零配置即可使用。
///
/// 对标 OpenWrite 的"公益模型"：默认连接免费 API 端点，
/// 用户无需配置任何 API Key 就能体验核心写作功能。
/// 想用更好的模型时，在设置中切换到自定义 Provider。
///
/// 端点策略（复刻 OpenWrite）：
/// - 主端点：opencode.ai/zen/v1（免费，无需 Key）
/// - 备用端点：SenseNova（需环境变量 SENSENOVA_API_KEY）
class FreeProvider extends AIProvider {
  FreeProvider({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ─── 内置端点配置（复刻 OpenWrite 公益模型） ───
  static const _baseUrl = 'https://opencode.ai/zen/v1/chat/completions';
  static const _model = 'deepseek-v4-flash-free';

  /// 免费端点不需要 API Key。
  static const _apiKey = '';

  @override
  String get name => 'free';

  @override
  String get displayName => '体验模型（免费）';

  @override
  bool get isAvailable => true;

  @override
  bool get supportsTools => true;

  @override
  String get currentModelId => _model;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
      };

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll(_headers)
      ..body = body;

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      final errBody = await response.stream.bytesToString();
      yield '体验模型连接失败 (${response.statusCode})，请在设置中配置自己的 API。\n$errBody';
      return;
    }

    await for (final chunk in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!chunk.startsWith('data: ')) continue;
      final data = chunk.substring(6).trim();
      if (data == '[DONE]') break;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final delta = json['choices']?[0]?['delta'] as Map?;
        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
      } catch (_) {}
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final resp = await _client
        .post(Uri.parse(_baseUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 120));

    if (resp.statusCode != 200) {
      return '体验模型连接失败 (${resp.statusCode})，请在设置中配置自己的 API。';
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['choices']?[0]?['message']?['content'] as String? ?? '';
  }

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'tools': tools.map((t) => t.toOpenAiJson()).toList(),
    });

    final resp = await _client
        .post(Uri.parse(_baseUrl), headers: _headers, body: body)
        .timeout(const Duration(seconds: 120));

    if (resp.statusCode != 200) {
      throw UnsupportedError(
          '体验模型不支持工具调用 (${resp.statusCode})');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choice = json['choices']?[0] as Map? ?? {};
    final message = choice['message'] as Map? ?? {};
    final content = message['content'] as String? ?? '';
    final rawToolCalls = message['tool_calls'] as List?;

    if (rawToolCalls == null || rawToolCalls.isEmpty) {
      return ToolTurn(content: content);
    }

    final toolCalls = rawToolCalls.map((tc) {
      final fn = tc['function'] as Map? ?? {};
      return ToolCall(
        id: tc['id'] as String? ?? '',
        name: fn['name'] as String? ?? '',
        argumentsJson: fn['arguments'] as String? ?? '{}',
      );
    }).toList();

    return ToolTurn(content: content, toolCalls: toolCalls);
  }

  @override
  Future<List<double>> embed(String text) async {
    // 体验模型不提供嵌入，返回空向量
    return List.filled(128, 0);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
