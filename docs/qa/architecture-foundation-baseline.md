# Architecture Foundation Baseline

> Recorded: 2026-08-02
> Branch: `agent/architecture-foundation` (forked from `agent/openwrite-impl`)
> Base commit: `413bea6`

## Environment

- OS: Windows 25H2
- Flutter: stable channel (Dart >=3.6.0 <4.0.0)
- Shell: PowerShell 7

## Baseline Commands and Results

### 1. flutter pub get --enforce-lockfile

```
Got dependencies!
1 package is discontinued.
27 packages have newer versions incompatible with dependency constraints.
```

**Result:** PASS (exit code 0)

### 2. flutter analyze lib/

```
No issues found! (ran in 55.5s)
```

**Result:** PASS — zero errors, zero warnings, zero infos

### 3. flutter test --exclude-tags network

```
00:29 +1084: All tests passed!
```

**Result:** PASS — 1084 tests, 0 failures, 0 skips

## Pre-existing Failures

None. The baseline is fully green.

## GitNexus Index Status

- Repository: `lingbi` at `C:\Users\a1691\Documents\Qoder\lingbi-impl`
- Indexed commit: `413bea6ed0884066953107ff123d62c3fd80dc44`
- Staleness: none (index matches HEAD)
- Stats: 401 files, 8287 symbols, 18983 relationships, 468 execution flows

## Notes

- No uncommitted business-code changes existed at baseline capture time.
- The plan document (`docs/superpowers/plans/2026-08-02-lingbi-local-pilot-to-server.md`) is untracked/ignored per repository `.gitignore` rules for `/docs/*`. It is preserved but not committed unless the owner explicitly requests versioning.
- No dependencies were added or changed.
