# LingBi P0–P3 Commercial Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn LingBi into a Windows-first, local-first, model-neutral and traceable AI creation operating system for professional Chinese long-form web-fiction authors and small content studios.

**Architecture:** Preserve the existing domain services and pipeline, but replace UI-level orchestration with deep workflow modules. Establish four trusted seams first—`ProjectBriefRepository`, `RuntimeModelSelection`, `ProjectAssetRepository`, and `ProjectSessionManager`—then connect the existing candidate/locking/snapshot pipeline through recoverable workflows. Advanced continuity, review, market, adaptation, sync, collaboration, and commercial capabilities build only on those seams.

**Tech Stack:** Flutter Desktop (Windows), Dart, Quill, local portable project files, existing Canon/ZVec abstractions, HTTP AI providers, WebDAV, Flutter test.

## Global Constraints

- Target Windows Desktop only; do not add Android, iOS, or responsive-phone requirements.
- Preserve existing user-owned dirty changes until each is explicitly absorbed and tested.
- No production behavior without a failing test first.
- User text and project assets remain readable, editable, and exportable without a subscription.
- Telemetry is opt-in and disabled by default.
- Every AI request records the actual provider/model/prompt version and context source summary, never the API key.
- Every AI mutation of正文 or Story Assets is candidate → diff → confirmation → atomic write → recoverable version.
- UI components call workflow/repository interfaces, never orchestrate AI, Canon, files, and versions directly.
- `flutter analyze lib/` must have zero errors; no new warnings in modified files.
- `flutter test` must pass after every task group.
- Each phase ends with `flutter build windows --release` and a phase acceptance report.
- External gates—licensed market data, payment merchant credentials, code-signing certificate, and real-user trials—must use production interfaces and remain visibly blocked until genuine evidence exists; no fake success.

---

## Dependency Map

```text
P0 trust seams
  ProjectBrief ─┐
  ModelRuntime ─┼─> ProjectSession -> ProjectAsset -> FirstChapterWorkflow
  File safety ──┘                         │                  │
                                          └-> Recovery <────┘

P1 long-form moat
  StoryGraph -> ContextCompiler -> Continuity gates -> Review/Propagation

P2 professional expansion
  Source-backed Market Intel + Reference ingestion + Adaptation workflows
  + Task model routing + Complete WebDAV sync

P3 commercial scale
  Collaboration + Entitlements + Privacy/Telemetry + Windows distribution
```

## Phase P0 — Trusted Writing Loop

### Task 1: Baseline Contract and Migration Fixtures

**Files:**
- Create: `test/fixtures/legacy_project_v1/.lingbi/project.json`
- Create: `test/fixtures/legacy_settings_v1.json`
- Create: `test/commercial_baseline_contract_test.dart`
- Create: `lib/services/migrations/schema_versions.dart`

**Interfaces:**
- Produces: `SchemaVersions.project`, `SchemaVersions.settings`, immutable legacy fixtures used by later migration tests.

- [ ] **Step 1: Write the failing schema contract test**

```dart
test('current schema versions are explicit positive integers', () {
  expect(SchemaVersions.project, greaterThan(0));
  expect(SchemaVersions.settings, greaterThan(0));
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/commercial_baseline_contract_test.dart`
Expected: FAIL because `schema_versions.dart` does not exist.

- [ ] **Step 3: Add explicit schema constants and checked-in legacy fixtures**

