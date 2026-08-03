import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/mutation/project_path_guard.dart';

void main() {
  group('normalizeRelativePath rejection', () {
    test('rejects empty path', () {
      expect(ProjectPathGuard.normalizeRelativePath(''), isNull);
    });

    test('rejects NUL segment', () {
      expect(ProjectPathGuard.normalizeRelativePath('a\u0000b'), isNull);
    });

    test('rejects absolute POSIX path', () {
      expect(ProjectPathGuard.normalizeRelativePath('/etc/passwd'), isNull);
    });

    test('rejects absolute Windows path', () {
      expect(ProjectPathGuard.normalizeRelativePath(r'\Windows\evil.dll'),
          isNull);
    });

    test('rejects drive-letter path', () {
      expect(ProjectPathGuard.normalizeRelativePath('C:/Windows/evil.dll'),
          isNull);
      expect(ProjectPathGuard.normalizeRelativePath(r'C:\Windows\evil.dll'),
          isNull);
    });

    test('rejects drive-relative path', () {
      expect(ProjectPathGuard.normalizeRelativePath('C:evil.dll'), isNull);
    });

    test('rejects UNC path', () {
      expect(ProjectPathGuard.normalizeRelativePath(r'\\server\share\f.txt'),
          isNull);
    });

    test('rejects parent traversal segments', () {
      expect(ProjectPathGuard.normalizeRelativePath('../escape.md'), isNull);
      expect(ProjectPathGuard.normalizeRelativePath('a/../b.md'), isNull);
      expect(ProjectPathGuard.normalizeRelativePath(r'a\..\b.md'), isNull);
    });

    test('rejects dot-segment and double separators', () {
      expect(ProjectPathGuard.normalizeRelativePath('a/./b.md'), isNull);
      expect(ProjectPathGuard.normalizeRelativePath('a//b.md'), isNull);
    });

    test('rejects trailing separator (empty final segment)', () {
      expect(ProjectPathGuard.normalizeRelativePath('a/b/'), isNull);
    });
  });

  group('normalizeRelativePath normalization', () {
    test('accepts plain relative path unchanged', () {
      expect(
        ProjectPathGuard.normalizeRelativePath('chapters/ch01.md'),
        'chapters/ch01.md',
      );
    });

    test('normalizes backslash separators to forward slashes', () {
      expect(
        ProjectPathGuard.normalizeRelativePath(r'chapters\ch01.md'),
        'chapters/ch01.md',
      );
    });

    test('accepts nested Chinese directory names', () {
      expect(
        ProjectPathGuard.normalizeRelativePath('章节内容/第一章.md'),
        '章节内容/第一章.md',
      );
    });
  });

  group('escapesRoot', () {
    late Directory tempDir;
    late Directory outside;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('path_guard_test_');
      outside = Directory.systemTemp.createTempSync('path_guard_outside_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      if (outside.existsSync()) outside.deleteSync(recursive: true);
    });

    test('returns false for a target inside the root', () async {
      await File('${tempDir.path}/a.txt').writeAsString('x');
      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: tempDir.path,
        normalizedRelativePath: 'a.txt',
      );
      expect(escapes, isFalse);
    });

    test('returns false for a new file under an existing parent', () async {
      await Directory('${tempDir.path}/chapters').create();
      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: tempDir.path,
        normalizedRelativePath: 'chapters/new.md',
      );
      expect(escapes, isFalse);
    });

    test('returns true for an unsafe relative path', () async {
      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: tempDir.path,
        normalizedRelativePath: '../outside.txt',
      );
      expect(escapes, isTrue);
    });

    test('returns true when the root itself is missing (fail closed)', () async {
      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: '${tempDir.path}/does-not-exist',
        normalizedRelativePath: 'a.txt',
      );
      expect(escapes, isTrue);
    });

    test('detects a junction escaping the root', () async {
      final junction = '${tempDir.path}/escape-junction';
      final proc = await Process.run(
        'cmd',
        ['/c', 'mklink', '/J', junction, outside.path],
      );
      if (proc.exitCode != 0) {
        // Host without junction privileges: keep the deterministic checks and
        // mark the host-specific check in the QA report instead of failing.
        // ignore: avoid_print
        print('SKIP junction escape: mklink unavailable (${proc.stderr})');
        return;
      }
      addTearDown(() {
        if (Directory(junction).existsSync()) {
          Directory(junction).deleteSync();
        }
      });

      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: tempDir.path,
        normalizedRelativePath: 'escape-junction/evil.md',
      );
      expect(escapes, isTrue);
    });

    test('does not flag a plain subdirectory junction inside the root',
        () async {
      final insideJunction = '${tempDir.path}/inner-link';
      final inner = Directory('${tempDir.path}/inner-real')..createSync();
      final proc = await Process.run(
        'cmd',
        ['/c', 'mklink', '/J', insideJunction, inner.path],
      );
      if (proc.exitCode != 0) {
        // ignore: avoid_print
        print('SKIP junction-in-root: mklink unavailable (${proc.stderr})');
        return;
      }
      addTearDown(() {
        if (Directory(insideJunction).existsSync()) {
          Directory(insideJunction).deleteSync();
        }
      });

      final escapes = await ProjectPathGuard.escapesRoot(
        rootPath: tempDir.path,
        normalizedRelativePath: 'inner-link/file.md',
      );
      expect(escapes, isFalse);
    });
  });
}
