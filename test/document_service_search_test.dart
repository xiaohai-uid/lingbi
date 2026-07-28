import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/storage_service.dart';

void main() {
  test('searchDocuments returns title and content matches for one project',
      () async {
    final root = await Directory.systemTemp.createTemp('lingbi-doc-search-');
    final database = Directory('${root.path}/db');
    final documents = Directory('${root.path}/docs');
    final storage = StorageService();
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: database.path);
    final service = DocumentService(
      zvecService: zvec,
      fileService: FileService(),
    );
    addTearDown(() async {
      await zvec.close();
      await root.delete(recursive: true);
    });

    final first = await service.createDocument(
      projectId: 'project-a',
      title: '开场设计',
      directoryPath: documents.path,
      content: '# 开场设计\n\n主角在雨夜醒来。',
    );
    await service.createDocument(
      projectId: 'project-a',
      title: '人物卡',
      directoryPath: documents.path,
      content: '# 人物卡\n\n主角的师父来自北境。',
    );
    await service.createDocument(
      projectId: 'project-b',
      title: '北境设定',
      directoryPath: documents.path,
      content: '# 北境设定\n\n不应出现在项目 A 的结果中。',
    );

    final titleMatches = await service.searchDocuments('project-a', '开场');
    final contentMatches = await service.searchDocuments('project-a', '北境');
    final empty = await service.searchDocuments('project-a', '不存在');

    expect(titleMatches.map((doc) => doc.id), contains(first.id));
    expect(contentMatches, hasLength(1));
    expect(contentMatches.single.title, '人物卡');
    expect(empty, isEmpty);
  });
}
