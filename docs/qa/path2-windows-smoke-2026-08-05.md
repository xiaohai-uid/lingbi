# Path 2 Windows Real-Machine Smoke — 2026-08-05

## Build under test

- Branch: `agent/architecture-foundation`
- HEAD: `1dcc701` plus uncommitted #52 market/ranking slice
- Binary: `build/windows/x64/runner/Release/lingbi.exe`
- Window: 1440x900, title `LingBi - AI Writing Studio`, process responding
- PID observed: 46968

## Status matrix

| # | Smoke path | Status | Evidence |
|---|------------|--------|----------|
| 1 | First launch / welcome / onboarding entry | REAL | Release exe launched; OCR confirms hero text, `新建自由项目`, genre cards, model selector |
| 2 | Model configuration / free mode | REAL | Keyboard opened model panel; OCR confirms `体验模型`, `sensenova`, `openai`, `gpt4c` |
| 3 | Project creation | REAL | `integration_test/path2_windows_smoke_test.dart` passed on Windows: welcome -> genre -> brief -> title -> submit -> editor |
| 4 | Canon initialization | REAL | Integration test verified genre template directory `小说资料` exists after project creation |
| 5 | First chapter candidate generation | REAL | Integration test verified first chapter file is created and selected through `openFirstChapter()` |
| 6 | Adopt first chapter | REAL | Integration test created a candidate, adopted it to the chapter file, and verified `CandidateStatus.adopted` |
| 7 | Close/reopen and persistence | REAL | Integration test closed all scopes, reopened the project directory, and preserved the same project id |
| 8 | Recovery center and restore | REAL | Integration test soft-deleted a chapter, scanned trash, and restored it to a target path |
| 9 | Import/export, portable package, DOCX | REAL | Integration test exported Markdown/TXT/DOCX and exported + validated a portable package |
| 10 | Settings, skill market, experimental labeling | REAL | Integration test rendered SettingsPage, SkillMarketPage, and ProjectNavigationBar `EXP` labels |

## Automation notes

- Synthetic mouse clicks were ignored by the Flutter window; keyboard navigation worked (`Tab`, `Space`, text input).
- Windows UI Automation exposed only the `FLUTTERVIEW` pane, so direct element invocation was not available.
- luma-mcp vision was reachable but returned GLM 429 on two attempts; OCR (`tesseract chi_sim+eng`) was used as the visual fallback.
- A Windows `integration_test` was added and passed: `flutter test integration_test/path2_windows_smoke_test.dart -d windows`.
- Screenshot evidence is under `C:\Users\a1691\AppData\Local\Temp\lingbi_smoke_*.png`.

## Remaining Path 2 work

All 10 Path 2 items now have Windows evidence. Any future regression should go through `diagnosing-bugs` and a regression test.

External commercial gates remain `BLOCKED_EXTERNAL` and are not part of local usability smoke.
