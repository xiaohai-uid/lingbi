# Flutter P0 Stabilization Milestone Report

Milestone: 0 - Freeze and protect the Flutter product

Date: 2026-08-06

## Commit SHA

Branch tip: `d9c3d27`

Task commits:

- `8b34661` docs: record Flutter P0 stabilization baseline
- `c942399` fix(security): disable general agent system commands
- `117616d` fix(project): fail closed on existing project directory
- `9efa771` fix(document): prevent duplicate title overwrite
- `0939f52` fix(session): bind first chapter after project creation
- `d9c3d27` fix(ai): prevent provider failures from becoming manuscript candidates

## Files created

- `docs/qa/flutter-p0-baseline.md`
- `docs/qa/flutter-p0-milestone-report-2026-08-06.md`
- `test/p0_golden_path_test.dart`
- `test/project_path_exists_test.dart`
- `test/document_service_duplicate_test.dart`
- `test/ai_error_no_candidate_test.dart`

## Files modified

- `lib/features/writing/services/agent/agent_tool_registry.dart`
- `lib/features/project/data/project_service.dart`
- `lib/services/document_service.dart`
- `lib/shared/interfaces/i_document_service.dart`
- `lib/ui_v2/components/app_scaffold.dart`
- `lib/ui_v2/controllers/project_session_manager.dart`
- `lib/shared/di/service_locator.dart`
- `lib/shared/errors/ai_error.dart`
- `lib/services/ai_service.dart`
- `lib/features/writing/data/pipeline/novel_application_service.dart`
- `lib/workflows/first_chapter/first_chapter_workflow.dart`
- All production AI providers
- Focused regression and integration tests

Deleted:

- `lib/shared/interfaces/process_runner.dart`
- `lib/services/security/local_process_runner.dart`

## Tests run

```text
flutter analyze lib/
No issues found

flutter test --exclude-tags network --concurrency=1
1523 passed
0 failed

flutter build windows --release
PASS

flutter test integration_test/path2_windows_smoke_test.dart -d windows
3 passed
0 failed
```

## Manual verification

- Create project through `ProjectSessionManager`: first chapter is created,
  selected, bound to the AI scope, and persisted across reopen.
- Generate through the real pipeline with a deterministic provider:
  candidate is created, adopted, and the adopted manuscript survives restart.
- Provider 401, 429, timeout, 500, and empty stream all produce a typed
  failure with `candidate_count == 0`.
- Windows release build and Path 2 smoke suite pass.

## Known failures

```text
NONE
```

## Security impact

- General agent `system_command` capability and all production execution paths
  for `cmd`, PowerShell, Python, Node, Dart, and Flutter were removed.
- Existing project directories are no longer deleted or reused during create.
- Duplicate document creation no longer overwrites manuscript bytes.
- Provider failures are typed exceptions and cannot become candidate content.

## Data migration impact

None. No existing project files are migrated or rewritten by this milestone.

## Compatibility impact

- First chapter is created as `chapters/chapter-1.md` with title `第一章`.
- Opening older projects that contain a root-level `chapter-1.md` still
  recognizes that file as the first chapter.
- `FreeProvider` no longer claims availability without a confirmed anonymous
  capability; unconfigured free mode fails with `配置 API Key` instead of
  returning error text as manuscript content.

## Gate

```text
PASS
```
