import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/portable_project_package_service.dart';

void main() {
  test('exports, validates and imports a complete portable project', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_package_');
    addTearDown(() => root.delete(recursive: true));
    final project = Directory('${root.path}/source');
    await File('${project.path}/.lingbi/project.json')
        .create(recursive: true)
        .then((file) => file.writeAsString('{"id":"p1","name":"Novel"}'));
    await File('${project.path}/chapter.md').writeAsString('# Chapter');
    await File('${project.path}/.lingbi/candidates/c1.md')
        .create(recursive: true)
        .then((file) => file.writeAsString('candidate'));
    final archive = '${root.path}/novel.lingbi.zip';
    final service = PortableProjectPackageService();

    final manifest = await service.exportPackage(project.path, archive);
    expect(manifest.files.map((file) => file.path), contains('chapter.md'));
    expect((await service.validatePackage(archive)).isValid, isTrue);

    final destination = '${root.path}/restored';
    await service.importPackage(archive, destination);
    expect(await File('$destination/chapter.md').readAsString(), '# Chapter');
    expect(File('$destination/.lingbi/candidates/c1.md').existsSync(), isTrue);
  });

  test('rejects a package whose content no longer matches its manifest',
      () async {
    final root = await Directory.systemTemp.createTemp('lingbi_package_bad_');
    addTearDown(() => root.delete(recursive: true));
    final project = Directory('${root.path}/source')..createSync();
    File('${project.path}/chapter.md').writeAsStringSync('original');
    final package = File('${root.path}/novel.lingbi.zip');
    final service = PortableProjectPackageService();
    await service.exportPackage(project.path, package.path);
    final bytes = await package.readAsBytes();
    bytes[bytes.length ~/ 2] ^= 0xff;
    await package.writeAsBytes(bytes, flush: true);

    final validation = await service.validatePackage(package.path);
    expect(validation.isValid, isFalse);
    await expectLater(
      service.importPackage(package.path, '${root.path}/restored'),
      throwsFormatException,
    );
  });
}
