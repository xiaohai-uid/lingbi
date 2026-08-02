# ADR-010: Candidate-Approval-Commit Mutation Protocol

## Status

Accepted

## Context

LingBi's current write paths (candidate adoption, Agent tool writes, batch
import, Skill file tools, restore) each implement their own ad-hoc mutation
logic. Some bypass approval entirely (`autoApprove: true`), some treat a
missing callback as consent, and none produce a verifiable receipt. ADR-009
defines what is canonical; this ADR defines how canonical state may change.

Related: [ADR-009](ADR-009-canonical-state-and-projections.md)

## Decision

### Three-record invariant

Every mutation to canonical state produces exactly three persisted records:

1. **CandidateChange** — proposes a specific content change bound to a target
   path, action type, payload hash, action hash, and base revision.
2. **ApprovalDecision** — records who approved or rejected, cryptographically
   bound to the exact candidate hash, action hash, and base revision.
3. **CommitReceipt** — proves the change was applied, recording before/after
   revisions, affected paths, and an idempotency key.

No canonical file may change without all three records existing in the journal.

### Origin-specific approval policy

| Origin | Candidate | Approval | Default behavior |
|---|---|---|---|
| User UI edit | persisted | implicit (exact user action) | allowed |
| Agent | persisted | explicit user decision | denied without decision |
| Batch import | one per logical asset + batch id | preview + explicit batch decision | preview only |
| Text Skill | no mutation unless it returns a proposal | explicit for writes | read-only |
| File tool | persisted | explicit | denied without decision |
| Restore | staging candidate set | explicit restore decision | restore as new copy |

### Immutability and state machine

- All three records are immutable once persisted. State changes create new
  records rather than mutating existing ones.
- Candidate states: `proposed`, `approved`, `rejected`, `committed`,
  `superseded`.
- Legal transitions: proposed→approved, proposed→rejected,
  approved→committed, proposed/approved→superseded.
- Terminal states (rejected, committed, superseded) cannot transition.

### Binding and validation

- `candidateHash` = SHA-256 of the canonical JSON of the CandidateChange.
- `actionHash` = SHA-256 binding action + target + payload hash + base
  revision. Any change to these invalidates prior approvals.
- An ApprovalDecision is valid only if its bound candidateHash, actionHash,
  and baseRevision all match the current candidate.
- Missing approval callbacks fail closed. `confirmWrite == null` and
  `autoApprove` must never authorize Agent or tool writes.

### Serialization

- All records use snake_case JSON keys.
- Every record carries `schema_version: 1`.
- Deserialization of unknown future schema versions produces a typed failure,
  never a silent default.

## Consequences

- `lib/domain/mutation/mutation_models.dart` defines the immutable records.
- `lib/domain/mutation/mutation_transitions.dart` defines the pure transition
  function.
- Later tasks (3–6) build the journal, store, protocol adapter, and migrate
  all existing write origins onto this protocol.
- Old candidate JSON files remain readable and are lazily upgraded on first
  interaction through the new protocol.
