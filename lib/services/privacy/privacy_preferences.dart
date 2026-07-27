/// Privacy preferences with persistent consent, default-off telemetry,
/// and revocation support.
library;

import 'dart:convert';
import 'dart:io';

/// Consent status.
class ConsentStatus {
  const ConsentStatus({
    required this.telemetryEnabled,
    required this.consentGiven,
    this.consentTimestamp,
    this.revokedAt,
  });

  final bool telemetryEnabled;
  final bool consentGiven;
  final DateTime? consentTimestamp;
  final DateTime? revokedAt;

  Map<String, Object?> toJson() => {
        'telemetry_enabled': telemetryEnabled,
        'consent_given': consentGiven,
        'consent_timestamp': consentTimestamp?.toUtc().toIso8601String(),
        'revoked_at': revokedAt?.toUtc().toIso8601String(),
      };

  factory ConsentStatus.fromJson(Map<String, dynamic> json) => ConsentStatus(
        telemetryEnabled: json['telemetry_enabled'] as bool? ?? false,
        consentGiven: json['consent_given'] as bool? ?? false,
        consentTimestamp: json['consent_timestamp'] != null
            ? DateTime.parse(json['consent_timestamp'] as String)
            : null,
        revokedAt: json['revoked_at'] != null
            ? DateTime.parse(json['revoked_at'] as String)
            : null,
      );
}

class PrivacyPreferences {
  PrivacyPreferences({required this.storageDir});

  final String storageDir;

  String _consentFile() => '$storageDir/privacy/consent.json';

  Future<ConsentStatus> getConsentStatus() async {
    final file = File(_consentFile());
    if (!await file.exists()) {
      return const ConsentStatus(telemetryEnabled: false, consentGiven: false);
    }
    try {
      final raw = await file.readAsString();
      return ConsentStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ConsentStatus(telemetryEnabled: false, consentGiven: false);
    }
  }

  Future<void> grantConsent() async {
    final dir = Directory('$storageDir/privacy');
    await dir.create(recursive: true);
    final status = ConsentStatus(
      telemetryEnabled: true,
      consentGiven: true,
      consentTimestamp: DateTime.now().toUtc(),
    );
    await File(_consentFile())
        .writeAsString(jsonEncode(status.toJson()), flush: true);
  }

  Future<void> revokeConsent() async {
    final dir = Directory('$storageDir/privacy');
    await dir.create(recursive: true);
    final current = await getConsentStatus();
    final status = ConsentStatus(
      telemetryEnabled: false,
      consentGiven: false,
      consentTimestamp: current.consentTimestamp,
      revokedAt: DateTime.now().toUtc(),
    );
    await File(_consentFile())
        .writeAsString(jsonEncode(status.toJson()), flush: true);
  }
}
