# LingBi OpenWrite Commercial Delta Execution Plan

> **Execution rule:** Use `superpowers:subagent-driven-development` task by task. Every production change starts from a failing test, each task has an implementer and an independent reviewer, and completion claims require fresh verification evidence.

**Goal:** Close the gap between the already-implemented P0-P3 skeleton and a trustworthy Windows-only commercial trial build, using the four OpenWrite Obsidian notes as product requirements without copying unsafe `system_command` behavior.

**Product position:** LingBi is a local-first, model-neutral AI writing operating system for Chinese long-form fiction authors and small studios. The primary commercial journey is genre selection -> prefilled project brief -> three-question onboarding -> visible project assets -> create/select first chapter -> generate candidate -> inspect/diff -> confirm atomic adoption -> optionally update maintenance assets -> recover/export/sync.

**Design system:** Open Design `warm-editorial` is the primary writing-surface system (warm paper, restrained terracotta accent, long-form typography and minimal elevation). Open Design `application` contributes desktop interaction rules (explicit hover/focus/loading/disabled states, 4/8/12/16/24/32 spacing, predictable cards and inputs). Existing LingBi tokens remain the implementation seam; no Figma or screenshot-derived implementation.

**Baseline on 2026-07-28:** local `flutter test` passes 998 tests only because three required Dart files are ignored but present locally. `flutter analyze lib/` reports 24 issues, including 3 warnings. The release report overstates several unconnected capabilities. External evidence gates cannot truthfully be completed by code.

## MVP scope amendment (user decision, 2026-07-28)

This iteration is an initial Windows trial build, not the final security/compliance release. Product usability and feature closure take priority over defense-in-depth.

- Keep only development-safety guardrails that prevent accidental local data loss (for example, release packaging may not recursively delete the repository or a drive root).
- In Task 2, implement custom endpoint connection testing and reliable runtime model switching only.
- Defer asymmetric commercial licensing, payment hardening, advanced diagnostic redaction, terminal sandboxing, code signing, legal/compliance review and adversarial security work to a dedicated later stream.
- Execute product tasks in this order: Task 4 -> Task 5 -> Task 6 -> Task 3 -> Task 7 -> Task 8 -> the MVP portions of Tasks 9 and 10.
- The MVP release report must label deferred items `DEFERRED_POST_MVP`; it must not spend implementation time pretending to complete them.
- Unit/widget tests are necessary but not sufficient. Before publication, run product-manager UAT on realistic, multi-asset Chinese-fiction projects (at minimum fantasy, urban/romance and mystery) through creation, 10+ chapter continuity, rewrite, candidate approval, Skill, restart recovery and export. Record both automated evidence and human content/UI review; a green test suite cannot override a failed real workflow.

## Global constraints

- Windows Desktop only; do not add mobile layouts or mobile platform code.
- Preserve local-first access to projects, documents, assets and exports regardless of entitlement.
- UI calls workflow/service interfaces; widgets do not orchestrate files, AI, Canon, versions and network directly.
- Every AI write is candidate -> diff -> approval -> atomic write -> recoverable version.
- No automatic conflict resolution for manuscript content.
- Telemetry is off by default and never records manuscript text, prompts, credentials or generic unbounded payloads.
- Unsupported external capabilities are visibly `BLOCKED_EXTERNAL`, never simulated as success.
- General terminal/system-command tools remain disabled until a separately reviewed sandbox exists.

## Task 1: Make the source tree and release evidence reproducible (P0)

**Files:** `.gitignore`, `pubspec.lock`, `.github/workflows/ci.yml`, `tool/windows/package_release.ps1`, `docs/qa/p0-windows-release-checklist.md`, `docs/qa/commercial-release-report.md`, `README.md`, `test/release_metadata_contract_test.dart`, plus the currently ignored production Dart files.

- [ ] RED: add a contract test/script proving all imported production sources, lockfile and QA gates are tracked, and that version/feature claims agree.
- [ ] Anchor root-only ignore rules so `lib/**/services` and `docs/qa` are not swallowed; track the three required Dart files and `pubspec.lock`.
- [ ] Remove the 24 analyzer issues without broad mechanical reformatting.
- [ ] Make Windows PR CI build/package the release, emit relative-path SHA256 and provenance, and upload the packaged artifact.
- [ ] Reclassify every release capability as `REAL`, `PARTIAL`, `DISABLED`, `BLOCKED_EXTERNAL` or `NOT_IMPLEMENTED` based on production evidence.
- [ ] Verify with `git ls-files`, `flutter analyze lib/`, `flutter test`, `flutter build windows --release`, and `tool/windows/package_release.ps1`.

