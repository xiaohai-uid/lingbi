# Task evidence

Evidence is append-only. Record concise, decision-relevant output; keep large raw logs in a named repository artifact and link it here. Never record credentials.

## Executor and review provenance

- Assigned executor: `<OPENCODE | QODER>`
- Active executor: `<OPENCODE | QODER>`
- Execution worktree: `<absolute path>`
- Baseline commit: `<full SHA>`
- Checkpoint commit: `<full SHA or UNCOMMITTED>`
- Qoder first-pass review: `<REQUIRED | NOT_REQUIRED>`
- Qoder review artifact: `<QODER_REVIEW.md path or N/A>`
- Frozen Qoder review range: `<exact range or N/A>`

## Baseline

- Captured: `<YYYY-MM-DD HH:MM timezone>`
- Repository: `<absolute path>`
- Branch: `<branch>`
- Baseline commit: `<full SHA>`
- Initial `git status --short --branch`:

```text
<exact output>
```

## Command record: `<short name>`

- Timestamp: `<YYYY-MM-DD HH:MM timezone>`
- Purpose: `<acceptance item or diagnosis>`
- Executor: `<OPENCODE | QODER | GPT/CODEX>`
- Working directory: `<absolute or repository-relative path>`
- Command:

```powershell
<exact command>
```

- Exit code: `<integer>`
- Classification: `<PASS | TASK_FAILURE | PRE_EXISTING_FAILURE | UNVERIFIED>`
- Key output:

```text
<exact decisive lines; do not replace with “passed”>
```

- Interpretation: `<what this proves and what it does not prove>`

Copy this command-record section for every required command and every failed autonomous attempt.

## Evidence integrity checklist

- [ ] Commands are exact and reproducible.
- [ ] Exit codes are recorded.
- [ ] Output is actual, not predicted or paraphrased.
- [ ] Pre-existing failures are distinguished from task failures.
- [ ] No claim relies only on chat history.
- [ ] No credentials or private values are present.
