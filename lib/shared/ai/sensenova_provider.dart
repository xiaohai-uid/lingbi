import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../errors/ai_error.dart';

/// 商汤 SenseNova Provider — 免费公测 API (OpenAI 兼容格式)
///
/// Base URL: https://token.sensenova.cn/v1
/// 免费模型: sensenova-6.7-flash-lite, deepseek-v4-flash
/// 限额: 每 5 小时 1500 次请求
class SenseNovaProvider extends AIProvider {
  SenseNovaProvider(
      {String? apiKey, String? modelOverride, http.Client? client})
      : _apiKey = apiKey,
        _modelOverride = modelOverride,
        _client = client ?? http.Client();
  String? _apiKey;
  final String? _modelOverride;
  final http.Client _client;
  static const String _baseUrl =
      'https://token.sensenova.cn/v1/chat/completions';

  set apiKey(String? key) => _apiKey = key;

  @override
  String get name => 'sensenova';

  @override
  String get displayName => 'SenseNova (商汤)';

  @override
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  // 默认使用 deepseek-v4-flash：推理模型 sensenova-6.7-flash-lite 会把有限的
  // token 全部消耗在 <think> 过程文本上，可见正文为 0 字，开箱即坏。
  String get _modelId => _modelOverride ?? 'deepseek-v4-flash';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    if (!isAvailable) {
      throw const AIException(
        type: AIExceptionType.noApiKey,
        message: '请先在设置中配置 SenseNova API Key',
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
      });
      request.body = body;

      final response = await _client.send(request).timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('连接超时', const Duration(seconds: 30)),
          );

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw aiExceptionFromHttp(response.statusCode, errBody);
      }

      final stream = response.stream.transform(utf8.decoder);

      bool isReasoning = false;
      await for (final chunk in stream) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              if (isReasoning) yield '</think>';
              return;
            }
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              final reasoning = delta?['reasoning'] ?? '';
              final content = delta?['content'] ?? '';

              if (reasoning != null && reasoning.isNotEmpty) {
                if (!isReasoning) {
                  isReasoning = true;
                  yield '<think>';
                }
                yield reasoning;
              } else if (content != null && content.isNotEmpty) {
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
    int maxTokens = 4096,
  }) async {
    if (!isAvailable) {
      throw const AIException(
        type: AIExceptionType.noApiKey,
        message: '请先在设置中配置 SenseNova API Key',
      );
    }

    final body = jsonEncode({
      'model': _modelId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    // 最多尝试 2 次（1 次重试，仅网络/超时错误）
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 120));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final message = json['choices']?[0]?['message'];
          final reasoning = message?['reasoning'] ?? '';
          final content = message?['content'] ?? '';
          if (reasoning != null && reasoning.isNotEmpty) {
            return '<think>$reasoning</think>${content ?? ''}';
          }
          return content ?? '';
        } else {
          throw aiExceptionFromHttp(response.statusCode, response.body);
        }
      } on TimeoutException catch (e) {
        if (attempt == 0) continue; // 重试
        throw aiExceptionFromObject(e);
      } on http.ClientException catch (e) {
        if (attempt == 0) continue; // 网络错误重试
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
    // SenseNova 暂未开放 embedding 接口，使用简单模拟
    final bytes = text.codeUnits;
    final result = <double>[];
    for (var i = 0; i < 128; i++) {
      result.add((bytes.fold(0, (a, b) => a + b) + i) % 1000 / 1000);
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