```dart
abstract final class SchemaVersions {
  static const project = 2;
  static const settings = 2;
  static const portablePackage = 1;
}
```

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test test/commercial_baseline_contract_test.dart`
Commit: `test: lock commercial data contracts`

### Task 2: ProjectBrief as the Single Creation Contract

**Files:**
- Create: `lib/domain/project/project_brief.dart`
- Create: `lib/services/project_brief_repository.dart`
- Modify: `lib/core/models/project.dart`
- Modify: `lib/services/project_service.dart`
- Test: `test/project_brief_repository_test.dart`

**Interfaces:**
- Produces: `ProjectBrief`, `ProjectBriefRepository.read(projectId)`, `write(projectId, brief, {expectedRevision})`.
- Consumes: portable `.lingbi/project.json` storage.

- [ ] **Step 1: Write tests for round-trip, genre preservation, revision conflict, and legacy migration**

```dart
test('round trip preserves template and genre', () async {
  final brief = ProjectBrief(title: '长夜', genreId: 'xuanhuan', templateId: 'genre:xuanhuan');
  await repository.write('p1', brief, expectedRevision: 0);
  expect(await repository.read('p1'), brief.copyWith(revision: 1));
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/project_brief_repository_test.dart`
Expected: FAIL because the domain type and repository are missing.

- [ ] **Step 3: Implement immutable JSON contract and atomic repository write**

```dart
final class ProjectBrief {
  const ProjectBrief({required this.title, required this.genreId, required this.templateId,
    this.targetPlatform, this.targetLength, this.audience, this.premise, this.revision = 0});
  final String title, genreId, templateId;
  final String? targetPlatform, audience, premise;
  final int? targetLength;
  final int revision;
}
```

- [ ] **Step 4: Make `ProjectService` create the complete brief before the first disk write**

- [ ] **Step 5: Run GREEN and commit**

Run: `flutter test test/project_brief_repository_test.dart test/project_service_test.dart`
Commit: `feat: persist project brief atomically`

### Task 3: Genre Card → Brief Sheet → Project Transaction

**Files:**
- Modify: `lib/ui_v2/pages/welcome_page.dart`
- Create: `lib/ui_v2/models/project_template.dart`
- Create: `lib/ui_v2/components/project_brief_sheet.dart`
- Modify: `lib/ui_v2/components/app_scaffold.dart`
- Test: `test/ui_v2_project_creation_flow_test.dart`

**Interfaces:**
- Produces: `ValueChanged<ProjectTemplate> onCreateProject`, `ProjectBriefSheet.show(...)` returning `ProjectBrief?`.
- Consumes: Task 2 `ProjectBriefRepository`.

- [ ] **Step 1: Write widget test proving 玄幻 is preselected and survives creation/reopen**

```dart
testWidgets('genre card passes the same genre through creation', (tester) async {
  await tester.tap(find.text('玄幻'));
  await tester.pumpAndSettle();
  expect(find.text('玄幻'), findsWidgets);
  expect(fakeCreator.lastBrief?.genreId, 'xuanhuan');
});
```

- [ ] **Step 2: Run RED and confirm the current `VoidCallback` loses the template**

Run: `flutter test test/ui_v2_project_creation_flow_test.dart`

- [ ] **Step 3: Replace the generic dialog with the context-preserving side sheet**
- [ ] **Step 4: Route new/open/import through one `ProjectSessionManager.open` path**
- [ ] **Step 5: Run GREEN and commit**

Commit: `feat: create projects from selected templates`

### Task 4: Transactional Runtime Model Selection

**Files:**
- Create: `lib/core/ai/runtime_model_selection.dart`
- Modify: `lib/core/ai/models/endpoint_config.dart`
- Modify: `lib/services/ai_service.dart`
- Modify: `lib/services/settings_service.dart`
- Modify: `lib/services/guided_flow_engine.dart`
- Modify: `lib/core/di/service_locator.dart`
- Modify: `lib/ui_v2/components/model_selector.dart`
- Test: `test/runtime_model_selection_test.dart`
- Test: `test/model_selector_widget_test.dart`

**Interfaces:**
- Produces: `RuntimeModelSelection.select(endpointId, modelId) -> ModelSelectionResult` and `RuntimeModelSnapshot current`.
- Guarantees: validate → rebuild provider → synchronize consumers → persist → publish; failure restores previous snapshot.

- [ ] **Step 1: Write a failing cross-consumer test**

```dart
test('successful switch updates chat, guided flow and next request payload', () async {
  final result = await runtime.select('provider-b', 'model-b');
  expect(result.isSuccess, isTrue);
  expect(ai.currentModelId, 'model-b');
  expect(guided.aiProvider.modelId, 'model-b');
  expect(settings.getSelectedModelId('provider-b'), 'model-b');
});
```

- [ ] **Step 2: Run RED and record stale-provider failure**
- [ ] **Step 3: Implement immutable endpoint `copyWith(modelId:)` and transactional runtime switch**
- [ ] **Step 4: Change `ModelSelector` to show pending state and update only after confirmed success**
- [ ] **Step 5: Test failure rollback, restart restore, deletion of current endpoint, and no duplicate registration**
- [ ] **Step 6: Run GREEN and commit**

Commit: `feat: make model selection match runtime requests`

### Task 5: ProjectAsset Repository and Visible Overview

**Files:**
- Create: `lib/domain/project/project_asset.dart`
- Create: `lib/services/project_asset_repository.dart`
- Create: `lib/ui_v2/pages/project_overview_page.dart`
- Create: `lib/ui_v2/components/project_asset_card.dart`
- Modify: `lib/services/project_meta_repository.dart`
- Modify: `lib/ui_v2/components/project_tabs.dart`
- Modify: `lib/ui_v2/components/app_scaffold.dart`
- Test: `test/project_asset_repository_test.dart`
- Test: `test/project_overview_page_test.dart`

**Interfaces:**
- Produces: stable `ProjectAsset{id, projectId, type, title, storagePath, revision, source, updatedAt}`.
- Asset states: `notStarted`, `generating`, `editable`, `awaitingConfirmation`, `failed`.

- [ ] **Step 1: Write failing tests for stable IDs, idempotent Canon indexing, optimistic revision, and five visible asset states**
- [ ] **Step 2: Run RED**
- [ ] **Step 3: Implement repository on top of existing `project_meta` files with temp-write + replace**
- [ ] **Step 4: Build Overview with one local-rule next action and no automatic paid network request**
- [ ] **Step 5: Verify navigation is Overview / Writing / Ideation / Review / Publish**
- [ ] **Step 6: Run GREEN and commit**

Commit: `feat: expose project assets and next actions`

### Task 6: Progressive Three-Question Onboarding

**Files:**
- Create: `lib/services/project_onboarding_workflow.dart`
- Create: `lib/ui_v2/components/onboarding_question_card.dart`
- Create: `lib/ui_v2/pages/project_onboarding_page.dart`
- Modify: `lib/services/guided_flow_engine.dart`
- Test: `test/project_onboarding_workflow_test.dart`
- Test: `test/project_onboarding_page_test.dart`

**Interfaces:**
- Produces: `ProjectOnboardingWorkflow.answer/skip/resume`, durable `OnboardingState`.
- Updates three initial assets: protagonist, core world rule, opening scene plan.

- [ ] **Step 1: Write failing resume/idempotency tests for protagonist goal, obstacle, and opening event**
- [ ] **Step 2: Run RED**
- [ ] **Step 3: Implement each answer as an atomic asset revision and durable workflow event**
- [ ] **Step 4: Replace full-screen chat as the only onboarding UI with question cards plus live asset preview**
- [ ] **Step 5: Verify skip/manual-writing/model-config-return paths**
- [ ] **Step 6: Run GREEN and commit**

Commit: `feat: add progressive project onboarding`

### Task 7: Recoverable FirstChapterWorkflow

**Files:**
- Create: `lib/workflows/first_chapter/first_chapter_workflow.dart`
- Create: `lib/workflows/first_chapter/first_chapter_state_store.dart`
- Create: `lib/workflows/first_chapter/first_chapter_event.dart`
- Modify: `lib/modules/pipeline/novel_application_service.dart`
- Modify: `lib/ui_v2/pages/editor_page.dart`
- Modify: `lib/ui_v2/components/candidate_panel.dart`
- Test: `test/first_chapter_workflow_test.dart`
- Test: `test/first_chapter_recovery_integration_test.dart`

**Interfaces:**
- Produces:

```dart
abstract interface class FirstChapterWorkflow {
  Stream<FirstChapterEvent> start(FirstChapterRequest request);
  Future<AdoptionResult> adopt(String candidateId);
  Future<void> reject(String candidateId);
  Future<FirstChapterState?> resume(String projectId);
  Future<void> cancel();
}
```

- [ ] **Step 1: Write RED tests for generate-without-overwrite, restart recovery, edit conflict, reject, adopt+snapshot, cancel, and disk-full failure**
- [ ] **Step 2: Run RED**
- [ ] **Step 3: Implement business-stage events: readingAssets, generating, candidateReady, waitingForConfirmation, writing, completed, failed**
- [ ] **Step 4: Route Editor and AI panel through this workflow; remove Widget-only candidate ownership**
- [ ] **Step 5: Verify every adoption uses existing write lock and source version check**
- [ ] **Step 6: Run GREEN and commit**

Commit: `feat: connect recoverable first chapter workflow`

### Task 8: Atomic Save, Recovery Center, and Portable Project Package

**Files:**
- Create: `lib/services/atomic_file_store.dart`
- Create: `lib/services/recovery_center_service.dart`
- Create: `lib/services/portable_project_package_service.dart`
- Create: `lib/ui_v2/pages/recovery_center_page.dart`
- Modify: `lib/services/document_service.dart`
- Modify: `lib/services/version_history_service.dart`
- Modify: `lib/services/export_service.dart`
- Test: `test/atomic_file_store_test.dart`
- Test: `test/recovery_center_service_test.dart`
- Test: `test/portable_project_package_test.dart`

**Interfaces:**
- Portable manifest includes schema, checksums, brief, documents, assets, Canon, candidates, versions, memos, and enabled local Skills metadata.

- [ ] **Step 1: Write fault-injection tests around temp write, fsync/flush, replace, manifest validation, and corrupted archive rejection**
- [ ] **Step 2: Run RED**
- [ ] **Step 3: Implement soft delete and unified candidates/versions/trash recovery APIs**
- [ ] **Step 4: Replace fake Word export with genuine DOCX or remove the claim until standards-compliant output exists**
- [ ] **Step 5: Import on a clean data directory and rebuild all indexes from portable files**
- [ ] **Step 6: Run GREEN and commit**

Commit: `feat: add crash-safe recovery and project packages`

### Task 9: Windows UX, Keyboard, Accessibility, and P0 Release Gate

**Files:**
- Create: `lib/ui_v2/services/command_palette_service.dart`
- Create: `lib/ui_v2/components/command_palette.dart`
- Modify: `lib/ui_v2/components/app_scaffold.dart`
- Modify: `lib/ui_v2/components/sidebar.dart`
- Modify: `lib/ui_v2/components/ai_assistant.dart`
- Modify: `windows/runner/main.cpp`
- Test: `test/windows_keyboard_navigation_test.dart`
- Create: `docs/qa/p0-windows-release-checklist.md`

**Interfaces:**
- Commands: Ctrl+N, Ctrl+O, Ctrl+K, Ctrl+Shift+A, Ctrl+Comma, Ctrl+S.
- Layout: 1440 three columns; 1280 collapsible AI; 1024 hidden AI overlay; editor ≥600px.

- [ ] **Step 1: Write failing shortcut, focus, Esc-preservation, and layout breakpoint widget tests**
- [ ] **Step 2: Run RED**
- [ ] **Step 3: Implement command routing and accessible focus/semantic states**
- [ ] **Step 4: Use Open Design outputs only after mapping each state to real workflow data**
- [ ] **Step 5: Run `flutter analyze lib/`, `flutter test`, and `flutter build windows --release`**
- [ ] **Step 6: Commit P0 acceptance evidence**

Commit: `feat: complete Windows trusted writing loop`

## Phase P1 — Long-Form Intelligence Moat

### Task 10: Time-Aware StoryGraph

**Files:**
- Create: `lib/modules/story_graph/story_graph.dart`
- Create: `lib/modules/story_graph/story_graph_repository.dart`
- Create: `lib/modules/story_graph/text_entity_linker.dart`
- Modify: `lib/services/canon_service.dart`
- Modify: `lib/services/character_relation_graph_service.dart`
- Test: `test/story_graph_repository_test.dart`
- Test: `test/text_entity_linker_eval_test.dart`

**Interfaces:**
- Entity facts carry `validFromChapter`, `validToChapter`, `sourceDocumentId`, `sourceRange`, `confidence`, and `confirmation`.

- [ ] Write RED tests for aliases, progression, temporal queries, evidence, undo, and F1 evaluation.
- [ ] Implement stable graph storage and migration from Canon.
- [ ] Add human confirmation for extracted facts and relations.
- [ ] Verify entity-linking F1 ≥0.90 on checked-in Chinese fiction corpus.
- [ ] Commit: `feat: add time-aware story graph`

### Task 11: Explainable ContextCompiler and Inspector

**Files:**
- Create: `lib/modules/context/context_compiler.dart`
- Create: `lib/modules/context/context_manifest.dart`
- Create: `lib/ui_v2/components/context_inspector.dart`
- Modify: `lib/modules/pipeline/context_assembler.dart`
- Modify: `lib/modules/pipeline/project_data_source.dart`
- Test: `test/context_compiler_test.dart`
- Test: `test/context_recall_eval_test.dart`

**Interfaces:**
- Produces `CompiledContext{text, entries, tokenEstimate, omissions}` where every entry has source, reason, time point, priority, token cost, and truncation status.

- [ ] Write RED tests for budget allocation, time-aware facts, mandatory constraints, deterministic truncation, and source display.
- [ ] Replace empty RAG/strand/runtime-state data sources with real adapters.
- [ ] Add user-visible inspector without exposing secrets or hidden chain-of-thought.
- [ ] Verify key-fact Recall@context ≥95% and stale fact injection <1%.
- [ ] Commit: `feat: compile explainable story context`

### Task 12: Continuity Gates

**Files:**
- Create: `lib/modules/continuity/continuity_gate.dart`
- Modify: `lib/services/foreshadowing_service.dart`
- Modify: `lib/services/strand_weave_service.dart`
- Modify: `lib/services/anti_hallucination_service.dart`
- Modify: `lib/modules/pipeline/novel_application_service.dart`
- Test: `test/continuity_gate_test.dart`

**Interfaces:**
- Produces pre-generation constraints and post-generation `ContinuityIssue` with evidence, severity, proposed action, and confirmation requirement.

- [ ] Write RED corpus tests for foreshadowing recall, strand red-lines, inventions vs contradictions, and false-positive budgets.
- [ ] Make high-risk conflicts block adoption or require explicit override.
- [ ] Verify high-risk recall ≥95%, false positives <10%, and no silent correction.
- [ ] Commit: `feat: enforce long-form continuity gates`

### Task 13: Planning Matrix and Scene Workflow

**Files:**
- Create: `lib/domain/planning/scene_card.dart`
- Create: `lib/services/planning_matrix_service.dart`
- Create: `lib/ui_v2/pages/planning_matrix_page.dart`
- Modify: `lib/core/database/story_beats_repository.dart`
- Modify: `lib/ui_v2/pages/storyboard_page.dart`
- Test: `test/planning_matrix_service_test.dart`

- [ ] Write RED tests for POV/location/subplot filters, drag reorder, chapter synchronization, and context updates.
- [ ] Implement stable scene cards and transactionally reorder related chapters.
- [ ] Verify 100-chapter filtering/reorder and undo.
- [ ] Commit: `feat: add scene planning matrix`

### Task 14: Whole-Book Review and Safe Change Propagation

**Files:**
- Create: `lib/workflows/review/book_review_workflow.dart`
- Create: `lib/workflows/review/change_plan.dart`
- Modify: `lib/services/six_dimension_review_service.dart`
- Modify: `lib/services/change_propagation_service.dart`
- Modify: `lib/services/de_ai_flavor_service.dart`
- Modify: `lib/services/workflow_approval_service.dart`
- Test: `test/book_review_workflow_test.dart`
- Test: `test/change_propagation_eval_test.dart`

- [ ] Write RED tests for evidence-linked findings, selective diff application, changed-source conflicts, undo, and reviewer feedback.
- [ ] Implement developmental/line/dialogue/copy/custom review modes.
- [ ] Make Canon changes generate an ordered impact plan, never silent batch edits.
- [ ] Verify propagation omissions <5% on the benchmark novel and factual drift <1% for style rewrites.
- [ ] Commit: `feat: add evidence-based whole-book revision`

### Task 15: Signed and Auditable Skills

**Files:**
- Create: `lib/services/skill/skill_manifest_verifier.dart`
- Create: `lib/services/skill/skill_audit_log.dart`
- Modify: `lib/services/skill/skill_executor.dart`
- Modify: `lib/services/skill_marketplace.dart`
- Modify: `lib/services/skill/distillation_service.dart`
- Test: `test/skill_security_test.dart`

- [ ] Write RED adversarial tests for path escape, undeclared network, manifest tampering, version rollback, and secret access.
- [ ] Enforce declared project-scoped capabilities and immutable audit records.
- [ ] Add install source, version, signature, permission diff, rollback, and offline package UI.
- [ ] Commit: `feat: secure the skill ecosystem`

### Task 16: P1 Evaluation and Windows Performance Budget

**Files:**
- Create: `tool/eval/run_long_form_eval.dart`
- Create: `test/fixtures/eval_novel/`
- Create: `docs/qa/p1-long-form-eval.md`

- [ ] Check in a rights-safe synthetic Chinese long-form evaluation corpus and expected facts.
- [ ] Measure 1000 chapters / 3 million Chinese characters: cold open, context compile, search, save, review, export.
- [ ] Run all P1 quality thresholds and record raw JSON results.
- [ ] Run analyze/test/release build.
- [ ] Commit: `test: add long-form quality gates`

## Phase P2 — Professional Growth Layer

### Task 17: Source-Backed Chinese Market Intelligence

**Files:**
- Create: `lib/services/market/market_data_connector.dart`
- Create: `lib/services/market/market_evidence.dart`
- Modify: `lib/services/market_intel_service.dart`
- Modify: `lib/ui_v2/components/market_panel.dart`
- Modify: `lib/ui_v2/components/toolbox_page.dart`
- Test: `test/market_intel_evidence_test.dart`

**Interfaces:**
- Every claim includes platform, observedAt, sampleSize, source URI/connector, license, confidence, and cache age.

- [ ] Write RED tests that reject un-sourced claims, stale evidence, missing project genre/platform, and synthetic AI trends.
- [ ] Implement connector registry with a disabled state when no licensed connector exists.
- [ ] Pass `ProjectBrief` context into the panel and ContextCompiler only after explicit user enablement.
- [ ] Commit: `feat: require evidence for market intelligence`

### Task 18: Authorized Reference Ingestion

**Files:**
- Create: `lib/services/reference/reference_source_policy.dart`
- Modify: `lib/services/reference_book_service.dart`
- Modify: `lib/ui_v2/components/reference_book_panel.dart`
- Test: `test/reference_ingestion_policy_test.dart`

- [ ] Write RED tests for local-file-first ingestion, source permission, robots/license metadata, resumable failure, citation ranges, and anti-copy similarity.
- [ ] Store every insight with a source locator and refuse unsupported scraping.
- [ ] Inject only abstract style constraints, never long copied text.
- [ ] Commit: `feat: make reference analysis traceable`

### Task 19: Professional Adaptation Workflows

**Files:**
- Create: `lib/workflows/adaptation/short_story_workflow.dart`
- Create: `lib/workflows/adaptation/drama_adaptation_workflow.dart`
- Create: `lib/workflows/adaptation/parallel_branch_workflow.dart`
- Modify: related services and panels.
- Test: `test/adaptation_workflows_test.dart`

- [ ] Write RED tests for derivation from project assets, stable character identity, reversible branches, scene/shot traceability, and export.
- [ ] Wrap existing ShortStory/Drama/ParallelWorld services in recoverable project workflows.
- [ ] Keep them out of primary navigation until measured professional value is available.
- [ ] Commit: `feat: productize professional adaptation workflows`

### Task 20: Task-Level Model Routing and Cost Controls

**Files:**
- Create: `lib/core/ai/task_model_runtime.dart`
- Modify: `lib/services/model_router_service.dart`
- Modify: all workflow request factories.
- Test: `test/task_model_runtime_test.dart`

- [ ] Write RED tests for planning/writing/review routes, budget caps, timeout, 429 fallback, local-only mode, and audit explanation.
- [ ] Resolve a model snapshot at task start and keep it stable for the task.
- [ ] Record fallback reason and actual cost estimate without exposing keys.
- [ ] Commit: `feat: route models by writing task`

### Task 21: Complete WebDAV Project Sync

**Files:**
- Create: `lib/services/sync/project_sync_manifest.dart`
- Create: `lib/services/sync/three_way_merge_service.dart`
- Modify: `lib/services/sync/webdav_service.dart`
- Modify: `lib/services/sync/sync_manager.dart`
- Create: `lib/ui_v2/pages/sync_conflict_page.dart`
- Test: `test/webdav_project_sync_test.dart`

- [ ] Write RED tests for all portable assets, interrupted upload, remote deletion, three-way conflict, candidate/version preservation, and secret exclusion.
- [ ] Sync the portable manifest rather than ad-hoc files.
- [ ] Present base/local/remote diff and never auto-resolve content conflicts silently.
- [ ] Commit: `feat: synchronize complete projects safely`

### Task 22: P2 Professional Value Gate

**Files:**
- Create: `docs/qa/p2-professional-pilot-protocol.md`
- Create: `tool/eval/run_professional_workflow_eval.dart`

- [ ] Define measurable tasks for market research, reference analysis, short story, drama, branching, routing, and sync.
- [ ] Automate technical portions and clearly mark external author/partner evidence as blocked until collected.
- [ ] Run analyze/test/release build and record outputs.
- [ ] Commit: `test: add professional workflow gates`

## Phase P3 — Commercial Scale

### Task 23: Studio Collaboration and Approval

**Files:**
- Create: `lib/domain/collaboration/role.dart`
- Create: `lib/services/collaboration_service.dart`
- Create: `lib/ui_v2/pages/collaboration_page.dart`
- Modify: `lib/services/workflow_approval_service.dart`
- Test: `test/collaboration_permissions_test.dart`

- [ ] Write RED tests for owner/editor/reviewer/viewer, comments, approvals, offline changes, audit log, and permission denial.
- [ ] Keep single-user confirmation lightweight while enabling studio roles when configured.
- [ ] Commit: `feat: add studio collaboration controls`

### Task 24: Signed Entitlements and Payment Adapter Boundary

**Files:**
- Create: `lib/services/entitlements/entitlement_service.dart`
- Create: `lib/services/entitlements/license_signature_verifier.dart`
- Create: `lib/services/billing/billing_gateway.dart`
- Modify: `lib/services/license_service.dart`
- Modify: `lib/services/subscription_service.dart`
- Test: `test/entitlement_service_test.dart`

**Interfaces:**
- `BillingGateway` is production-disabled until merchant credentials and webhook verification exist.
- Local content operations never depend on a paid entitlement.

- [ ] Write RED tests for signed offline license, tamper, expiry, refund, offline grace, network failure, purchase restore, and local-content access after downgrade.
- [ ] Replace format-only activation with signature verification.
- [ ] Implement a real gateway adapter contract; do not ship fake purchase success.
- [ ] Commit: `feat: enforce trustworthy entitlements`

### Task 25: Privacy, Consent, Diagnostics, and Reliability Telemetry

**Files:**
- Create: `lib/services/privacy/privacy_preferences.dart`
- Create: `lib/services/diagnostics/diagnostic_event.dart`
- Modify: `lib/services/sync/sync_manager.dart`
- Modify: `lib/ui_v2/pages/settings_page.dart`
- Test: `test/privacy_consent_test.dart`

- [ ] Write RED tests proving default-off telemetry, explicit consent record, field allow-list, revocation, retention, export, and secret redaction.
- [ ] Wire the existing UI switch to persistent consent rather than Widget-only state.
- [ ] Define crash-free sessions and funnel events without collecting manuscript contents.
- [ ] Commit: `feat: make diagnostics private by default`

### Task 26: Windows Distribution, Migration, Update, and Rollback

**Files:**
- Create: `lib/services/migrations/migration_runner.dart`
- Modify: `lib/services/update_checker.dart`
- Create: `tool/windows/package_release.ps1`
- Create: `docs/qa/windows-install-upgrade-matrix.md`
- Test: `test/migration_runner_test.dart`

- [ ] Write RED tests for every legacy schema, failed migration rollback, interrupted update, and downgrade protection.
- [ ] Produce deterministic release artifacts and checksums.
- [ ] Keep code-signing marked blocked until a genuine certificate is provided; never create a fake signature.
- [ ] Verify clean install, upgrade, uninstall-with-data-preserved, and rollback in disposable Windows profiles.
- [ ] Commit: `build: add Windows release and migration gates`

### Task 27: Live Provider and User-Journey Acceptance

**Files:**
- Create: `integration_test/commercial_user_journey_test.dart`
- Create: `tool/eval/run_live_provider_acceptance.dart`
- Create: `docs/qa/live-provider-acceptance-report.md`

**Interfaces:**
- The live harness reads an API credential only through a protected local credential alias or process environment; it never accepts a key on the command line and never prints, persists, exports, or snapshots the value.
- Live requests are bounded by an explicit maximum request count and token budget, and write only redacted provider/model/status/latency evidence.

- [ ] Write RED tests proving the harness refuses missing credentials, redacts authorization headers, caps usage, and cannot include manuscript/API secrets in logs.
- [ ] Add user-perspective journeys for first launch, every project entry, every primary navigation item, all 31 capability states, model switching, offline fallback, error recovery, export/reimport, and restart resume.
- [ ] Run deterministic fake-provider journeys first, then use the protected free API for bounded live generation, review, style, continuity, routing, and adaptation checks.
- [ ] Record functional result, actual provider/model, latency, recoverability, and user-visible next action for every journey.
- [ ] Keep any feature with failed or missing live evidence disabled or labelled `BLOCKED_EXTERNAL`; do not mark the release commercial-ready.
- [ ] Commit: `test: add live commercial user acceptance`

### Task 28: Final Commercial Verification and Publication

**Files:**
- Create: `docs/qa/commercial-release-report.md`
- Modify: `README.md`
- Modify: release notes/version metadata.

- [ ] Audit every one of the 31 capabilities as real/disabled/blocked; remove unsupported marketing claims.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test tool`.
- [ ] Run `flutter analyze lib/` and record zero errors.
- [ ] Run full `flutter test` and record count/failures.
- [ ] Run long-form and professional evaluation suites.
- [ ] Run live-provider user journeys and verify the acceptance report contains no credential or manuscript content.
- [ ] Run `flutter build windows --release` and record artifact checksum.
- [ ] Check `git diff`, stage only project-owned changes, and create final commits.
- [ ] Push `verify/batch1-20260724` to `origin`.
- [ ] Open a draft PR against remote `main` containing evidence, remaining external gates, migration notes, and rollback instructions.

## External Evidence Gates

The following are part of P2/P3 completion but cannot truthfully be closed by source code alone:

1. Licensed/authorized platform market-data sources and their usage terms.
2. Merchant account, webhook secret, refund flow, and tax/invoice policy.
3. Windows code-signing certificate and reputation validation.
4. Privacy/legal text approved for the actual deployment jurisdiction.
5. 30–50 real first-time users and professional-author benchmark tasks.

For each gate, the code must expose a disabled production adapter, a health/status screen, and an acceptance protocol. The release report must say `BLOCKED_EXTERNAL` until genuine evidence is supplied.

## Self-Review Checklist

- [ ] Every capability in the 31-item benchmark maps to at least one task.
- [ ] P0 creates a usable product independent of P1–P3.
- [ ] P1 builds the Story Graph + Context Compiler + safe-generation moat.
- [ ] P2 expansion capabilities remain out of primary navigation until value evidence exists.
- [ ] P3 never locks user-owned local content behind payment.
- [ ] No task calls a mock, placeholder, or disabled external adapter “complete”.
- [ ] Existing dirty files are reviewed and absorbed only with tests.
- [ ] Every production task includes a RED command, GREEN command, and commit boundary.
