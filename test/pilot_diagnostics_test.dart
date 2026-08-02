/// Pilot diagnostics redaction tests.
///
/// Task F1: feat(pilot): diagnostics redaction for pilot port interfaces
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/pilot/diagnostics.dart';

void main() {
  group('redact', () {
    test('redacts email addresses', () {
      final result = redact('User user@example.com logged in');
      expect(result, contains('[EMAIL_REDACTED]'));
      expect(result, isNot(contains('user@example.com')));
    });

    test('redacts API keys', () {
      final result = redact('Using key sk-abc123456789xyz for request');
      expect(result, contains('[KEY_REDACTED]'));
      expect(result, isNot(contains('sk-abc123456789xyz')));
    });

    test('redacts Bearer tokens', () {
      final result =
          redact('Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig');
      expect(result, contains('[TOKEN_REDACTED]'));
      expect(result, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
    });

    test('redacts IP addresses', () {
      final result = redact('Connection from 192.168.1.100 established');
      expect(result, contains('[IP_REDACTED]'));
      expect(result, isNot(contains('192.168.1.100')));
    });

    test('redacts long hex hashes', () {
      final result = redact(
          'Checksum: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6 verified');
      expect(result, contains('[HASH_REDACTED]'));
      expect(result,
          isNot(contains('a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6')));
    });

    test('preserves non-sensitive content', () {
      const input = 'Entitlement check: pro plan active, 42 uses remaining';
      expect(redact(input), input);
    });

    test('handles multiple PII in one string', () {
      final result = redact(
          'User admin@corp.io used key sk-1234567890abcdef from 10.0.0.1');
      expect(result, isNot(contains('admin@corp.io')));
      expect(result, isNot(contains('sk-1234567890abcdef')));
      expect(result, isNot(contains('10.0.0.1')));
    });
  });

  group('DiagnosticEntry', () {
    test('safe factory auto-redacts message', () {
      final entry = DiagnosticEntry.safe(
        subsystem: 'identity',
        rawMessage: 'Login from user@test.com at 192.168.0.1',
      );
      expect(entry.message, contains('[EMAIL_REDACTED]'));
      expect(entry.message, contains('[IP_REDACTED]'));
      expect(entry.subsystem, 'identity');
    });

    test('toString includes subsystem and redacted message', () {
      final entry = DiagnosticEntry.safe(
        subsystem: 'usage',
        rawMessage: 'API call with key sk-abcdefgh12345678',
      );
      final str = entry.toString();
      expect(str, contains('usage'));
      expect(str, contains('[KEY_REDACTED]'));
      expect(str, isNot(contains('sk-abcdefgh12345678')));
    });
  });
}
