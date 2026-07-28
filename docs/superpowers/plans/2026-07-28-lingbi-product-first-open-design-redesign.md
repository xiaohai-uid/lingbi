# LingBi Product-First Open Design Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a modern, product-first LingBi Windows UI in the existing Open Design project while preserving the current 24-state artifact as a separate internal review surface.

**Architecture:** Open Design remains the sole design generator and owns the visual direction. The existing `lingbi-windows-full-suite.html` remains the code-grounded review artifact; a new `lingbi-windows-product.html` becomes the user-facing product artifact, supported by a short `visual-direction.md` rationale. Browser and literal structural checks validate that review tooling never leaks into the product artifact and that product truth remains intact.

**Tech Stack:** Open Design MCP, HTML/CSS/JavaScript artifacts, Codex in-app Browser, Flutter repository documentation, Obsidian project record.

## Global Constraints

- Work in Open Design project `lingbi-windows-code-grounded-full-suite`; do not create a replacement project.
- Open Design chooses the visual language without a prescribed style, palette, typeface, radius, shadow, density, or component aesthetic.
- The product artifact must not show the board index, board numbers, code annotations, preview-width controls, or previous/next review controls.
- Preserve the real areas `overview / writing / ideation / review / publish`.
- Preserve the assets `protagonist / worldRules / outline / openingScene / firstChapter`.
- Preserve candidate generation -> explicit confirmation -> atomic adoption -> recovery.
- Do not promote planned, partial, disabled, or externally blocked capabilities to fully working features.
- Keep telemetry off by default and preserve the local-first Windows-desktop context.
- Keep all 24 code-grounded states accessible in the separate review artifact.
- Do not modify Flutter source, business logic, services, or tests.

---

### Task 1: Freeze the current review baseline and commission the redesign

**Files:**
- Read: Open Design `lingbi-windows-full-suite.html`
- Read: `docs/design/lingbi-ui-code-facts.md`
- Read: `docs/design/lingbi-ui-traceability-audit.md`
- Create through Open Design: `lingbi-windows-product.html`
- Create through Open Design: `visual-direction.md`
- Preserve: Open Design `lingbi-windows-full-suite.html`

**Interfaces:**
- Consumes: existing 24-board review artifact and repository fact/audit documents.
- Produces: a product-only HTML entry and a written declaration of the visual direction selected by Open Design.

- [ ] **Step 1: Verify the exact Open Design project and baseline files**

Call `get_project(project: "lingbi-windows-code-grounded-full-suite")` and `list_files(project: "lingbi-windows-code-grounded-full-suite")`.

Expected: project name is `LingBi Windows Code-Grounded Full Suite`; `lingbi-windows-full-suite.html` and `00-code-fact-acknowledgement.html` exist.

- [ ] **Step 2: Pull the current review artifact as generation context**

Call `get_artifact(project: "lingbi-windows-code-grounded-full-suite", entry: "lingbi-windows-full-suite.html", include: "all")` once.

Expected: the bundle contains the six groups, 24 boards, product truth annotations, and current review shell.

- [ ] **Step 3: Commission Open Design without prescribing a visual style**

Start one Open Design run in the existing project. The prompt must state:

```text
Study the current lingbi-windows-full-suite.html and the supplied code-grounded fact pack before designing. Preserve that file as the internal 24-state review surface.

Create a new primary artifact named lingbi-windows-product.html that opens directly into a real, full-width LingBi Windows desktop application. The product artifact must contain no board index, board numbers, code/service/maturity annotations, preview-width controls, or previous/next review controls.

You are the design authority for the visual direction. Choose a modern, distinctive, coherent style that you believe best fits a serious local-first AI writing application. Do not follow a prescribed palette, typography, radius, dashboard convention, or the previous warm-editorial styling merely for continuity. Make a material redesign rather than a cosmetic pass.

Keep the real areas overview, writing, ideation, review, and publish; the five project assets protagonist, worldRules, outline, openingScene, and firstChapter; the candidate-confirmation-atomic-adoption-recovery safety chain; truthful maturity states; local-first Windows context; and telemetry off by default. Do not invent unsupported product capabilities.

Make the product artifact navigable enough to inspect the main workspace and representative startup, onboarding, writing, review, publishing/recovery, marketplace, and settings states. Also create visual-direction.md explaining the style you selected and why it suits LingBi.
```

Do not pass a design-system ID or a style-specific skill. Use an agent returned by `list_agents`; never guess the agent name.

- [ ] **Step 4: Poll without canceling an active generation**

Call `get_run(runId)` every 30–60 seconds until it returns `succeeded`, `failed`, or `canceled`. Report a brief progress update between unchanged running polls.

Expected: `succeeded` with a preview URL or a clear agent message. Do not substitute manual `write_file` edits for a slow run.

- [ ] **Step 5: Verify generated file boundaries**

Call `list_files` again.

Expected: `lingbi-windows-product.html`, `visual-direction.md`, and the unchanged review artifact all exist. If the review artifact was overwritten, commission a corrective run to restore the 24-state review surface before proceeding.

---

### Task 2: Run structural product-truth checks

**Files:**
- Read: Open Design `lingbi-windows-product.html`
- Read: Open Design `lingbi-windows-full-suite.html`
- Read: Open Design `visual-direction.md`

**Interfaces:**
- Consumes: the three Task 1 outputs.
- Produces: a pass/fail checklist that gates visual review.

- [ ] **Step 1: Pull the new product artifact and rationale**

