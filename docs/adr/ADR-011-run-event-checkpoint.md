# ADR-011: Run, RunEvent, and Checkpoint

## Status

Accepted

## Context

LingBi's Agent loops, writing workflows, and first-chapter journey each
maintain their own ad-hoc state. When the app crashes or a provider stream
disconnects, there is no unified way to detect interrupted work, reconcile
side effects, or resume safely. ADR-009 classifies canonical state; ADR-010
defines mutation records. This ADR adds operational state: the Run lifecycle.

Related: [ADR-009](ADR-009-canonical-state-and-projections.md),
[ADR-010](ADR-010-candidate-approval-commit.md)

## Decision

### Run lifecycle

A Run represents one unit of AI-assisted work (generation, review, import).

Statuses: `queued`, `running`, `waitingProvider`, `waitingApproval`,
`committing`, `succeeded`, `failed`, `cancelled`, `interrupted`.

Terminal states: `succeeded`, `failed`, `cancelled`.

### RunEvent store

Every Run appends immutable events to `.lingbi/runs/<run-id>/events.jsonl`.
Each event carries: event_id, run_id, monotonic sequence, event_type,
occurred_at, project_brief_revision, idempotency_key, payload_hash,
previous_event_hash, and a redacted payload.

The hash chain and duplicate-idempotency rules mirror the mutation journal
(ADR-010 Task 3).

### Checkpoint

A Checkpoint is a periodic snapshot of Run state enabling crash recovery.
It records: last applied event sequence/hash, current status, ProjectBrief
revision/hash, candidate ids, pending approval/effect, completed receipts,
and provider metadata (excluding secrets).

### Recovery protocol

For every side effect: append `effect_intended` → persist checkpoint →
perform side effect → append `effect_completed` with receipt. On restart:
- receipt exists → append missing completed event;
- no receipt + target at before revision → retry once;
- target changed inconsistently → mark interrupted, require recovery UI.

## Consequences

- `lib/domain/runtime/run_models.dart` defines RunStatus and RunEvent.
- `lib/domain/runtime/run_transitions.dart` defines the pure transition table.
- `lib/shared/interfaces/run_store.dart` defines the storage interface.
- `lib/services/runtime/jsonl_run_store.dart` provides the local adapter.
- Existing workflow states remain as projections during migration.
