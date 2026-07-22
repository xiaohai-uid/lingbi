# GPT/Codex final review result: `<APPROVE | FIX_REQUIRED | ESCALATE>`

Only GPT/Codex may complete this template or make the final integration decision. Qoder first-pass review is advisory technical evidence and cannot authorize merge, push, or final approval.

## Review identity

- Task: `<TASK-ID>`
- Reviewer: `GPT/Codex decision layer`
- Reviewed branch: `<branch>`
- Baseline commit: `<full SHA>`
- Reviewed commit: `<full SHA>`
- Reviewed evidence: `SPEC.md`, `STATE.md`, `EVIDENCE.md`, `REVIEW_BUNDLE.md`, and `<diff/patch>`
- Qoder first-pass review: `<QODER_REVIEW.md path or NOT_REQUIRED>`

## Decision

Choose exactly one:

- `APPROVE`: scope matches SPEC and all critical acceptance claims have reliable evidence.
- `FIX_REQUIRED`: bounded corrections can satisfy the existing SPEC.
- `ESCALATE`: requirements, architecture, risk, or repository state needs a user decision.

Decision: `<APPROVE | FIX_REQUIRED | ESCALATE>`

## Findings

### `<F1 or NONE>`

- Problem: `<specific defect or evidence gap>`
- Evidence: `<file, diff, command result, or missing artifact>`
- Impact: `<acceptance/risk impact>`
- Required change: `<bounded result, not implementation guess>`
- Verification command: `<exact command>`
- Priority: `<critical | high | medium | low>`

Repeat for each actionable finding. Remove this example when there are none and write `No actionable findings.`

## Prohibited changes during repair

- `<adjacent scope that must remain untouched>`

## Evidence required on resubmission

- `<command/diff/artifact>`

## Approval statement

Complete only for `APPROVE`:

- Acceptance criteria satisfied: `<yes/no with links>`
- Scope matches SPEC: `<yes/no>`
- High-risk unresolved issue: `<none or describe>`
- Integration authorized by this review: `<yes/no; user authorization may still be required>`
