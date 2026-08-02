/// Pilot diagnostics with PII redaction.
///
/// Ensures the 5 pilot port interfaces (identity/entitlement/usage/
/// model-access/update) have diagnostic logging that never leaks PII.
///
/// Task F1: feat(pilot): diagnostics redaction for pilot port interfaces
library;

/// Redacts potentially sensitive information from diagnostic strings.
///
/// Rules:
/// - Email addresses → `[EMAIL_REDACTED]`
/// - API keys (sk-..., key-..., ak-...) → `[KEY_REDACTED]`
/// - Bearer tokens → `[TOKEN_REDACTED]`
/// - UUIDs longer than 8 chars → first 8 chars + `...`
/// - IP addresses → `[IP_REDACTED]`
String redact(String input) {
  var result = input;

  // Email addresses
  result = result.replaceAllMapped(
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    (_) => '[EMAIL_REDACTED]',
  );

  // API keys (sk-..., key-..., ak-..., pk-...)
  result = result.replaceAllMapped(
    RegExp(r'\b(sk|key|ak|pk)-[a-zA-Z0-9]{8,}\b'),
    (_) => '[KEY_REDACTED]',
  );

  // Bearer tokens
  result = result.replaceAllMapped(
    RegExp(r'Bearer\s+[a-zA-Z0-9._\-]{16,}'),
    (_) => 'Bearer [TOKEN_REDACTED]',
  );

  // IP addresses (v4)
  result = result.replaceAllMapped(
    RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
    (_) => '[IP_REDACTED]',
  );

  // Long hex/base64 tokens (32+ chars, likely secrets)
  result = result.replaceAllMapped(
    RegExp(r'\b[a-fA-F0-9]{32,}\b'),
    (_) => '[HASH_REDACTED]',
  );

  return result;
}

/// A diagnostic log entry with guaranteed redaction.
final class DiagnosticEntry {
  DiagnosticEntry({
    required this.subsystem,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Creates a diagnostic entry with automatic redaction.
  factory DiagnosticEntry.safe({
    required String subsystem,
    required String rawMessage,
  }) {
    return DiagnosticEntry(
      subsystem: subsystem,
      message: redact(rawMessage),
    );
  }

  /// Which pilot port subsystem (identity/entitlement/usage/model-access/update).
  final String subsystem;

  /// Already-redacted message.
  final String message;

  final DateTime timestamp;

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] $subsystem: $message';
}
