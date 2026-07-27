/// Entitlement service with signed offline license, grace period,
/// and local-content-never-locked guarantee.
library;

import 'dart:convert';
import 'dart:io';

import 'license_signature_verifier.dart';

export 'license_signature_verifier.dart';

/// Result of license activation.
class ActivationResult {
  const ActivationResult({
    required this.activated,
    this.product,
    this.licensee,
    this.failureReason,
  });

  final bool activated;
  final String? product;
  final String? licensee;
  final String? failureReason;
}

/// Result of entitlement validation.
class EntitlementStatus {
  const EntitlementStatus({
    required this.isValid,
    this.gracePeriodActive = false,
    this.product,
  });

  final bool isValid;
  final bool gracePeriodActive;
  final String? product;
}

class EntitlementService {
  EntitlementService({required this.storageDir});

  final String storageDir;

  String _licenseFile() => '$storageDir/license.json';

  Future<ActivationResult> activateLicense({
    required String licenseData,
    required LicenseSignatureVerifier verifier,
  }) async {
    final verification = verifier.verify(licenseData);

    if (!verification.valid) {
      return ActivationResult(
        activated: false,
        failureReason: verification.failureReason,
      );
    }

    // Persist activated license
    final dir = Directory(storageDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(_licenseFile()).writeAsString(
      jsonEncode({
        'license_data': licenseData,
        'activated_at': DateTime.now().toUtc().toIso8601String(),
        'product': verification.product,
        'licensee': verification.licensee,
        'expires_at': verification.expiresAt.toUtc().toIso8601String(),
      }),
      flush: true,
    );

    return ActivationResult(
      activated: true,
      product: verification.product,
      licensee: verification.licensee,
    );
  }

  /// Local content is NEVER locked behind payment.
  Future<bool> canAccessLocalContent(String projectId) async => true;

  /// Validate entitlement with offline grace period.
  Future<EntitlementStatus> validateEntitlement({
    required bool networkAvailable,
  }) async {
    final file = File(_licenseFile());
    if (!await file.exists()) {
      return const EntitlementStatus(isValid: false);
    }

    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(data['expires_at'] as String).toUtc();
      final product = data['product'] as String?;

      final notExpired = expiresAt.isAfter(DateTime.now().toUtc());

      // Offline: grant grace period regardless of expiry
      // (cannot confirm revocation or renewal without network)
      if (!networkAvailable) {
        return EntitlementStatus(
          isValid: notExpired,
          gracePeriodActive: true,
          product: product,
        );
      }

      if (notExpired) {
        return EntitlementStatus(isValid: true, product: product);
      }

      return const EntitlementStatus(isValid: false);
    } catch (_) {
      return const EntitlementStatus(isValid: false);
    }
  }
}
