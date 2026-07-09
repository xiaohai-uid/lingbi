import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/quota_service.dart';

void main() {
  group('AIService quota enforcement', () {
    test('chat throws StateError when daily quota is exhausted', () {
      final quota = QuotaService();
      // Exhaust the daily quota
      while (quota.tryConsume()) {}

      final ai = AIService(quotaService: quota);
      expect(quota.canUse, isFalse);
      expect(() => ai.chat(message: '续写'), throwsA(isA<StateError>()));
    });

    test('chat does not throw when quota is available', () {
      final quota = QuotaService();
      final ai = AIService(quotaService: quota);
      expect(quota.canUse, isTrue);
      // Should not throw synchronously (returns a stream lazily)
      expect(() => ai.chat(message: '续写'), returnsNormally);
    });
  });
}
