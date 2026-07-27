import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/migrations/migration_runner.dart';

void main() {
  late Directory tempDir;
  late MigrationRunner runner;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_migrate_');
    runner = MigrationRunner(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('schema migration', () {
    test('migrates v1 project schema to v2', () async {
      // Write a v1 project file
      final projectDir = Directory('${tempDir.path}/proj-1/.lingbi');
      await projectDir.create(recursive: true);
      await File('${projectDir.path}/project.json').writeAsString(
        '{"title": "Old Project", "genre": "xuanhuan"}',
      );

      final result = await runner.migrateProject('proj-1');

      expect(result.migrated, isTrue);
      expect(result.fromVersion, 1);
      expect(result.toVersion, 2);

      // Verify the migrated file has schema_version
      final migrated = await File('${projectDir.path}/project.json').readAsString();
      expect(migrated, contains('"schema_version":2'));
      expect(migrated, contains('"title":"Old Project"'));
    });

    test('skips migration when already at current version', () async {
      final projectDir = Directory('${tempDir.path}/proj-2/.lingbi');
      await projectDir.create(recursive: true);
      await File('${projectDir.path}/project.json').writeAsString(
        '{"schema_version": 2, "title": "Current"}',
      );

      final result = await runner.migrateProject('proj-2');
      expect(result.migrated, isFalse);
      expect(result.fromVersion, 2);
    });

    test('failed migration rolls back to backup', () async {
      final projectDir = Directory('${tempDir.path}/proj-3/.lingbi');
      await projectDir.create(recursive: true);
      final originalContent = '{"title": "Fragile", "genre": "urban"}';
      await File('${projectDir.path}/project.json').writeAsString(originalContent);

      // Inject a failing migration
      runner.injectFailure('proj-3');
      final result = await runner.migrateProject('proj-3');

      expect(result.migrated, isFalse);
      expect(result.error, isNotNull);

      // Original file is restored
      final restored = await File('${projectDir.path}/project.json').readAsString();
      expect(restored, originalContent);
    });
  });

  group('downgrade protection', () {
    test('refuses to open a project from a newer schema version', () async {
      final projectDir = Directory('${tempDir.path}/proj-future/.lingbi');
      await projectDir.create(recursive: true);
      await File('${projectDir.path}/project.json').writeAsString(
        '{"schema_version": 99, "title": "From The Future"}',
      );

      final result = await runner.migrateProject('proj-future');
      expect(result.migrated, isFalse);
      expect(result.error, contains('newer'));
    });
  });

  group('interrupted update recovery', () {
    test('detects and recovers from interrupted migration', () async {
      final projectDir = Directory('${tempDir.path}/proj-int/.lingbi');
      await projectDir.create(recursive: true);
      await File('${projectDir.path}/project.json').writeAsString(
        '{"title": "Interrupted"}',
      );
      // Simulate interrupted migration: backup exists but no completion marker
      await File('${projectDir.path}/project.json.bak').writeAsString(
        '{"title": "Interrupted"}',
      );

      final recovered = await runner.recoverInterrupted('proj-int');
      expect(recovered, isTrue);

      // Backup is cleaned up after successful recovery
      final bakExists = await File('${projectDir.path}/project.json.bak').exists();
      expect(bakExists, isFalse);
    });
  });
}
