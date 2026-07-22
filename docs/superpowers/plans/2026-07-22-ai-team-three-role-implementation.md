# AI Team Three-Role Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the V1 Git handoff workflow so GPT/Codex makes final decisions, Qoder executes and first-pass reviews complex work in separate contexts, and OpenCode executes simple work or takes over a released task.

**Architecture:** Git task artifacts remain the single shared state. Every task carries an executor assignment and a mutual-exclusion lease. Qoder Quest runs complex work in a worktree, a separate Qoder Chat normalizes `/ultra-review` findings, and OpenCode uses a bounded project agent for simple or backup execution; GPT/Codex alone writes the final review decision.

**Tech Stack:** Markdown contracts, Git, Windows PowerShell 5.1+, Qoder project Skills/Hooks, OpenCode 1.18 project agents, Flutter/Dart validation commands already documented by the repository.

## Global Constraints

- Do not modify LingBi business code, tests, dependencies, generated files, or product behavior.
- Do not merge or push; commits remain on `chore/ai-team-v1-mvr`.
- Preserve the original dirty worktree at `C:\codex\lingbi-review` exactly.
- Never store credentials, raw secrets, or full local chat transcripts.
- Qoder implementation and Qoder Ultra Review must use separate contexts.
- GPT/Codex retains final `APPROVE`, `FIX_REQUIRED`, or `ESCALATE` authority.
- A task may have only one active executor lease.
- Use PowerShell-native scripts and commands on Windows.

---

### Task 1: Shared three-role contract and deterministic validator

**Files:**
- Modify: `AGENTS.md`
- Modify: `.ai/PROJECT_MAP.md`
- Modify: `.ai/tasks/README.md`
- Modify: `.ai/templates/SPEC.template.md`
- Modify: `.ai/templates/STATE.template.md`
- Modify: `.ai/templates/EVIDENCE.template.md`
- Modify: `.ai/templates/REVIEW_BUNDLE.template.md`
- Modify: `.ai/templates/REVIEW.template.md`
- Create: `.ai/templates/QODER_REVIEW.template.md`
- Create: `.ai/scripts/validate-workflow.ps1`

**Interfaces:**
- Consumes: existing V1 task lifecycle and approved design `docs/superpowers/specs/2026-07-22-ai-team-three-role-design.md`.
- Produces: task fields `Complexity`, `Assigned executor`, `First-pass review`, `Active executor`, and `Lease status`; Qoder review statuses `PASS`, `PASS_WITH_FINDINGS`, `FAIL`; a validator returning exit `0` only when all required contracts exist.

- [ ] **Step 1: Extend the shared role contract**

Update `AGENTS.md` so its role section defines:

```markdown
- **GPT/Codex:** plans, classifies, assigns, and makes the final review decision; it does not implement an assigned business-code task.
- **Qoder Quest:** executes `COMPLEX` tasks in a dedicated worktree.
- **Qoder Ultra Review:** runs in a separate ordinary Chat context against a frozen Git range and writes first-pass findings only.
- **OpenCode:** executes `SIMPLE` tasks or a GPT-reassigned released task.
```

Add deterministic assignment, lease, separate-review, evidence, and no-merge/no-push rules. Replace wording that treats OpenCode as the only executor.

- [ ] **Step 2: Extend task templates**

Add this metadata to `SPEC.template.md`:

```markdown
- Complexity: `<SIMPLE | COMPLEX>`
- Assigned executor: `<OPENCODE | QODER>`
- First-pass review: `<REQUIRED | NOT_REQUIRED>`
```

Add this lease block to `STATE.template.md`:

```markdown
## Execution lease

- Active executor: `<NONE | OPENCODE | QODER>`
- Lease status: `<RELEASED | HELD>`
- Lease acquired at: `<timestamp or N/A>`
- Worktree path: `<absolute path>`
- Checkpoint commit: `<full SHA or UNCOMMITTED>`
```

