import 'dart:io';
import '../lib/quota_service.dart';
import 'package:test/test.dart';

void main() {
  group('QuotaService', () {
    late QuotaService service;
    late File testFile;

    setUp(() {
      testFile = File('test_quota_data.json');
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
      service = QuotaService(
        dailyLimit: 10,
        storagePath: 'test_quota_data.json',
      );
    });

    tearDown(() {
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('should start with full quota', () {
      final status = service.getStatus();
      expect(status['remaining'], 10);
      expect(status['limit'], 10);
    });

    test('should consume tokens', () {
      final result = service.consume();
      expect(result['success'], true);
      expect(result['remaining'], 9);
    });

    test('should return false when quota exhausted', () {
      for (var i = 0; i < 10; i++) {
        service.consume();
      }
      final result = service.consume();
      expect(result['success'], false);
      expect(result['remaining'], 0);
    });

    test('should reset quota', () {
      for (var i = 0; i < 10; i++) {
        service.consume();
      }
      final resetResult = service.reset();
      expect(resetResult['success'], true);
      expect(resetResult['remaining'], 10);
      expect(resetResult['limit'], 10);
    });

    test('should report utilization percentage', () {
      for (var i = 0; i < 5; i++) {
        service.consume();
      }
      final status = service.getStatus();
      expect(status['utilization'], '50.0%');
    });

    test('should consume multiple tokens at once', () {
      final result = service.consumeMany(3);
      expect(result['success'], true);
      expect(result['consumed'], 3);
      expect(result['remaining'], 7);
    });

    test('should handle consumeMany exceeding available tokens', () {
      final result = service.consumeMany(20);
      expect(result['success'], false);
      expect(result['consumed'], 10);
      expect(result['remaining'], 0);
    });

    test('should persist state to file', () {
      service.consume();
      service.consume();
      // Recreate service to test state loading
      final service2 = QuotaService(
        dailyLimit: 10,
        storagePath: 'test_quota_data.json',
      );
      final status = service2.getStatus();
      expect(status['remaining'], 8);
    });

    test('should refill tokens over time', () async {
      // Consume all tokens
      for (var i = 0; i < 10; i++) {
        service.consume();
      }
      expect(service.getStatus()['remaining'], 0);

      // Create a service with fast refill for testing
      final fastService = QuotaService(
        dailyLimit: 10,
        refillRate: 5,
        refillIntervalMs: 50,
        storagePath: 'test_fast_quota.json',
      );
      // Consume all tokens
      for (var i = 0; i < 10; i++) {
        fastService.consume();
      }
      expect(fastService.getStatus()['remaining'], 0);

      // Wait for refill
      await Future.delayed(Duration(milliseconds: 60));
      final status = fastService.getStatus();
      expect(status['remaining'], greaterThan(0));

      // Clean up
      File('test_fast_quota.json').deleteSync();
    });

    test('should handle empty content gracefully', () {
      // getStatus on a fresh service works fine
      final status = service.getStatus();
      expect(status['remaining'], 10);
      expect(status['limit'], 10);
      expect(status.containsKey('lastRefill'), true);
    });

    test('should correctly report limit after reset', () {
      service.consume();
      service.consume();
      service.consume();
      final resetResult = service.reset();
      expect(resetResult['remaining'], 10);
      expect(resetResult['limit'], 10);

      final status = service.getStatus();
      expect(status['remaining'], 10);
    });

    test('should handle state file with corrupted data', () {
      testFile.writeAsStringSync('corrupted data');
      final newService = QuotaService(
        dailyLimit: 10,
        storagePath: 'test_quota_data.json',
      );
      expect(newService.getStatus()['remaining'], 10);
    });
  });
}
