# Task workspace protocol

Each active unit of work lives at `.ai/tasks/<TASK-ID>/` and is committed with the code it governs. Chat messages may point to the directory but never replace its files.

## Create a task

1. Copy the six files from `.ai/templates/` into a new task directory.
2. Rename them to `SPEC.md`, `STATE.md`, `EVIDENCE.md`, `REVIEW_BUNDLE.md`, `REVIEW.md`, and `BLOCKER.md` as needed.
3. GPT completes `SPEC.md`; OpenCode must not rewrite goal, scope, non-goals, architecture constraints, or acceptance criteria.
4. OpenCode records baseline branch, commit and dirty state in `STATE.md` and `EVIDENCE.md` before editing.
5. Delete neither historical evidence nor failed attempts. Add a new dated record.

## Status values

- `READY`: contract is complete and execution may start.
- `IN_PROGRESS`: implementation or verification is active.
- `BLOCKED`: execution stopped and `BLOCKER.md` explains the decision needed.
- `IMPLEMENTED_BUT_UNVERIFIED`: code exists but required machine evidence is missing or failing.
- `READY_FOR_REVIEW`: implementation and required evidence are ready for GPT.
- `APPROVED`: GPT recorded `APPROVE` in `REVIEW.md`.
- `REJECTED`: GPT found the task incompatible with the contract or evidence.

Only GPT review may move `READY_FOR_REVIEW` to `APPROVED`.

## Switch window or free model

Before switching, OpenCode must:

1. update `STATE.md` with the current branch and commit;
2. list completed work, current failures, evidence locations and the single next action;
3. record commands and exit codes in `EVIDENCE.md`;
4. create a focused checkpoint commit when the worktree is safe to commit;
5. list actions that must not be repeated.

Start the new window with this fixed instruction:

> Take over the task at `.ai/tasks/<TASK-ID>/`. Read `AGENTS.md`, `CONTEXT.md`, relevant ADRs, `.ai/PROJECT_MAP.md`, then the task's `SPEC.md`, `STATE.md`, and `EVIDENCE.md`. Inspect the last five commits, current Git status, and the diff from the task baseline. Do not re-plan completed work. Continue only from `STATE.md`'s single next action and obey scope, acceptance, and escalation rules.

## Completion and review

OpenCode may set `READY_FOR_REVIEW` only after producing:

- a focused Git commit SHA;
- the baseline-to-current diff scope;
- changed-file list and rationale;
- every required command with exit code and key output;
- explicit `PASS`, `FAIL`, or `UNVERIFIED` for each acceptance item;
- known risks and deviations;
- `REVIEW_BUNDLE.md`.

Pure prose, confidence statements, or “looks good” are not evidence.
