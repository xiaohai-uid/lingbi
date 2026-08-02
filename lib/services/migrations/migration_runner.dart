/// Migration runner with rollback, downgrade protection, and
/// interrupted-update recovery.
library;

import 'dart:convert';
import 'dart:io';

/// Result of a migration attempt.
class MigrationResult {
  const MigrationResult({
    required this.migrated,
    this.fromVersion,
    this.toVersion,
    this.error,
  });

  final bool migrated;
  final int? fromVersion;
  final int? toVersion;
  final String? error;
}

class MigrationRunner {
  MigrationRunner({required this.storageDir});

  final String storageDir;
  static const currentSchemaVersion = 2;

  final Set<String> _failureInjections = {};

  /// Inject a failure for testing rollback.
  void injectFailure(String projectId) => _failureInjections.add(projectId);

  String _projectFile(String projectId) =>
      '$storageDir/$projectId/.lingbi/project.json';

  Future<MigrationResult> migrateProject(String projectId) async {
    final file = File(_projectFile(projectId));
    if (!await file.exists()) {
      return const MigrationResult(migrated: false, error: 'Project not found');
    }

    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final version = data['schema_version'] as int? ?? 1;

    // Downgrade protection
    if (version > currentSchemaVersion) {
      return MigrationResult(
        migrated: false,
        fromVersion: version,
        error:
            'Project uses schema version $version which is newer than '
            'supported version $currentSchemaVersion. Please update the app.',
      );
    }

    // Already current
    if (version == currentSchemaVersion) {
      return MigrationResult(migrated: false, fromVersion: version);
    }

    // Create backup before migration
    final bakFile = File('${file.path}.bak');
    await file.copy(bakFile.path);

    try {
      // Check for injected failure
      if (_failureInjections.contains(projectId)) {
        throw StateError('Injected migration failure for testing');
      }

      // Apply migration v1 -> v2
      data['schema_version'] = currentSchemaVersion;
      data['migrated_at'] = DateTime.now().toUtc().toIso8601String();

      // Atomic write
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(jsonEncode(data), flush: true);
      await tmpFile.rename(file.path);

      // Clean up backup on success
      if (await bakFile.exists()) await bakFile.delete();

      return MigrationResult(
        migrated: true,
        fromVersion: version,
        toVersion: currentSchemaVersion,
      );
    } catch (e) {
      // Rollback: restore from backup
      if (await bakFile.exists()) {
        await bakFile.copy(file.path);
        await bakFile.delete();
      }
      return MigrationResult(
        migrated: false,
        fromVersion: version,
        error: 'Migration failed and was rolled back: $e',
      );
    }
  }

  /// Recover from an interrupted migration (backup exists without completion).
  Future<bool> recoverInterrupted(String projectId) async {
    final file = File(_projectFile(projectId));
    final bakFile = File('${file.path}.bak');

    if (!await bakFile.exists()) return false;

    // Restore from backup and clean up
    await bakFile.copy(file.path);
    await bakFile.delete();
    return true;
  }
}
