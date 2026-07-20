# Review Bundle

## 1. Task and review range

- Task: `TASK-20260720-V1-WORKFLOW-DRILL`
- Baseline commit: `46c6d91ebe4f1d150dd7412ec4e453d88640de10`
- Current/reviewed commit: `54e59b9c269ce7d18a488e0d16d64f5aaac90e83`
- Branch: `chore/ai-team-v1-mvr`
- Requested outcome: approve the minimum V1 workflow infrastructure and fresh-window drill.

## 2. Actual changes

| File | Why it changed | Acceptance item |
| --- | --- | --- |
| `AGENTS.md` | Fixed roles, startup order, scope, evidence, retry, handoff, PowerShell and integration rules | Mandatory rules are machine-detectable |
| `.ai/PROJECT_MAP.md` | Maps current architecture, authority, toolchain, validation and takeover boundaries | Actual environment and commands are discoverable |
| `.ai/tasks/README.md` | Defines task lifecycle, status values and fixed new-window instruction | Fresh-window handoff is repeatable |
| `.ai/templates/*.template.md` | Provides six substantive task/evidence/review/blocker contracts | All requested usable templates exist |
| Drill `SPEC.md`, `STATE.md`, `EVIDENCE.md` | Captures a real low-risk workflow execution and baseline | Actual command evidence is preserved |

## 3. Acceptance matrix

| Acceptance item | Status | Evidence |
| --- | --- | --- |
| Requested files and usable templates exist | `PASS` | `EVIDENCE.md#workflow-structure-validation` |
| Mandatory V1 rules are machine-detectable | `PASS` | `EVIDENCE.md#workflow-structure-validation` |
| Flutter/Dart/OpenCode baselines include exit codes | `PASS` | `EVIDENCE.md#toolchain` through `EVIDENCE.md#windows-build` |
| Fresh OpenCode recovers task without old chat | `PASS` | `EVIDENCE.md#fresh-opencode-takeover` |
| No business or unrelated files changed | `PASS` | Commit diff and Git evidence below |
| Review bundle contains Git and command evidence | `PASS` | This file and `EVIDENCE.md` |

## 4. Commands and results

| Command | Exit code | Key result | Evidence |
| --- | ---: | --- | --- |
| `flutter pub get` | `0` | dependency resolution completed; symlink warning | `EVIDENCE.md#dependency-resolution` |
| `dart format --output=none --set-exit-if-changed lib test` | `1` | 49 pre-existing formatting differences | `EVIDENCE.md#format-baseline` |
| `flutter analyze` | `1` | 2065 pre-existing full-repo issues | `EVIDENCE.md#static-analysis` |
| `flutter analyze lib test` | `1` | 253 pre-existing app/test issues | `EVIDENCE.md#static-analysis` |
| `flutter test` | `0` | 88 tests passed | `EVIDENCE.md#flutter-tests` |
| `flutter build windows --debug` | `1` | blocked before compilation by symlink support | `EVIDENCE.md#windows-build` |
| workflow structure validation attempt 1 | `1` | validator boolean defect identified | `EVIDENCE.md#workflow-structure-validation` |
| workflow structure validation attempt 2 | `0` | 12 files and seven rules passed | `EVIDENCE.md#workflow-structure-validation` |
| fresh `opencode run` with exact startup list | `0` | takeover possible without old chat | `EVIDENCE.md#fresh-opencode-takeover` |

## 5. Git evidence

- `git status --short --branch` after checkpoint: clean; branch ahead by one commit.
- `git diff --stat 46c6d91..54e59b9`: `12 files changed, 935 insertions(+)`.
- Added: `AGENTS.md` and eleven `.ai/` workflow/drill files.
- Modified business files: none.
- Deleted files: none.
- Full review patch: `git diff 46c6d91ebe4f1d150dd7412ec4e453d88640de10..54e59b9c269ce7d18a488e0d16d64f5aaac90e83`.

## 6. Design deviations

- Deviated from approved V1: no.
- GitNexus remains outside the minimum workflow as required.
- Existing analyzer/format/build failures were documented, not repaired or hidden.

## 7. Unresolved risks and known failures

- Windows debug build cannot run until Developer Mode/symlink support is enabled; this is an environment blocker.
- App-focused analysis has 253 existing issues, including unresolved identity subsystem imports and dependencies.
- Format baseline reports 49 nonconforming files.
- The original dirty worktree still contains uncommitted context/ADR/agent documents; it is intentionally untouched.

## 8. Highest-value review targets

1. `AGENTS.md`: confirm role, scope, retry and evidence enforcement is unambiguous.
2. `.ai/tasks/README.md`: confirm a model/window switch requires no GPT-generated replacement prompt.
3. `.ai/templates/EVIDENCE.template.md` and `REVIEW_BUNDLE.template.md`: confirm prose-only completion cannot pass review.

## 9. Executor declaration

- [x] Every completion claim is supported by code, Git, command, or process evidence.
- [x] No unverified function is described as complete.
- [x] No unrelated change is included.
- [x] No credential is present.
- [x] `STATE.md` reflects the handoff state.
