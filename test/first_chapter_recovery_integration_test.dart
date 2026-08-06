import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_workflow.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/features/project/data/project_root_resolver.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

import 'support/fake_conformance_provider.dart';

/// real pipeline 测试含 AI 调用（无 key 时走 fallback，CI 并行下较慢），
/// 放宽默认 30 秒超时避免环境性 flake。
void main() {
  test('file state store replaces state recoverably and ignores stale temp',
      () async {
    final temp = Directory.systemTemp.createTempSync('lingbi_first_chapter_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final store = FileFirstChapterStateStore(projectDirectory: temp.path);
    final state = FirstChapterState(
      projectId: 'p1',
      chapterId: 'c1',
      targetFilePath: '${temp.path}/chapter.md',
      stage: FirstChapterStage.waitingForConfirmation,
      candidateId: 'candidate-1',
      sourceVersion: 'v1',
      updatedAt: DateTime.utc(2026, 7, 27),
    );

    await store.write(state);
    File('${store.stateFilePath}.tmp').writeAsStringSync('{broken');
    final restored = await store.read('p1');

    expect(restored?.candidateId, 'candidate-1');
    expect(restored?.stage, FirstChapterStage.waitingForConfirmation);
  });

  test(
    'real pipeline preserves human text until adoption and creates snapshot',
    () async {
      final temp = Directory.systemTemp.createTempSync('lingbi_real_chapter_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final storage = StorageService();
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '${temp.path}/db');
      final files = FileService();
      final projects = ProjectService(
        zvecService: zvec,
        fileService: files,
        mutationProtocol: _proto('${temp.path}/project'),
      );
      final project = await projects.createPortableProject(
        name: '首章事务测试',
        directoryPath: '${temp.path}/project',
      );
      final documents = DocumentService(zvecService: zvec, fileService: files);
      final document = await documents.createDocument(
        projectId: project.id,
        title: '第一章',
        directoryPath: project.directoryPath,
        content: '人工正文，不可提前覆盖。',
      );
      final ai = AIService(
        quotaService: QuotaService(),
        freeProvider: FakeConformanceProvider(chatResponse: '第一章正文：雨夜开场。'),
      );
      addTearDown(ai.dispose);
      final application = NovelApplicationService(
        projectDir: project.directoryPath,
        projectId: project.id,
        documentService: documents,
        canonService: CanonService(zvecService: zvec),
        aiService: ai,
        mutationProtocol: _proto(project.directoryPath),
      );
      final workflow = FirstChapterWorkflowController(
        pipeline: NovelFirstChapterPipeline(application),
        stateStore: FileFirstChapterStateStore(
          projectDirectory: project.directoryPath,
        ),
      );

      await workflow
          .start(FirstChapterRequest(
            projectId: project.id,
            chapterId: document.id,
            targetFilePath: document.filePath,
            instruction: '生成一个雨夜开场',
          ))
          .drain<void>();
      expect(await documents.readContent(document.filePath), '人工正文，不可提前覆盖。');
      final state = await workflow.resume(project.id);

      final adopted = await workflow.adopt(state!.candidateId!);

      expect(adopted.isSuccess, isTrue,
          reason: 'adopt: ${adopted.code}: ${adopted.message}');
      // 采纳后内容应已被 AI 候选替换（不再是原始人工正文）。
      // 不断言具体 Provider 输出文本，避免测试依赖真实网络调用。
      final adoptedContent = await documents.readContent(document.filePath);
      expect(adoptedContent, isNot('人工正文，不可提前覆盖。'));
      final snapshots = Directory('${project.directoryPath}/.lingbi/snapshots')
          .listSync()
          .whereType<File>()
          .toList();
      expect(snapshots, hasLength(1));
      expect(snapshots.single.readAsStringSync(), '人工正文，不可提前覆盖。');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'project-bound production DI writes project journal and first chapter',
    () async {
      final temp = Directory.systemTemp.createTempSync('lingbi_prod_di_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final storage = StorageService();
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '${temp.path}/db');
      final files = FileService();
      final projects = ProjectService(
        zvecService: zvec,
        fileService: files,
      );
      final resolver = ProjectRootResolverAdapter(
        projectService: projects,
        allowMissingMetadata: true,
      );
      final protocol = LocalMutationProtocol.projectBound(
        resolver: resolver,
        journalFactory: ProjectMutationJournalFactory(resolver: resolver),
        storeForRoot: (root) => FileCanonicalStore.projectOwned(
          root,
          atomicStore: AtomicFileStore(),
        ),
      );
      projects.mutationProtocol = protocol;

      final project = await projects.createPortableProject(
        name: '生产DI测试',
        directoryPath: '${temp.path}/project',
      );
      expect(File('${project.directoryPath}/.lingbi/project.json').existsSync(),
          isTrue);
      expect(
        File(
          '${project.directoryPath}/.lingbi/mutations/events.jsonl',
        ).existsSync(),
        isTrue,
      );

      final documents = DocumentService(zvecService: zvec, fileService: files);
      final document = await documents.createDocument(
        projectId: project.id,
        title: '第一章',
        directoryPath: project.directoryPath,
        content: '人工正文，不可提前覆盖。',
      );
      final ai = AIService(
        quotaService: QuotaService(),
        freeProvider: FakeConformanceProvider(chatResponse: '第一章正文：雨夜开场。'),
      );
      addTearDown(ai.dispose);
      final application = NovelApplicationService(
        projectDir: project.directoryPath,
        projectId: project.id,
        documentService: documents,
        canonService: CanonService(zvecService: zvec),
        aiService: ai,
        mutationProtocol: protocol,
      );
      final workflow = FirstChapterWorkflowController(
        pipeline: NovelFirstChapterPipeline(application),
        stateStore: FileFirstChapterStateStore(
          projectDirectory: project.directoryPath,
        ),
      );

      await workflow
          .start(FirstChapterRequest(
            projectId: project.id,
            chapterId: document.id,
            targetFilePath: document.filePath,
            instruction: '生成一个雨夜开场',
          ))
          .drain<void>();
      final state = await workflow.resume(project.id);
      final adopted = await workflow.adopt(state!.candidateId!);

      expect(adopted.isSuccess, isTrue,
          reason: 'adopt: ${adopted.code}: ${adopted.message}');
      final journal = LocalMutationJournal.projectOwned(
        ResolvedProjectRoot(
          projectId: project.id,
          rootPath: project.directoryPath,
        ),
      );
      final events = await journal.readAll();
      expect(events.map((event) => event.eventType),
          contains(LocalMutationJournal.receiptEventType));
      final adoptedContent = await documents.readContent(document.filePath);
      expect(adoptedContent, isNot('人工正文，不可提前覆盖。'));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
