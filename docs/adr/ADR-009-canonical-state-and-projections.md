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
| Run, RunEvent, Checkpoint | canonical operational state until retention policy archives it |
| Backup/restore manifest and restore receipt | canonical audit state |
| Search index, vector embedding, UI summaries, caches | projection |
| Marketplace rankings and remote catalog cache | replaceable external cache |

### Revision rules

1. Every canonical file carries a monotonically increasing `revision` integer
   and a deterministic `content_hash` (lowercase SHA-256 hex).
2. A mutation is only valid if its `base_revision` matches the current revision
   of the target. Mismatch produces a typed `REVISION_CONFLICT` result.
3. `content_hash` is computed over the canonical serialization of the file
   content, not over transport or display representations.
4. Projections and caches never carry revision authority. They may be deleted
   and rebuilt from canonical state at any time.
5. Replaceable external caches may be stale indefinitely; they never participate
   in conflict detection.

### Canonical hashing

- **JSON:** recursively sort object keys lexicographically, preserve list order,
  encode as UTF-8, compute SHA-256. No fields are excluded unless the caller
  explicitly passes a reduced map.
- **Text:** normalize CRLF (`\r\n`) to LF (`\n`). Do not trim leading/trailing
  whitespace. Encode as UTF-8, compute SHA-256.
- Output is always lowercase hexadecimal (64 characters for SHA-256).

## Consequences

- All future mutation, backup, and sync code references this classification.
- `lib/domain/mutation/canonical_revision.dart` provides the value object and
  hash functions. Domain code imports neither Flutter nor `dart:io`.
- Projections must be rebuildable; tests may delete them without data loss.
- Related: ADR-010 (candidate-approval-commit) will link here.
