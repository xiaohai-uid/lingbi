import 'package:quota/main.dart' as main;
import 'package:quota/lib/quota_service.dart';
import 'package:test/test.dart';
import 'dart:io';

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
    });

    test('should reset quota', () {
      for (var i = 0; i < 10; i++) {
        service.consume();
      }
      final resetResult = service.reset();
      expect(resetResult['success'], true);
      expect(resetResult['remaining'], 10);
    });
  });
}
