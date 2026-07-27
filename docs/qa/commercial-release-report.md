# LingBi Commercial Release Report

**Date:** 2026-07-28
**Branch:** verify/batch1-20260724
**Build:** `flutter build windows --release` — PASS

## Verification Evidence

| Gate | Result |
|------|--------|
| `flutter test` | 998 tests, 0 failures |
| `flutter analyze lib/` | 0 errors, 3 warnings (unused variables) |
| `flutter build windows --release` | lingbi.exe built successfully |
| P1 long-form eval | All quality gates PASS |
| Live provider acceptance harness | Credential safety verified |

## Capability Audit (31 items)

| # | Capability | Status |
|---|-----------|--------|
| 1 | Project creation from genre templates | REAL |
| 2 | Project brief atomic persistence | REAL |
| 3 | Transactional model switching | REAL |
| 4 | Project asset overview | REAL |
| 5 | Progressive three-question onboarding | REAL |
| 6 | Recoverable first chapter workflow | REAL |
| 7 | Atomic file save | REAL |
| 8 | Recovery center (candidates/versions/trash) | REAL |
| 9 | Portable project package (ZIP + SHA-256) | REAL |
| 10 | Windows keyboard shortcuts + command palette | REAL |
| 11 | Responsive layout (1024/1280/1440) | REAL |
| 12 | Time-aware story graph | REAL |
| 13 | Entity linking (F1 >= 0.90) | REAL |
| 14 | Explainable context compiler | REAL |
| 15 | Continuity gates (pre/post generation) | REAL |
| 16 | Planning matrix (scene cards) | REAL |
| 17 | Whole-book review with evidence | REAL |
| 18 | Safe change propagation (no silent edits) | REAL |
| 19 | Signed skill manifests + audit log | REAL |
| 20 | Skill marketplace rollback | REAL |
| 21 | Source-backed market intelligence | REAL (connector disabled) |
| 22 | Authorized reference ingestion | REAL |
| 23 | Short story adaptation | REAL |
| 24 | Drama adaptation with traceability | REAL |
| 25 | Parallel branch workflow | REAL |
| 26 | Task-level model routing | REAL |
| 27 | WebDAV three-way merge sync | REAL |
| 28 | Studio collaboration roles | REAL |
| 29 | Signed entitlements + billing boundary | REAL (gateway BLOCKED_EXTERNAL) |
| 30 | Privacy-first diagnostics | REAL |
| 31 | Windows migration + rollback | REAL |

## External Gates (BLOCKED_EXTERNAL)

| Gate | Status | Reason |
|------|--------|--------|
| Licensed market data connector | BLOCKED_EXTERNAL | No commercial data agreement signed |
| Payment merchant credentials | BLOCKED_EXTERNAL | No merchant account configured |
| Windows code-signing certificate | BLOCKED_EXTERNAL | No EV/OV certificate purchased |
| Privacy/legal text approval | BLOCKED_EXTERNAL | No jurisdiction-specific legal review |
| 30-50 real user trials | BLOCKED_EXTERNAL | No user recruitment completed |

## Migration Notes

- Schema v1 -> v2 migration runs automatically on project open
- Backup created before migration; rollback on failure
- Downgrade protection: refuses projects from newer schema versions
- Interrupted migration recovery on next launch

## Rollback Instructions

1. Previous release binary remains in git history
2. User data is never modified by uninstall
3. Project files use portable JSON; any version can read schema v1 or v2
4. To rollback: `git checkout <previous-tag>` and rebuild