Extend EVIDENCE and REVIEW_BUNDLE with executor provenance and Qoder review linkage. Restrict `REVIEW.template.md` to GPT/Codex final decisions.

- [ ] **Step 3: Add the Qoder first-pass review template**

Create `.ai/templates/QODER_REVIEW.template.md` with:

```markdown
# Qoder first-pass technical review

- Review context: `SEPARATE_QODER_CHAT`
- Frozen baseline: `<full SHA>`
- Frozen checkpoint: `<full SHA>`
- Ultra Review target: `<exact range or commit>`
- Status: `<PASS | PASS_WITH_FINDINGS | FAIL>`
- Files modified by reviewer: `NONE`

## Findings

| ID | Severity | File:line | Evidence | Required disposition |
| --- | --- | --- | --- | --- |

## Gate statement

This report is advisory technical evidence. It does not authorize merge, push, or final approval.
```

- [ ] **Step 4: Write the structural validator**

Create `.ai/scripts/validate-workflow.ps1` that:

```powershell
param([string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)
$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Require-File([string]$RelativePath) {
  if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $RelativePath) -PathType Leaf)) {
    $failures.Add("Missing file: $RelativePath")
  }
}

function Require-Text([string]$RelativePath, [string]$Pattern) {
  $path = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
      -not (Select-String -LiteralPath $path -Pattern $Pattern -Quiet)) {
    $failures.Add("Missing contract in ${RelativePath}: $Pattern")
  }
}
```

It must check all shared files and clauses, print one line per failure, print a pass summary when empty, and exit `1` on failures or `0` on success.

- [ ] **Step 5: Run the validator and repository diff checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai\scripts\validate-workflow.ps1
git diff --check
git status --short
```

Expected: validator exit `0`; `git diff --check` exit `0`; only Task 1 workflow files are modified.

- [ ] **Step 6: Commit Task 1**

```powershell
git add AGENTS.md .ai
git commit -m "feat(ai): define three-role task authority and leases"
```

### Task 2: Qoder complex executor, review adapters, and Git guard hook

**Files:**
- Create: `.qoder/skills/complex-task-executor/SKILL.md`
- Create: `.qoder/skills/first-pass-review/SKILL.md`
- Create: `.qoder/hooks/guard-git.ps1`
- Create: `.qoder/settings.json`

**Interfaces:**
- Consumes: assignment and lease fields from Task 1.
- Produces: two unique Qoder skills and a deterministic PreToolUse hook that blocks integration/destructive Git commands while allowing evidence and checkpoint commands.

- [ ] **Step 1: Create the complex execution Skill**

Create `.qoder/skills/complex-task-executor/SKILL.md` with YAML frontmatter:

```yaml
---
name: lingbi-complex-task-executor
description: Execute a GPT-assigned COMPLEX LingBi task from .ai/tasks in a Qoder Quest worktree with lease, evidence, checkpoint, and handoff rules.
---
```

The body must require the repository startup order, `Assigned executor: QODER`, a released-to-held lease transition, exact acceptance commands, two-attempt blocker rule, checkpoint commit, REVIEW_BUNDLE, released lease, and no merge/push.

- [ ] **Step 2: Create the separate first-pass review Skill**

Create `.qoder/skills/first-pass-review/SKILL.md` with a unique name and rules to reject use inside Quest Agent Mode, require a frozen range, invoke `/ultra-review` in ordinary Chat, remain read-only, and normalize findings into `QODER_REVIEW.md`.

- [ ] **Step 3: Create the PowerShell Git guard hook**

Create `.qoder/hooks/guard-git.ps1` that reads hook JSON from stdin, extracts `.tool_input.command`, and exits `2` for:

```text
git push
git merge
git rebase
git reset --hard
git clean -f / -fd / -fx
git branch -D
git checkout --
git restore . / --worktree
```

It must exit `0` for read-only Git commands, `git add`, and `git commit`. Invalid hook JSON must fail closed with exit `2` and a concise message that contains no input payload.

- [ ] **Step 4: Register the Qoder project hook**

Create `.qoder/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File .qoder/hooks/guard-git.ps1"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 5: Verify hook syntax and allow/deny behavior**

