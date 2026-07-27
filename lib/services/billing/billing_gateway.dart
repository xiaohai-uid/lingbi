/// Billing gateway adapter boundary.
///
/// Production-disabled until merchant credentials and webhook verification
/// exist. Never ships fake purchase success.
library;

enum PurchaseStatus {
  success,
  failed,
  blockedExternal,
  pending,
}

/// Result of a purchase attempt.
class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.status,
    this.reason,
  });

  final bool success;
  final PurchaseStatus status;
  final String? reason;
}

class BillingGateway {
  const BillingGateway._(this._enabled, this.disabledReason);

  /// Production gateway: disabled until real merchant credentials exist.
  const BillingGateway.production()
      : _enabled = false,
        disabledReason =
            'BLOCKED_EXTERNAL: No merchant account, webhook secret, or '
            'payment processor credentials configured. Purchase flow '
            'cannot proceed without genuine payment infrastructure.';

  final bool _enabled;
  final String? disabledReason;

  bool get isEnabled => _enabled;

  /// Attempt to initiate a purchase. Returns blocked if gateway is disabled.
  Future<PurchaseResult> initiatePurchase({
    required String productId,
    required String userId,
  }) async {
    if (!_enabled) {
      return PurchaseResult(
        success: false,
        status: PurchaseStatus.blockedExternal,
        reason: disabledReason,
      );
    }

    // Real implementation would go here with merchant SDK
    return const PurchaseResult(
      success: false,
      status: PurchaseStatus.failed,
      reason: 'Not implemented',
    );
  }
}
