/// Immutable mutation domain records.
///
/// Domain-layer — no Flutter, no dart:io.
/// See ADR-010 for the candidate-approval-commit protocol.
library;

/// Who or what originated a mutation.
enum ChangeOrigin {
  userUi,
  agent,
  batchImport,
  skill,
  restore,
  recovery,
  externalMutation,
  legacyMigration;

  String get wireName {
    return switch (this) {
      userUi => 'user_ui',
      agent => 'agent',
      batchImport => 'batch_import',
      skill => 'skill',
      restore => 'restore',
      recovery => 'recovery',
      externalMutation => 'external_mutation',
      legacyMigration => 'legacy_migration',
    };
  }

  static ChangeOrigin fromWire(String value) => switch (value) {
        'user_ui' => userUi,
        'agent' => agent,
        'batch_import' => batchImport,
        'skill' => skill,
        'restore' => restore,
        'recovery' => recovery,
        'external_mutation' => externalMutation,
        'legacy_migration' => legacyMigration,
        _ => throw FormatException('Unknown ChangeOrigin: $value'),
      };
}

/// What kind of change is proposed.
enum ChangeAction {
  createText,
  replaceText,
  replaceAsset,
  restoreSnapshot;

  String get wireName {
    return switch (this) {
      createText => 'create_text',
      replaceText => 'replace_text',
      replaceAsset => 'replace_asset',
      restoreSnapshot => 'restore_snapshot',
    };
  }

  static ChangeAction fromWire(String value) => switch (value) {
        'create_text' => createText,
        'replace_text' => replaceText,
        'replace_asset' => replaceAsset,
        'restore_snapshot' => restoreSnapshot,
        _ => throw FormatException('Unknown ChangeAction: $value'),
      };
}

/// Lifecycle state of a candidate change.
enum CandidateState {
  proposed,
  approved,
  rejected,
  committed,
  superseded;

  String get wireName => name;

  static CandidateState fromWire(String value) => switch (value) {
        'proposed' => proposed,
        'approved' => approved,
        'rejected' => rejected,
        'committed' => committed,
        'superseded' => superseded,
        _ => throw FormatException('Unknown CandidateState: $value'),
      };

  /// Terminal states cannot transition further.
  bool get isTerminal =>
      this == rejected || this == committed || this == superseded;
}

/// Thrown when deserializing a record with an unsupported schema version.
final class UnsupportedSchemaVersionException implements Exception {
  const UnsupportedSchemaVersionException(this.version, this.typeName);

  final Object? version;
  final String typeName;

  @override
  String toString() =>
      'UnsupportedSchemaVersionException($typeName: schema_version=$version)';
}

/// The durable marker written before an approved canonical target is replaced.
///
/// A commit intent is recovery state, not a commit receipt. It remains
/// immutable until a receipt or explicit recovery outcome resolves it.
final class CommitIntent {
  const CommitIntent({
    required this.id,
    required this.projectId,
    required this.candidateId,
    required this.targetPath,
    required this.baseRevision,
    required this.expectedRevision,
    required this.expectedContentHash,
    required this.idempotencyKey,
  });

  factory CommitIntent.fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'];
    if (version != currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version, 'CommitIntent');
    }
    return CommitIntent(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      candidateId: json['candidate_id'] as String? ?? '',
      targetPath: json['target_path'] as String? ?? '',
      baseRevision: json['base_revision'] as int? ?? 0,
      expectedRevision: json['expected_revision'] as int? ?? 0,
      expectedContentHash: json['expected_content_hash'] as String? ?? '',
      idempotencyKey: json['idempotency_key'] as String? ?? '',
    );
  }

  static const currentSchemaVersion = 1;

  final String id;
  final String projectId;
  final String candidateId;
  final String targetPath;
  final int baseRevision;
  final int expectedRevision;
  final String expectedContentHash;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
        'schema_version': currentSchemaVersion,
        'id': id,
        'project_id': projectId,
        'candidate_id': candidateId,
        'target_path': targetPath,
        'base_revision': baseRevision,
        'expected_revision': expectedRevision,
        'expected_content_hash': expectedContentHash,
        'idempotency_key': idempotencyKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitIntent &&
          id == other.id &&
          projectId == other.projectId &&
          candidateId == other.candidateId &&
          targetPath == other.targetPath &&
          baseRevision == other.baseRevision &&
          expectedRevision == other.expectedRevision &&
          expectedContentHash == other.expectedContentHash &&
          idempotencyKey == other.idempotencyKey;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        candidateId,
        targetPath,
        baseRevision,
        expectedRevision,
        expectedContentHash,
        idempotencyKey,
      );
}

