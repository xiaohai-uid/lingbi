/// Identity port — upgrade seam for future account identity.
///
/// Local pilot: anonymous installation id in secure storage.
/// Future: AccountIdentityAdapter replaces this.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Provides installation identity without requiring login.
abstract interface class IdentityPort {
  /// Get the anonymous installation id (stable across restarts).
  Future<Result<String>> getInstallationId();

  /// Reset the installation id (for testing or user request).
  Future<Result<String>> resetInstallationId();

  /// Whether the identity is authenticated (always false in local pilot).
  Future<bool> isAuthenticated();
}
