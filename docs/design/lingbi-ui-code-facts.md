# LingBi UI Code Facts

This is the bounded source-of-truth package for Open Design. It describes the current Windows Flutter application, not an aspirational replacement architecture.

## Product

- Product: LingBi / 灵笔, a local-first Windows desktop writing tool for Chinese long-form fiction authors and small studios.
- Platform: Windows Desktop only. Do not produce Android, iOS, phone, or tablet layouts.
- Primary journey: genre selection -> prefilled project brief -> three-question onboarding -> visible project assets -> create/select first chapter -> generate candidate -> inspect/diff -> explicit adoption or rejection -> version/recovery/export.
- Trust rule: local projects, manuscripts, assets, history, and exports remain accessible without a subscription or network connection.
- AI write rule: AI output is a candidate. It does not become manuscript text until the author explicitly adopts it through the application workflow.
- Current branch: `agent/lingbi-openwrite-commercial-delta` in a linked worktree.
- Existing dirty implementation work must not be interpreted as a completed production contract.

## Application Shell

Source: `lib/ui_v2/components/app_scaffold.dart`.

`AppScaffold` owns four top-level surfaces:

1. Welcome state when no project is open.
2. Skill marketplace.
3. Settings.
4. Project workspace.

The project workspace is composed from:

- `TopBar`: theme, sidebar, AI panel, search, project switching, project tab closing, Skill market, and Windows commands.
- `ProjectNavigationBar`: the five project lifecycle tabs.
- `Sidebar`: chapter tree and document creation/selection.
- Current project page.
- `AiAssistantPanel`: docked on wide layouts and overlaid on narrower layouts.

The project navigation is exactly:

| `ProjectTab` | User label | Page |
|---|---|---|
| `overview` | 概览 | `ProjectOverviewPage` |
| `writing` | 写作 | `EditorPage` |
| `ideation` | 构思 | `StoryboardPage` |
| `review` | 审稿 | `ToolboxPage` |
| `publish` | 发布 | `ImportExportPage` |

Do not replace this navigation with project library, outline, asset library, collaboration, or recovery as primary project tabs. Those concepts may appear inside the existing lifecycle tabs or as global surfaces only when a production entry exists.

Windows commands already represented in `AppScaffold`:

- `Ctrl+N`: new project / return to welcome flow.
- `Ctrl+O`: open project directory.
- `Ctrl+K`: command palette.
- `Ctrl+Shift+A`: toggle AI assistant.
- `Ctrl+,`: settings.
- `Ctrl+S`: save command dispatch.
- `Esc`: dismiss settings or Skill marketplace.

Responsive workspace facts:

- Chapter sidebar is visible only when enabled and there is enough width.
- At less than 900 px the chapter sidebar is not docked; the design targets start at 1280 px.
- A docked AI panel may force the sidebar to hide below 1180 px.
- The AI assistant changes from docked presentation to an overlay according to `WorkspaceLayoutPolicy`.
- Design and review at 1280, 1440, 1600, and 1920 px.

## Project Session

Source: `lib/ui_v2/controllers/project_session_manager.dart`.

`ProjectSessionManager` is the intended UI boundary for project lifecycle. It:

- creates a project from a `ProjectBrief`;
- opens a project directory;
- restores the most recent valid project;
- loads up to five recent projects;
- opens or creates the first chapter;
- selects the active document and binds it to the active `ProjectSessionScope`;
- persists the selected document inside the project;
- persists recent project paths outside individual projects;
- exposes one active `ProjectSessionSnapshot`.

The UI must preserve a single continuous session across create, onboarding, overview, first chapter, candidate, restart, and recovery. It must not introduce a second project-selection model outside `ProjectSessionManager` or the existing project-tab controller.

Required session states:

- no project;
- valid recent projects;
- moved or deleted recent project omitted without blocking welcome;
- damaged recent project recoverable through Open Project;
- project open with no selected chapter;
- first chapter created and selected;
- selected chapter restored after restart;
- project or chapter operation failed with retry/alternate path.

## Project Assets

Source: `lib/domain/project/project_asset.dart` and `lib/services/project_asset_repository.dart`.

The five `ProjectAssetType` values are exact and exhaustive for the overview contract:

| Type | Chinese title | Storage path |
|---|---|---|
| `protagonist` | 主角 | `project_meta/characters.json` |
| `worldRules` | 世界规则 | `project_meta/worldbuilding.json` |
| `outline` | 故事大纲 | `project_meta/outline.json` |
| `openingScene` | 开场设计 | `project_meta/opening_scene.json` |
| `firstChapter` | 第一章 | `chapters/first-chapter.md` |

