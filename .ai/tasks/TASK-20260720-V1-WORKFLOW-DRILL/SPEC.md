# TASK-20260720-V1-WORKFLOW-DRILL: Fresh-window workflow takeover drill

## Contract metadata

- Author: GPT 5.6 decision layer
- Status: `READY`
- Created: `2026-07-20`
- Baseline branch: `chore/ai-team-v1-mvr`
- Baseline commit: `46c6d91ebe4f1d150dd7412ec4e453d88640de10`
- Risk: `LOW`
- Minimum verification level: `L0`

## 1. Goal

Prove that the repository-local AI workflow is complete enough for a brand-new OpenCode process to identify the active task, current state, evidence, and next action without prior chat. The drill must not modify LingBi business code.

## 2. Background and design intent

OpenCode free-model or window changes currently lose context, while GPT receives only prose summaries. The approved V1 replaces chat memory with committed task contracts, state, Git evidence, and review bundles.

## 3. In scope

- Validate the existence and substantive content of `AGENTS.md`, `.ai/PROJECT_MAP.md`, all six templates, and `.ai/tasks/README.md`.
- Record the actual Flutter/Dart/OpenCode baseline and verification results.
- Run a new `opencode run` process in read-only mode and require it to report this task's identity, status, baseline and single next action from repository files.
- Produce a complete `REVIEW_BUNDLE.md` and GPT `REVIEW.md`.

## 4. Non-goals

- Do not modify `lib/`, `test/`, `windows/`, services, dependencies, or product behavior.
- Do not repair existing formatting, analyzer, build, or business-code failures.
- Do not install or configure GitNexus/MCP.
- Do not merge, push, or alter the user's original dirty worktree.

## 5. Relevant modules and evidence sources

| Path or command | Why it matters |
| --- | --- |
| `AGENTS.md` | Fixed execution-model rules and role boundaries |
| `.ai/PROJECT_MAP.md` | Repository context and actual validation entry points |
| `.ai/templates/` | Reusable contracts for future tasks |
| `.ai/tasks/README.md` | New-window handoff protocol |
| `git status`, `git diff` | Prove scope isolation |
| `opencode run` | Fresh-process takeover proof |

## 6. Architecture and safety constraints

- Git owns live task state and evidence; Obsidian owns only durable project context/indexes.
- A prose-only OpenCode response is not review evidence unless it reports facts read from the committed repository files and is captured as command output.
- Preserve the original worktree's `CONTEXT.md`, `AGENTS.md`, ADR, and agent-doc changes exactly.
- Never read or record credentials.

## 7. Execution stages

### Stage A: Repository workflow validation

- Implementation result: required rules and templates exist and contain the mandatory V1 contracts.
- Required verification: PowerShell required-file and phrase checks recorded in `EVIDENCE.md`.
- Checkpoint condition: no business-code path is modified.

### Stage B: Fresh OpenCode takeover

- Implementation result: a new OpenCode process accurately identifies task state and next action without old conversation context.
- Required verification: `opencode run` output captured in `EVIDENCE.md`.
- Checkpoint condition: OpenCode makes no file changes.

## 8. Acceptance criteria

- [ ] All requested workflow files and usable templates exist.
- [ ] Mandatory scope, handoff, retry, evidence and unverified-state rules are machine-detectable.
- [ ] Actual Flutter/Dart/OpenCode baselines are recorded with exit codes.
- [ ] Fresh OpenCode correctly reports this task, baseline, status and next action from files only.
- [ ] No business-code or unrelated file changes exist.
- [ ] Review bundle contains Git scope and command evidence.

## 9. Required commands

```powershell
git status --short --branch
flutter --version
dart --version
opencode --version
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter analyze lib test
flutter test
flutter build windows --debug
```

The workflow file checks and read-only `opencode run` command are recorded verbatim in `EVIDENCE.md` after execution.

## 10. Escalation conditions

Stop and create `BLOCKER.md` if required files cannot be created without overwriting user work, if OpenCode modifies files during the read-only takeover, or if the same takeover failure remains after two evidence-based attempts.

## 11. Required final outputs

- focused Git commit SHA and branch;
- baseline-to-current diff scope;
- command evidence and known baseline failures;
- `STATE.md`, `EVIDENCE.md`, `REVIEW_BUNDLE.md`, and `REVIEW.md`;
- explicit fresh-window takeover decision.
