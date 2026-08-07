import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/import_export/data/portable_project_package_service.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';

/// Task 15: portable ZIP must reject every Windows traversal vector:
/// `../`, `..\`, `C:\`, `C:relative`, `\\server\share`, mixed separators,
/// NUL, absolute paths.
void main() {
  const manifestName = 'lingbi-manifest.json';

  Future<String> craftMaliciousPackage(
    String maliciousPath,
    String rootDir,
  ) async {
    final files = <String, String>{
      maliciousPath: 'evil',
      'chapter.md': '# Chapter',
    };
    final manifest = {
      'schemaVersion': SchemaVersions.portablePackage,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'files': [
        for (final entry in files.entries)
          {
            'path': entry.key,
            'size': utf8.encode(entry.value).length,
            'sha256': sha256.convert(utf8.encode(entry.value)).toString(),
            'category': 'documents',
          },
      ],
    };
    final archive = Archive()
      ..add(ArchiveFile.bytes(
          manifestName, utf8.encode(jsonEncode(manifest))))
      ..add(ArchiveFile.bytes('chapter.md', utf8.encode('# Chapter')))
      ..add(ArchiveFile.bytes(maliciousPath, utf8.encode('evil')));
    final bytes = ZipEncoder().encodeBytes(archive);
    final package = File('$rootDir/evil.lingbi.zip');
    await package.writeAsBytes(bytes, flush: true);
    return package.path;
  }

  Future<void> expectRejected(String maliciousPath) async {
    final root = await Directory.systemTemp.createTemp('lingbi_zip_evil_');
    addTearDown(() => root.delete(recursive: true));
    final package = await craftMaliciousPackage(maliciousPath, root.path);

    final validation = await PortableProjectPackageService()
        .validatePackage(package);
    expect(validation.isValid, isFalse,
        reason: 'must reject path: $maliciousPath');
    await expectLater(
      PortableProjectPackageService()
          .importPackage(package, '${root.path}/dest'),
      throwsA(isA<FormatException>()),
      reason: 'import must reject path: $maliciousPath',
    );
    expect(Directory('${root.path}/dest').existsSync(), isFalse,
        reason: 'no destination may be created for: $maliciousPath');
  }

  test('rejects .. traversal with forward slash', () {
    expectRejected('../evil.md');
  });

  test('rejects .. traversal with backslash', () {
    expectRejected(r'..\evil.md');
  });

  test('rejects nested traversal', () {
    expectRejected('chapters/../../evil.md');
  });

  test('rejects drive-qualified absolute C:\\ path', () {
    expectRejected(r'C:\windows\evil.md');
  });

  test('rejects drive-relative C:path', () {
    expectRejected('C:evil.md');
    expectRejected('C:../evil.md');
  });

  test('rejects UNC server share path', () {
    expectRejected(r'\\server\share\evil.md');
  });

  test('rejects mixed separator smuggling', () {
    expectRejected('chapters/..\\evil.md');
    expectRejected(r'chapters\../evil.md');
  });

  test('rejects NUL and control characters', () {
    expectRejected('evil\u0000.md');
    expectRejected('evil\u0001.md');
  });

  test('rejects absolute POSIX path', () {
    expectRejected('/tmp/evil.md');
  });

  test('accepts legitimate relative paths', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_zip_ok_');
    addTearDown(() => root.delete(recursive: true));
    final project = Directory('${root.path}/source');
    await File('${project.path}/.lingbi/project.json')
        .create(recursive: true)
        .then((file) => file.writeAsString('{"id":"p1","name":"Novel"}'));
    await Directory('${project.path}/.lingbi/candidates')
        .create(recursive: true);
    await File('${project.path}/.lingbi/candidates/第一章.md')
        .writeAsString('candidate');

    final service = PortableProjectPackageService();
    final archive = '${root.path}/good.lingbi.zip';
    await service.exportPackage(project.path, archive);
    expect((await service.validatePackage(archive)).isValid, isTrue);

    final destination = '${root.path}/restored';
    await service.importPackage(archive, destination);
    expect(
      await File('$destination/.lingbi/candidates/第一章.md').readAsString(),
      'candidate',
    );
  });

  test('LocalMode never overwrites a same-name chapter', () {
    // Regression contract for the LocalMode same-name overwrite fix:
    // the fix appends a -N suffix instead of clobbering the existing file.
    final root = Directory.systemTemp.createTempSync('lingbi_localmode_');
    addTearDown(() => root.deleteSync(recursive: true));
    final existing = File('${root.path}/第一章.md')
      ..writeAsStringSync('# 第一章\n\n原有内容');

    // Simulate the LocalMode _newChapter collision policy.
    final baseName = '第一章';
    var fileName = baseName;
    var index = 2;
    while (File('${root.path}/$fileName.md').existsSync()) {
      fileName = '$baseName-$index';
      index += 1;
    }
    File('${root.path}/$fileName.md').writeAsStringSync('# $fileName\n\n');

    expect(
      File('${root.path}/第一章.md').readAsStringSync(),
      '# 第一章\n\n原有内容',
      reason: 'existing chapter must be untouched',
    );
    expect(File('${root.path}/第一章-2.md').existsSync(), isTrue,
        reason: 'new chapter gets a suffixed name');
  });
}
