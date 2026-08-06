import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/import_export/data/import_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/models/project.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lingbi_doc_duplicate_');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('creating the same title twice fails and preserves the original bytes',
      () async {
    final service = DocumentService(fileService: FileService());
    final first = await service.createDocument(
      projectId: 'project-a',
      title: '第一章',
      directoryPath: temp.path,
      content: '原始正文',
    );

    await expectLater(
      service.createDocument(
        projectId: 'project-a',
        title: '第一章',
        directoryPath: temp.path,
        content: '不应覆盖',
      ),
      throwsA(isA<FileError>()
          .having((error) => error.code, 'code', 'DOCUMENT_ALREADY_EXISTS')),
    );

    expect(File(first.filePath).readAsStringSync(), '原始正文');
  });

  test('importing the same filename twice fails and preserves the original',
      () async {
    final service = DocumentService(fileService: FileService());
    final projectDir = Directory('${temp.path}/project')..createSync();
    final sourceDir = Directory('${temp.path}/source')..createSync();
    final project = Project(name: '导入测试', directoryPath: projectDir.path);
    final source = File('${sourceDir.path}/外部章节.md')
      ..writeAsStringSync('# 外部章节\n\n首次导入正文');

    final first = await importTextFileIntoProject(
      project: project,
      documentService: service,
      filePath: source.path,
    );

    try {
      await importTextFileIntoProject(
        project: project,
        documentService: service,
        filePath: source.path,
      );
      fail('expected FileError');
    } on FileError catch (error) {
      expect(error.code, 'DOCUMENT_ALREADY_EXISTS');
    }

    expect(File(first.filePath).readAsStringSync(), contains('首次导入正文'));
  });
}
