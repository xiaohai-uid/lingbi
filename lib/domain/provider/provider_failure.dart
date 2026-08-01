/// Provider failure taxonomy.
///
/// Domain-layer — normalized error kinds across all Providers.
library;

/// Normalized failure categories for Provider operations.
enum ProviderFailureKind {
  auth,
  permission,
  invalidRequest,
  unsupportedCapability,
  rateLimit,
  quota,
  timeout,
  network,
  server,
  malformedResponse,
  cancelled,
  unknown;

  /// Whether this failure kind is retryable.
  bool get isRetryable =>
      this == rateLimit ||
      this == timeout ||
      this == network ||
      this == server;

  String get wireName => name;
}

/// A typed Provider failure with normalized kind.
final class ProviderFailure {
  const ProviderFailure({
    required this.kind,
    required this.message,
    this.retryAfterSeconds,
    this.statusCode,
  });

  final ProviderFailureKind kind;
  final String message;
  final int? retryAfterSeconds;
  final int? statusCode;

  @override
  String toString() => 'ProviderFailure(${kind.name}: $message)';
}
