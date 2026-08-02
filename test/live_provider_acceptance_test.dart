import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/acceptance/live_provider_harness.dart';

void main() {
  group('credential safety', () {
    test('refuses to run without credentials', () {
      final harness = LiveProviderHarness(
        credentialSource: const NoCredentialSource(),
      );

      expect(
        () => harness.validateSetup(),
        throwsA(isA<MissingCredentialException>()),
      );
    });

    test('redacts authorization headers in logs', () {
      final harness = LiveProviderHarness(
        credentialSource: const NoCredentialSource(),
      );

      final logEntry = harness.formatLogEntry(
        provider: 'sensenova',
        model: 'nova-ptc-xl-v1',
        status: 200,
        latencyMs: 350,
        headers: {'authorization': 'Bearer sk-secret-key-12345'},
      );

      expect(logEntry, isNot(contains('sk-secret-key-12345')));
      expect(logEntry, contains('[REDACTED]'));
      expect(logEntry, contains('sensenova'));
      expect(logEntry, contains('200'));
    });

    test('caps usage at configured maximum requests', () {
      final harness = LiveProviderHarness(
        credentialSource: const NoCredentialSource(),
        maxRequests: 5,
        maxTokens: 10000,
      );

      expect(harness.canMakeRequest, isTrue);
      for (var i = 0; i < 5; i++) {
        harness.recordRequest(tokensUsed: 100);
      }
      expect(harness.canMakeRequest, isFalse);
      expect(harness.totalRequests, 5);
    });

    test('cannot include manuscript content in logs', () {
      final harness = LiveProviderHarness(
        credentialSource: const NoCredentialSource(),
      );

      final logEntry = harness.formatLogEntry(
        provider: 'test',
        model: 'test-model',
        status: 200,
        latencyMs: 100,
        requestBody: '叶澜走进了青梧城，她的断臂隐隐作痛。',
      );

      // Manuscript content must not appear in logs
      expect(logEntry, isNot(contains('叶澜')));
      expect(logEntry, isNot(contains('青梧城')));
      expect(logEntry, contains('[CONTENT_REDACTED]'));
    });
  });

  group('user journey structure', () {
    test('defines all required journey checkpoints', () {
      const journeys = UserJourneyCheckpoints.all;

      expect(journeys, contains('first_launch'));
      expect(journeys, contains('project_creation'));
      expect(journeys, contains('model_switch'));
      expect(journeys, contains('first_chapter_generation'));
      expect(journeys, contains('offline_fallback'));
      expect(journeys, contains('export_reimport'));
      expect(journeys, contains('restart_resume'));
      expect(journeys.length, greaterThanOrEqualTo(7));
    });
  });
}
