import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/features/onboarding/data/project_onboarding_workflow.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/features/project/ui/project_brief_sheet.dart';
import 'package:lingbi/ui_v2/controllers/project_session_manager.dart';
import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/features/onboarding/ui/project_onboarding_page.dart';
import 'package:lingbi/features/project/ui/project_overview_page.dart';
import 'package:lingbi/features/onboarding/ui/welcome_page.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class _MemoryMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> values = {};

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async =>
      values['$projectId/$fileName'];

  @override
  Future<void> write(
    String projectId,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    values['$projectId/$fileName'] = data;
  }

  @override
  Future<void> delete(String projectId, String fileName) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => projectId;

  @override
  Future<List<String>> list(String projectId) async => const [];

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
    String projectId,
    WorldConstitution constitution,
  ) async {}
}

enum _GoldenStage { welcome, brief, onboarding, overview, editor }

class _GoldenPathHarness extends StatefulWidget {
  const _GoldenPathHarness({required this.metaRepository});

  final _MemoryMetaRepository metaRepository;

  @override
  State<_GoldenPathHarness> createState() => _GoldenPathHarnessState();
}

class _GoldenPathHarnessState extends State<_GoldenPathHarness> {
  _GoldenStage _stage = _GoldenStage.welcome;
  late ProjectTemplate? _template;
  late Project? _project;

  late final ProjectAssetRepository _assets = ProjectAssetRepository(
    metaRepository: widget.metaRepository,
  );
  late final ProjectOnboardingWorkflow _onboarding = ProjectOnboardingWorkflow(
    metaRepository: widget.metaRepository,
    assetRepository: _assets,
  );

  @override
  Widget build(BuildContext context) => switch (_stage) {
        _GoldenStage.welcome => WelcomePage(
            onCreateProject: (template) => setState(() {
              _template = template;
              _stage = _GoldenStage.brief;
            }),
            onOpenProject: () {},
            onOpenSkillMarket: () {},
          ),
        _GoldenStage.brief => ProjectBriefSheet(
            template: _template!,
            onCancel: () => setState(() => _stage = _GoldenStage.welcome),
            onSubmit: _createProject,
          ),
        _GoldenStage.onboarding => ProjectOnboardingPage(
            projectId: _project!.id,
            workflow: _onboarding,
            modelSelector: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('模型未配置'),
                TextButton(onPressed: null, child: Text('配置模型')),
                TextButton(onPressed: null, child: Text('继续手写')),
              ],
            ),
            onCompleted: () => setState(() => _stage = _GoldenStage.overview),
            onManualWriting: () => setState(() => _stage = _GoldenStage.editor),
          ),
        _GoldenStage.overview => ProjectOverviewPage(
            project: _project!,
            repository: _assets,
            onAssetSelected: (asset) {
              if (asset.type.name == 'firstChapter') {
                setState(() => _stage = _GoldenStage.editor);
              }
            },
          ),
        _GoldenStage.editor => const Center(child: Text('第一章编辑器')),
      };

  void _createProject(ProjectBrief brief) {
    setState(() {
      _project = Project(
        id: 'golden-project',
        name: brief.title,
        directoryPath: r'C:\LingBi\万界守夜人',
        genre: brief.genreId,
        templateId: brief.templateId,
      );
      _stage = _GoldenStage.onboarding;
    });
  }
}

void main() {
  testWidgets('welcome offers one-click recovery for the recent project',
      (tester) async {
    final recent = Project(
      id: 'recent-project',
      name: '万界守夜人',
      directoryPath: r'C:\LingBi\万界守夜人',
      genre: 'xuanhuan',
    );
    Project? resumed;

    // Dynamic construction makes the RED runnable before the optional recent
    // project API exists on WelcomePage.
    final dynamic welcome = Function.apply(WelcomePage.new, const [], {
      #onCreateProject: (ProjectTemplate _) {},
      #onOpenProject: () {},
      #onOpenSkillMarket: () {},
      #recentProjects: [recent],
      #onResumeProject: (Project project) => resumed = project,
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: welcome)));

    expect(find.text('最近项目'), findsOneWidget);
    expect(find.text('万界守夜人'), findsOneWidget);
    await tester.tap(find.text('万界守夜人'));
    expect(resumed?.id, 'recent-project');
  });

  test(
    'session manager creates the project and selects a persisted first chapter',
    () async {
      final temp = await Directory.systemTemp.createTemp('lingbi-golden-');
      addTearDown(() => temp.delete(recursive: true));
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
      );

      // Dynamic dispatch keeps the RED executable against the old manager API:
      // it must fail because the unified create/first-chapter path is absent.
      final dynamic goldenSession = manager;
      final created = await goldenSession.createProject(
        directoryPath: '${temp.path}/万界守夜人',
        brief: const ProjectBrief(
          title: '万界守夜人',
          genreId: 'xuanhuan',
          templateId: 'genre:xuanhuan',
        ),
      );
      final firstChapter = await goldenSession.openFirstChapter();

      expect(created.project.genre, 'xuanhuan');
      expect(firstChapter.title, '第一章');
      expect(manager.activeScope?.boundChapterId, firstChapter.id);
      expect(File(firstChapter.filePath).existsSync(), isTrue);
    },
  );

  testWidgets(
    'Windows keyboard and mouse golden path keeps genre and reaches first chapter',
    (tester) async {
      final meta = _MemoryMetaRepository();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [LingBiColors.light]),
          home: Scaffold(body: _GoldenPathHarness(metaRepository: meta)),
        ),
      );

      // Mouse: choose a genre. The brief must already carry the same genre.
      await tester.tap(find.text('玄幻'));
      await tester.pumpAndSettle();
      expect(find.text('玄幻'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('continue-with-template')));
      await tester.pumpAndSettle();

      // Keyboard: enter only the title; no second genre choice is required.
      await tester.enterText(
        find.byKey(const ValueKey('project-title-field')),
        '万界守夜人',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.tap(find.byKey(const ValueKey('project-create-submit')));
      await tester.pumpAndSettle();

      expect(find.text('模型未配置'), findsOneWidget);
      expect(find.text('配置模型'), findsOneWidget);
      expect(find.text('继续手写'), findsOneWidget);

      // Complete all three questions with keyboard submit.
      for (final answer in ['守住故乡', '天道抹去众生记忆', '收到自己的讣告']) {
        await tester.enterText(find.byType(TextField).first, answer);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      // Completion lands on the asset overview exactly once, never loops.
      expect(find.text('创作资产'), findsOneWidget);
      expect(find.text('用三个问题开始创作'), findsNothing);
      expect(find.text('第一章'), findsOneWidget);

      // Mouse: first chapter is a direct, visible route into the editor.
      await tester.tap(find.text('第一章'));
      await tester.pumpAndSettle();
      expect(find.text('第一章编辑器'), findsOneWidget);

      final state = await ProjectOnboardingWorkflow(
        metaRepository: meta,
        assetRepository: ProjectAssetRepository(metaRepository: meta),
      ).resume('golden-project');
      expect(state.isCompleted, isTrue);
      expect(
        state.answers.values,
        containsAll(['守住故乡', '天道抹去众生记忆', '收到自己的讣告']),
      );
    },
  );
}
