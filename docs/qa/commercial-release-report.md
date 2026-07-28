# LingBi Commercial Release Evidence

**Evidence date:** 2026-07-28

**Branch:** `agent/lingbi-openwrite-commercial-delta`

**Release metadata version:** `1.0.1`

This report records repository evidence; it is not a commercial-readiness certificate. Status vocabulary is limited to `REAL`, `PARTIAL`, `DISABLED`, `BLOCKED_EXTERNAL`, and `NOT_IMPLEMENTED`.

## Task 1 reproducibility gates

| Gate | Evidence state |
|------|----------------|
| Tracked imported sources, `pubspec.lock`, and QA gates | PASS — `test/release_metadata_contract_test.dart` (4/4) |
| App/launcher/installer/README version agreement | PASS — `1.0.1` |
| `flutter analyze lib/` | PASS — `No issues found` |
| `flutter test` | PASS — 1002 tests, 0 failures |
| `flutter build windows --release` | PASS locally; CI runs for pull requests and protected-branch pushes |
| Portable package | PASS locally — relative-path `SHA256SUMS.txt` and `PROVENANCE.json` emitted |
| Repository-wide format check | FAIL (pre-existing) — 173 historical files would change; no broad reformat was applied in Task 1 |
| Installer/upgrade/uninstall/rollback matrix | Not yet executed; release remains not commercially ready |

P1 long-form evaluation in this repository is synthetic and is not accepted as professional-user or live-provider evidence. A live-provider run without real credentials is not evidence of provider acceptance.

## Capability audit

| # | Capability | Status | Repository evidence / remaining gap |
|---|------------|--------|-------------------------------------|
| 1 | Project creation from genre templates | PARTIAL | UI/services exist; Windows golden path is not closed |
| 2 | Project brief atomic persistence | REAL | Repository and atomic-write tests cover persisted briefs |
| 3 | Transactional runtime model switching | PARTIAL | Rollback consumers and real bounded endpoint check remain incomplete |
| 4 | Project asset overview | PARTIAL | Components exist; session routing is incomplete |
| 5 | Progressive three-question onboarding | PARTIAL | State is tested; end-to-end first-chapter transition is incomplete |
| 6 | Recoverable first chapter workflow | PARTIAL | Candidate/version pieces exist; restart journey is incomplete |
| 7 | Atomic file save | REAL | Temp/flush/replace/backup behavior has automated tests |
| 8 | Recovery center | PARTIAL | Services/pages exist; real restore and editor refresh are incomplete |
| 9 | Portable project package | PARTIAL | ZIP/hash validation exists; staged import/register/restart transaction is incomplete |
| 10 | Windows shortcuts and command palette | REAL | `test/windows_keyboard_navigation_test.dart` |
| 11 | Windows responsive layout | REAL | Targeted 1024/1280/1440 widget tests |
| 12 | Time-aware story graph | PARTIAL | Domain/service tests exist; production journey evidence is incomplete |
| 13 | Entity linking quality | PARTIAL | Synthetic test/eval evidence only; no professional corpus evidence |
| 14 | Explainable context compiler | PARTIAL | Compiler exists; real chapter/Canon/onboarding bridge is incomplete |
| 15 | Continuity gates | PARTIAL | Unit-level gates exist; production generation path is incomplete |
| 16 | Planning matrix | PARTIAL | Scene-card domain exists; complete writing workflow is unverified |
| 17 | Whole-book review with evidence | PARTIAL | Workflow tests exist; persisted restart-safe change plan is incomplete |
| 18 | Safe change propagation | PARTIAL | No-silent-edit tests exist; full downstream application path is incomplete |
| 19 | Signed skill manifests and audit log | PARTIAL | Sources are tracked; production workflow/approval trust chain is incomplete |
| 20 | Skill marketplace rollback | PARTIAL | Unit tests exist; production install/update path remains unverified |
| 21 | Licensed market intelligence | BLOCKED_EXTERNAL | No licensed connector agreement or credentials |
| 22 | Authorized reference ingestion | PARTIAL | Policy tests exist; production ingestion evidence is incomplete |
| 23 | Short-story adaptation | PARTIAL | Domain workflow tests only |
| 24 | Drama adaptation with traceability | PARTIAL | Domain workflow tests only |
| 25 | Parallel branch workflow | PARTIAL | Unit-level reversible branch behavior only |
| 26 | Task-level model routing | PARTIAL | Metadata/routing pieces exist; runtime consumer rollback is incomplete |
| 27 | WebDAV project synchronization | PARTIAL | Components exist; complete portable-project round trip/conflict UI is incomplete |
| 28 | Studio collaboration roles | PARTIAL | Role/service behavior exists; multi-user production evidence is absent |
| 29 | Entitlements and billing boundary | PARTIAL | Billing is safely disabled; asymmetric production license trust root is incomplete |
| 30 | Privacy-first diagnostics | PARTIAL | Types/services exist; one persistent DI preference and record-time consent remain incomplete |
| 31 | Windows migration and rollback | PARTIAL | Migration helpers exist; open/register/restart transaction and install matrix are incomplete |
| 32 | Standards-compliant DOCX export | NOT_IMPLEMENTED | Word export is not advertised |
| 33 | General terminal/system-command tools | DISABLED | Separate reviewed sandbox is required before enablement |

## External gates

| Gate | Status | Required evidence |
|------|--------|-------------------|
| Licensed market-data connector | BLOCKED_EXTERNAL | Commercial data agreement and production credentials |
| Payment/refund/tax integration | BLOCKED_EXTERNAL | Merchant account, verified webhooks, refund and tax evidence |
| Windows code signing/SmartScreen | BLOCKED_EXTERNAL | Genuine OV/EV certificate and reputation evidence |
| Privacy/legal text approval | BLOCKED_EXTERNAL | Jurisdiction-approved text |
| Professional author/studio pilots | BLOCKED_EXTERNAL | Real recruited users and recorded outcomes |
| Live provider acceptance | BLOCKED_EXTERNAL | Real provider credentials and redacted bounded-run evidence |

## Rollback limits

- Git history can reproduce a previous binary only when the referenced commit, tracked lockfile, toolchain and build evidence are retained.
- The application aims to preserve user data on uninstall, but that claim remains unverified until the Windows install matrix is executed.
- Project migration downgrade/interruption behavior remains `PARTIAL`; do not claim arbitrary-version compatibility.