/// The explicit result recorded when an in-flight commit intent is resolved.
enum RecoveryOutcomeType {
  receiptCompleted,
  intentAbandoned,
  targetFrozen;

  String get wireName => switch (this) {
        receiptCompleted => 'receipt_completed',
        intentAbandoned => 'intent_abandoned',
        targetFrozen => 'target_frozen',
      };

  static RecoveryOutcomeType fromWire(String value) => switch (value) {
        'receipt_completed' => receiptCompleted,
        'intent_abandoned' => intentAbandoned,
        'target_frozen' => targetFrozen,
        _ => throw FormatException('Unknown RecoveryOutcomeType: $value'),
      };

  /// More precise vocabulary for the untouched-base reconciliation case.
  static const intentAbandonedAtBase = intentAbandoned;
}

/// An immutable, auditable resolution of a [CommitIntent].
final class RecoveryOutcome {
  const RecoveryOutcome({
    required this.id,
    required this.intentId,
    required this.projectId,
    required this.targetPath,
    required this.outcome,
    required this.resolvedAt,
    this.reason,
  });

  factory RecoveryOutcome.fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'];
    if (version != currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version, 'RecoveryOutcome');
    }
    return RecoveryOutcome(
      id: json['id'] as String? ?? '',
      intentId: json['intent_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      targetPath: json['target_path'] as String? ?? '',
      outcome: RecoveryOutcomeType.fromWire(json['outcome'] as String? ?? ''),
      resolvedAt: DateTime.parse(json['resolved_at'] as String? ??
          DateTime.utc(1970).toIso8601String()),
      reason: json['reason'] as String?,
    );
  }

  static const currentSchemaVersion = 1;

  final String id;
  final String intentId;
  final String projectId;
  final String targetPath;
  final RecoveryOutcomeType outcome;
  final DateTime resolvedAt;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'schema_version': currentSchemaVersion,
        'id': id,
        'intent_id': intentId,
        'project_id': projectId,
        'target_path': targetPath,
        'outcome': outcome.wireName,
        'resolved_at': resolvedAt.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoveryOutcome &&
          id == other.id &&
          intentId == other.intentId &&
          projectId == other.projectId &&
          targetPath == other.targetPath &&
          outcome == other.outcome &&
          resolvedAt == other.resolvedAt &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
      id, intentId, projectId, targetPath, outcome, resolvedAt, reason);
}

/// Compatibility name for callers that describe the record explicitly.
typedef RecoveryOutcomeRecord = RecoveryOutcome;

/// The file or asset targeted by a mutation.
final class ChangeTarget {
  const ChangeTarget({
    required this.projectRelativePath,
    required this.kind,
  });

  factory ChangeTarget.fromJson(Map<String, dynamic> json) => ChangeTarget(
        projectRelativePath: json['project_relative_path'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
      );

  final String projectRelativePath;
  final String kind;

  Map<String, dynamic> toJson() => {
        'project_relative_path': projectRelativePath,
        'kind': kind,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeTarget &&
          projectRelativePath == other.projectRelativePath &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(projectRelativePath, kind);
}

/// An immutable proposal to change one canonical target.
///
/// State changes produce a new record; the original is never mutated.
final class CandidateChange {
  const CandidateChange({
    required this.id,
    required this.projectId,
    required this.origin,
    required this.action,
    required this.target,
    required this.baseRevision,
    required this.payloadHash,
    required this.actionHash,
    required this.createdAt,
    required this.state,
    this.runId,
  });

  factory CandidateChange.fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'];
    if (version != currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version, 'CandidateChange');
    }
    return CandidateChange(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      origin: ChangeOrigin.fromWire(json['origin'] as String? ?? ''),
      action: ChangeAction.fromWire(json['action'] as String? ?? ''),
      target: ChangeTarget.fromJson(
          (json['target'] as Map<String, dynamic>?) ?? {}),
      baseRevision: json['base_revision'] as int? ?? 0,
      payloadHash: json['payload_hash'] as String? ?? '',
      actionHash: json['action_hash'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ??
          DateTime.utc(1970).toIso8601String()),
      state: CandidateState.fromWire(json['state'] as String? ?? 'proposed'),
      runId: json['run_id'] as String?,
    );
  }

  static const currentSchemaVersion = 1;

  final String id;
  final String projectId;
  final ChangeOrigin origin;
  final ChangeAction action;
  final ChangeTarget target;
  final int baseRevision;
  final String payloadHash;
  final String actionHash;
  final DateTime createdAt;
  final CandidateState state;
  final String? runId;

