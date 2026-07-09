import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/llm_errors.dart';

void main() {
  group('LLMException hierarchy', () {
    test('LLMException subclasses are throwable', () {
      const exc = LLMResponseException(
          message: 'Generic error', provider: 'test', statusCode: 500);
      expect(exc.message, 'Generic error');
      expect(exc.provider, 'test');
      expect(exc, isA<Exception>());
    });

    test('LLMAuthException for authentication failures', () {
      const exc = LLMAuthException(
        message: 'Invalid API key',
        provider: 'openai',
      );
      expect(exc, isA<LLMException>());
      expect(exc.message, contains('API key'));
      expect(exc.provider, 'openai');
    });

    test('LLMRateLimitException for rate limiting', () {
      const exc = LLMRateLimitException(
        message: 'Too many requests',
        provider: 'deepseek',
        retryAfterSeconds: 30,
      );
      expect(exc, isA<LLMException>());
      expect(exc.retryAfterSeconds, 30);
    });

    test('LLMTimeoutException for timeouts', () {
      const exc = LLMTimeoutException(
        message: 'Request timed out',
        provider: 'claude',
        timeoutSeconds: 60,
      );
      expect(exc, isA<LLMException>());
      expect(exc.timeoutSeconds, 60);
    });

    test('LLMResponseException for bad responses', () {
      const exc = LLMResponseException(
        message: 'Invalid response format',
        provider: 'gemini',
        statusCode: 400,
      );
      expect(exc, isA<LLMException>());
      expect(exc.statusCode, 400);
    });

    test('LLMConfigurationException for config errors', () {
      const exc = LLMConfigurationException(
        message: 'API key not configured',
        provider: 'openai',
        missingField: 'api_key',
      );
      expect(exc, isA<LLMException>());
      expect(exc.missingField, 'api_key');
    });

    test('toString includes provider and message', () {
      const exc = LLMAuthException(
        message: 'Invalid key',
        provider: 'openai',
      );
      final str = exc.toString();
      expect(str, contains('openai'));
      expect(str, contains('Invalid key'));
    });
  });
}