Run PowerShell parser validation, then pipe synthetic PreToolUse JSON to the hook. Expected: `git status --short` exits `0`; `git push origin main` exits `2`; malformed JSON exits `2`.

- [ ] **Step 6: Commit Task 2**

```powershell
git add .qoder
git commit -m "feat(ai): add Qoder complex execution and review guardrails"
```

### Task 3: OpenCode simple executor and backup profile

**Files:**
- Create: `.opencode/agents/simple-executor.md`

**Interfaces:**
- Consumes: current user-selected OpenCode free model, task assignment, task lease, and V1 startup order.
- Produces: primary agent `simple-executor` with bounded iterations, no subagents/web access, no external-directory access, explicit safe command rules, and destructive Git denial.

- [ ] **Step 1: Create the OpenCode project agent**

Create `.opencode/agents/simple-executor.md` with:

```yaml
---
description: Execute only GPT-assigned SIMPLE tasks or explicitly reassigned backup tasks from .ai/tasks.
mode: primary
steps: 24
permission:
  edit: allow
  task: deny
  skill: deny
  webfetch: deny
  websearch: deny
  external_directory: deny
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
    "git rev-parse*": allow
    "git add*": allow
    "git commit*": allow
    "flutter test*": allow
    "flutter analyze*": allow
    "dart format*": allow
    "git push*": deny
    "git merge*": deny
    "git rebase*": deny
    "git reset*": deny
    "git clean*": deny
---
```

Do not set `model`; the user may switch among configured free models. The prompt must require `Assigned executor: OPENCODE`, lease acquisition, narrow scope, evidence, release, and escalation when a simple task becomes complex.

- [ ] **Step 2: Verify OpenCode discovers and resolves the agent**

Run:

```powershell
opencode debug agent simple-executor
```

Expected: mode `primary`, steps `24`, task/skill/web/external access denied, safe Git/test commands allowed, and push/merge/reset/clean denied.

- [ ] **Step 3: Commit Task 3**

```powershell
git add .opencode
git commit -m "feat(ai): add bounded OpenCode simple executor"
```

### Task 4: Three-role workflow drill artifacts

**Files:**
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/SPEC.md`
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/STATE.md`
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/EVIDENCE.md`
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/REVIEW_BUNDLE.md`
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/QODER_REVIEW.md`
- Create: `.ai/tasks/TASK-20260722-THREE-ROLE-DRILL/REVIEW.md`

**Interfaces:**
- Consumes: all Tasks 1-3 contracts.
- Produces: a repository-only drill proving assignment, lease, handoff, agent discovery, hook behavior, structural validation, and honest classification of unavailable Qoder UI execution.

- [ ] **Step 1: Write a documentation-only drill SPEC**

Set `Complexity: COMPLEX`, `Assigned executor: QODER`, `First-pass review: REQUIRED`, allow only workflow/config/drill paths, prohibit business code, and define exact commands from Tasks 1-3.

- [ ] **Step 2: Capture baseline and acquire/release the simulated lease**

Record the current branch, baseline commit, clean/dirty paths, active executor transitions, and exact timestamps. Simulation may validate state mechanics but must not be described as an actual Qoder Quest run.

- [ ] **Step 3: Record fresh command evidence**

Run and record exit codes/key output for:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai\scripts\validate-workflow.ps1
opencode debug agent simple-executor
git diff --check
git status --short --branch
```

Also record synthetic Qoder hook allow/deny tests and Qoder project/skill discovery evidence available from local files or logs.

- [ ] **Step 4: Classify Qoder UI-dependent gates honestly**

