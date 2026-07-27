/// License signature verification for offline entitlement checks.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A signed license.
class SignedLicense {
  const SignedLicense({
    required this.licensee,
    required this.product,
    required this.expiresAt,
    required this.signature,
    required this.serialized,
  });

  final String licensee;
  final String product;
  final DateTime expiresAt;
  final String signature;
  final String serialized;
}

/// Result of license verification.
class LicenseVerification {
  const LicenseVerification({
    required this.valid,
    required this.licensee,
    required this.product,
    required this.expiresAt,
    this.failureReason,
  });

  final bool valid;
  final String licensee;
  final String product;
  final DateTime expiresAt;
  final String? failureReason;
}

class LicenseSignatureVerifier {
  const LicenseSignatureVerifier._(this._key, this._mode);

  factory LicenseSignatureVerifier.testOnly({required String key}) =>
      LicenseSignatureVerifier._(key, 'test');

  factory LicenseSignatureVerifier.production() =>
      LicenseSignatureVerifier._('', 'production');

  final String _key;
  final String _mode;

  /// Create a test license (never use in production).
  static SignedLicense createTestLicense({
    required String licensee,
    required String product,
    required DateTime expiresAt,
    required String key,
  }) {
    final payload = jsonEncode({
      'licensee': licensee,
      'product': product,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    });
    final signature = _sign(payload, key);
    final serialized = jsonEncode({
      'payload': payload,
      'signature': signature,
    });
    return SignedLicense(
      licensee: licensee,
      product: product,
      expiresAt: expiresAt,
      signature: signature,
      serialized: serialized,
    );
  }

  /// Verify a serialized license string.
  LicenseVerification verify(String licenseData) {
    try {
      final decoded = jsonDecode(licenseData) as Map<String, dynamic>;
      final payload = decoded['payload'] as String;
      final signature = decoded['signature'] as String;

      // Verify signature
      final expected = _sign(payload, _key);
      if (signature != expected) {
        return LicenseVerification(
          valid: false,
          licensee: '',
          product: '',
          expiresAt: DateTime.now(),
          failureReason: 'Invalid signature - license may be tampered',
        );
      }

      final payloadData = jsonDecode(payload) as Map<String, dynamic>;
      final expiresAt =
          DateTime.parse(payloadData['expires_at'] as String).toUtc();

      // Check expiry
      if (expiresAt.isBefore(DateTime.now().toUtc())) {
        return LicenseVerification(
          valid: false,
          licensee: payloadData['licensee'] as String,
          product: payloadData['product'] as String,
          expiresAt: expiresAt,
          failureReason: 'License expired on ${expiresAt.toIso8601String()}',
        );
      }

      return LicenseVerification(
        valid: true,
        licensee: payloadData['licensee'] as String,
        product: payloadData['product'] as String,
        expiresAt: expiresAt,
      );
    } catch (e) {
      return LicenseVerification(
        valid: false,
        licensee: '',
        product: '',
        expiresAt: DateTime.now(),
        failureReason: 'Cannot parse license: $e',
      );
    }
  }

  static String _sign(String payload, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(payload)).toString();
  }
}
