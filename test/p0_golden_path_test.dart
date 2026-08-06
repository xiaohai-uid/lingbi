import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/ui_v2/controllers/project_session_manager.dart';

void main() {
  test('createProject binds and persists chapter-1 through the session path',
      () async {
    final temp = await Directory.systemTemp.createTemp('lingbi_p0_golden_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final storage = StorageService();
    await storage.initialize(dbPath: '${temp.path}/db');
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${temp.path}/db');
    addTearDown(zvec.close);

    final projectDir = '${temp.path}/测试小说';
    final documents = DocumentService(
      zvecService: zvec,
      fileService: FileService(),
    );
    final manager = ProjectSessionManager(
      documentService: documents,
      canonService: CanonService(zvecService: zvec),
      aiService: AIService(quotaService: QuotaService()),
      mutationProtocol: _proto(projectDir),
    );

    final session = await manager.createProject(
      directoryPath: projectDir,
      brief: const ProjectBrief(
        title: '测试小说',
        genreId: 'xuanhuan',
        templateId: 'genre:xuanhuan',
      ),
    );

    final document = session.selectedDocument;
    expect(document, isNotNull);
    expect(document!.title, '第一章');
    expect(document.filePath, endsWith('chapters/chapter-1.md'));
    expect(File(document.filePath).existsSync(), isTrue);
    expect(manager.activeScope?.boundChapterId, document.id);
    expect(await documents.readContent(document.filePath), contains('# 第一章'));

    manager.dispose();

    final restarted = ProjectSessionManager(
      documentService: documents,
      canonService: CanonService(zvecService: zvec),
      aiService: AIService(quotaService: QuotaService()),
      mutationProtocol: _proto(projectDir),
    );
    final reopened = await restarted.openProjectDirectory(projectDir);

    expect(reopened.selectedDocument?.id, document.id);
    expect(
      await documents.readContent(reopened.selectedDocument!.filePath),
      contains('# 第一章'),
    );

    restarted.dispose();
  });
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
