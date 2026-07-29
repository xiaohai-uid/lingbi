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
        'CHANGELOG.md',
        'CONTRIBUTING.md',
        'SECURITY.md',
        'docs/FAQ.md',
        'docs/GETTING_STARTED.md',
        'docs/qa/p0-windows-release-checklist.md',
        'docs/qa/commercial-release-report.md',
        '.github/workflows/ci.yml',
        '.github/workflows/release.yml',
        'tool/windows/build_release_assets.ps1',
        'tool/windows/package_release.ps1',
        'tool/windows/release_path_guard.ps1',
        'tool/windows/smoke_test_installer.ps1',
      };

      expect(
        tracked,
        containsAll(requiredEvidence),
        reason:
            'A clean checkout must contain the dependency lock and QA gates.',
      );

      final missingImports = _untrackedProductionImports(
        repositoryRoot,
        tracked,
      );

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
      expect(workflow, contains('RUNNER_TEMP'));
      expect(workflow, contains('LINGBI_PACKAGE_DIR'));
      expect(workflow, isNot(contains("github.event_name == 'push'")));
      expect(workflow, contains('SHA256SUMS.txt'));
      expect(workflow, contains('PROVENANCE.json'));
    });

    test('version tags publish both beginner-friendly Windows packages', () {
      final workflow = File(
        p.join(repositoryRoot.path, '.github', 'workflows', 'release.yml'),
      ).readAsStringSync();
      final builder = File(
        p.join(
          repositoryRoot.path,
          'tool',
          'windows',
          'build_release_assets.ps1',
        ),
      ).readAsStringSync();

      expect(workflow, contains("tags: ['v*']"));
      expect(workflow, contains('contents: write'));
      expect(workflow, contains('build_release_assets.ps1'));
      expect(workflow, contains('smoke_test_installer.ps1'));
      expect(workflow, contains('gh release create'));
      expect(builder, contains('Lingbi-Windows-Portable-'));
      expect(builder, contains('Lingbi-Setup-'));
      expect(builder, contains('SHA256SUMS.txt'));
      expect(builder, contains('PROVENANCE.json'));
      expect(builder, contains('Assert-SafeReleaseOutputPath'));
    });

    test('Windows binaries and installer expose public product metadata', () {
      final resource = File(
        p.join(repositoryRoot.path, 'windows', 'runner', 'Runner.rc'),
      ).readAsStringSync();
      final installer = File(
        p.join(repositoryRoot.path, 'installer', 'lingbi_setup.iss'),
      ).readAsStringSync();

      expect(resource, contains('LingBi Open Source Contributors'));
      expect(resource, contains('灵笔 (LingBi)'));
      expect(resource, isNot(contains('com.example')));
      expect(installer, isNot(contains(r'launcher\build')));
      expect(installer, contains('PrivilegesRequiredOverridesAllowed=commandline'));
    });

    test('CI toolchain matches the enforced lockfile SDK floor', () {
      final workflow = File(
        p.join(repositoryRoot.path, '.github', 'workflows', 'ci.yml'),
      ).readAsStringSync();
      final readme = File(
        p.join(repositoryRoot.path, 'README.md'),
      ).readAsStringSync();
      final lockfile = File(
        p.join(repositoryRoot.path, 'pubspec.lock'),
      ).readAsStringSync();

      expect(lockfile, contains('dart: ">=3.12.0 <4.0.0"'));
      expect(lockfile, contains('flutter: ">=3.44.0"'));
      expect(
        RegExp("flutter-version: '3.44.6'").allMatches(workflow).length,
        2,
      );
      expect(
        RegExp(r'flutter pub get --enforce-lockfile').allMatches(workflow).length,
        2,
      );
      expect(readme, contains('Flutter 3.44.6'));
      expect(readme, isNot(contains('Flutter 3.38')));
    });

    test('a clean checkout reports missing imports but exempts generated sources',
        () {
      final fixture = Directory.systemTemp.createTempSync('lingbi-imports-');
      addTearDown(() => fixture.deleteSync(recursive: true));
      final mainFile = File(p.join(fixture.path, 'lib', 'main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'missing.dart';
import 'package:lingbi/services/missing_service.dart';
import 'generated_plugin_registrant.dart';
part 'models/chapter.g.dart';

void main() {}
''');
      _runGit(fixture, ['init', '--quiet']);
      _runGit(fixture, ['add', p.relative(mainFile.path, from: fixture.path)]);
      final tracked = _gitLines(fixture, ['ls-files']).toSet();

      expect(
        _untrackedProductionImports(fixture, tracked),
        {
          'lib/main.dart -> lib/missing.dart',
          'lib/main.dart -> lib/services/missing_service.dart',
        },
      );
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
    expect(sums.any((line) => line.endsWith('  README.txt')), isTrue);
    expect(sums.any((line) => line.contains(temp.path)), isFalse);
    expect(File(p.join(outputDir, 'README.txt')).existsSync(), isTrue);

    final provenance = jsonDecode(
      File(p.join(outputDir, 'PROVENANCE.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(provenance['version'],
        _yamlVersion(File('pubspec.yaml').readAsStringSync()));
    expect(provenance['source_commit'],
        _gitLines(repositoryRoot, ['rev-parse', 'HEAD']).single);
    expect(provenance['build_configuration'], 'release');
  });

  test('release packager rejects destructive output targets before deletion',
      () async {
    final temp = Directory.systemTemp.createTempSync('lingbi-release-safety-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final fixtureRoot = Directory(p.join(temp.path, 'repository'))..createSync();
    final buildDir = Directory(p.join(temp.path, 'input'))..createSync();
    final gitDir = p.join(fixtureRoot.path, '.git', 'worktrees', 'fixture');
    final commonDir = p.join(fixtureRoot.path, '.git');
    final unsafeTargets = {
      p.rootPrefix(fixtureRoot.path),
      fixtureRoot.path,
      fixtureRoot.parent.path,
      gitDir,
      p.join(commonDir, 'objects'),
      buildDir.path,
      buildDir.parent.path,
      p.join(buildDir.path, 'nested-output'),
      p.join(fixtureRoot.path, 'lib', 'release-output'),
    };

    for (final outputDir in unsafeTargets) {
      final result = await _validateGuardTarget(
        repositoryRoot: fixtureRoot,
        gitDir: gitDir,
        commonDir: commonDir,
        buildDir: buildDir.path,
        outputDir: outputDir,
      );
      expect(result.exitCode, isNot(0), reason: 'unsafe target: $outputDir');
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('Refusing unsafe OutputDir'),
        reason: 'unsafe target: $outputDir',
      );
    }

    final safeResult = await _validateGuardTarget(
      repositoryRoot: fixtureRoot,
      gitDir: gitDir,
      commonDir: commonDir,
      buildDir: buildDir.path,
      outputDir: p.join(temp.path, 'safe-package'),
    );
    expect(
      safeResult.exitCode,
      0,
      reason: '${safeResult.stdout}\n${safeResult.stderr}',
    );

    final integrationResult = await _validatePackageTarget(
      repositoryRoot: repositoryRoot,
      buildDir: buildDir.path,
      outputDir: buildDir.path,
    );
    expect(integrationResult.exitCode, isNot(0));
    expect(
      '${integrationResult.stdout}\n${integrationResult.stderr}',
      contains('Refusing unsafe OutputDir'),
    );
  });
}

Set<String> _untrackedProductionImports(
  Directory root,
  Set<String> tracked,
) {
  final missingImports = <String>{};
  final directive = RegExp(r'''(?:import|export|part)\s+['\"]([^'\"]+)['\"]''');
  for (final sourcePath in tracked.where(
    (path) =>
        path.endsWith('.dart') && path.startsWith('lib/'),
  )) {
    final source = File(p.join(root.path, sourcePath));
    if (!source.existsSync()) continue;
    for (final match in directive.allMatches(source.readAsStringSync())) {
      final imported = match.group(1)!;
      final resolved = _resolveProductionImport(sourcePath, imported);
      if (resolved != null &&
          !_isGeneratedSource(resolved) &&
          !tracked.contains(resolved)) {
        missingImports.add('$sourcePath -> $resolved');
      }
    }
  }
  return missingImports;
}

bool _isGeneratedSource(String sourcePath) {
  final fileName = p.posix.basename(sourcePath);
  return fileName == 'generated_plugin_registrant.dart' ||
      fileName.endsWith('.g.dart') ||
      fileName.endsWith('.freezed.dart');
}

List<String> _gitLines(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceAll(r'\', '/'))
      .toList();
}

void _runGit(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Future<ProcessResult> _validatePackageTarget({
  required Directory repositoryRoot,
  required String buildDir,
  required String outputDir,
}) {
  return Process.run(
    'powershell',
    [
      '-NoProfile',
      '-File',
      p.join(repositoryRoot.path, 'tool', 'windows', 'package_release.ps1'),
      '-SkipBuild',
      '-ValidateOnly',
      '-BuildDir',
      buildDir,
      '-OutputDir',
      outputDir,
    ],
    workingDirectory: repositoryRoot.path,
  );
}

Future<ProcessResult> _validateGuardTarget({
  required Directory repositoryRoot,
  required String gitDir,
  required String commonDir,
  required String buildDir,
  required String outputDir,
}) {
  final guard = p.join(
    Directory.current.path,
    'tool',
    'windows',
    'release_path_guard.ps1',
  );
  final command = '''
. '$guard'
Assert-SafeReleaseOutputPath -OutputDir '$outputDir' -BuildDir '$buildDir' -RepositoryRoot '${repositoryRoot.path}' -GitDir '$gitDir' -GitCommonDir '$commonDir' | Out-Null
''';
  return Process.run(
    'powershell',
    ['-NoProfile', '-Command', command],
    workingDirectory: repositoryRoot.path,
  );
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
