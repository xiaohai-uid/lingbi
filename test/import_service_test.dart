import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/import_export/data/import_service.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/models/project.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_import_service_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('导入 Markdown 文件创建项目内文档并保留正文', () async {
    final storage = StorageService();
    await storage.initialize(dbPath: '${tempDir.path}/db');
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize();

    final projectDir = '${tempDir.path}/我的小说';
    final projectService = ProjectService(
      zvecService: zvec,
      mutationProtocol: _proto(projectDir),
    );
    final project = await projectService.createPortableProject(
      name: '导入测试',
      directoryPath: projectDir,
    );
    final documentService = DocumentService(
      zvecService: zvec,
      fileService: FileService(),
    );

    final source = File('${tempDir.path}/外部章节.md')
      ..writeAsStringSync('# 外部章节\n\n这是拖放导入的正文。');

    final document = await importTextFileIntoProject(
      project: project,
      documentService: documentService,
      filePath: source.path,
    );

    expect(document.title, '外部章节');
    expect(File(document.filePath).existsSync(), isTrue);
    final content = await documentService.readContent(document.filePath);
    expect(content, contains('这是拖放导入的正文。'));
  });

  test('不支持的扩展名被拒绝', () async {
    final source = File('${tempDir.path}/notes.pdf')..writeAsStringSync('pdf');

    await expectLater(
      importTextFileIntoProject(
        project: Project(
          name: '临时项目',
          directoryPath: tempDir.path,
        ),
        documentService: DocumentService(
          zvecService: ZVecService(storageService: StorageService()),
          fileService: FileService(),
        ),
        filePath: source.path,
      ),
      throwsArgumentError,
    );
  });
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
