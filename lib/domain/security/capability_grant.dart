/// Security capability model and grants.
///
/// Domain-layer — no Flutter, no dart:io.
library;

/// Vocabulary of capabilities that can be granted to Skills/tools/plugins.
enum Capability {
  projectRead('project.read'),
  projectProposeWrite('project.propose_write'),
  canonRead('canon.read'),
  canonProposeWrite('canon.propose_write'),
  networkHttp('network.http'),
  secretNamedRead('secret.named_read'),
  processExecute('process.execute'),
  mcpConnect('mcp.connect'),
  marketplaceInstall('marketplace.install');

  const Capability(this.wireName);
  final String wireName;

  static Capability? fromWire(String value) {
    for (final c in values) {
      if (c.wireName == value) return c;
    }
    return null; // Unknown capabilities fail closed
  }
}

/// Approval policy for a grant.
enum ApprovalPolicy {
  /// No approval needed (e.g., read-only).
  automatic,

  /// User must approve each use.
  explicitPerUse,

  /// User approves once per session.
  explicitPerSession,

  /// Denied — grant exists but is inactive.
  denied,
}

/// An immutable capability grant binding a grantee to a capability.
final class CapabilityGrant {
  const CapabilityGrant({
    required this.grantId,
    required this.capability,
    required this.granteeId,
    required this.granteeVersion,
    required this.granteeHash,
    required this.projectId,
    required this.approvalPolicy,
    this.pathScope,
    this.networkScope,
    this.expiresAt,
  });

  final String grantId;
  final Capability capability;
  final String granteeId;
  final String granteeVersion;
  final String granteeHash;
  final String projectId;
  final ApprovalPolicy approvalPolicy;
  final String? pathScope;
  final String? networkScope;
  final DateTime? expiresAt;

  /// Returns true if the grant is currently active.
  bool get isActive {
    if (approvalPolicy == ApprovalPolicy.denied) return false;
    if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!)) {
      return false;
    }
    return true;
  }

  /// Returns true if this grant is bound to the given manifest hash.
  bool matchesManifest(String manifestHash) => granteeHash == manifestHash;

  Map<String, dynamic> toJson() => {
        'grant_id': grantId,
        'capability': capability.wireName,
        'grantee_id': granteeId,
        'grantee_version': granteeVersion,
        'grantee_hash': granteeHash,
        'project_id': projectId,
        'approval_policy': approvalPolicy.name,
        if (pathScope != null) 'path_scope': pathScope,
        if (networkScope != null) 'network_scope': networkScope,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
