# ADR-009: Canonical State and Projections

## Status

Accepted

## Context

LingBi stores all project data as local JSON/text files. As the system grows
(mutation protocol, run recovery, backup/restore, future server adapters), we
need one unambiguous classification of what is authoritative and what can be
rebuilt. Without this, a cache or index could accidentally become the source of
truth, and crash recovery cannot know what to protect.

## Decision

### Classification

| Data | Classification |
|---|---|
| Project identity/configuration (`.lingbi/project.json`) | canonical |
| ProjectBrief | canonical |
| Chapters and accepted assets | canonical |
| Canon and author-confirmed facts | canonical |
| CandidateChange, ApprovalDecision, CommitReceipt | canonical audit state |
| CommitIntent for an in-flight mutation | canonical recovery state |
| Run, RunEvent, Checkpoint | canonical operational state until retention policy archives it |
| Backup/restore manifest and restore receipt | canonical audit state |
| Search index, vector embedding, UI summaries, caches | projection |
| Marketplace rankings and remote catalog cache | replaceable external cache |

### Revision rules

1. Every structured canonical JSON file uses a canonical envelope carrying a
   monotonically increasing `revision` integer and a deterministic
   `content_hash` (lowercase SHA-256 hex) alongside its complete `payload`.
   The content hash describes the payload only; `revision` and `content_hash`
   are envelope metadata and do not participate in that payload hash.
2. Human-readable canonical text files remain raw text. Their `content_hash`
   is computed from normalized text, while `revision`, the latest hash, and
   the evidence that advances them are authoritative in the project's
   mutation journal rather than embedded in the text or a per-file sidecar.
3. A mutation is only valid if its `base_revision` matches the current
   revision of the target (from the envelope for JSON or the journal for
   text). Mismatch produces a typed `REVISION_CONFLICT` result.
4. For structured canonical JSON, `content_hash` is computed over the
   canonical serialization of `payload`, not over envelope metadata, transport,
   or display representations. This avoids self-referential hashing and keeps
   a revision increment distinct from content identity.
5. Projections and caches never carry revision authority. They may be deleted
   and rebuilt from canonical state at any time.
6. Replaceable external caches may be stale indefinitely; they never participate
   in conflict detection.

### Canonical hashing

- **JSON payload:** recursively sort object keys lexicographically, preserve
  list order, encode as UTF-8, and compute SHA-256. The envelope's
  `content_hash` and `revision` are excluded by the envelope contract, not by
  an ad-hoc caller choice.
- **Text:** normalize CRLF (`\r\n`) to LF (`\n`). Do not trim leading/trailing
  whitespace. Encode as UTF-8, compute SHA-256.
- Output is always lowercase hexadecimal (64 characters for SHA-256).

### Legacy format migration

- Versioned read adapters may parse legacy canonical files that do not yet
  contain the canonical envelope. Reading them is side-effect free.
- Before the first protocol write, the system records a migration baseline:
  original bytes, detected source format, and normalized content hash.
- The first envelope write is represented by an explicit migration candidate
  or migration event. Opening or indexing a legacy file never silently rewrites
  it.
- The project remains read-only with respect to the legacy file until the user
  explicitly accepts the one-time storage-format upgrade. Acceptance produces
  the migration evidence required by the mutation protocol.
- A migration must preserve the business payload; if parsing is ambiguous or
  lossy, the file remains read-only and produces a typed migration failure.

## Consequences

- All future mutation, backup, and sync code references this classification.
- `lib/domain/mutation/canonical_revision.dart` provides the value object and
  hash functions. Domain code imports neither Flutter nor `dart:io`.
- Projections must be rebuildable; tests may delete them without data loss.
- Related: [ADR-010](ADR-010-candidate-approval-commit.md) defines the
  candidate-approval-commit mutation protocol built on this classification.
