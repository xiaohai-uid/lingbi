# AI Team Three-Role Execution and Review Design

## Status and decision

- Status: approved for implementation on 2026-07-22.
- Selected approach: Qoder performs complex implementation and an independent first-pass technical review; GPT/Codex retains final `APPROVE`, `FIX_REQUIRED`, or `ESCALATE` authority; OpenCode handles simple execution and backup takeover.
- This design upgrades the approved V1 Git evidence workflow. It does not change LingBi product behavior or business code.

## Goals

1. Keep GPT/Codex focused on product intent, architecture, task classification, acceptance criteria, and final evidence-based decisions.
2. Use Qoder Quest for difficult implementation in an isolated worktree.
3. Use a separate Qoder Chat `/ultra-review` pass as a technical quality gate over a frozen commit or diff.
4. Use OpenCode free models for simple, bounded tasks and for takeover after a stopped Qoder execution.
5. Make every handoff recoverable from Git files without old chat history.
6. Prevent two executors from modifying the same task worktree concurrently.

## Non-goals

- Qoder does not gain final product or architecture approval authority.
- Qoder's Review panel or Ultra Review output does not replace automated command evidence.
- OpenCode is not prohibited from technically editing many files by global machine configuration; the project contract and assigned task scope constrain it.
- Obsidian does not receive live task state, raw logs, complete diffs, or credentials.
- This change does not merge the workflow branch into a product branch or push it remotely without explicit user authorization.

## Role and authority model

### GPT/Codex: decision and final review layer

GPT/Codex owns goal alignment, architecture, task decomposition, executor assignment, acceptance criteria, and the final review decision. It may inspect the repository and run read-only or verification commands, but it does not implement business changes for an assigned execution task. Its final decision is based on the task SPEC, frozen Git range, machine evidence, Qoder first-pass review when required, and unresolved risks.

### Qoder Quest: complex execution layer

Qoder receives tasks classified `COMPLEX` and assigned `QODER`. It executes in a dedicated Git worktree, treats the repository SPEC as authoritative, and may create an execution sub-plan without redefining product requirements. It maintains `STATE.md` and `EVIDENCE.md`, commits a reviewable checkpoint, and stops before merge or push.

Complex work includes any of the following:

- architecture-affecting or cross-module changes;
- difficult debugging without an existing narrow fix;
- migrations, concurrency, persistence, security, or broad refactors;
- changes whose acceptance requires several independent gates;
- work that GPT/Codex explicitly classifies as high-risk.

### Qoder Ultra Review: independent first-pass technical gate

The first-pass reviewer runs in a separate ordinary Qoder Chat context after the executor has frozen a checkpoint commit. It invokes `/ultra-review` against the explicit commit or baseline-to-checkpoint range and checks completeness, correctness, and impact. It must not modify files during review. Findings are normalized into `QODER_REVIEW.md` with severity, file and line, evidence, recommendation, and disposition.

Qoder's official documentation states that Ultra Review is not available in Quest Agent Mode. Therefore the Quest execution context cannot also serve as the formal Ultra Review context.

### OpenCode: simple execution and backup layer

OpenCode receives tasks classified `SIMPLE` and assigned `OPENCODE`. A simple task has a narrow file list, no architecture change, deterministic acceptance commands, and a low-cost rollback. OpenCode may also take over a stopped Qoder task only after Qoder has updated task state, recorded a safe checkpoint when possible, released the execution lease, and GPT/Codex has reassigned the executor.

Model quota exhaustion is a handoff condition, not permission to silently switch executors or reconstruct intent from chat.

### User

The user states product intent and decides irreversible product choices. The user is not required to restate code state, manually synthesize logs, or manually test code. The user authorizes merge and push separately.

## Task classification and execution lease

Every task SPEC contains:

- `Complexity: SIMPLE | COMPLEX`
- `Assigned executor: OPENCODE | QODER`
- `First-pass review: REQUIRED | NOT_REQUIRED`
- exact baseline commit, allowed paths, forbidden paths, and acceptance commands.

Every task STATE contains:

- `Execution status`
- `Active executor`
- `Lease status: RELEASED | HELD`
- `Lease acquired at`
- `Worktree path`
- `Branch`
- `Baseline commit`
- `Checkpoint commit`
- one executable next action.

An executor may edit only when it is the assigned active executor and the lease is `HELD`. A second executor must stop if the lease is held. Before a window, model, or executor switch, the active executor updates STATE and EVIDENCE, creates a checkpoint when safe, and sets the lease to `RELEASED`.

## End-to-end flows

### Complex task

1. GPT/Codex writes the task SPEC, assigns `QODER`, and requires first-pass review.
2. Qoder Quest opens a dedicated worktree and acquires the task lease.
3. Qoder reads the repository contract, project map, task files, Git status/history, and baseline diff.
4. Qoder implements only the assigned scope, runs acceptance commands, and records command, exit code, and key output.
5. Qoder updates STATE, creates a checkpoint commit, produces REVIEW_BUNDLE, and releases the lease.
6. A separate Qoder Chat runs `/ultra-review` on the frozen range and writes `QODER_REVIEW.md`. The review context is read-only.
7. GPT/Codex reviews the compact bundle, frozen diff, machine evidence, and Qoder findings, then records the final decision in `REVIEW.md`.
8. No merge or push occurs without explicit user authorization.

### Simple task

1. GPT/Codex writes the task SPEC, assigns `OPENCODE`, and marks first-pass review according to risk.
2. OpenCode acquires the lease, implements the bounded change, runs acceptance commands, and records evidence.
3. OpenCode creates a checkpoint and REVIEW_BUNDLE, then releases the lease.
4. GPT/Codex performs final review. Qoder Ultra Review is optional unless the task or observed diff crosses the complex-risk threshold.

