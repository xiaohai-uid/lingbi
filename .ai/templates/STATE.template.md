# Current task state

## Identity

- Task: `<TASK-ID>`
- Status: `<READY | IN_PROGRESS | BLOCKED | IMPLEMENTED_BUT_UNVERIFIED | READY_FOR_REVIEW | APPROVED | REJECTED>`
- Updated: `<YYYY-MM-DD HH:MM timezone>`
- Active branch: `<branch>`
- Baseline commit: `<full SHA>`
- Current commit: `<full SHA or UNCOMMITTED>`

## Execution lease

- Active executor: `<NONE | OPENCODE | QODER>`
- Lease status: `<RELEASED | HELD>`
- Lease acquired at: `<timestamp or N/A>`
- Worktree path: `<absolute path>`
- Checkpoint commit: `<full SHA or UNCOMMITTED>`

## Completed and verified

- `<result>` — evidence: `EVIDENCE.md#<anchor>`

List only results supported by repository or command evidence.

## Current code state

- Modified modules: `<paths or none>`
- Working behavior: `<evidenced behavior or none>`
- Failing behavior: `<failure and evidence or none>`
- Unrelated dirty files preserved: `<paths or none>`

## Commands already run

| Command | Exit code | Classification | Evidence |
| --- | ---: | --- | --- |
| `<exact command>` | `<integer>` | `<PASS | TASK_FAILURE | PRE_EXISTING_FAILURE | UNVERIFIED>` | `EVIDENCE.md#<anchor>` |

## Current blocker or risk

- `<none, or concise blocker/risk with evidence>`

## Single next action

1. `<one executable action with exact path/command and expected result>`

## Do not repeat

- `<completed investigation, failed approach, or command that must not be rerun without new evidence>`

## Handoff readiness checklist

- [ ] A new window can locate the active SPEC and baseline commit.
- [ ] All completed claims link to evidence.
- [ ] The next action is singular and executable.
- [ ] Failed attempts and their outcomes are recorded.
- [ ] No required context exists only in chat.
