# LingBi Commercial Release Evidence

**Evidence date:** 2026-07-29

**Branch:** `agent/openwrite-parity-ui`

**Evidence commit:** `700b2f04fd84ccae656654b339d38d929ca602a2`

**Release metadata version:** `1.0.1`

This report records repository evidence; it is not a commercial-readiness certificate. Status vocabulary is limited to `REAL`, `PARTIAL`, `DISABLED`, `BLOCKED_EXTERNAL`, and `NOT_IMPLEMENTED`.

## Task 1 reproducibility gates

| Gate | Evidence state |
|------|----------------|
| Tracked imported sources, `pubspec.lock`, and QA gates | PASS — `test/release_metadata_contract_test.dart` (4/4) |
| App/launcher/installer/README version agreement | PASS — `1.0.1` |
| `flutter analyze lib/` | PASS — `No issues found` |
| `flutter test --exclude-tags network` | PASS — 1056 tests, 0 failures |
| Live 10K provider acceptance | BLOCKED_EXTERNAL — an earlier run produced 12577 Chinese characters; the 2026-07-29 rerun hit SenseNova HTTP 429 after chapter 1 |
| `flutter build windows --release` | PASS — `build/windows/x64/runner/Release/lingbi.exe` |
| Portable package | PASS — relative-path `SHA256SUMS.txt`; `PROVENANCE.json` records commit `700b2f0` and `source_dirty: false` |
| Repository-wide format check | FAIL (pre-existing) — 173 historical files would change; no broad reformat was applied in Task 1 |
| Installer/upgrade/uninstall/rollback matrix | Not yet executed; release remains not commercially ready |

The deterministic suite is release evidence for repository behavior, not a substitute for provider availability or professional-user acceptance. Provider error text is now rejected at the chapter commit boundary instead of being saved as content.

## OpenWrite capability-parity slice

| Capability | Status | Current evidence / limit |
|------------|--------|--------------------------|
| Multi-provider model selection and routing | REAL | Runtime selector, endpoint settings, task routing and rollback tests |
| Project-aware AI read/search/write tools | REAL | Sandboxed `file_read`, `file_write`, `list_dir`, project document search and explicit write confirmation |
| Web search with source insertion | REAL | AI assistant source browser inserts attributed context blocks |
| Long-session context compression | REAL | `SessionCompactor` is wired into `AgentToolLoop` and preserves tool-call pairs |
| Novel-writer context assembly | REAL | Maintenance documents, Canon and recent chapters are compiled with mandatory priority |
| Candidate-first chapter generation | REAL | Candidate preview, rejection/regeneration, explicit adoption and atomic write |
| Post-chapter state settlement | REAL | Extracted facts require selection/confirmation before updating `章节摘要.md`; decisions are persisted |
| Project-backed six-dimension review | REAL | Selects real project documents, uses document ID and persists historical/latest JSON reports |
| Skill discovery/marketplace | REAL | Built-in/local discovery, install/update rollback and agent `skill_lookup`; remote trust remains policy-bound |
| WebDAV project sync | PARTIAL | Round-trip and conflict behavior are tested; production server interoperability remains external |
| TXT/Markdown/DOCX export | REAL | DOCX OOXML parts and content are tested; chapter selection is available in publish workflow |
| Licensed ranking/market data | BLOCKED_EXTERNAL | Bundled sample snapshots are clearly labeled; no licensed production connector exists |

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
| 17 | Whole-book review with evidence | PARTIAL | Project-backed chapter review now persists evidence; restart-safe whole-book change plans remain incomplete |
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
| 32 | Standards-compliant DOCX export | REAL | OOXML package and document content are verified in `test/openwrite_delta_test.dart` |
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
