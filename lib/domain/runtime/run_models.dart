/// Run lifecycle domain models.
///
/// Domain-layer — no Flutter, no dart:io.
/// See ADR-011 for Run/Event/Checkpoint design.
library;

/// Lifecycle status of a Run.
enum RunStatus {
  queued,
  running,
  waitingProvider,
  waitingApproval,
  committing,
  succeeded,
  failed,
  cancelled,
  interrupted;

  /// Terminal states cannot transition further.
  bool get isTerminal =>
      this == succeeded || this == failed || this == cancelled;

  String get wireName => name;

  static RunStatus fromWire(String value) => switch (value) {
        'queued' => queued,
        'running' => running,
        'waitingProvider' => waitingProvider,
        'waitingApproval' => waitingApproval,
        'committing' => committing,
        'succeeded' => succeeded,
        'failed' => failed,
        'cancelled' => cancelled,
        'interrupted' => interrupted,
        _ => throw FormatException('Unknown RunStatus: $value'),
      };
}

/// An immutable event in a Run's append-only history.
final class RunEvent {
  const RunEvent({
    required this.eventId,
    required this.runId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.projectBriefRevision,
    required this.payloadHash,
    required this.previousEventHash,
    this.idempotencyKey,
    this.payload = const {},
  });

  factory RunEvent.fromJson(Map<String, dynamic> json) => RunEvent(
        eventId: json['event_id'] as String? ?? '',
        runId: json['run_id'] as String? ?? '',
        sequence: json['sequence'] as int? ?? 0,
        eventType: json['event_type'] as String? ?? '',
        occurredAt: json['occurred_at'] as String? ?? '',
        projectBriefRevision: json['project_brief_revision'] as int? ?? 0,
        idempotencyKey: json['idempotency_key'] as String?,
        payloadHash: json['payload_hash'] as String? ?? '',
        previousEventHash: json['previous_event_hash'] as String? ?? '',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      );

  final String eventId;
  final String runId;
  final int sequence;
  final String eventType;
  final String occurredAt;
  final int projectBriefRevision;
  final String? idempotencyKey;
  final String payloadHash;
  final String previousEventHash;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'run_id': runId,
        'sequence': sequence,
        'event_type': eventType,
        'occurred_at': occurredAt,
        'project_brief_revision': projectBriefRevision,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        'payload_hash': payloadHash,
        'previous_event_hash': previousEventHash,
        'payload': payload,
      };

  RunEvent copyWith({
    int? sequence,
    String? occurredAt,
    String? payloadHash,
    String? previousEventHash,
  }) =>
      RunEvent(
        eventId: eventId,
        runId: runId,
        sequence: sequence ?? this.sequence,
        eventType: eventType,
        occurredAt: occurredAt ?? this.occurredAt,
        projectBriefRevision: projectBriefRevision,
        idempotencyKey: idempotencyKey,
        payloadHash: payloadHash ?? this.payloadHash,
        previousEventHash: previousEventHash ?? this.previousEventHash,
        payload: payload,
      );
}
