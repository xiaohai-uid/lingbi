/// Security policy interface for capability checking.
library;

import 'package:lingbi/domain/security/capability_grant.dart';
import 'package:lingbi/shared/errors/result.dart';

/// Checks and manages capability grants.
abstract interface class SecurityPolicy {
  /// Check if a grantee has an active grant for a capability.
  Future<Result<CapabilityGrant>> checkGrant({
    required String granteeId,
    required Capability capability,
    required String projectId,
  });

  /// Issue a new grant.
  Future<Result<CapabilityGrant>> issueGrant(CapabilityGrant grant);

  /// Revoke a specific grant.
  Future<Result<void>> revokeGrant(String grantId);

  /// Revoke all grants bound to a manifest hash (manifest update).
  Future<Result<int>> revokeByManifestHash(String manifestHash);

  /// Enter safe mode: revoke all non-core grants.
  Future<Result<int>> enterSafeMode(String projectId);

  /// Check if safe mode is active.
  Future<bool> isSafeModeActive(String projectId);
}