## Task 2: Establish truthful runtime configuration, privacy and entitlements (P0/P3)

**Files:** `lib/core/ai/runtime_model_selection.dart`, `lib/services/ai_service.dart`, `lib/services/settings_service.dart`, `lib/services/license_service.dart`, `lib/services/subscription_service.dart`, `lib/services/entitlements/*`, `lib/services/privacy/*`, `lib/services/diagnostics/*`, `lib/core/di/service_locator.dart`, `lib/ui_v2/pages/settings_page.dart`.

- [ ] RED: test that an unsaved endpoint performs a real bounded connection/model check without being persisted, and failed model switching rolls back every consumer.
- [ ] Route every model selection through `RuntimeModelSelection`; show actual endpoint/model/latency/error and never claim success before a request succeeds.
- [ ] Replace format-only license activation with an asymmetric signed entitlement trust root. If no production public key exists, activation is disabled and `BLOCKED_EXTERNAL`.
- [ ] Register one persistent privacy preference and one guarded diagnostic collector in DI; default off, enforce consent at record time, remove generic `data`, redact by key and value.
- [ ] Verify endpoint, runtime switch, entitlement UI/DI, restart persistence, refund/downgrade and privacy revocation tests.

## Task 3: Make project open, migration, versions and recovery real (P0)

**Files:** `lib/services/project_service.dart`, `lib/services/migrations/migration_runner.dart`, `lib/services/portable_project_package_service.dart`, `lib/services/version_history_service.dart`, `lib/services/recovery_center_service.dart`, `lib/services/document_service.dart`, `lib/ui_v2/pages/import_export_page.dart`, `lib/ui_v2/pages/version_history_page.dart`, `lib/ui_v2/pages/recovery_center_page.dart`, `lib/core/di/service_locator.dart`.

- [ ] RED: open/import a project in a clean data directory, restart, and prove project/documents remain registered after migration.
- [ ] Add one `openAndRegisterProject(directoryPath)` transaction: recover interrupted migration, validate/migrate, scan, index and register; package import uses staging and commits only after validation.
- [ ] Restore a version by snapshotting current text then atomically replacing the actual document and refreshing repository/editor state.
- [ ] Add preview/adopt/restore actions for candidates, versions and snapshots; conflicts offer save-as instead of overwrite.
- [ ] Verify migration rollback, import/restart and recovery user journeys.

## Task 4: Complete the Windows golden path with Open Design (P0)

**Files:** `lib/domain/project/project_asset.dart`, `lib/services/project_asset_repository.dart`, `lib/services/project_onboarding_workflow.dart`, `lib/ui_v2/controllers/project_session_manager.dart`, `lib/ui_v2/components/app_scaffold.dart`, `lib/ui_v2/components/project_brief_sheet.dart`, `lib/ui_v2/pages/welcome_page.dart`, `lib/ui_v2/pages/project_overview_page.dart`, `lib/ui_v2/pages/project_onboarding_page.dart`, `lib/ui_v2/pages/editor_page.dart`, `test/windows_golden_path_test.dart`.

- [ ] RED: keyboard/mouse journey from selecting `玄幻` through saved first candidate, without manual sidebar detours or overview/onboarding loops.
- [ ] Preserve selected genre/template in the brief, show model readiness, and create the protagonist/world/opening assets through the three questions.
- [ ] Route create/open/import/recent-project through `ProjectSessionManager`; after onboarding create and select the first chapter before opening the editor.
- [ ] Apply Warm Editorial to writing surfaces and Application interaction states through existing tokens: one accent, warm paper, clear hierarchy, explicit focus/loading/error/retry and no decorative gradients/glass.
- [ ] Restart and prove project, selected chapter, candidate and version resume.

## Task 5: Connect real context, Skill execution and safe candidate maintenance (P0/P1)

