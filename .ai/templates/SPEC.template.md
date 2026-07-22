# <TASK-ID>: <task name>

## Contract metadata

- Author: GPT 5.6 decision layer
- Status: `READY`
- Created: `<YYYY-MM-DD>`
- Baseline branch: `<branch>`
- Baseline commit: `<full SHA>`
- Risk: `<LOW | MEDIUM | HIGH>`
- Minimum verification level: `<L0 | L1 | L2 | L3>`
- Complexity: `<SIMPLE | COMPLEX>`
- Assigned executor: `<OPENCODE | QODER>`
- First-pass review: `<REQUIRED | NOT_REQUIRED>`

## 1. Goal

Describe the observable result in one to three sentences. State what the user can do or what verifiable condition changes.

## 2. Background and design intent

Explain why the task exists, which current behavior it changes, and which accepted product or architecture decision governs it. Link exact repository documents.

## 3. In scope

- List each required behavior or artifact.
- Name relevant paths when known.
- Keep every item independently verifiable.

## 4. Non-goals

- List adjacent work explicitly excluded from this task.
- Do not refactor unrelated modules “while here.”
- Do not change product goals or accepted architecture.

## 5. Relevant modules and evidence sources

| Path or command | Why it matters |
| --- | --- |
| `<path>` | `<responsibility or evidence>` |

## 6. Architecture and safety constraints

- Preserve: `<existing contract>`.
- Do not break: `<compatibility or data invariant>`.
- New logic must pass through: `<existing boundary>`.
- Do not hard-code: `<environment-specific value>`.
- Do not read, log, store, or commit credentials.
- Preserve unrelated dirty files exactly.

## 7. Execution stages

### Stage A: `<bounded deliverable>`

- Implementation result: `<observable result>`
- Required verification: `<exact command>`
- Checkpoint condition: `<what must be true before commit>`

### Stage B: `<bounded deliverable>`

- Implementation result: `<observable result>`
- Required verification: `<exact command>`
- Checkpoint condition: `<what must be true before commit>`

Remove unused stages; add stages only when each has a distinct reviewable result.

## 8. Acceptance criteria

- [ ] `<functional or artifact criterion>`
- [ ] Relevant format check passes or its pre-existing failure is documented.
- [ ] Relevant static/type analysis passes or its pre-existing failure is documented.
- [ ] Required unit/integration tests pass.
- [ ] Required build or smoke check passes, or status is `IMPLEMENTED_BUT_UNVERIFIED`.
- [ ] No unrelated file changes exist.
- [ ] Documentation/ADR is updated if the implementation changes a durable contract.

## 9. Required commands

Record the real exit code and key output for every command in `EVIDENCE.md`.

```powershell
<exact read-only or verification command>
```

Do not invent commands. If the repository cannot provide a required gate, state that gap here before execution.

## 10. Escalation conditions

Stop and create `BLOCKER.md` when:

- the task requires changing its goal, scope, core architecture, or acceptance threshold;
- repository state contradicts a task assumption;
- required tests cannot run;
- security, data migration, compatibility, or destructive-operation risk appears;
- the same blocker remains after two autonomous evidence-based attempts.

## 11. Required final outputs

- Git commit SHA and branch
- baseline-to-current diff summary and changed-file list
- acceptance matrix with evidence links
- commands, exit codes and key output
- unresolved risks and deviations
- updated `STATE.md` and `EVIDENCE.md`
- `REVIEW_BUNDLE.md`
