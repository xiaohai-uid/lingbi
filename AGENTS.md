# LingBi agent operating contract

This repository uses GPT/Codex as the decision/review layer, Qoder Quest for complex execution, Qoder Ultra Review for independent first-pass technical review, and OpenCode for simple or reassigned execution. Chat history is disposable; Git files and command evidence are authoritative.

## Roles

- **GPT/Codex:** plans, classifies, assigns, and makes the final review decision; it does not implement an assigned business-code task.
- **Qoder Quest:** executes `COMPLEX` tasks in a dedicated worktree.
- **Qoder Ultra Review:** runs in a separate ordinary Chat context against a frozen Git range and writes first-pass findings only.
- **OpenCode:** executes `SIMPLE` tasks or a GPT-reassigned released task.
- **User:** state the goal, transfer repository files or patches between tools, and decide major product/architecture choices. The user is not expected to paraphrase code state or manually test the application.

## Assignment, lease, and review rules

- GPT/Codex records `Complexity`, `Assigned executor`, and `First-pass review` in every task SPEC before execution. `SIMPLE` tasks are assigned to `OPENCODE`; `COMPLEX` tasks are assigned to `QODER` and require first-pass review. A released Qoder task may move to OpenCode only after GPT/Codex explicitly reassigns it in the SPEC.
- An executor may edit only when it is both the assigned and active executor and `Lease status` is `HELD`. Each task has one execution lease; a second executor must stop when the lease is held.
- Before changing window, model, or executor, the active executor updates STATE and EVIDENCE, records a safe checkpoint when possible, and releases the lease. The replacement reads repository artifacts and Git evidence, then acquires a new lease.
- Qoder Ultra Review is separate from Qoder Quest execution: it uses an ordinary Chat context and is strictly read-only for frozen business code and the target Git range. Its only permitted write is the current task's `QODER_REVIEW.md`, which normalizes `/ultra-review` output; it must not modify implementation files, `SPEC.md`, `STATE.md`, `EVIDENCE.md`, `REVIEW_BUNDLE.md`, or the frozen checkpoint commit.
- Completion evidence includes executor provenance, baseline and checkpoint SHAs, diff scope, commands with timestamps and exit codes, and the linked Qoder review when first-pass review is required. Qoder review statuses are `PASS`, `PASS_WITH_FINDINGS`, and `FAIL`; they do not replace command evidence.
- Only GPT/Codex may record the final `APPROVE`, `FIX_REQUIRED`, or `ESCALATE` decision in `REVIEW.md`. Qoder review cannot authorize integration.
- Executors and reviewers must not merge or push. Merge or push requires explicit user authorization after the final GPT/Codex decision.

## Required startup sequence

Before changing anything, OpenCode must read, in order:

1. this `AGENTS.md`;
2. `CONTEXT.md` and relevant files under `docs/adr/`;
3. `.ai/PROJECT_MAP.md`;
4. the active task's `SPEC.md`;
5. the active task's `STATE.md` and `EVIDENCE.md`;
6. the last five Git commits, current `git status`, and the diff from the task baseline commit.

If the active task directory is unknown, stop and ask for its path. Do not infer an active task from old chat.

## Execution rules

- Do not expand task scope, change product goals, replace key modules, or weaken acceptance criteria without GPT approval.
- Record the baseline before editing. Distinguish pre-existing failures and user-owned changes from task changes.
- Keep unrelated dirty files untouched. Never clean, reset, discard, or commit them.
- Run the exact acceptance commands in `SPEC.md`. Record command, timestamp, exit code, executor provenance, and key output in `EVIDENCE.md`.
- A prose summary is not acceptance evidence. Completion claims require a Git commit SHA, diff scope, commands, exit codes, and key output.
- If reliable machine evidence is unavailable, set the task state to `IMPLEMENTED_BUT_UNVERIFIED`; never call it complete.
- For the same blocker, make at most two autonomous evidence-based attempts. If both fail, stop and create/update `BLOCKER.md`.
- Before changing model, compacting context, or closing a window, update `STATE.md`, record a checkpoint commit when safe, and make the next action executable by a fresh window.
- Never expose credentials in repository files, task evidence, logs, commits, or review bundles.
- The execution shell is Windows PowerShell. Use PowerShell-native commands such as `Get-ChildItem`, `Get-Content`, and `Select-Object`; do not use POSIX-only forms such as `head` or `ls -la`.

## Task and review lifecycle

Use `.ai/tasks/<TASK-ID>/`. Start from `.ai/templates/`. During execution maintain `STATE.md` and `EVIDENCE.md`; on completion create `REVIEW_BUNDLE.md`; for required first-pass review create `QODER_REVIEW.md`; on a GPT/Codex final decision create `REVIEW.md`; on escalation create `BLOCKER.md`.

Only a GPT/Codex `APPROVE` review with verifiable evidence permits integration. Do not merge or push unless the user explicitly authorizes it.

## Repository conventions

- GitHub Issues are the external issue tracker. Use labels `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix` when issue operations are explicitly requested.
- Use the domain vocabulary in `CONTEXT.md`; surface conflicts with ADRs before implementation.
- Current P0 is local-first Flutter Desktop. Do not make Docker, microservices, networking, or GitNexus a prerequisite unless the active spec explicitly says so.
