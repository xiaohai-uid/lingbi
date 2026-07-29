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

  test('real pipeline preserves human text until adoption and creates snapshot',
      () async {
    final temp = Directory.systemTemp.createTempSync('lingbi_real_chapter_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final storage = StorageService();
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${temp.path}/db');
    final files = FileService();
    final projects = ProjectService(zvecService: zvec, fileService: files);
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
    final ai = AIService(quotaService: QuotaService());
    addTearDown(ai.dispose);
    final application = NovelApplicationService(
      projectDir: project.directoryPath,
      projectId: project.id,
      documentService: documents,
      canonService: CanonService(zvecService: zvec),
      aiService: ai,
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

    expect(adopted.isSuccess, isTrue);
    expect(await documents.readContent(document.filePath),
        contains('Free provider'));
    final snapshots = Directory('${project.directoryPath}/.lingbi/snapshots')
        .listSync()
        .whereType<File>()
        .toList();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.readAsStringSync(), '人工正文，不可提前覆盖。');
  });
}