Every asset carries:

- stable id;
- project id;
- type and title;
- storage path;
- revision number;
- source: `user`, `ai`, or `imported`;
- state;
- last update time.

The five `ProjectAssetState` values are:

- `notStarted`;
- `generating`;
- `editable`;
- `awaitingConfirmation`;
- `failed`.

The project overview must not show all assets as complete by default. Asset cards need explicit source, revision, update time, next action, and failure/retry behavior.

## First Chapter Safety Chain

Sources:

- `lib/workflows/first_chapter/first_chapter_workflow.dart`
- `lib/workflows/first_chapter/first_chapter_event.dart`
- `lib/workflows/first_chapter/first_chapter_state_store.dart`
- `lib/modules/pipeline/novel_application_service.dart`
- `lib/ui_v2/components/candidate_panel.dart`
- `lib/ui_v2/pages/editor_page.dart`

The workflow stages represented by `FirstChapterStage` are a recoverable state machine. The user-visible sequence is:

1. `readingAssets`: read project assets and prepare context.
2. `generating`: stream candidate content.
3. `candidateReady`: candidate exists.
4. `waitingForConfirmation`: manuscript is unchanged and the author decides.
5. `writing`: explicit adoption is in progress.
6. `completed`: candidate was safely adopted.

Alternative states are:

- `rejected`;
- `cancelled`;
- `failed`.

The workflow persists project id, chapter id, target path, stage, source version, candidate id/content, error, and update time. `resume(projectId)` restores it after restart.

Design rules:

- Candidate and manuscript must be visually separated.
- “Candidate generated” must never look like “manuscript saved”.
- Adoption is an explicit author action.
- Rejection changes no manuscript text.
- Cancellation preserves local manuscript and recoverable state.
- Adoption failure returns to confirmation with an error and next action.
- Candidate expiration or source-version mismatch must be shown as a recoverable conflict, not silently overwritten.
- Version/recovery affordances appear after adoption and during failure handling.

## Page Inventory

All current `lib/ui_v2/pages` entries:

| Page | Responsibility |
|---|---|
| `WelcomePage` | Genre/template entry, recent projects, create/open project, Skill market entry. |
| `ProjectOnboardingPage` | Three-question onboarding and manual-writing escape path. |
| `ProjectOverviewPage` | Five project assets and next actions. |
| `EditorPage` | Chapter writing, generation coordination, candidate handling, save commands. |
| `StoryboardPage` | Ideation and scene/story planning. |
| `GuidedFlowPage` | Guided-flow conversation surface retained as a supporting flow, not the primary information architecture. |
| `CanonPage` | Canon/structured story knowledge surface. |
| `SkillMarketPage` | Browse, inspect, install, and manage Skills. |
| `SettingsPage` | Model/provider endpoint, sync, entitlement, privacy, and application settings. |
| `ImportExportPage` | Import/export surface inside Publish. |
| `VersionHistoryPage` | View historical versions; current end-to-end restore maturity is partial. |
| `RecoveryCenterPage` | Candidate, snapshot, and recovery entry; current production closure is partial. |

## Component Inventory

### Shell and navigation

- `AppScaffold`
- `TopBar`
- `ProjectNavigationBar`
- `ProjectTabs`
- `Sidebar`
- `CommandPalette`
- `ModelStatusBar`

### Creation, onboarding, and assets

- `ProjectBriefSheet`
- `OnboardingGate`
- `OnboardingWizard`
- `OnboardingQuestionCard`
- `ProjectAssetCard`

### Writing and candidate safety

- `WritingToolbar`
- `AiAssistantPanel`
- `CandidatePanel`
- `ModelSelector`
- `SlashCommandMenu`
- `ErrorBanner`

### Review and specialist tools

- `ToolboxPage`
- `AntiHallucinationPanel`
- `ForeshadowingPanel`
- `StrandWeavePanel`
- `StyleProfilePanel`
- `SixDimensionReviewPanel`
- `ChangePropagationPanel`
- `CharacterRelationPanel`
- `ClarityCheckPanel`
- `DeAiFlavorPanel`
- `ReferenceBookPanel`
- `VectorKnowledgePanel`
- `WebSearchPanel`
- `MarketPanel`
- `ModelRouterPanel`
- `WorkflowApprovalPanel`
- `DramaConversionPanel`
- `ParallelWorldPanel`
- `ShortStoryPanel`

