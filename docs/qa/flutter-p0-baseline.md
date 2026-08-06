# LingBi Flutter P0 Stabilization Baseline

日期：2026-08-06

## Repository state

- Repository: `xiaohai-uid/lingbi`
- Branch: `stabilize/flutter-p0`
- Baseline HEAD: `3876d03795a661278f238e8136304d3ca8863466`
- Baseline commit: `chore(release): publish LingBi 1.2.0 formal release metadata (#114)`

## Toolchain

- Flutter: `3.44.6` stable
- Dart: `3.12.2`
- Windows build target: PASS (`flutter build windows --release`)

## Test baseline

```text
flutter test --exclude-tags network --concurrency=1
1515 passed
0 failed
```

Known failures before the test run:

```text
NONE
```

Note: the first full run reported three `release_metadata_contract_test.dart`
failures because a WSL-created worktree wrote a Unix `.git` path that Windows
Git could not resolve. The worktree Git path was corrected locally, the failing
file reran `7/7` passing, and the full suite reran with `1515/1515` passing.
This is a local worktree tooling issue, not a source defect.

## Task A audit against the LingBi Next plan

### Task 0.2 - General system commands

FAIL. `AgentToolRegistry.specs` still exposes `system_command`; production code
still contains command execution paths for `cmd`, PowerShell, Python, Node,
Dart, and Flutter through whitelist/blacklist handling.

Required work:

- Remove `system_command` from `AgentToolRegistry.specs`.
- Remove the production execution path and the whitelist/blacklist helpers.
- Add a contract test that `specs` contains `file_read`, `file_write`,
  `list_dir`, and does not contain `system_command`.

### Task 0.3 - Existing project directory must not be destroyed

FAIL. `ProjectService.createPortableProject` calls
`Directory(directoryPath).create(recursive: true)` and then deletes
`project_meta/` and `.lingbi/` when the requested path already exists.

Required work:

- If the requested project directory already exists, fail with a typed
  `PROJECT_PATH_EXISTS` result.
- Do not delete `.lingbi/`, `project_meta/`, `chapters/`, or `*.md`.
- Add a regression test with a sentinel manuscript and byte comparison.

### Task 0.4 - Duplicate document must not overwrite

FAIL. `DocumentService.createDocument` sanitizes the title and writes the
target `.md` file unconditionally, so creating the same title twice overwrites
the first file.

Required work:

- Before creating a physical document, if the target exists, fail with
  `DOCUMENT_ALREADY_EXISTS`.
- Add tests for same-title creation and same-filename import.
- Assert original bytes remain unchanged.

### Task 0.5 - Ordinary project creation must bind the first chapter

FAIL. `AppScaffold._createProject` calls `ProjectService.createPortableProject`
directly. `ProjectSessionManager.createProject` exists but is not used by the
production UI and does not automatically call `openFirstChapter`.

Required work:

- Route production create/open through `ProjectSessionManager`.
- `createProject` must create and select the first chapter.
- The editor must receive a non-null document after project creation.
- Reuse `ProjectSessionManager`; do not add a third workflow.

### Task 0.6 - Provider failures must not become candidates

FAIL. `FreeProvider` yields human-readable error strings for non-200
responses, and `NovelApplicationService.generateCandidate` creates a candidate
before streaming and saves it even if the stream contains an error string.
There is no typed provider error boundary in the current release main.

Required work:

- Provider failures must surface as typed errors.
- Generation must fail without creating a candidate for 401, 429, timeout,
  500, and empty stream.
- The manuscript file must remain unchanged.

## Gate after fixes

```text
flutter analyze lib/
flutter test --exclude-tags network --concurrency=1
flutter build windows --release
```

Every gate must pass before the stabilization branch is considered complete.
