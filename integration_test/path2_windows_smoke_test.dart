import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/import_export/data/export_service.dart';
import 'package:lingbi/features/import_export/data/portable_project_package_service.dart';
import 'package:lingbi/features/onboarding/ui/welcome_page.dart';
import 'package:lingbi/features/project/ui/project_brief_sheet.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/features/settings/ui/settings_page.dart';
import 'package:lingbi/features/skill/ui/skill_market_page.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/recovery_center_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/ui_v2/components/project_tabs.dart';
import 'package:lingbi/ui_v2/controllers/project_session_manager.dart';
import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

enum _Path2Stage { welcome, brief, editor }

class _Path2Harness extends StatefulWidget {
  const _Path2Harness();

  @override
  State<_Path2Harness> createState() => _Path2HarnessState();
}

class _Path2HarnessState extends State<_Path2Harness> {
  _Path2Stage _stage = _Path2Stage.welcome;
  late ProjectTemplate _template;

  @override
  Widget build(BuildContext context) => switch (_stage) {
        _Path2Stage.welcome => WelcomePage(
            onCreateProject: (template) => setState(() {
              _template = template;
              _stage = _Path2Stage.brief;
            }),
            onOpenProject: () {},
            onOpenSkillMarket: () {},
          ),
        _Path2Stage.brief => ProjectBriefSheet(
            template: _template,
            onCancel: () => setState(() => _stage = _Path2Stage.welcome),
            onSubmit: (_) => setState(() => _stage = _Path2Stage.editor),
          ),
        _Path2Stage.editor => const Center(child: Text('第一章编辑器')),
      };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Path 2 project creation reaches editor on Windows',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: const Scaffold(body: _Path2Harness()),
      ),
    );

    expect(find.text('把灵感写成长篇故事'), findsOneWidget);
    await tester.tap(find.text('玄幻'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-with-template')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('project-title-field')),
      'SmokeTest',
    );
    await tester.tap(find.byKey(const ValueKey('project-create-submit')));
    await tester.pumpAndSettle();

    expect(find.text('第一章编辑器'), findsOneWidget);
  });

  testWidgets('Path 2 project/canon/first chapter/persistence on Windows',
      (tester) async {
    final temp = await Directory.systemTemp.createTemp('lingbi-path2-');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final storage = StorageService();
    await storage.initialize(dbPath: '${temp.path}/db');
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${temp.path}/db');
    final manager = ProjectSessionManager(
      documentService: DocumentService(
        zvecService: zvec,
        fileService: FileService(),
      ),
      canonService: CanonService(zvecService: zvec),
      aiService: AIService(quotaService: QuotaService()),
      mutationProtocol: _path2Protocol('${temp.path}/SmokeTest'),
    );

    final created = await manager.createProject(
      directoryPath: '${temp.path}/SmokeTest',
      brief: const ProjectBrief(
        title: 'SmokeTest',
        genreId: 'xuanhuan',
        templateId: 'genre:xuanhuan',
      ),
    );
    expect(Directory('${temp.path}/SmokeTest/小说资料').existsSync(), isTrue);

    final firstChapter = await manager.openFirstChapter();
    expect(File(firstChapter.filePath).existsSync(), isTrue);
    expect(manager.activeScope?.boundChapterId, firstChapter.id);

    final candidateService = CandidateService(
      projectDir: '${temp.path}/SmokeTest',
      projectId: created.project.id,
      mutationProtocol: _path2Protocol('${temp.path}/SmokeTest'),
    );
    final candidate = candidateService.createCandidate(
      chapterId: firstChapter.id,
      content: '第一章正文：主人公在宗门醒来。',
    );
    await candidateService.adopt(candidate.id, firstChapter.filePath);
    expect(
      File(firstChapter.filePath).readAsStringSync(),
      contains('主人公在宗门醒来'),
    );
    expect(candidateService.getCandidate(candidate.id)?.status,
        CandidateStatus.adopted);

    final recovery = RecoveryCenterService(
      mutationProtocol: _path2Protocol('${temp.path}/SmokeTest'),
    );
    final toRestore = File('${temp.path}/SmokeTest/chapters/to-restore.md');
    await toRestore.writeAsString('restore me');
    final deleted = await recovery.softDelete(
      '${temp.path}/SmokeTest',
      toRestore.path,
    );
    expect(deleted.errorOrNull(), isNull);
    expect(toRestore.existsSync(), isFalse);
    final recoveryItems = await recovery.scan('${temp.path}/SmokeTest');
    final trashItem = recoveryItems.firstWhere(
      (item) => item.type == RecoveryItemType.trash,
    );
    final restored = await recovery.restore(
      trashItem,
      targetPath: 'chapters/restored.md',
    );
    expect(restored.errorOrNull(), isNull);
    expect(
      File('${temp.path}/SmokeTest/chapters/restored.md').readAsStringSync(),
      'restore me',
    );

    manager.closeAll();
    final reopened =
        await manager.openProjectDirectory('${temp.path}/SmokeTest');
    expect(reopened.project.id, created.project.id);
    expect(manager.activeProject?.id, created.project.id);

    final exportDir = Directory('${temp.path}/exports')..createSync();
    final exporter = ExportService();
    await exporter.exportAsMarkdown(
      content: '# SmokeTest',
      savePath: '${exportDir.path}/chapter.md',
    );
    await exporter.exportAsTxt(
      content: '# SmokeTest',
      savePath: '${exportDir.path}/chapter.txt',
    );
    await exporter.exportAsDocx(
      title: 'SmokeTest',
      content: '正文',
      savePath: '${exportDir.path}/chapter.docx',
    );
    expect(File('${exportDir.path}/chapter.md').existsSync(), isTrue);
    expect(
      File('${exportDir.path}/chapter.txt').readAsStringSync(),
      contains('SmokeTest'),
    );
    expect(File('${exportDir.path}/chapter.docx').lengthSync(), greaterThan(0));

    final packageService = PortableProjectPackageService();
    final packagePath = '${exportDir.path}/project.zip';
    final manifest = await packageService.exportPackage(
      '${temp.path}/SmokeTest',
      packagePath,
    );
    expect(manifest.files, isNotEmpty);
    final validation = await packageService.validatePackage(packagePath);
    expect(validation.isValid, isTrue);
    expect(validation.manifest?.files, isNotEmpty);
  });

  testWidgets('Path 2 settings/skill market/experimental labels on Windows',
      (tester) async {
    final locator = await ServiceLocator.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: const Scaffold(body: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets);
    expect(find.text('AI 模型'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: Scaffold(body: SkillMarketPage(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('技能市场'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: Scaffold(
          body: ProjectNavigationBar(
            currentTab: ProjectTab.ideation,
            onTabChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EXP'), findsWidgets);
    expect(locator.initSucceeded, isTrue);
  });
}

LocalMutationProtocol _path2Protocol(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