The existence of a component does not prove a complete production workflow. Use the maturity matrix below.

## Page-Service Matrix

| Surface | Primary UI symbols | Service/workflow boundary | Design implication |
|---|---|---|---|
| Welcome/create | `WelcomePage`, `ProjectBriefSheet` | `ProjectService`, `ProjectSessionManager`, `ProjectBriefRepository` | Preserve selected genre and task context through creation. |
| Onboarding | `ProjectOnboardingPage`, onboarding components | `ProjectOnboardingWorkflow`, `GuidedFlowEngine`, genre flow Skills | Three visible outputs, resume, failure, and manual-writing path. |
| Overview | `ProjectOverviewPage`, `ProjectAssetCard` | `ProjectAssetRepository` | Five exact assets with state/source/revision/time. |
| Writing | `EditorPage`, `Sidebar`, `WritingToolbar` | `DocumentService`, `ProjectSessionScope`, `EditorAiCoordinator` | Current project/chapter and save state are always visible. |
| Candidate | `CandidatePanel` | `FirstChapterWorkflow`, `NovelApplicationService`, `CandidateService`, `AtomicFileStore`, `VersionHistoryService` | Candidate and manuscript are separate until explicit adoption. |
| AI panel | `AiAssistantPanel`, `ModelSelector`, `ModelStatusBar` | `AIService`, `RuntimeModelSelection`, `SettingsService` | Show actual provider/model/readiness/error, not cosmetic model selection. |
| Ideation | `StoryboardPage` | planning/story graph services | Use current project context and existing structured assets. |
| Review | `ToolboxPage` and specialist panels | corresponding services in `lib/services` | Tool availability and maturity are visible before invocation. |
| Publish | `ImportExportPage` | `ExportService`, `PortableProjectPackageService` | Format and selected chapter scope are explicit; unsupported formats stay disabled. |
| Version history | `VersionHistoryPage` | `VersionHistoryService` | Viewing may be available while full restore remains partial. |
| Recovery | `RecoveryCenterPage` | `RecoveryCenterService`, migration/atomic store services | Preview target, conflict, adopt/save-as/retry. |
| Skill marketplace | `SkillMarketPage` | `SkillMarketplace`, Skill loader/executor/permission/audit services | Installed does not imply the production execution chain is fully connected. |
| Settings/model | `SettingsPage` | `SettingsService`, endpoint configs, runtime model selection | A success state requires a real bounded request. |
| Settings/WebDAV | `SettingsPage` | `SyncManager`, `WebDavService`, manifests/merge | Partial; never show “synced” for an empty or unverified scope. |
| Settings/privacy | `SettingsPage` | privacy preferences/diagnostic services | Do not expose manuscript, prompt, credential, or unrestricted payload data. |

## Maturity Matrix

Vocabulary:

- `REAL`: production UI entry and essential data flow exist.
- `PARTIAL`: page or service exists but end-to-end wiring, persistence, external compatibility, or recovery is incomplete.
- `PLANNED`: specification or test-shaped intent exists without a production entry.
- `DISABLED`: intentionally unavailable for safety or product scope.
- `BLOCKED_EXTERNAL`: requires genuine credentials, licensed data, approval, or human evidence.

| Capability | Maturity | Evidence/limit the UI must express |
|---|---|---|
| Local project and document access | REAL | Local files do not depend on entitlement. |
| Genre/template creation | REAL, evolving | Current implementation work is closing genre preservation and session routing. |
| Project session/recent selection | REAL, evolving | Manager exists; AppScaffold integration is being completed. |
| Five project assets | REAL, evolving | Repository/model exist; not every asset is complete by default. |
| First-chapter candidate safety chain | REAL, critical | Candidate, confirmation, atomic adoption, rejection, state persistence. |
| Windows commands and wide workspace | REAL | Keyboard commands and dock/overlay policy exist. |
| Runtime model display and switching | PARTIAL | UI/config exist; all production consumers and rollback require closure. |
| Custom endpoint connection check | PARTIAL | Never show success until a real bounded request succeeds. |
| Context compiler in production generation | PARTIAL | Compiler exists; production integration and budget correctness are incomplete. |
| Skill marketplace | REAL for browsing/install; PARTIAL for execution | Loader/executor services exist; installed Skill must not be presented as guaranteed runtime injection. |
| Version history restore | PARTIAL | History surface/service exist; actual document replacement and refresh require closure. |
| Recovery center | PARTIAL | Recovery services/UI exist; clean-directory restart and conflict-safe adoption require closure. |
| Portable import/export | PARTIAL | Packaging skeleton exists; selective formats and clean restore are incomplete. |
| Standards-compliant DOCX | PLANNED | Do not show Word as available until conformance passes. |
| OS drag/drop import | PLANNED | Do not draw it as active. |
| WebDAV full-project sync | PARTIAL | Empty-scope sync and third-party compatibility cannot be shown as success. |
| Market intelligence | BLOCKED_EXTERNAL | No licensed, fresh source means no trusted claims or green success. |
| Commercial entitlement/payment | BLOCKED_EXTERNAL | Keep local content accessible; purchase/activation success needs real trust evidence. |
| Privacy/diagnostics production enforcement | PARTIAL | Consent and redaction boundaries must be visible; diagnostics are not a manuscript capture surface. |
| General terminal/system command tool | DISABLED | No approved sandbox; no enable toggle or success flow. |
| Real provider content quality | BLOCKED_EXTERNAL | Credentials and human UAT evidence are required. |
| Windows code signing/SmartScreen reputation | BLOCKED_EXTERNAL | Do not imply a trusted signed release. |

