# Review Bundle

## 1. Task and review range

- Task: `<TASK-ID>`
- Baseline commit: `<full SHA>`
- Current commit: `<full SHA>`
- Branch: `<branch>`
- Assigned executor: `<OPENCODE | QODER>`
- Executor worktree: `<absolute path>`
- Checkpoint commit: `<full SHA>`
- First-pass review: `<REQUIRED | NOT_REQUIRED>`
- Qoder review artifact: `<QODER_REVIEW.md path or N/A>`
- Frozen Qoder review range: `<exact range or N/A>`
- Qoder review status: `<PASS | PASS_WITH_FINDINGS | FAIL | NOT_REQUIRED>`
- Requested outcome: `<APPROVE or identify required fixes>`

## 2. Actual changes

| File | Why it changed | SPEC/acceptance item |
| --- | --- | --- |
| `<path>` | `<reason>` | `<section or criterion>` |

## 3. Acceptance matrix

| Acceptance item | Status | Evidence |
| --- | --- | --- |
| `<criterion>` | `<PASS | FAIL | UNVERIFIED>` | `EVIDENCE.md#<anchor>` |

Any `UNVERIFIED` item forces task status `IMPLEMENTED_BUT_UNVERIFIED`, unless the SPEC explicitly permits it for review.

## 4. Commands and results

| Command | Exit code | Key result | Evidence |
| --- | ---: | --- | --- |
| `<exact command>` | `<integer>` | `<decisive output>` | `EVIDENCE.md#<anchor>` |

## 5. Git evidence

- `git status --short --branch`: `<clean or exact paths>`
- `git diff --stat <baseline>..<current>`: `<exact summary>`
- Added: `<paths or none>`
- Modified: `<paths or none>`
- Deleted: `<paths or none>`
- Full patch: `<attached REVIEW.patch, commit SHA, or exact diff command>`

## 6. Design deviations

- Deviated from SPEC: `<no | yes>`
- If yes: `<change, evidence, reason, impact, and approving decision>`

Unapproved deviations cannot be accepted.

## 7. Unresolved risks and known failures

- `<risk/failure, evidence, and whether pre-existing>`

## 8. Highest-value review targets

1. `<file/range or contract and why>`
2. `<file/range or contract and why>`
3. `<file/range or contract and why>`

## 9. Executor declaration

- [ ] Executor provenance and checkpoint SHA are recorded above.
- [ ] Required Qoder first-pass review is linked and its status is recorded.
- [ ] Every completion claim is supported by code, Git, command, or log evidence.
- [ ] No unverified function is described as complete.
- [ ] No unrelated change is included.
- [ ] No credential is present.
- [ ] `STATE.md` reflects the handoff state.
