import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/core/file_system/sync_service.dart';
import 'package:lingbi/services/document_service.dart';

class _UnusedZVecService implements ZVecService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSyncService implements SyncService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
      'writeDocumentContent writes markdown content to an existing v4 document path',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('lingbi_document_service_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = DocumentService(
      zvecService: _UnusedZVecService(),
      fileService: FileService(),
      syncService: _UnusedSyncService(),
    );
    final filePath = '${tempDir.path}/chapter.md';

    await service.writeDocumentContent(filePath, '# 第一章\n\n正文');

    expect(await File(filePath).readAsString(), '# 第一章\n\n正文');
  });
}
