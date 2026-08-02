# LingBi UI Traceability Audit

Date: 2026-07-28

Open Design project: `lingbi-windows-code-grounded-full-suite`

Entry artifact: `lingbi-windows-full-suite.html`

Preview: `http://127.0.0.1:7456/api/projects/lingbi-windows-code-grounded-full-suite/raw/lingbi-windows-full-suite.html`

## Acceptance

- User review: accepted as generally correct on 2026-07-28; remaining visual sampling was intentionally skipped at the user's request.
- Code-grounding gate: passed before full-suite generation via `00-code-fact-acknowledgement.html` (`READY`).
- Board count: 24 boards across six groups.
- Required project tabs: `overview / writing / ideation / review / publish`.
- Required project assets: `protagonist / worldRules / outline / openingScene / firstChapter`.
- Required first-chapter safety chain: candidate -> confirmation -> atomic adoption -> recovery.
- Maturity language: `REAL / PARTIAL / PLANNED / DISABLED / BLOCKED_EXTERNAL`, with mixed labels where a board spans multiple boundaries.
- Width controls: 1280, 1440, 1600, 1920.
- Visual constraints: Warm Editorial Windows; no gradients, glass treatment, mobile layout, or emoji-based primary navigation.
- Privacy telemetry: default off and explicitly labeled `默认关闭`.

## Board-to-code traceability

| Board | Product state | Code entry | Service boundary | Maturity |
|---|---|---|---|---|
| A01 | Welcome and recent projects | `WelcomePage`, `AppScaffold` | `ProjectSessionManager`, `ProjectService`, `ProjectBriefRepository` | REAL, evolving |
| A02 | Genre selection | `WelcomePage`, `ProjectBriefSheet` | `ProjectService`, `ProjectSessionManager`, `ProjectBriefRepository` | REAL, evolving |
| A03 | Prefilled project brief | `ProjectBriefSheet`, `WelcomePage` | `ProjectService`, `ProjectSessionManager`, `ProjectBriefRepository` | REAL, evolving |
| A04 | In-place model setup | `SettingsPage`, `ModelStatusBar`, `ModelSelector` | `SettingsService`, `RuntimeModelSelection`, `AIService` | PARTIAL |
| A05 | Open/import/recent-project failure | `WelcomePage`, `ProjectSessionManager` | `ProjectSessionManager`, `ProjectService` | REAL, evolving |
| B06 | Three-question onboarding | `ProjectOnboardingPage`, `OnboardingWizard`, `OnboardingQuestionCard` | `ProjectOnboardingWorkflow`, `GuidedFlowEngine`, genre-flow Skills | REAL, evolving |
| B07 | Asset generation in progress | `ProjectOverviewPage`, `ProjectAssetCard` | `ProjectAssetRepository` | REAL, evolving |
| B08 | Interrupted onboarding recovery | `ProjectOnboardingPage`, `OnboardingGate` | `ProjectOnboardingWorkflow`, `GuidedFlowEngine` | REAL, evolving |
| B09 | Five-asset project overview | `ProjectOverviewPage`, `ProjectAssetCard` | `ProjectAssetRepository` | REAL, evolving |
| B10 | Asset failure and awaiting confirmation | `ProjectAssetCard`, `ErrorBanner` | `ProjectAssetRepository` | REAL, evolving |
| C11 | Empty editor and create-first-chapter action | `EditorPage`, `Sidebar`, `WritingToolbar` | `DocumentService`, `ProjectSessionScope`, `EditorAiCoordinator` | REAL |
| C12 | Normal writing workspace | `EditorPage`, `Sidebar`, `WritingToolbar`, `AiAssistantPanel` | `DocumentService`, `ProjectSessionScope`, `EditorAiCoordinator`, `AIService` | REAL |
| C13 | Candidate generation in progress | `CandidatePanel`, `EditorPage`, `ModelStatusBar` | `FirstChapterWorkflow`, `NovelApplicationService`, `CandidateService` | REAL, critical |
| C14 | Candidate preview and diff | `CandidatePanel`, `EditorPage` | `FirstChapterWorkflow`, `NovelApplicationService`, `CandidateService` | REAL, critical |
| C15 | Adopt, reject, and cancel decisions | `CandidatePanel`, `EditorPage` | `FirstChapterWorkflow`, `NovelApplicationService`, `CandidateService`, `AtomicFileStore` | REAL, critical |
| C16 | Interrupted generation / stale candidate / adoption failure | `CandidatePanel`, `RecoveryCenterPage`, `ErrorBanner` | `FirstChapterWorkflow`, `CandidateService`, `AtomicFileStore`, `VersionHistoryService` | REAL, critical |
| D17 | Storyboard ideation | `StoryboardPage` | planning/story-graph services | REAL |
| D18 | Review toolbox overview | `ToolboxPage` | corresponding services in `lib/services` | PARTIAL |
| D19 | Specialist tool — all states | `ClarityCheckPanel`, `ToolboxPage` | corresponding services | PARTIAL |
| E20 | Import/export with format and chapter scope | `ImportExportPage` | `ExportService`, `PortableProjectPackageService` | PARTIAL |
| E21 | Version history | `VersionHistoryPage` | `VersionHistoryService` | PARTIAL |
| E22 | Recovery center and conflict handling | `RecoveryCenterPage` | `RecoveryCenterService`, migration/atomic-store services | PARTIAL |
| F23 | Skill marketplace and Skill detail | `SkillMarketPage` | `SkillMarketplace`, Skill loader/executor/permission/audit services | REAL browse/install; PARTIAL execution |
| F24 | Model, endpoint, WebDAV, privacy, entitlement | `SettingsPage` | `SettingsService`, `SyncManager`, `WebDavService`, `RuntimeModelSelection` | MIXED |

## Generation and correction evidence

- Code-fact acknowledgement run: `da3df271-8409-47d8-a9d4-8c4922c2c055`.
- Initial full-suite run: `40379c68-2c88-49af-8870-0cea5e71c962`.
- Asset/offline/privacy correction run: `8b05d086-bff1-467b-8dab-55fb2edae72c`.
- Review-shell clipping correction run: `c1ffcbb4-d7a9-4d22-8e27-a0a107fe5713`.
- Structural inspection confirmed 24 unique boards, each carrying a visible code entry, service boundary, and maturity annotation.
- Wide-layout inspection confirmed a 1600 px product frame fits without review-shell clipping in a 1920 px viewport.

## Known repository baseline limits

The UI design artifact does not claim to repair the current Flutter test baseline. The pre-design baseline had three unrelated failures: the onboarding test's `genreId` named-parameter mismatch, a `No element` failure in the Windows golden-path test, and the release-packager metadata contract. The user explicitly approved continuing the design work with those limits recorded.
