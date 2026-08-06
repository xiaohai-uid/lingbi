import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';

void main() {
  test('Flutter opens the shared Project V2 fixture', () async {
    final fixture = '${Directory.current.path}/test/fixtures/project_v2';
    final service = ProjectService(fileService: FileService());

    final opened = await service.openPortableProject(fixture);
    final document = opened.documents.single;

    expect(opened.project.name, 'V2兼容测试');
    expect(document.title, '第一章');
    expect(document.revision, 0);
    expect(document.order, 0);
    expect(document.filePath,
        endsWith('chapters/22222222-2222-4222-8222-222222222222.md'));
    expect(File(document.filePath).existsSync(), isTrue);
    final content = await File(document.filePath).readAsString();
    expect(content.replaceAll('\r\n', '\n'), '# 第一章\n\nV2 fixture content.\n');
  });
}