If no installed non-interactive Qoder interface can create a Quest and run `/ultra-review`, set those criteria to `UNVERIFIED`, task state to `IMPLEMENTED_BUT_UNVERIFIED`, and record the exact remaining actions:

```text
Create Qoder Quest in Worktree mode for this task, execute the no-business-code drill, freeze its checkpoint, then run /ultra-review in a separate ordinary Qoder Chat and save normalized output to QODER_REVIEW.md.
```

- [ ] **Step 5: Produce bundle and provisional final review**

Write REVIEW_BUNDLE from actual evidence. GPT/Codex must choose `ESCALATE` or `FIX_REQUIRED` rather than `APPROVE` if required Qoder execution/review evidence remains unavailable.

- [ ] **Step 6: Commit Task 4**

```powershell
git add .ai/tasks/TASK-20260722-THREE-ROLE-DRILL
git commit -m "test(ai): record three-role workflow drill evidence"
```

### Task 5: Fresh takeover tests and final repository verification

**Files:**
- Modify only if evidence requires correction: workflow/config/drill files created above.

**Interfaces:**
- Consumes: committed workflow adapters and drill SPEC.
- Produces: fresh-process OpenCode takeover evidence, Qoder executable-interface discovery result, final Git scope evidence, and a final honest readiness decision.

- [ ] **Step 1: Test a fresh OpenCode simple-task interpretation**

Use a read-only prompt with the project agent:

```powershell
opencode run --agent simple-executor "Read AGENTS.md and .ai/tasks/TASK-20260722-THREE-ROLE-DRILL/SPEC.md and STATE.md. Do not edit or run acceptance commands. Report assigned executor, complexity, lease state, and whether this OpenCode agent may execute it."
```

Expected: it identifies Qoder/COMPLEX and refuses to execute.

- [ ] **Step 2: Probe installed Qoder non-interactive entry points**

Run `--help` only against discovered Qoder executables. Do not install another Qoder product or send a live task unless a documented non-interactive interface exists. Record command and exit code.

- [ ] **Step 3: Re-run all deterministic verification**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .ai\scripts\validate-workflow.ps1
opencode debug agent simple-executor
git diff --check
git status --short --branch
git log -6 --oneline
```

Expected: deterministic checks exit `0`; working tree clean after evidence commit; recent commits correspond only to this workflow upgrade.

- [ ] **Step 4: Review requirement coverage**

Compare the implementation against every acceptance criterion in the approved design. Record any Qoder UI-dependent gap as `IMPLEMENTED_BUT_UNVERIFIED`; do not infer success from Qoder documentation or installed files.

- [ ] **Step 5: Commit evidence corrections if needed**

```powershell
git add AGENTS.md .ai .qoder .opencode
git commit -m "docs(ai): finalize three-role workflow verification"
```

Skip this commit if there is no correction or new evidence to record.

### Task 6: Durable handoff and final report

**Files:**
- Update through controlled Obsidian tool: `10_Projects/LingBi.md`
- Update through controlled Obsidian tool: a durable AI workflow knowledge/decision note.

**Interfaces:**
- Consumes: final branch, commit SHAs, deterministic verification, and drill status.
- Produces: durable project state and a concise report distinguishing configured, verified, and unverified capabilities.

- [ ] **Step 1: Update Obsidian through `obsidian-agent.mjs`**

Record role authority, evidence branch/commits, Qoder Ultra Review separation, current readiness, exact remaining UI validation if any, and one next action. Do not copy logs or diffs.

- [ ] **Step 2: Validate the Vault**

```powershell
node C:\Users\a1691\.codex\skills\obsidian-operator\scripts\obsidian-agent.mjs validate
```

Expected: `valid: true`, no locks or issues.

- [ ] **Step 3: Deliver final report**

Report:

- branch and commit SHAs;
- created/modified files;
- commands with exit codes;
- Qoder and OpenCode drill results;
- whether each role is configured and actually verified;
- remaining blockers;
- whether a fresh Qoder/OpenCode context can take over without old chat.
