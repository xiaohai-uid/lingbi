# Windows Install / Upgrade Matrix

| Scenario | Expected | Status |
|----------|----------|--------|
| Clean install (no prior data) | App launches, welcome page shown | PASS |
| Upgrade from v1 schema | Migration runs, backup created, data preserved | PASS (tested) |
| Upgrade from current schema | No migration, app launches | PASS (tested) |
| Downgrade attempt (newer schema) | Refused with clear error | PASS (tested) |
| Interrupted migration | Backup restored on next launch | PASS (tested) |
| Uninstall with data preserved | User data in AppData remains | MANUAL |
| Rollback to previous version | Previous binary runs, data compatible | MANUAL |
| Code-signed installer | SmartScreen passes | BLOCKED_EXTERNAL |

## Code Signing Status

BLOCKED_EXTERNAL: No EV/OV code-signing certificate is configured.
The packaging script (`tool/windows/package_release.ps1`) produces
checksums but cannot sign without a genuine certificate.
