/// Provider 失败回退链
///
/// 当主模型调用失败时，按优先级依次尝试备用模型，
/// 直到某个模型成功或所有模型耗尽。
library fallback_chain;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'llm_client.dart';

/// 回退链结果
class FallbackResult {
  const FallbackResult({
    required this.content,
    required this.model,
    required this.attempts,
  });
  final String content;
  final String model;
  final int attempts;
}

/// 回退链
class FallbackChain {
  FallbackChain({
    required this.client,
    required this.models,
    this.maxRetriesPerModel = 1,
  });
  final LLMClient client;

  /// 按优先级排列的模型列表（第一个为主模型）
  final List<String> models;
  final int maxRetriesPerModel;

  /// 依次尝试 [models]，返回第一个成功的结果。
  ///
  /// 所有模型均失败时抛出 [FallbackExhaustedException]，
  /// 其 [lastError] 为最后一个模型的错误。
  Future<FallbackResult> chatWithFallback({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    if (models.isEmpty) {
      throw FallbackExhaustedException('No models configured', null);
    }
    Object? lastError;
    for (var i = 0; i < models.length; i++) {
      final model = models[i];
      for (var attempt = 0; attempt < maxRetriesPerModel; attempt++) {
        try {
          final content = await client.chat(
            messages: messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          return FallbackResult(
            content: content,
            model: model,
            attempts: i + 1,
          );
        } catch (e) {
          lastError = e;
        }
      }
    }
    throw FallbackExhaustedException(
      'All ${models.length} models failed',
      lastError,
    );
  }

  /// 流式回退：依次尝试 [models]，返回第一个成功建立（HTTP 2xx）的流。
  ///
  /// 若某模型连接失败或返回非 2xx，关闭该流并尝试下一个；
  /// 全部失败抛出 [FallbackExhaustedException]。
  /// 注意：仅能在“建流前”阶段切换模型，流中途出错无法重试。
  Future<http.StreamedResponse> chatStreamWithFallback({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (models.isEmpty) {
      throw FallbackExhaustedException('No models configured', null);
    }
    Object? lastError;
    for (var i = 0; i < models.length; i++) {
      final model = models[i];
      for (var attempt = 0; attempt < maxRetriesPerModel; attempt++) {
        try {
          final response = await client.chatStream(
            messages: messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return response;
          }
          await response.stream.drain();
          lastError = Exception('Model $model returned ${response.statusCode}');
        } catch (e) {
          lastError = e;
        }
      }
    }
    throw FallbackExhaustedException(
      'All ${models.length} models failed (stream)',
      lastError,
    );
  }
}

/// 所有模型均失败
class FallbackExhaustedException implements Exception {
  FallbackExhaustedException(this.message, this.lastError);
  final String message;
  final Object? lastError;

  @override
  String toString() =>
      'FallbackExhaustedException: $message' +
      (lastError != null ? ' (last: $lastError)' : '');
}
