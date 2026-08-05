import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/privacy/privacy_preferences.dart';
import 'package:lingbi/services/diagnostics/diagnostic_event.dart';

void main() {
  late Directory tempDir;
  late PrivacyPreferences prefs;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_privacy_');
    prefs = PrivacyPreferences(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('default-off telemetry', () {
    test('telemetry is disabled by default', () async {
      final status = await prefs.getConsentStatus();
      expect(status.telemetryEnabled, isFalse);
      expect(status.consentGiven, isFalse);
    });

    test('explicit consent enables telemetry and records timestamp', () async {
      await prefs.grantConsent();
      final status = await prefs.getConsentStatus();
      expect(status.telemetryEnabled, isTrue);
      expect(status.consentGiven, isTrue);
      expect(status.consentTimestamp, isNotNull);
    });

    test('revocation disables telemetry and records timestamp', () async {
      await prefs.grantConsent();
      await prefs.revokeConsent();
      final status = await prefs.getConsentStatus();
      expect(status.telemetryEnabled, isFalse);
      expect(status.revokedAt, isNotNull);
    });
  });

  group('field allow-list', () {
    test('only allow-listed fields are collected', () {
      const event = DiagnosticEvent(
        type: 'session_start',
        fields: {
          'app_version': '1.2.0',
          'os': 'windows',
          'manuscript_content': 'secret text',
          'api_key': 'sk-12345',
        },
      );

      final sanitized = event.sanitized();
      expect(sanitized.fields, contains('app_version'));
      expect(sanitized.fields, contains('os'));
      expect(sanitized.fields, isNot(contains('manuscript_content')));
      expect(sanitized.fields, isNot(contains('api_key')));
    });

    test('secret redaction removes authorization patterns', () {
      const event = DiagnosticEvent(
        type: 'api_call',
        fields: {
          'endpoint': 'https://api.example.com/v1/chat',
          'authorization': 'Bearer sk-abc123',
          'latency_ms': '250',
        },
      );

      final sanitized = event.sanitized();
      expect(sanitized.fields['authorization'], isNull);
      expect(sanitized.fields['endpoint'], isNotNull);
      expect(sanitized.fields['latency_ms'], '250');
    });
  });

  group('retention and export', () {
    test('events older than retention period are purged', () async {
      final collector = DiagnosticCollector(
        storageDir: tempDir.path,
        retentionDays: 30,
        clock: () => DateTime.utc(2026, 7, 28),
      );

      await collector.record(DiagnosticEvent(
        type: 'old_event',
        fields: {'data': 'old'},
        timestamp: DateTime.utc(2026, 6),
      ));
      await collector.record(DiagnosticEvent(
        type: 'recent_event',
        fields: {'data': 'recent'},
        timestamp: DateTime.utc(2026, 7, 20),
      ));

      await collector.purgeExpired();
      final events = await collector.export();
      expect(events, hasLength(1));
      expect(events.first.type, 'recent_event');
    });

    test('export produces user-readable JSON', () async {
      final collector = DiagnosticCollector(
        storageDir: tempDir.path,
        retentionDays: 30,
        clock: () => DateTime.utc(2026, 7, 28),
      );

      await collector.record(const DiagnosticEvent(
        type: 'session_start',
        fields: {'app_version': '1.2.0'},
      ));

      final exported = await collector.exportJson();
      expect(exported, contains('session_start'));
      expect(exported, contains('app_version'));
    });
  });
}
