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
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/features/project/ui/project_brief_sheet.dart';
import 'package:lingbi/ui_v2/controllers/project_session_manager.dart';
import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/features/onboarding/ui/welcome_page.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

enum _GoldenStage { welcome, brief, editor }

class _GoldenPathHarness extends StatefulWidget {
  const _GoldenPathHarness();

  @override
  State<_GoldenPathHarness> createState() => _GoldenPathHarnessState();
}

class _GoldenPathHarnessState extends State<_GoldenPathHarness> {
  _GoldenStage _stage = _GoldenStage.welcome;
  late ProjectTemplate? _template;

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
        _GoldenStage.editor => const Center(child: Text('第一章编辑器')),
      };

  void _createProject(ProjectBrief brief) {
    setState(() => _stage = _GoldenStage.editor);
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
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [LingBiColors.light]),
          home: const Scaffold(body: _GoldenPathHarness()),
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

      expect(find.text('第一章编辑器'), findsOneWidget);
    },
  );
}
