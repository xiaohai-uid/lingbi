# Blocker request

## Identity

- Task: `<TASK-ID>`
- Status: `BLOCKED`
- Branch: `<branch>`
- Baseline commit: `<full SHA>`
- Current commit: `<full SHA or UNCOMMITTED>`
- Raised: `<YYYY-MM-DD HH:MM timezone>`

## Blocked objective

`<SPEC section and exact result that cannot currently be completed>`

## Observed conflict or failure

- Expected: `<expected condition>`
- Actual: `<actual condition>`
- Evidence: `EVIDENCE.md#<anchor>`
- Scope/risk impact: `<why execution must stop>`

## Autonomous attempts

### Attempt 1

- Hypothesis: `<evidence-based hypothesis>`
- Action/command: `<exact action>`
- Exit code/result: `<integer or exact result>`
- Evidence: `EVIDENCE.md#<anchor>`

### Attempt 2

- New evidence and different hypothesis: `<what changed>`
- Action/command: `<exact action>`
- Exit code/result: `<integer or exact result>`
- Evidence: `EVIDENCE.md#<anchor>`

No third autonomous attempt is permitted for the same blocker.

## Decision required

State one focused question that GPT or the user must decide. List only genuinely compatible options and their impact.

## Safe state and resume point

- Preserved files/data: `<what is safe>`
- Uncommitted changes: `<paths or none>`
- Last safe commit: `<full SHA>`
- After decision, run: `<single exact next action>`

## Actions explicitly not taken

- No scope expansion.
- No acceptance-threshold reduction.
- No destructive cleanup, reset, migration, merge, push, or credential access.
