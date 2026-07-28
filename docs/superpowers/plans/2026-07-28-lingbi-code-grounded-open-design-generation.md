# LingBi Code-Grounded Open Design Generation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate and validate a complete 24-board LingBi Windows UI suite in Open Design using a source-backed code fact pack instead of an isolated product prompt.

**Architecture:** The repository specification is the source of truth. A compact fact pack extracts the application shell, project lifecycle, asset state machine, first-chapter safety workflow, UI inventory, service boundaries, and maturity matrix. Open Design must first produce a fact-acknowledgement artifact; only after that artifact passes contract checks may it generate the visual suite. Final acceptance combines structural file inspection, browser review, and a traceability audit.

**Tech Stack:** Flutter/Dart source as evidence; Markdown specifications; Open Design MCP; self-contained HTML/CSS/JavaScript artifacts; PowerShell and `rg` for read-only validation.

## Global Constraints

- Windows Desktop only; target widths are 1280, 1440, 1600, and 1920 px.
- Project navigation is exactly `overview / writing / ideation / review / publish`.
- Project assets are exactly protagonist, world rules, outline, opening scene, and first chapter.
- AI output follows candidate -> explicit author confirmation -> atomic adoption -> version/recovery.
- Every board carries code entry, service boundary, and maturity evidence.
- Use `REAL / PARTIAL / PLANNED / DISABLED / BLOCKED_EXTERNAL` without simulating success.
- Warm paper, deep ink, one terracotta accent; green means verified success only.
- No mobile layouts, emoji primary navigation, decorative gradients, glassmorphism, or invented services.
- Preserve all unrelated dirty worktree changes.

---

## File Map

- Create `docs/design/lingbi-ui-code-facts.md`: the bounded evidence pack passed to Open Design.
- Create Open Design project `LingBi Windows Code-Grounded Full Suite`: contains acknowledgement and full-suite artifacts.
- Create Open Design artifact `00-code-fact-acknowledgement.html`: proves the design agent understood the code before designing.
- Create Open Design artifact `lingbi-windows-full-suite.html`: interactive index and 24 reviewable boards.
- Create `docs/design/lingbi-ui-traceability.md`: final board-to-code and board-to-state audit.
- Modify Obsidian project `LingBi`: durable result, project id, artifact name, commit and next action only.

### Task 1: Build the bounded code fact pack

**Files:**
- Create: `docs/design/lingbi-ui-code-facts.md`
- Read: `lib/ui_v2/components/app_scaffold.dart`
- Read: `lib/ui_v2/controllers/project_session_manager.dart`
- Read: `lib/domain/project/project_asset.dart`
- Read: `lib/workflows/first_chapter/first_chapter_workflow.dart`
- Read: `lib/ui_v2/pages/*.dart`
- Read: `lib/ui_v2/components/*.dart`
- Read: `docs/qa/commercial-release-report.md`
- Read: `docs/superpowers/specs/2026-07-28-lingbi-code-grounded-full-suite-ui-design.md`

**Interfaces:**
- Consumes: repository source and the approved UI specification.
- Produces: a Markdown fact pack with headings `Product`, `Application Shell`, `Project Session`, `Project Assets`, `First Chapter Safety Chain`, `Page Inventory`, `Component Inventory`, `Page-Service Matrix`, `Maturity Matrix`, `24-Board Contract`, `Visual Contract`, and `Rejection Conditions`.

- [ ] **Step 1: Extract the source inventory**

Run:

```powershell
rg --files lib/ui_v2/pages lib/ui_v2/components lib/ui_v2/controllers lib/domain/project lib/workflows/first_chapter lib/services | Sort-Object
```

Expected: current Dart files are listed; no generated or mobile platform files are included.

- [ ] **Step 2: Write the fact pack**

Create the exact sections listed in `Produces`. Every page-service row must name existing Dart symbols. The maturity matrix must distinguish production entry, service skeleton, test-only evidence, disabled capability, and external evidence dependency.

