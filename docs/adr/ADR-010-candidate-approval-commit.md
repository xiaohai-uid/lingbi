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

### Three-record business invariant

Every completed mutation to canonical state produces exactly three immutable
business records:

1. **CandidateChange** — proposes a specific content change bound to a target
   path, action type, payload hash, action hash, and base revision.
2. **ApprovalDecision** — records who approved or rejected, cryptographically
   bound to the exact candidate hash, action hash, and base revision.
3. **CommitReceipt** — proves the change was applied, recording before/after
   revisions, affected paths, and an idempotency key.

An in-flight mutation may also persist one `CommitIntent` recovery marker. A
canonical file change is not considered committed until all three business
records exist and the receipt verifies the applied result. `CommitIntent` is
not a fourth business audit record; it exists only to make an interrupted
commit detectable and recoverable.

### Origin-specific approval policy

| Origin | Candidate | Approval | Default behavior |
|---|---|---|---|
| User UI edit | persisted | implicit (exact user action) | allowed |
| Agent | persisted | explicit user decision | denied without decision |
| Batch import | one per logical asset + batch id | preview + explicit batch decision | preview only |
| Text Skill | no mutation unless it returns a proposal | explicit for writes | read-only |
| File tool | persisted | explicit | denied without decision |
| Restore | staging candidate set | explicit restore decision | restore as new copy |
| External file edit | observed candidate/event | explicit reconciliation | frozen pending review |
| Legacy migration | persisted migration candidate | explicit migration decision | read-only until accepted |

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

### Crash consistency

- Before changing a canonical target, persist a `CommitIntent` containing the
  candidate hash, action hash, base revision, expected after revision/hash, and
  idempotency key.
- Replace the target atomically, verify the resulting revision/hash, and then
  persist the `CommitReceipt`.
- On startup, unresolved intents block further writes to their targets until
  recovery determines one of three outcomes: the target matches the expected
  result and the receipt can be completed; the target remains at the base
  result and the intent can be abandoned; or the target is indeterminate and
  requires fail-closed manual recovery.
- `CommitIntent` is immutable. Its resolution is evidenced by the resulting
  receipt or an explicitly recorded recovery outcome; it is never silently
  discarded.
- When the target is indeterminate, the protocol preserves the current bytes,
  the intent, and all available before/after evidence, then freezes the target
  and raises a visible recovery incident. It never auto-overwrites, auto-
  rolls back, or chooses by modification time.
- If the user elects to keep the current bytes, the protocol creates a new
  recovery-origin `CandidateChange` bound to the current revision and content
  hash. It requires a new explicit approval before becoming canonical; the
  original intent's approval is never inherited.

### Canonical file commit unit

- The mutation payload for a canonical asset collection is the complete
  canonical file, not an isolated asset fragment or an implicit in-place patch.
- Candidate payload hash, expected-after hash, and the bytes written to disk
  must all describe the same canonical serialization.
- Asset identifiers, operation type, and logical asset metadata may narrow the
  target for user-facing review, but they never replace the complete-file
  revision and hash checks.
- Asset-level patching or splitting assets into separate canonical files is a
  future protocol revision, not an alternate interpretation of this one.

### Failure contract

- Every canonical mutation entry point returns a typed `Result` describing
  success or a specific failure; callers must not infer success from `null`,
  `false`, an empty value, or a swallowed exception.
- Missing protocol dependencies, unresolved or ambiguous project roots,
  revision/content conflicts, unresolved recovery intents, permission errors,
  and storage failures are distinct fail-closed error categories.
- Infrastructure adapters may catch platform exceptions, but they must map
  them to the typed failure contract before returning to the domain or
  application layer.
- There is no implicit direct-write fallback when the mutation protocol is
  unavailable.

### Target path safety

- A mutation target is persisted only as a normalized project-relative path.
- Absolute paths, drive-qualified paths, UNC paths, empty segments, NUL bytes,
  and traversal segments (`..`) are rejected before any storage operation.
- The resolved target must remain within the resolved project root after
  symbolic links, junctions, and other reparse points are evaluated. Escaping
  the root is a typed fail-closed error, not a path to sanitize or rewrite.
- Path validation is part of the protocol boundary and is repeated at commit;
  a path that was safe when proposed is not trusted after a project move or
  filesystem topology change.

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