**Files:** `lib/modules/context/*`, `lib/modules/pipeline/project_data_source.dart`, `lib/modules/pipeline/context_assembler.dart`, `lib/services/novel_application_service.dart`, `lib/services/skill/*`, `lib/workflows/skill/skill_execution_workflow.dart`, `lib/ui_v2/pages/editor_page.dart`, `lib/ui_v2/components/candidate_panel.dart`.

- [ ] RED: with seven ordered chapters, compile only the preceding five real summaries plus Canon and onboarding assets, with an explainable manifest and deterministic truncation.
- [ ] Bridge onboarding protagonist/world/opening answers into Canon/project assets and route production generation through `ContextCompiler`.
- [ ] Build `SkillExecutionWorkflow`: loader -> progressive resources -> permission check -> prompt/provider -> candidate -> approval -> atomic write -> audit. Changing `SKILL.md` must change the next request.
- [ ] Candidate actions support preview/diff, adopt, partial rewrite, reject and save-as. Adoption is atomic and versioned.
- [ ] After adoption, separately ask whether to update summary, character state, foreshadowing and timeline; no maintenance write before that confirmation.

## Task 6: Add the bounded Agent Tool Runtime and memo workspace (P1)

**Files:** `lib/agent_runtime/agent_tool.dart`, `tool_registry.dart`, `tool_call_loop.dart`, `tool_approval_policy.dart`, `tool_audit_log.dart`, `lib/domain/project/project_memo.dart`, `lib/services/memo_repository.dart`, `lib/ui_v2/components/tool_call_card.dart`, `lib/ui_v2/components/memo_panel.dart`, `lib/ui_v2/components/ai_assistant.dart`.

- [ ] RED: model emits read -> question -> write; reads may auto-run, writes pause for explicit approval, rejection changes no files, replay is idempotent.
- [ ] Register only bounded tools: `question`, `read_project_asset`, `list_project_files`, `write_project_asset`, `create_chapter`, `update_chapter_summary`, `web_search`, `create_memo`.
- [ ] Route writes through existing approval/candidate/atomic-version seams and redact the audit log.
- [ ] Implement project-scoped memo CRUD, restart recovery, Agent creation, portable packaging and sync inclusion.
- [ ] Keep terminal/system commands absent and document the sandbox gate.

## Task 7: Complete the Windows writing/import/export surface (P2)

**Files:** `lib/services/markdown_document_codec.dart`, `lib/ui_v2/components/markdown_preview_pane.dart`, `lib/ui_v2/pages/editor_page.dart`, `lib/ui_v2/pages/import_export_page.dart`, `lib/services/export_service.dart`, `lib/services/i_export_service.dart`, `pubspec.yaml`.

- [ ] RED: Markdown headings/emphasis/lists/links survive save/reopen; preview renders deterministically.
- [ ] Add Windows source/preview split or toggle without losing document semantics.
- [ ] Implement real OS drag/drop for MD/TXT using the same validated import path as the picker.
- [ ] Add stable ordered chapter selection and make TXT/MD/DOCX obey it.
- [ ] Produce standards-compliant OOXML DOCX containing Chinese text, or keep Word export disabled until the conformance test passes.

## Task 8: Wire complete WebDAV project synchronization (P2)

**Files:** `lib/services/sync/project_sync_manifest.dart`, `three_way_merge_service.dart`, `sync_manager.dart`, `webdav_service.dart`, `lib/ui_v2/pages/sync_conflict_page.dart`, `lib/ui_v2/pages/settings_page.dart`.

- [ ] RED: fake WebDAV round trip for the entire portable project, including interruption, remote deletion, candidates, versions and memos while excluding secrets.
- [ ] Replace `syncAll({})` with `syncProject(projectDir)`; reject empty scope.
- [ ] Parse ETag/Last-Modified, persist the base manifest and resume interrupted transfers.
- [ ] Any two-sided manuscript change opens base/local/remote conflict UI; no upload/overwrite until the user chooses.
- [ ] Keep third-party server compatibility evidence separate from the code-complete fake-server gate.

## Task 9: Replace synthetic quality and market claims with enforceable gates (P1/P2/P3)

