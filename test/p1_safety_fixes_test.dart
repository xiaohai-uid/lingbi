import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/ui_v2/controllers/project_session_manager.dart';

/// Task 15 regression tests: rename collisions never overwrite, opening a
/// project never rewrites bodies, provider errors are never saved as
/// manuscript content.
void main() {
  late Directory temp;
  late StorageService storage;
  late ZVecService zvec;
  late DocumentService documents;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('lingbi_p1fix_');
    storage = StorageService();
    await storage.initialize(dbPath: '${temp.path}/db');
    zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${temp.path}/db');
    documents = DocumentService(
      zvecService: zvec,
      fileService: FileService(),
    );
  });

  tearDown(() async {
    await zvec.close();
    await temp.delete(recursive: true);
  });

  test('rename to an existing title throws and preserves both files',
      () async {
    final projectDir = '${temp.path}/novel';
    await Directory('$projectDir/chapters').create(recursive: true);
    final first = await documents.createDocument(
      projectId: 'p1',
      title: '第一章',
      directoryPath: '$projectDir/chapters',
      content: '第一章内容',
    );
    final second = await documents.createDocument(
      projectId: 'p1',
      title: '第二章',
      directoryPath: '$projectDir/chapters',
      content: '第二章内容',
    );

    // Rename 第二章 -> 第一章 (collision).
    await expectLater(
      documents.renameDocument(second, '第一章'),
      throwsA(
        isA<FileError>().having(
          (error) => error.code,
          'code',
          'RENAME_COLLISION',
        ),
      ),
    );

    // Both files must still exist with their original content.
    expect(
      await File(first.filePath).readAsString(),
      '第一章内容',
      reason: 'existing chapter must not be overwritten',
    );
    expect(
      await File(second.filePath).readAsString(),
      '第二章内容',
      reason: 'renamed chapter must keep its content',
    );
    final loaded = await storage.query('documents');
    expect(loaded.length, 2);
  });

  test('opening a project never rewrites chapter bodies', () async {
    final projectDir = '${temp.path}/测试小说';
    final counting = CountingDocumentService(
      zvecService: zvec,
      fileService: FileService(),
    );
    final manager = ProjectSessionManager(
      documentService: counting,
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
    final document = session.selectedDocument!;
    await counting.saveDocument(document, '外部工具写入的正文');

    // Simulate an external edit, then reopen the project. Opening must be
    // read-only: zero additional saveDocument calls.
    final bodyPath = File(document.filePath);
    await bodyPath.writeAsString('外部编辑后的正文');
    manager.dispose();
    counting.saves = 0;
    final reopened = await ProjectSessionManager(
      documentService: counting,
      canonService: CanonService(zvecService: zvec),
      aiService: AIService(quotaService: QuotaService()),
      mutationProtocol: _proto(projectDir),
    ).openProjectDirectory(projectDir);

    expect(reopened.selectedDocument, isNotNull);
    expect(await bodyPath.readAsString(), '外部编辑后的正文',
        reason: 'opening must not rewrite the body');
    expect(counting.saves, 0,
        reason: 'opening a project must never write chapter bodies');
  });

  test('provider error surfaces are never mistaken for manuscript',
      () async {
    // Real provider error shapes must be detected.
    expect(looksLikeProviderError('401 Unauthorized'), isTrue);
    expect(looksLikeProviderError('HTTP 401'), isTrue);
    expect(looksLikeProviderError('429 Too Many Requests'), isTrue);
    expect(looksLikeProviderError('500 Internal Server Error'), isTrue);
    expect(
        looksLikeProviderError(
            '{"error":{"type":"insufficient_quota","message":"quota"}}'),
        isTrue);
    expect(looksLikeProviderError('Connection refused'), isTrue);
    expect(looksLikeProviderError('request timed out'), isTrue);
    expect(looksLikeProviderError('Invalid API key provided'), isTrue);
    expect(looksLikeProviderError('服务暂时不可用'), isTrue);
    expect(looksLikeProviderError('API Key 无效'), isTrue);
    expect(looksLikeProviderError('请求过于频繁'), isTrue);

    // Normal manuscript text must never be flagged.
    expect(looksLikeProviderError('雨夜，林渊推开旧车站的门。'), isFalse);
    expect(looksLikeProviderError('第一章 雨夜'), isFalse);
    expect(looksLikeProviderError('他看了一眼时间，已经是深夜。'), isFalse);
    expect(looksLikeProviderError(''), isFalse);
  });
}

/// Counts saveDocument calls so tests can prove open is read-only.
class CountingDocumentService extends DocumentService {
  CountingDocumentService({
    super.zvecService,
    required super.fileService,
  });

  int saves = 0;

  @override
  Future<Document> saveDocument(Document doc, String content) async {
    saves += 1;
    return super.saveDocument(doc, content);
  }
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