- [ ] **Step 3: Verify symbols and prohibited placeholders**

Run:

```powershell
rg -n "TBD|TODO|待定|invented|假定" docs/design/lingbi-ui-code-facts.md
rg -n "ProjectTab|ProjectAsset|FirstChapterWorkflow|ProjectSessionManager" docs/design/lingbi-ui-code-facts.md
```

Expected: the first command returns no matches; the second returns all four code contracts.

- [ ] **Step 4: Commit only the fact pack**

```powershell
git add -f -- docs/design/lingbi-ui-code-facts.md
git diff --cached --check
git commit -m "docs: add LingBi UI code fact pack"
```

Expected: one documentation file is committed; unrelated dirty files remain unstaged.

### Task 2: Make Open Design acknowledge the code facts

**Files:**
- Consume: `docs/design/lingbi-ui-code-facts.md`
- Create in Open Design: `00-code-fact-acknowledgement.html`

**Interfaces:**
- Consumes: the complete fact pack as `start_run.prompt` content in project `LingBi Windows Code-Grounded Full Suite`.
- Produces: a read-only acknowledgement artifact containing the five `ProjectTab` values, five `ProjectAsset` types, the first-chapter stages, the 24-board matrix, and a list of prohibited false claims.

- [ ] **Step 1: Create or resolve the Open Design project**

Use `mcp__open_design__list_projects`. If `LingBi Windows Code-Grounded Full Suite` does not exist, use `mcp__open_design__create_project` with that exact name. Record the returned project id; never rely on expiring active context.

- [ ] **Step 2: Start the acknowledgement run**

Use `mcp__open_design__start_run` with:

- `project`: the explicit project id;
- `agent`: `codex`;
- `model`: `default`;
- `prompt`: the complete fact pack followed by an instruction to create only `00-code-fact-acknowledgement.html`, not the visual suite.

The prompt must require a visible failure banner if any fact is unclear. Do not pass a plugin or skill because `list_skills` is empty and a design-system plugin is unnecessary for factual acknowledgement.

- [ ] **Step 3: Wait for the run without replacing it**

Poll `mcp__open_design__get_run` every 30–60 seconds. Continue while status is `running`. Do not call `write_file` as a shortcut and do not cancel unless the user asks.

- [ ] **Step 4: Validate the acknowledgement artifact**

Fetch it with `mcp__open_design__get_artifact(entry: "00-code-fact-acknowledgement.html")`. Confirm literal presence of:

```text
overview writing ideation review publish
protagonist worldRules outline openingScene firstChapter
candidate confirmation atomic adoption recovery
REAL PARTIAL PLANNED DISABLED BLOCKED_EXTERNAL
24
```

Expected: all contracts are present and no alternate primary navigation is proposed. If any check fails, start a correction run in the same project with the missing facts; do not advance.

### Task 3: Generate the complete visual suite

**Files:**
- Consume: approved acknowledgement artifact and `docs/design/lingbi-ui-code-facts.md`
- Create in Open Design: `lingbi-windows-full-suite.html`

**Interfaces:**
- Consumes: the acknowledged code facts and board contract.
- Produces: one self-contained interactive HTML artifact with a board index, 24 full-size Windows boards, state switching, code annotations, and width previews.

- [ ] **Step 1: Start the visual generation run**

Use `mcp__open_design__start_run` with the explicit project id, `agent: "codex"`, `model: "default"`, and a prompt that begins with the approved acknowledgement. Require `lingbi-windows-full-suite.html` as the only new entry artifact.

The prompt must require:

```text
6 groups / 24 numbered boards
code entry + service boundary + maturity annotation on every board
1280 / 1440 / 1600 / 1920 preview controls
default / loading / error / offline / recovery / conflict states
candidate and manuscript visually separated
Warm Editorial Windows tokens
no alternate navigation or false success
```

