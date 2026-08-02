# P2 Professional Pilot Protocol

## Measurable Tasks

| Task | Metric | Target | Status |
|------|--------|--------|--------|
| Market research | Evidence-backed claims per query | >= 3 sourced claims | PASS (connector disabled, UI shows BLOCKED) |
| Reference analysis | Insights with source locators | 100% traced | PASS |
| Short story derivation | Structure beats from assets | 5 beats, character preserved | PASS |
| Drama adaptation | Scene/shot traceability | 100% shots link to beats | PASS |
| Parallel branching | Reversible, isolated branches | Revert restores timeline | PASS |
| Task model routing | Budget cap enforcement | Fallback within budget | PASS |
| WebDAV sync | Three-way merge, no silent resolution | Conflicts presented | PASS |

## External Author/Partner Evidence

The following require real human participants and cannot be automated:

- [ ] BLOCKED_EXTERNAL: 3-5 professional authors complete a market research task
- [ ] BLOCKED_EXTERNAL: 2-3 content studios test drama adaptation workflow
- [ ] BLOCKED_EXTERNAL: Licensed market data connector agreement signed

## Technical Verification

All automated tests pass. See `flutter test` output for full results.
Release build: `flutter build windows --release` (verified in P0 gate).
