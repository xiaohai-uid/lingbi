/// Entitlement port — upgrade seam for future signed entitlements.
///
/// Local pilot: enables approved local features without server.
/// Future: SignedRemoteEntitlementAdapter replaces this.
library;

import 'package:lingbi/shared/errors/result.dart';

/// A feature entitlement grant.
final class Entitlement {
  const Entitlement({
    required this.featureId,
    required this.granted,
    this.expiresAt,
    this.metadata = const {},
  });

  final String featureId;
  final bool granted;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);

  bool get isActive => granted && !isExpired;
}

/// Checks feature entitlements.
abstract interface class EntitlementPort {
  /// Check if a feature is entitled.
  Future<Result<Entitlement>> checkFeature(String featureId);

  /// List all entitled features.
  Future<Result<List<Entitlement>>> listEntitlements();

  /// Whether offline grace period is active.
  Future<bool> isOfflineGraceActive();
}