## 24-Board Contract

Every board includes a visible or review-layer annotation for code entry, service boundary, and maturity.

### Group A — Startup and project creation

1. Welcome and recent projects.
2. Genre selection.
3. Prefilled project brief.
4. In-place model setup with return to the original task.
5. Open/import/recent-project failure.

### Group B — Onboarding and overview

6. Three-question onboarding.
7. Asset generation in progress.
8. Interrupted onboarding recovery.
9. Five-asset project overview.
10. Asset failure and awaiting confirmation.

### Group C — Writing safety chain

11. Empty editor and create-first-chapter action.
12. Normal writing workspace.
13. Candidate generation in progress.
14. Candidate preview and diff.
15. Adopt, reject, and cancel decisions.
16. Interrupted generation, stale candidate, or adoption failure recovery.

### Group D — Ideation and review

17. Storyboard ideation.
18. Review toolbox overview.
19. One specialist tool showing input, loading, result, failure, and restricted states.

### Group E — Publish and recovery

20. Import/export with format and chapter scope.
21. Version history.
22. Recovery center and conflict handling.

### Group F — Platform capabilities

23. Skill marketplace and Skill detail.
24. Model, endpoint, WebDAV, privacy, and entitlement settings.

Shared state set:

- default;
- hover/focus/selected/disabled;
- empty;
- loading/progress;
- cancel;
- timeout/retry;
- offline;
- partial completion;
- failure;
- recovery;
- conflict;
- external capability blocked.

## Visual Contract

- Warm paper application background, light warm working surfaces, deep ink text.
- One terracotta accent for primary actions, selection, and active navigation.
- Green only for outcomes verified by the running system.
- Clear sans-serif interface typography; restrained Song-style serif only for manuscript reading and editorial titles.
- 8 px spacing baseline; primary controls approximately 44 px high.
- Information-dense Windows desktop layout without cramped cards.
- Unified line icons; no emoji as primary navigation.
- No decorative gradients, glassmorphism, floating decorative cards, or meaningless animation.
- Motion explains progress, panel transition, state change, or recovery only.
- The editor may use three columns: chapter navigation, manuscript, AI/candidate panel.
- At narrower supported widths, preserve manuscript priority and overlay/collapse secondary panels.
- Copy uses truthful Chinese labels and gives the next action when a capability is unavailable.

## Rejection Conditions

Reject the design before visual review if any condition is true:

- It omits any of the five `ProjectTab` values or replaces them with a new primary navigation.
- It omits any of the five `ProjectAssetType` values.
- It treats candidate generation as direct manuscript mutation.
- It omits explicit adoption/rejection and recovery.
- It contains fewer than 24 numbered boards.
- It lacks code-entry, service-boundary, or maturity annotations.
- It shows WebDAV, provider connection, market data, entitlement, signing, or real-provider quality as verified without evidence.
- It enables a terminal/system-command tool.
- It uses emoji primary navigation, decorative gradients, glassmorphism, or mobile phone frames.
- It designs only ideal states and omits loading, failure, offline, conflict, and recovery.
- It invents a service, page, data model, or production capability not present in this fact pack.

Open Design must first create a separate acknowledgement artifact that restates the application shell, project session, five assets, first-chapter safety chain, maturity vocabulary, 24-board matrix, and rejection conditions. Only an acknowledgement that passes literal and semantic checks may be used to generate the visual suite.
