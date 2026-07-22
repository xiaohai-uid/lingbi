# Task workspace protocol

Each active unit of work lives at `.ai/tasks/<TASK-ID>/` and is committed with the code it governs. Chat messages may point to the directory but never replace its files.

## Create a task

1. Copy the templates needed for the task into a new task directory. Use `QODER_REVIEW.template.md` when first-pass review is required.
2. Rename them to `SPEC.md`, `STATE.md`, `EVIDENCE.md`, `REVIEW_BUNDLE.md`, `QODER_REVIEW.md`, `REVIEW.md`, and `BLOCKER.md` as needed.
3. GPT/Codex completes `SPEC.md`, classifies the task, assigns the executor, and sets the first-pass review requirement. Executors must not rewrite goal, scope, non-goals, architecture constraints, or acceptance criteria.
4. The assigned executor records baseline branch, commit, dirty state, active executor, and a held execution lease in `STATE.md` and `EVIDENCE.md` before editing.
5. Delete neither historical evidence nor failed attempts. Add a new dated record.

## Status values

- `READY`: contract is complete and execution may start.
- `IN_PROGRESS`: implementation or verification is active.
- `BLOCKED`: execution stopped and `BLOCKER.md` explains the decision needed.
- `IMPLEMENTED_BUT_UNVERIFIED`: code exists but required machine evidence is missing or failing.
- `READY_FOR_REVIEW`: implementation and required evidence are ready for GPT.
- `APPROVED`: GPT recorded `APPROVE` in `REVIEW.md`.
- `REJECTED`: GPT found the task incompatible with the contract or evidence.

Only GPT/Codex final review may move `READY_FOR_REVIEW` to `APPROVED`. Qoder first-pass review is advisory and uses only `PASS`, `PASS_WITH_FINDINGS`, or `FAIL`.

## Execution paths

### Simple task

1. GPT/Codex records `SIMPLE`, assigns `OPENCODE`, and sets first-pass review in SPEC.
2. OpenCode acquires the single execution lease, performs only the issued scope, records evidence, creates a checkpoint, and releases the lease.
3. GPT/Codex makes the final decision in `REVIEW.md`.

### Complex task

1. GPT/Codex records `COMPLEX`, assigns `QODER`, and requires first-pass review in SPEC.
2. Qoder Quest acquires the single execution lease in a dedicated worktree, records evidence, freezes a checkpoint, and releases the lease.
3. A separate ordinary Qoder Chat performs read-only Ultra Review against the frozen range and writes `QODER_REVIEW.md`.
4. GPT/Codex makes the final decision in `REVIEW.md`.

### Released-task takeover

1. The active executor records state and evidence, creates a safe checkpoint when possible, and changes the lease to `RELEASED`.
2. GPT/Codex explicitly changes `Assigned executor` in SPEC.
3. The replacement executor verifies the release, acquires the single lease, and continues from STATE's one executable next action.

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

The assigned executor may set `READY_FOR_REVIEW` only after producing:

- a focused Git commit SHA;
- the baseline-to-current diff scope;
- changed-file list and rationale;
- every required command with exit code and key output;
- explicit `PASS`, `FAIL`, or `UNVERIFIED` for each acceptance item;
- known risks and deviations;
- `REVIEW_BUNDLE.md`.

For a `COMPLEX` task, Qoder Ultra Review must additionally produce a separate `QODER_REVIEW.md` against the frozen Git range before GPT/Codex's final decision. Neither executor nor reviewer may merge or push; user authorization is required separately.

Pure prose, confidence statements, or “looks good” are not evidence.
