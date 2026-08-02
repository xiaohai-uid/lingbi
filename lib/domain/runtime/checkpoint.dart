/// Checkpoint domain model for Run crash recovery.
///
/// Domain-layer — no Flutter, no dart:io.
library;

import 'package:lingbi/domain/runtime/run_models.dart';

/// A periodic snapshot of Run state enabling crash recovery.
final class Checkpoint {
  const Checkpoint({
    required this.runId,
    required this.lastEventSequence,
    required this.lastEventHash,
    required this.status,
    required this.projectBriefRevision,
    required this.projectBriefHash,
    required this.checkpointHash,
    this.candidateIds = const [],
    this.pendingApprovalId,
    this.pendingEffectKey,
    this.completedReceiptIds = const [],
    this.providerMetadata = const {},
    this.partialCandidateId,
    this.createdAt,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) => Checkpoint(
        runId: json['run_id'] as String? ?? '',
        lastEventSequence: json['last_event_sequence'] as int? ?? 0,
        lastEventHash: json['last_event_hash'] as String? ?? '',
        status: RunStatus.fromWire(json['status'] as String? ?? 'running'),
        projectBriefRevision: json['project_brief_revision'] as int? ?? 0,
        projectBriefHash: json['project_brief_hash'] as String? ?? '',
        candidateIds: (json['candidate_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        pendingApprovalId: json['pending_approval_id'] as String?,
        pendingEffectKey: json['pending_effect_key'] as String?,
        completedReceiptIds: (json['completed_receipt_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        providerMetadata:
            (json['provider_metadata'] as Map<String, dynamic>?) ?? {},
        partialCandidateId: json['partial_candidate_id'] as String?,
        checkpointHash: json['checkpoint_hash'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  final String runId;
  final int lastEventSequence;
  final String lastEventHash;
  final RunStatus status;
  final int projectBriefRevision;
  final String projectBriefHash;
  final List<String> candidateIds;
  final String? pendingApprovalId;
  final String? pendingEffectKey;
  final List<String> completedReceiptIds;
  final Map<String, dynamic> providerMetadata;
  final String? partialCandidateId;
  final String checkpointHash;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
        'run_id': runId,
        'last_event_sequence': lastEventSequence,
        'last_event_hash': lastEventHash,
        'status': status.wireName,
        'project_brief_revision': projectBriefRevision,
        'project_brief_hash': projectBriefHash,
        'candidate_ids': candidateIds,
        if (pendingApprovalId != null)
          'pending_approval_id': pendingApprovalId,
        if (pendingEffectKey != null) 'pending_effect_key': pendingEffectKey,
        'completed_receipt_ids': completedReceiptIds,
        'provider_metadata': providerMetadata,
        if (partialCandidateId != null)
          'partial_candidate_id': partialCandidateId,
        'checkpoint_hash': checkpointHash,
        if (createdAt != null) 'created_at': createdAt,
      };
}
