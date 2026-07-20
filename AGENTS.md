# LingBi agent operating contract

This repository uses GPT 5.6 as the decision/review layer and OpenCode as the execution layer. Chat history is disposable; Git files and command evidence are authoritative.

## Roles

- **GPT 5.6:** align the goal, issue `.ai/tasks/<TASK-ID>/SPEC.md`, decide architecture, review the real diff/evidence, and return `APPROVE`, `FIX_REQUIRED`, or `ESCALATE` in `REVIEW.md`.
- **OpenCode:** read the repository contract, implement only the issued scope, run commands, maintain task state, commit checkpoints, and produce review evidence.
- **User:** state the goal, transfer repository files or patches between tools, and decide major product/architecture choices. The user is not expected to paraphrase code state or manually test the application.

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
- Run the exact acceptance commands in `SPEC.md`. Record command, timestamp, exit code, and key output in `EVIDENCE.md`.
- A prose summary is not acceptance evidence. Completion claims require a Git commit SHA, diff scope, commands, exit codes, and key output.
- If reliable machine evidence is unavailable, set the task state to `IMPLEMENTED_BUT_UNVERIFIED`; never call it complete.
- For the same blocker, make at most two autonomous evidence-based attempts. If both fail, stop and create/update `BLOCKER.md`.
- Before changing model, compacting context, or closing a window, update `STATE.md`, record a checkpoint commit when safe, and make the next action executable by a fresh window.
- Never expose credentials in repository files, task evidence, logs, commits, or review bundles.
- The execution shell is Windows PowerShell. Use PowerShell-native commands such as `Get-ChildItem`, `Get-Content`, and `Select-Object`; do not use POSIX-only forms such as `head` or `ls -la`.

## Task and review lifecycle

Use `.ai/tasks/<TASK-ID>/`. Start from `.ai/templates/`. During execution maintain `STATE.md` and `EVIDENCE.md`; on completion create `REVIEW_BUNDLE.md`; on a decision-layer review create `REVIEW.md`; on escalation create `BLOCKER.md`.

Only an `APPROVE` review with verifiable evidence permits integration. Do not merge or push unless the user explicitly authorizes it.

## Repository conventions

- GitHub Issues are the external issue tracker. Use labels `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix` when issue operations are explicitly requested.
- Use the domain vocabulary in `CONTEXT.md`; surface conflicts with ADRs before implementation.
- Current P0 is local-first Flutter Desktop. Do not make Docker, microservices, networking, or GitNexus a prerequisite unless the active spec explicitly says so.
