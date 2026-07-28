import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final repositoryRoot = Directory.current.absolute;

  group('release source contract', () {
    test('every imported production source and release gate is tracked', () {
      final tracked = _gitLines(repositoryRoot, ['ls-files']).toSet();
      final requiredEvidence = {
        'pubspec.lock',
        'docs/qa/p0-windows-release-checklist.md',
        'docs/qa/commercial-release-report.md',
        '.github/workflows/ci.yml',
        'tool/windows/package_release.ps1',
      };

      expect(
        tracked,
        containsAll(requiredEvidence),
        reason:
            'A clean checkout must contain the dependency lock and QA gates.',
      );

      final missingImports = <String>[];
      final directive =
          RegExp(r'''(?:import|export|part)\s+['\"]([^'\"]+)['\"]''');
      for (final sourcePath in tracked.where(
        (path) =>
            path.endsWith('.dart') &&
            (path.startsWith('lib/') || path.startsWith('test/')),
      )) {
        final source = File(p.join(repositoryRoot.path, sourcePath));
        if (!source.existsSync()) continue;
        for (final match in directive.allMatches(source.readAsStringSync())) {
          final imported = match.group(1)!;
          final resolved = _resolveProductionImport(sourcePath, imported);
          if (resolved != null &&
              File(p.join(repositoryRoot.path, resolved)).existsSync() &&
              !tracked.contains(resolved)) {
            missingImports.add('$sourcePath -> $resolved');
          }
        }
      }

      expect(
        missingImports,
        isEmpty,
        reason:
            'Imported production code must not depend on ignored local files.',
      );
    });

    test('release versions and capability statuses use one truthful vocabulary',
        () {
      final appVersion = _yamlVersion(
        File(p.join(repositoryRoot.path, 'pubspec.yaml')).readAsStringSync(),
      );
      final launcherVersion = _yamlVersion(
        File(
          p.join(repositoryRoot.path, 'launcher', 'pubspec.yaml'),
        ).readAsStringSync(),
      ).split('+').first;
      final installer = File(
        p.join(repositoryRoot.path, 'installer', 'lingbi_setup.iss'),
      ).readAsStringSync();
      final installerVersion = RegExp(
        r'#define LingbiVersion "([^"]+)"',
      ).firstMatch(installer)!.group(1);
      final readme = File(
        p.join(repositoryRoot.path, 'README.md'),
      ).readAsStringSync();
      final readmeVersion = RegExp(
        r'Lingbi-Setup-([0-9]+\.[0-9]+\.[0-9]+)\.exe',
      ).firstMatch(readme)!.group(1);

      expect(
        {appVersion, launcherVersion, installerVersion, readmeVersion},
        {appVersion},
        reason: 'App, launcher, installer, and download metadata must agree.',
      );

      const allowedStatuses = {
        'REAL',
        'PARTIAL',
        'DISABLED',
        'BLOCKED_EXTERNAL',
        'NOT_IMPLEMENTED',
      };
      final report = File(
        p.join(
            repositoryRoot.path, 'docs', 'qa', 'commercial-release-report.md'),
      ).readAsLinesSync();
      final capabilityRows = report
          .map((line) => line.split('|').map((cell) => cell.trim()).toList())
          .where((cells) => cells.length >= 5 && int.tryParse(cells[1]) != null)
          .map((cells) => cells[3])
          .toList();

      expect(capabilityRows, isNotEmpty);
      expect(
        capabilityRows.where((status) => !allowedStatuses.contains(status)),
        isEmpty,
        reason: 'Capability claims must use the auditable release vocabulary.',
      );
    });

    test('pull requests build, package, and upload release evidence', () {
      final workflow = File(
        p.join(repositoryRoot.path, '.github', 'workflows', 'ci.yml'),
      ).readAsStringSync();

      expect(workflow, contains(r'package_release.ps1'));
      expect(workflow, contains('build/windows/release-package/'));
      expect(workflow, isNot(contains("github.event_name == 'push'")));
      expect(workflow, contains('SHA256SUMS.txt'));
      expect(workflow, contains('PROVENANCE.json'));
    });
  });

  test('release packager emits relative checksums and source provenance',
      () async {
    final temp =
        Directory.systemTemp.createTempSync('lingbi-release-contract-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final buildDir = Directory(p.join(temp.path, 'input'))..createSync();
    final nestedDir = Directory(p.join(buildDir.path, 'data'))..createSync();
    final executable = File(p.join(buildDir.path, 'lingbi.exe'))
      ..writeAsStringSync('release-binary');
    File(p.join(nestedDir.path, 'asset.bin')).writeAsStringSync('asset');
    final outputDir = p.join(temp.path, 'package');

    final result = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-File',
        p.join(repositoryRoot.path, 'tool', 'windows', 'package_release.ps1'),
        '-SkipBuild',
        '-BuildDir',
        buildDir.path,
        '-OutputDir',
        outputDir,
      ],
      workingDirectory: repositoryRoot.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final sums = File(p.join(outputDir, 'SHA256SUMS.txt')).readAsLinesSync();
    final expectedHash =
        sha256.convert(executable.readAsBytesSync()).toString().toUpperCase();
    expect(sums, contains('$expectedHash  lingbi.exe'));
    expect(sums.any((line) => line.endsWith('  data/asset.bin')), isTrue);
    expect(sums.any((line) => line.contains(temp.path)), isFalse);

    final provenance = jsonDecode(
      File(p.join(outputDir, 'PROVENANCE.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(provenance['version'],
        _yamlVersion(File('pubspec.yaml').readAsStringSync()));
    expect(provenance['source_commit'],
        _gitLines(repositoryRoot, ['rev-parse', 'HEAD']).single);
    expect(provenance['build_configuration'], 'release');
  });
}

List<String> _gitLines(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceAll('\\', '/'))
      .toList();
}

String? _resolveProductionImport(String sourcePath, String imported) {
  if (imported.startsWith('package:lingbi/')) {
    return 'lib/${imported.substring('package:lingbi/'.length)}';
  }
  if (imported.startsWith('dart:') ||
      imported.startsWith('package:') ||
      imported.contains('://')) {
    return null;
  }
  final resolved =
      p.posix.normalize(p.posix.join(p.posix.dirname(sourcePath), imported));
  return resolved.startsWith('lib/') ? resolved : null;
}

String _yamlVersion(String yaml) {
  return RegExp(r'^version:\s*([^\s]+)', multiLine: true)
      .firstMatch(yaml)!
      .group(1)!;
}
