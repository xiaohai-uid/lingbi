/// Live provider acceptance harness.
///
/// Reads credentials only through protected environment variables.
/// Never accepts a key on the command line. Never prints, persists,
/// exports, or snapshots credential values. Caps usage by explicit
/// maximum request count and token budget. Writes only redacted
/// provider/model/status/latency evidence.
library;

/// Credential source abstraction.
abstract class CredentialSource {
  String? get apiKey;
  String get description;
}

/// No credential available.
class NoCredentialSource implements CredentialSource {
  const NoCredentialSource();
  @override
  String? get apiKey => null;
  @override
  String get description => 'No credential source configured';
}

/// Environment variable credential source (protected).
class EnvCredentialSource implements CredentialSource {
  const EnvCredentialSource({required this.envVar});
  final String envVar;

  @override
  String? get apiKey => const String.fromEnvironment('') != ''
      ? null
      : _readEnv(envVar);

  @override
  String get description => 'Environment variable: $envVar';

  static String? _readEnv(String name) {
    // In production, reads from Platform.environment
    // Never logs or persists the value
    return null; // Placeholder - real impl reads Platform.environment[name]
  }
}

class MissingCredentialException implements Exception {
  const MissingCredentialException(this.message);
  final String message;
  @override
  String toString() => 'MissingCredentialException: $message';
}

/// Fields that must be redacted from logs.
const _redactedHeaderKeys = {'authorization', 'api-key', 'x-api-key', 'token'};

class LiveProviderHarness {
  LiveProviderHarness({
    required this.credentialSource,
    this.maxRequests = 50,
    this.maxTokens = 100000,
  });

  final CredentialSource credentialSource;
  final int maxRequests;
  final int maxTokens;

  int _requestCount = 0;
  int _tokenCount = 0;

  int get totalRequests => _requestCount;
  int get totalTokens => _tokenCount;

  bool get canMakeRequest =>
      _requestCount < maxRequests && _tokenCount < maxTokens;

  void recordRequest({required int tokensUsed}) {
    _requestCount++;
    _tokenCount += tokensUsed;
  }

  /// Validate that credentials are available before running.
  void validateSetup() {
    if (credentialSource.apiKey == null) {
      throw MissingCredentialException(
        'No API credential available from: ${credentialSource.description}. '
        'Set the appropriate environment variable before running live tests.',
      );
    }
  }

  /// Format a log entry with all secrets redacted.
  String formatLogEntry({
    required String provider,
    required String model,
    required int status,
    required int latencyMs,
    Map<String, String>? headers,
    String? requestBody,
  }) {
    final parts = <String>[
      'provider=$provider',
      'model=$model',
      'status=$status',
      'latency=${latencyMs}ms',
    ];

    // Redact headers
    if (headers != null) {
      for (final entry in headers.entries) {
        if (_redactedHeaderKeys.contains(entry.key.toLowerCase())) {
          parts.add('${entry.key}=[REDACTED]');
        }
      }
    }

    // Never include request body content (may contain manuscript text)
    if (requestBody != null) {
      parts.add('body=[CONTENT_REDACTED]');
    }

    return parts.join(' | ');
  }
}

/// Required user journey checkpoints for commercial acceptance.
class UserJourneyCheckpoints {
  static const all = [
    'first_launch',
    'project_creation',
    'project_open_existing',
    'project_import',
    'navigation_overview',
    'navigation_writing',
    'navigation_ideation',
    'navigation_review',
    'navigation_publish',
    'model_switch',
    'first_chapter_generation',
    'candidate_adoption',
    'offline_fallback',
    'error_recovery',
    'export_reimport',
    'restart_resume',
    'onboarding_three_questions',
    'asset_overview_states',
    'command_palette',
    'keyboard_shortcuts',
  ];
}