Use `get_artifact` for `lingbi-windows-product.html` and `get_file` for `visual-direction.md`.

Expected: the product artifact is non-empty and the rationale names a coherent chosen direction with concrete hierarchy, typography, color, spacing, and interaction decisions.

- [ ] **Step 2: Verify review tooling is absent from the product artifact**

Run literal checks against the product HTML for these forbidden product-surface strings and selectors:

```text
面板索引
预览宽度
代码入口
服务边界
成熟度
board-link
sidebar-index
```

Expected: zero occurrences in visible product markup and product navigation. Incidental prose inside non-rendered generation metadata is acceptable only if it cannot appear in the rendered product.

- [ ] **Step 3: Verify required product truths remain present**

Check for product-native representations of:

```text
overview / writing / ideation / review / publish
protagonist / worldRules / outline / openingScene / firstChapter
candidate / confirm / adopt / recovery
local-first or equivalent Chinese copy
privacy telemetry default off
```

Expected: each concept is present in UI copy, navigation, state data, or explicit interaction logic. Missing concepts require an Open Design correction run.

- [ ] **Step 4: Re-verify the separate review surface**

Count unique board definitions or sidebar entries in `lingbi-windows-full-suite.html`.

Expected: exactly 24 boards, retaining code-entry, service-boundary, and maturity annotations.

- [ ] **Step 5: Commission corrections through Open Design when checks fail**

Send one correction prompt listing only observed failures and acceptance evidence. Do not prescribe a replacement visual style and do not edit the artifact manually.

Expected: corrected run succeeds, then Steps 1–4 are repeated from fresh output.

---

### Task 3: Visually validate the product artifact

**Files:**
- Inspect: Open Design `lingbi-windows-product.html`
- Preserve: Open Design `lingbi-windows-full-suite.html`

**Interfaces:**
- Consumes: structurally valid product and review artifacts.
- Produces: browser evidence at the supported Windows desktop widths and a short defect list or acceptance statement.

- [ ] **Step 1: Open the product artifact in the in-app Browser**

Navigate directly to:

```text
http://127.0.0.1:7456/api/projects/lingbi-windows-code-grounded-full-suite/raw/lingbi-windows-product.html
```

Expected: the first viewport is full-width LingBi product UI with no outer review shell.

- [ ] **Step 2: Inspect product navigation and representative flows**

Use DOM snapshots before each interaction and click only unique, counted locators. Inspect at least:

```text
startup or recent projects
project overview and five assets
normal writing workspace
candidate preview and adoption decision
review tool
publish or recovery
settings and privacy
```

Expected: navigation feels product-native, states remain understandable, and no review controls appear.

- [ ] **Step 3: Check Windows desktop widths**

Temporarily inspect the product at viewport widths 1280, 1440, 1600, and 1920 with a practical desktop height. Reset the browser viewport after testing.

Expected: no overlapping primary navigation, inaccessible actions, unintended horizontal clipping, or unreadable text at any supported width.

- [ ] **Step 4: Evaluate design quality without imposing a house style**

Record evidence for:

```text
clear hierarchy
coherent visual system
distinctive product identity
appropriate density for long-form writing
consistent states and controls
absence of generic dashboard or component-gallery framing
```

Expected: the result is a material redesign. If it is only a palette/spacing pass or remains visually generic, commission Open Design to critique its own output and perform one focused refinement while retaining its chosen direction.

- [ ] **Step 5: Keep the accepted product tab as the deliverable**

Finalize browser tabs with only the accepted product preview marked `deliverable`.

---

### Task 4: Record traceability and hand off

**Files:**
- Modify: `docs/design/lingbi-ui-traceability-audit.md`
- Modify through Obsidian operator: `10_Projects/LingBi.md`

**Interfaces:**
- Consumes: accepted Open Design product/review artifacts and validation evidence.
- Produces: durable repository and project-workbench records with direct preview links.

- [ ] **Step 1: Update the repository audit**

Append a product-first redesign section containing:

```text
Open Design project ID
product artifact name and preview URL
review artifact name and preview URL
selected visual direction summary
structural check results
desktop-width visual check results
generation and correction run IDs
known unrelated Flutter test baseline limits
```

- [ ] **Step 2: Verify and commit only the audit update**

Run:

```powershell
git diff --check -- docs/design/lingbi-ui-traceability-audit.md
git add -f -- docs/design/lingbi-ui-traceability-audit.md
git diff --cached --name-status
git commit -m "docs: record LingBi product-first redesign"
```

Expected: the staged diff contains only `docs/design/lingbi-ui-traceability-audit.md`.

- [ ] **Step 3: Update the LingBi Obsidian project with optimistic locking**

Run `obsidian-agent.cmd status`, capture the current `LingBi` `mtime_ms`, dry-run `project update`, then write the product and review preview URLs, selected direction, commit SHA, and next implementation action using `--expected-mtime`.

Expected: update succeeds without a lock conflict.

- [ ] **Step 4: Validate the Obsidian write**

Run `obsidian-agent.cmd validate`.

Expected: no new LingBi issue. Report any unrelated pre-existing vault issues separately.

- [ ] **Step 5: Final verification and handoff**

Verify fresh evidence:

```text
product preview opens
product artifact has no visible review shell
review artifact still exposes 24 states
audit commit exists
unrelated worktree changes remain untouched
```

Report the two preview links, selected visual direction, validation result, commit SHA, and any remaining limits without claiming the Flutter test baseline is green.