Do not apply `design-system-application` because its purple dashboard aesthetic conflicts with the approved contract. Do not apply `design-system-editorial` blindly because the product is an application, not a magazine. Express the approved hybrid directly in the prompt.

- [ ] **Step 2: Wait for terminal status**

Poll `mcp__open_design__get_run` every 30–60 seconds and report continued progress to the user. Accept only `succeeded`; preserve failed-run diagnostics for the correction prompt.

- [ ] **Step 3: Fetch the complete bundle once**

Use `mcp__open_design__get_artifact(entry: "lingbi-windows-full-suite.html")`. Do not fetch sibling files one by one.

- [ ] **Step 4: Run structural contract checks**

Confirm the artifact contains 24 unique numbered board identifiers and all required group labels, code annotations, maturity terms, widths, candidate actions, offline state, recovery state, and conflict state.

Expected rejection conditions:

```text
fewer than 24 boards
project library / outline / asset library used as replacement primary navigation
emoji primary navigation
green success on unverified sync or provider state
candidate content shown as already committed manuscript
mobile phone frame
```

### Task 4: Review visually and correct by evidence

**Files:**
- Consume: Open Design `lingbi-windows-full-suite.html`
- Create: `docs/design/lingbi-ui-traceability.md`

**Interfaces:**
- Consumes: generated visual suite and repository source.
- Produces: a 24-row audit with `Board`, `User Goal`, `Code Entry`, `Service Boundary`, `Maturity`, `Required States`, `Result`, and `Correction`.

- [ ] **Step 1: Open the Open Design preview**

Use the successful run's `previewUrl`. Review the board index first, then all 24 boards at 1440 px, followed by representative checks at 1280 and 1920 px.

- [ ] **Step 2: Audit the golden path**

Walk this exact path:

```text
玄幻题材卡 -> prefilled ProjectBriefSheet -> model readiness -> three-question onboarding -> five-asset overview -> create/select first chapter -> generate candidate -> diff -> adopt or reject -> version/recovery
```

Expected: no sidebar detour, no overview/onboarding loop, no direct overwrite of manuscript text.

- [ ] **Step 3: Write the traceability audit**

Create 24 rows. `Result` is only `PASS` or `REVISE`. A `REVISE` row must state the exact wrong copy, missing state, wrong code boundary, or width defect.

- [ ] **Step 4: Commission focused correction runs**

For each correction batch, call `mcp__open_design__start_run` in the same project with the exact failing board ids and audit evidence. Require modification of `lingbi-windows-full-suite.html`; do not regenerate accepted boards without cause.

- [ ] **Step 5: Repeat validation until every row passes**

Fetch the full artifact after each successful correction run and update the audit. Stop only when all 24 rows are `PASS` and no global rejection condition remains.

### Task 5: Persist and hand off the approved design

**Files:**
- Commit: `docs/design/lingbi-ui-traceability.md`
- Modify through Obsidian operator: project `LingBi`

**Interfaces:**
- Consumes: the accepted Open Design project and traceability audit.
- Produces: durable project id, artifact entry, preview link, audit commit, and next implementation action.

- [ ] **Step 1: Verify repository cleanliness by scope**

Run:

```powershell
git diff --check -- docs/design/lingbi-ui-traceability.md
git status --short
```

Expected: the audit is the only new design file; pre-existing dirty source/test files remain unrelated and unstaged.

- [ ] **Step 2: Commit the audit**

```powershell
git add -f -- docs/design/lingbi-ui-traceability.md
git commit -m "docs: audit LingBi full UI suite"
```

- [ ] **Step 3: Update Obsidian safely**

Run `obsidian-agent.mjs status`, use the current LingBi `mtime_ms`, dry-run the project update, write the Open Design project id, artifact entry, audit commit and next action, then run `validate`. Report pre-existing Vault validation issues without editing unrelated notes.

- [ ] **Step 4: Present the approved suite**

Return the Open Design preview link, repository fact-pack link, traceability-audit link, commits, and any remaining external capability caveats. Do not claim Flutter implementation has begun.
