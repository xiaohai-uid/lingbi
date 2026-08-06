import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/shared/errors/app_error.dart';

void main() {
  test('createPortableProject fails closed when the directory already exists',
      () async {
    final temp = await Directory.systemTemp.createTemp('lingbi_path_exists_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final projectDir = '${temp.path}/同名小说';
    Directory('$projectDir/.lingbi').createSync(recursive: true);
    Directory('$projectDir/project_meta').createSync(recursive: true);
    Directory('$projectDir/chapters').createSync(recursive: true);
    final sentinel = File('$projectDir/chapters/第一章.md')
      ..writeAsStringSync('原始正文');

    final service = ProjectService();

    await expectLater(
      service.createPortableProject(
        name: '同名小说',
        directoryPath: projectDir,
      ),
      throwsA(isA<FileError>()
          .having((error) => error.code, 'code', 'PROJECT_PATH_EXISTS')),
    );

    expect(sentinel.readAsBytesSync(), utf8.encode('原始正文'));
    expect(File('$projectDir/.lingbi/project.json').existsSync(), isFalse);
    expect(Directory('$projectDir/.lingbi').existsSync(), isTrue);
    expect(Directory('$projectDir/project_meta').existsSync(), isTrue);
    expect(Directory('$projectDir/chapters').existsSync(), isTrue);
    expect(File('$projectDir/chapters/第一章.md').existsSync(), isTrue);
  });
}
