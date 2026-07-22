# LingBi project map

## Repository identity

- Canonical repository: `C:\codex\lingbi-review`
- V1 workflow implementation worktree: `C:\codex\worktrees\lingbi-review-v1-mvr`
- Product: LingBi, a local-first Flutter Desktop writing application for novel authors.
- Current delivery direction: portable Markdown projects, safe local editing, Canon content, and AI suggestions that require explicit author approval.

## Authoritative project documents

Read these before planning or implementation:

1. `CONTEXT.md` — domain vocabulary and product boundaries.
2. `docs/adr/` — accepted architecture decisions present on the current branch.
3. `docs/superpowers/plans/2026-07-19-lingbi-p0-master.md` — P0 ticket order and acceptance boundaries when available in the working copy.
4. `SPEC.md` — legacy/root product specification; resolve conflicts in favor of newer accepted ADRs and the P0 master plan.
5. Active `.ai/tasks/<TASK-ID>/SPEC.md` — the only contract for the current task.

## Code map

| Path | Responsibility | Default task status |
| --- | --- | --- |
| `lib/main.dart` | Flutter application entry and degraded local-mode startup | Active P0 |
| `lib/core/` | AI providers, models, filesystem, persistence and infrastructure boundaries | Active P0; inspect only relevant modules |
| `lib/services/` | Product use cases and application services | Active P0 |
| `lib/ui/` | Flutter pages, layouts, widgets and themes | Active P0 |
| `test/` | Flutter unit and widget tests, including local-mode coverage | Primary automated gate |
| `windows/` | Windows runner and generated Flutter plugin integration | Build infrastructure |
| `launcher/` | Legacy/secondary launcher code | Out of scope unless named in SPEC |
| `lingbi_server/` | Server and microservice experiments | Not a P0 prerequisite |
| `services/` | Additional service experiments | Not a P0 prerequisite |
| `openspec/` | Older/future specifications | Reference only; not current task authority |

## Toolchain observed on 2026-07-20

- Flutter `3.44.6` (stable)
- Dart `3.12.2`
- OpenCode `1.18.3`
- Rust/Cargo: unavailable on PATH
- OpenCode MCP: no servers configured; GitNexus is not a V1 prerequisite
- Shell: Windows PowerShell; use PowerShell-native inspection commands rather than POSIX-only aliases/options

## Repeatable validation entry points

Run only commands relevant to the active task and copy the real results into `EVIDENCE.md`.

| Capability | Command | Current audited baseline |
| --- | --- | --- |
| Dependency resolution | `flutter pub get` | Completes, but warns that Windows plugin builds require Developer Mode/symlink support |
| Format check | `dart format --output=none --set-exit-if-changed lib test` | Fails: 49 of 62 checked files would change |
| Full repository analysis | `flutter analyze` | Fails: 2065 issues, including legacy service dependencies/missing files |
| App-focused analysis | `flutter analyze lib test` | Must be run and recorded per task; do not assume it passes |
| Unit/widget tests | `flutter test` | Passes: 88 tests on audited baseline `46c6d91` |
| Windows debug build | `flutter build windows --debug` | Must be run and recorded per task; symlink support may block it |
| Interactive startup | `flutter run -d windows` | Manual/interactive; never claim it ran unless actual process evidence is recorded |

The full analyzer and format baseline are already failing. A task may still be reviewable when its specified targeted gates pass, but it must not describe these baseline failures as caused or fixed by the task.

## Three-role workflow contract

- GPT/Codex classifies every task as `SIMPLE` or `COMPLEX`, assigns `OPENCODE` or `QODER`, and owns the final review decision.
- Qoder Quest executes `COMPLEX` tasks only in a dedicated worktree. Its checkpoint is reviewed by Qoder Ultra Review in a separate ordinary Chat context against a frozen Git range.
- OpenCode executes `SIMPLE` tasks and may take over a released Qoder task only after an explicit GPT/Codex reassignment.
- Every task has a single held execution lease. Executors preserve user-owned dirty changes, record evidence and checkpoint SHAs, and release the lease before handoff.
- Qoder first-pass review is advisory evidence (`PASS`, `PASS_WITH_FINDINGS`, or `FAIL`); only GPT/Codex may approve. No executor or reviewer may merge or push without explicit user authorization.

## Executor startup and takeover contract

A fresh executor window receives only the repository/worktree path and active task path. It must obtain all other context from `AGENTS.md`, this map, task files, Git history/status, and the baseline diff. It must verify that it is the assigned executor and that the execution lease is released before acquiring it. If any required file is missing or contradictory, it stops and writes `BLOCKER.md` instead of reconstructing intent from memory.