  /// Creates a copy with a different state (all other fields preserved).
  CandidateChange withState(CandidateState newState) => CandidateChange(
        id: id,
        projectId: projectId,
        origin: origin,
        action: action,
        target: target,
        baseRevision: baseRevision,
        payloadHash: payloadHash,
        actionHash: actionHash,
        createdAt: createdAt,
        state: newState,
        runId: runId,
      );

  Map<String, dynamic> toJson() => {
        'schema_version': currentSchemaVersion,
        'id': id,
        'project_id': projectId,
        'origin': origin.wireName,
        'action': action.wireName,
        'target': target.toJson(),
        'base_revision': baseRevision,
        'payload_hash': payloadHash,
        'action_hash': actionHash,
        'created_at': createdAt.toUtc().toIso8601String(),
        'state': state.wireName,
        if (runId != null) 'run_id': runId,
      };
}

/// An immutable approval or rejection decision bound to exact candidate state.
final class ApprovalDecision {
  const ApprovalDecision({
    required this.id,
    required this.candidateId,
    required this.candidateHash,
    required this.actionHash,
    required this.baseRevision,
    required this.actorId,
    required this.approved,
    required this.decidedAt,
    required this.policy,
  });

  factory ApprovalDecision.fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'];
    if (version != currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version, 'ApprovalDecision');
    }
    return ApprovalDecision(
      id: json['id'] as String? ?? '',
      candidateId: json['candidate_id'] as String? ?? '',
      candidateHash: json['candidate_hash'] as String? ?? '',
      actionHash: json['action_hash'] as String? ?? '',
      baseRevision: json['base_revision'] as int? ?? 0,
      actorId: json['actor_id'] as String? ?? '',
      approved: json['approved'] as bool? ?? false,
      decidedAt: DateTime.parse(json['decided_at'] as String? ??
          DateTime.utc(1970).toIso8601String()),
      policy: json['policy'] as String? ?? '',
    );
  }

  static const currentSchemaVersion = 1;

  final String id;
  final String candidateId;
  final String candidateHash;
  final String actionHash;
  final int baseRevision;
  final String actorId;
  final bool approved;
  final DateTime decidedAt;
  final String policy;

  /// Returns true only if all bound values match the current candidate.
  bool matchesCandidate({
    required String candidateHash,
    required String actionHash,
    required int baseRevision,
  }) {
    return this.candidateHash == candidateHash &&
        this.actionHash == actionHash &&
        this.baseRevision == baseRevision;
  }

  Map<String, dynamic> toJson() => {
        'schema_version': currentSchemaVersion,
        'id': id,
        'candidate_id': candidateId,
        'candidate_hash': candidateHash,
        'action_hash': actionHash,
        'base_revision': baseRevision,
        'actor_id': actorId,
        'approved': approved,
        'decided_at': decidedAt.toUtc().toIso8601String(),
        'policy': policy,
      };
}

/// An immutable receipt proving a commit was applied.
final class CommitReceipt {
  const CommitReceipt({
    required this.id,
    required this.candidateId,
    required this.approvalId,
    required this.idempotencyKey,
    required this.beforeRevision,
    required this.afterRevision,
    required this.affectedPaths,
    required this.committedAt,
    required this.receiptHash,
  });

  factory CommitReceipt.fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'];
    if (version != currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version, 'CommitReceipt');
    }
    return CommitReceipt(
      id: json['id'] as String? ?? '',
      candidateId: json['candidate_id'] as String? ?? '',
      approvalId: json['approval_id'] as String? ?? '',
      idempotencyKey: json['idempotency_key'] as String? ?? '',
      beforeRevision: json['before_revision'] as int? ?? 0,
      afterRevision: json['after_revision'] as int? ?? 0,
      affectedPaths: (json['affected_paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      committedAt: DateTime.parse(json['committed_at'] as String? ??
          DateTime.utc(1970).toIso8601String()),
      receiptHash: json['receipt_hash'] as String? ?? '',
    );
  }

  static const currentSchemaVersion = 1;

  final String id;
  final String candidateId;
  final String approvalId;
  final String idempotencyKey;
  final int beforeRevision;
  final int afterRevision;
  final List<String> affectedPaths;
  final DateTime committedAt;
  final String receiptHash;

  Map<String, dynamic> toJson() => {
        'schema_version': currentSchemaVersion,
        'id': id,
        'candidate_id': candidateId,
        'approval_id': approvalId,
        'idempotency_key': idempotencyKey,
        'before_revision': beforeRevision,
        'after_revision': afterRevision,
        'affected_paths': affectedPaths,
        'committed_at': committedAt.toUtc().toIso8601String(),
        'receipt_hash': receiptHash,
      };
}
