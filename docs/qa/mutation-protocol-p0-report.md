# MutationProtocol Commercial P0 Report

**Evidence date:** 2026-08-05

**Branch:** `agent/architecture-foundation`

**Ticket:** #69 MP-11 commercial P0 release gate

**Scope:** final verification, evidence files, and the production fixes
required by review: recovery-center frozen-intent lookup, restore path and
stable project identity, and receipt after-content-hash evidence.

**Line endings:** `mutation-protocol-p0-report.md` and the MP-11 section in
`p0-windows-release-checklist.md` are normalized to LF because the repository
has no `.gitattributes` or `core.autocrlf`; this keeps `git diff --check` clean.

## Result

**LOCAL_PASS** — the core mutation protocol, project identity, path safety,
crash recovery, recovery-center discoverability, restore, and first-chapter
journey have automated evidence. External distribution gates remain
`BLOCKED_EXTERNAL` and are not claimed complete.

## Verification Commands

| Command | Result |
|---------|--------|
| `flutter analyze lib/` | PASS — no issues |
| Focused mutation/recovery/first-chapter suites | PASS — see evidence table |
| `flutter test --exclude-tags network --concurrency=1` | PASS — 1473 tests, 0 failures |
| `flutter build windows --release` | See Windows artifact section |
| `tool/windows/package_release.ps1 -SkipBuild` | See Windows artifact section |

## RED Evidence

Before the production fixes, the exact failures were:

| Test | Exact failure |
|------|---------------|
| `mutation_fault_injection_test.dart` — reconcilePending frozen intent still visible | Expected length `1`, actual `[]`: `targetFrozen outcomes must still resolve their commit intent` |
| `recovery_center_service_test.dart` — restore routes stable project id | Expected `proj-restore`, actual the temp directory path used as `projectId` |

## Windows Artifact

`flutter build windows --release` succeeded and produced
`build\windows\x64\runner\Release\lingbi.exe`.

`tool/windows/package_release.ps1 -SkipBuild` succeeded and emitted
`PROVENANCE.json` plus relative-path `SHA256SUMS.txt` at
`C:\Users\a1691\AppData\Local\Temp\lingbi-release-package`.

The package step reports code signing as `BLOCKED_EXTERNAL`: no genuine
EV/OV certificate is configured, so SmartScreen warnings remain expected.

## GitNexus Change Scope

| Command | Result |
|---------|--------|
| `detect_changes --scope unstaged` | 17 files, 56 symbols, 8 affected processes, risk high. Includes user dirty `AGENTS.md`/`CLAUDE.md` plus the MP-11 production/test/docs changes |
| `detect_changes --scope compare --base-ref main` | 100 files, 872 symbols, 184 affected flows, risk critical. This reflects the local branch's existing work including #86 plus the MP-11 changes |

## P0 Acceptance Evidence