**Files:** `tool/eval/run_long_form_eval.dart`, `test/fixtures/eval_novel/`, `lib/workflows/review/book_review_workflow.dart`, `lib/services/market/market_data_connector.dart`, `market_evidence.dart`, `lib/services/market_intel_service.dart`, `lib/services/acceptance/live_provider_harness.dart`, acceptance/evaluation tests and reports.

- [ ] Generate a rights-safe 1000-chapter, >=3,000,000 Chinese-character corpus and make the runner call real repositories, context, continuity, review, save and export paths.
- [ ] Enforce: entity F1 >= 0.90; context key-fact recall >= 95%; stale facts < 1%; high-risk continuity recall >= 95%; false positives < 10%; propagation omissions < 5%; style factual drift < 1%.
- [ ] Make whole-book review persist evidence-linked change plans, validate source versions and support restart-safe undo.
- [ ] Add a licensed connector registry and evidence schema. Unsourced/stale/unlicensed market claims are rejected and never injected; no connector means `BLOCKED_EXTERNAL`.
- [ ] Implement a bounded live-provider harness with atomic request/token budgets and redacted evidence; without credentials it remains `BLOCKED_EXTERNAL`.

### Task 9A: Real-novel product-manager UAT (MVP hard gate)

**Data:** Freeze public-domain Chinese works with source page/revision/license/SHA256 manifests: `西游记` for fantasy continuity, `红楼梦` for urban/romance relationship continuity, and `狄公传` or `三侠五义` for mystery clues. CI keeps a 10-chapter smoke subset; the Windows UAT artifact contains 20-30+ chapters per project.

**Files:** `tool/uat/fetch_public_domain_corpus.dart`, `tool/uat/build_novel_projects.dart`, `tool/uat/run_real_novel_uat.dart`, `test/fixtures/real_novels/*/manifest.json`, `test/real_app_golden_path_test.dart`, `test/real_novel_import_roundtrip_test.dart`, `integration_test/windows_real_novel_journey_test.dart`, `docs/qa/real-novel-uat-rubric.md`, `docs/qa/real-novel-uat-results.json`.

- [ ] Use real `AppScaffold`, DI and temp project directories; a handwritten stage harness does not count as product evidence.
- [ ] For each genre: select genre, complete genre-specific onboarding, import 20-30 chapters, continue/rewrite 10 chapters, approve/reject candidates, restart/recover, selectively export and reimport.
- [ ] Record actual chapter/character counts, provider/model, timing and the exact failed step. Missing credentials are `BLOCKED`, never `PASS`.
- [ ] Automated thresholds: no pre-approval disk mutation; save/recovery/export round trip 100%; preceding-five-chapter recall >=90%; hard timeline conflicts 0; naming consistency >=95%; chapter length 1800-3000 Chinese characters; direct adoption >=70% after human review.
- [ ] Human review: at least two blinded reviewers per genre score UI task clarity, character voice, continuity, pacing and genre fit. Mean genre-fit >=4/5 and lightly-editable-or-better >=90% are required for the commercial-trial label.

## Task 10: Final Windows commercial verification and GitHub publication (P3)

**Files:** `.github/workflows/ci.yml`, `launcher/`, `installer/`, `tool/windows/*`, `docs/qa/*`, `README.md`, release metadata.

- [ ] Unify version metadata across app, launcher, installer, README and artifact names.
- [ ] Verify update staging, checksum/signature failure, interruption and rollback; run the clean-install/upgrade/uninstall-preserve-data matrix in a disposable profile.
- [ ] Keep code signing, merchant/payment, legal approval, licensed market data, professional pilots and real provider runs `BLOCKED_EXTERNAL` until genuine evidence is supplied.
- [ ] Fresh gates: format check, zero analyzer issues, full tests, targeted integration tests, long-form/professional evaluations, release build, package checksum, clean checkout verification.
- [ ] Independent final code review, explicit staging, commits, push `agent/lingbi-openwrite-commercial-delta`, and create a draft PR against `main` with evidence, migration and rollback notes.

## External evidence gates

Only these may remain blocked after repository work: licensed market-data agreements/credentials; merchant account/webhooks/refunds/tax; Windows OV/EV certificate and SmartScreen reputation; jurisdiction-approved privacy/legal text; real professional-author/studio pilots; real provider credentials and live-run evidence. All other items are implementation gaps, not external blockers.