### Backup takeover

1. Qoder records the failure, quota stop, or context pressure and updates STATE/EVIDENCE.
2. Qoder releases the lease and records a checkpoint commit when safe.
3. GPT/Codex changes the assigned executor to `OPENCODE` or starts a replacement Qoder context.
4. The new executor reads only repository artifacts and Git evidence, acquires the lease, and continues from the single next action.

## Evidence and review contracts

Completion claims require:

- baseline and checkpoint commit SHAs;
- baseline-to-checkpoint diff scope;
- every required command, exit code, timestamp, and relevant output;
- classification of pre-existing failures and environment blockers;
- explicit unverified behavior;
- a Qoder first-pass review artifact for complex tasks;
- a final GPT/Codex review decision.

Qoder first-pass review statuses are `PASS`, `PASS_WITH_FINDINGS`, or `FAIL`. They are advisory gates for GPT/Codex and cannot authorize integration. Final statuses remain `APPROVE`, `FIX_REQUIRED`, or `ESCALATE`.

Pure prose, the Quest Review panel alone, or an Ultra Review report without command evidence is not acceptance evidence.

## Repository components

The implementation extends the existing V1 files and adds focused adapter files:

- `AGENTS.md`: shared authority, classification, lease, startup, evidence, and final-decision rules.
- `.ai/templates/SPEC.template.md`: executor assignment and review requirements.
- `.ai/templates/STATE.template.md`: execution lease and checkpoint fields.
- `.ai/templates/EVIDENCE.template.md`: executor and review provenance.
- `.ai/templates/REVIEW_BUNDLE.template.md`: Qoder review and final review inputs.
- `.ai/templates/QODER_REVIEW.template.md`: normalized first-pass findings.
- `.ai/templates/REVIEW.template.md`: final GPT/Codex-only decision.
- `.ai/tasks/README.md`: simple, complex, and takeover lifecycles.
- `.ai/scripts/validate-workflow.ps1`: deterministic structural validation.
- `.qoder/skills/complex-task-executor/SKILL.md`: Qoder Quest handoff and evidence procedure.
- `.qoder/skills/first-pass-review/SKILL.md`: separate read-only Ultra Review normalization procedure.
- `.qoder/settings.json` and `.qoder/hooks/`: project guardrails for dangerous Git operations and audit reminders, using PowerShell-native scripts.
- `.opencode/agents/simple-executor.md`: bounded OpenCode executor profile, after validating the installed OpenCode schema.

## Safety model

- Complex Qoder work uses a Qoder Worktree rather than Local execution.
- Only one task execution lease may be held for a task.
- Executors cannot merge or push.
- Destructive Git operations are blocked by deterministic project hooks where the product supports them and prohibited by the shared contract everywhere.
- Existing user-owned dirty changes are never imported into a task worktree unless explicitly listed in the SPEC.
- Qoder MCP auto-run is not expanded to mutating external servers. GitNexus, if configured, is treated as advisory read-only context and its indexed commit must be recorded.
- No credential values are written into repository artifacts, hooks, task evidence, review bundles, or Obsidian.

## Validation design

Implementation is accepted only when all applicable checks have fresh evidence:

1. Static workflow validation confirms required files, required authority clauses, executor fields, lease fields, and review statuses.
2. PowerShell syntax validation passes for every new hook and validator script.
3. A fresh OpenCode process can execute the simple-task startup sequence and report the correct assignment without old chat.
4. Qoder can discover the project skills and open the approved workflow worktree.
5. A Qoder Quest drill produces a checkpoint, evidence, and review bundle without business-code changes.
6. A separate Qoder Chat Ultra Review pass targets the frozen checkpoint and produces normalized findings.
7. GPT/Codex can issue the final decision from repository evidence without requiring a full execution transcript.
8. Git diff confirms that the workflow upgrade changes no business code and includes no unrelated user changes.

If Qoder cannot be driven through an installed CLI or another non-interactive local interface, infrastructure readiness and actual Qoder UI execution are reported separately. The system cannot claim Qoder execution or Ultra Review validation merely because files are configured.

## Acceptance criteria

- The repository contract matches the approved three-role authority model.
- Every task has a deterministic executor assignment and mutual-exclusion lease.
- Complex tasks require a separate Qoder first-pass review artifact.
- Qoder review cannot approve integration or replace command evidence.
- OpenCode can recover a released task without a rewritten GPT prompt.
- The workflow validator and script syntax checks pass.
- At least one fresh handoff drill is recorded for each executable path that can be run non-interactively in the installed environment.
- Any path requiring unavailable UI automation is marked `IMPLEMENTED_BUT_UNVERIFIED`, with an exact remaining validation action.
- No business code, user-owned unrelated changes, credentials, automatic merge, or automatic push is included.

## Sources

- [Qoder Ultra Review](https://docs.qoder.com/zh/user-guide/chat/ultra-review)
- [Qoder Quest Agent Mode](https://docs.qoder.com/zh/user-guide/quest/agent-mode)
- [Qoder Spec-driven Quest](https://docs.qoder.com/zh/user-guide/quest/spec-driven)
- [Qoder Quest Review and Commit](https://docs.qoder.com/zh/user-guide/quest/review-and-commit)
- [Qoder Quest Execution Environments](https://docs.qoder.com/zh/user-guide/quest/execution-environments)
- [Qoder Hooks](https://docs.qoder.com/zh/extensions/hooks)
- Local research record: `C:\codex\docs\research\2026-07-22-qoder-review-and-execution-capabilities.md`
