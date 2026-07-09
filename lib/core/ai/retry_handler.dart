import 'dart:async';
import 'dart:math';
import 'llm_errors.dart';

/// 指数退避重试处理器
///
/// 自动重试可恢复的错误（如速率限制、超时），
/// 不可恢复的错误（如认证失败）直接抛出。
class RetryHandler {
  const RetryHandler({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
    Set<Type>? retryableErrors,
  }) : retryableErrors = retryableErrors ?? _defaultRetryable;
  final int maxRetries;
  final Duration baseDelay;
  final double backoffFactor;
  final Set<Type> retryableErrors;

  /// 默认可重试错误类型
  static const Set<Type> _defaultRetryable = {
    LLMRateLimitException,
    LLMTimeoutException,
    LLMResponseException,
  };

  /// 执行带重试的异步操作
  ///
  /// 如果 [fn] 抛出 [retryableErrors] 中的异常，则按指数退避重试。
  /// 非重试类型的异常直接抛出。
  Future<T> execute<T>(Future<T> Function() fn) async {
    var lastError = null as dynamic;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await fn();
      } catch (e) {
        lastError = e;

        // 如果是最后一次尝试，不再重试
        if (attempt >= maxRetries) break;

        // 检查是否可重试
        if (!_isRetryable(e)) rethrow;

        // 指数退避
        final delayMs =
            baseDelay.inMilliseconds * pow(backoffFactor, attempt).toInt();
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // 所有重试耗尽，抛出最后一个错误
    if (lastError is Exception) throw lastError;
    throw lastError as Object;
  }

  bool _isRetryable(dynamic error) {
    for (final type in retryableErrors) {
      if (error.runtimeType == type) return true;
    }
    return false;
  }
}
