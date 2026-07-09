import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/retry_handler.dart';
import 'package:lingbi/core/ai/llm_errors.dart';

void main() {
  group('RetryHandler', () {
    test('succeeds on first attempt', () async {
      const handler = RetryHandler();
      var callCount = 0;
      final result = await handler.execute(() async {
        callCount++;
        return 'success';
      });
      expect(result, 'success');
      expect(callCount, 1);
    });

    test('retries on retryable errors', () async {
      const handler = RetryHandler(baseDelay: Duration.zero);
      var callCount = 0;
      final result = await handler.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw const LLMRateLimitException(
            message: 'Rate limited',
            provider: 'test',
          );
        }
        return 'success after retry';
      });
      expect(result, 'success after retry');
      expect(callCount, 3);
    });

    test('throws on non-retryable errors', () async {
      const handler = RetryHandler(baseDelay: Duration.zero);
      expect(
        () => handler.execute(() async {
          throw const LLMAuthException(
              message: 'Auth failed', provider: 'test');
        }),
        throwsA(isA<LLMAuthException>()),
      );
    });

    test('throws after exhausting retries', () async {
      const handler = RetryHandler(maxRetries: 2, baseDelay: Duration.zero);
      expect(
        () => handler.execute(() async {
          throw const LLMRateLimitException(
            message: 'Always rate limited',
            provider: 'test',
          );
        }),
        throwsA(isA<LLMRateLimitException>()),
      );
    });

    test('only retries registered retryable error types', () async {
      const handler = RetryHandler(
        maxRetries: 2,
        baseDelay: Duration.zero,
        retryableErrors: {LLMTimeoutException},
      );
      expect(
        () => handler.execute(() async {
          throw const LLMRateLimitException(
            message: 'Rate limit not in retryable set',
            provider: 'test',
          );
        }),
        throwsA(isA<LLMRateLimitException>()),
      );
    });

    test('backoff delay increases with retry count', () async {
      const handler = RetryHandler(
        baseDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      final stopwatch = Stopwatch()..start();
      await handler.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw const LLMRateLimitException(
            message: 'Rate limited',
            provider: 'test',
          );
        }
        return 'done';
      });
      stopwatch.stop();
      // 2 retries: 10ms + 20ms = at least 30ms
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(25));
    });
  });
}