| Scenario | Status | Evidence |
|----------|--------|----------|
| Real temporary project directory | REAL | `test/mutation_p0_acceptance_test.dart`, `test/first_chapter_recovery_integration_test.dart` |
| Project-owned journal at `<root>/.lingbi/mutations/events.jsonl` | REAL | `test/project_mutation_journal_test.dart`, `test/mutation_p0_acceptance_test.dart` |
| Candidate -> approval -> commit writes full payload | REAL | `test/mutation_commit_writes_test.dart`, `test/mutation_p0_acceptance_test.dart` |
| Candidate hash, receipt after-content-hash, final disk bytes agree | REAL | `test/mutation_crash_recovery_test.dart`, `test/mutation_p0_acceptance_test.dart`, `test/chapter_mutation_protocol_integration_test.dart` |
| Close/reopen preserves state and journal chain | REAL | `test/mutation_p0_acceptance_test.dart`, `test/first_chapter_recovery_integration_test.dart` |
| Project move keeps identity and writes to current root | REAL | `test/mutation_project_move_test.dart`, `test/mutation_p0_acceptance_test.dart` |
| Duplicate copy is classified and not silently rebindable | REAL | `test/duplicate_project_identity_test.dart`, `test/mutation_p0_acceptance_test.dart` |
| Path escape is rejected at propose and commit | REAL | `test/project_path_guard_test.dart`, `test/file_canonical_store_test.dart`, `test/mutation_fault_injection_test.dart`, `test/mutation_commit_writes_test.dart` |
| External edit fails closed with `REVISION_CONFLICT` | REAL | `test/mutation_crash_recovery_test.dart`, `test/mutation_fault_injection_test.dart` |
| Crash before apply abandons intent | REAL | `test/mutation_crash_recovery_test.dart`, `test/mutation_fault_injection_test.dart` |
| Crash after apply completes receipt | REAL | `test/mutation_crash_recovery_test.dart`, `test/mutation_fault_injection_test.dart` |
| Indeterminate bytes freeze and preserve current content | REAL | `test/mutation_crash_recovery_test.dart`, `test/recovery_incident_test.dart` |
| Recovery center can surface an unresolved frozen intent | REAL | `test/recovery_incident_test.dart`, `test/mutation_fault_injection_test.dart` |
| Recovery center can surface a frozen intent after `reconcilePending` | REAL | `test/mutation_fault_injection_test.dart` |
| Factory-bound recovery center can scan and decide incidents | REAL | `test/mutation_fault_injection_test.dart` |
| Restore routes stable project id and relative path through MutationProtocol | REAL | `test/recovery_center_service_test.dart` |
| Clean portable project export/validate/import | REAL | `test/portable_project_package_test.dart` |
| Windows junction/symlink containment | PARTIAL | Deterministic rejection tests pass; host `mklink /J` still skipped with `无效开关 - "escape-junction"` |
| Full Windows install/upgrade/uninstall/rollback matrix | PARTIAL | `docs/qa/windows-install-upgrade-matrix.md` has manual entries remaining |

## User-Visible Behavior

- Candidate approval writes the complete chapter file atomically; the project
  can be closed and reopened, and the mutation journal still validates.
- A project move keeps its identity and writes to the current root. A
  duplicate project copy is classified and is not silently rebound.
- Path escapes, external edits, revision conflicts, and indeterminate crash
  bytes fail closed without overwriting user content.
- A frozen incident remains visible in the recovery center after
  `reconcilePending`; the user can approve the current bytes or abandon them
  to trash.
- Trash restore writes through `MutationProtocol` with a stable project id and
  project-relative target, producing a complete journal receipt and rejecting
  paths outside the project root.
- A valid portable package can be cleanly imported; corrupted package bytes are
  rejected before import.

## Known Gaps

1. **Release metadata and public release are out of sync.**
   Code metadata is still `1.0.1`, while the latest public release is `v1.1.0`.
   README/version synchronization belongs to #52.

2. **Host-specific junction evidence is unavailable in this run.**
   `mklink /J` was unavailable when the full suite ran, so the Windows junction
   test printed a skip instead of proving host containment.

## External Gates

| Gate | Status |
|------|--------|
| Windows code signing / SmartScreen | BLOCKED_EXTERNAL |
| Payment, refund, and tax integration | BLOCKED_EXTERNAL |
| Approved legal and privacy text | BLOCKED_EXTERNAL |
| Licensed market-data connector | BLOCKED_EXTERNAL |
| Real WebDAV server acceptance | BLOCKED_EXTERNAL |
| Professional author/studio pilots | BLOCKED_EXTERNAL |
| Live provider acceptance beyond current local SenseNova key | BLOCKED_EXTERNAL |

## Conclusion

The MP-11 local functionality gate is verified. The recovery-center lookup and
restore receipt gaps are fixed and covered by green tests; `#69` is now a local
pass with remaining external distribution gates explicitly `BLOCKED_EXTERNAL`.
