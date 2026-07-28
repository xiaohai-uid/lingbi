import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/ui_v2/components/project_brief_sheet.dart';
import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/ui_v2/pages/welcome_page.dart';

void main() {
  testWidgets('genre card shows selection before the only continue action',
      (tester) async {
    ProjectTemplate? selected;
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WelcomePage(
          onCreateProject: (template) => selected = template,
          onOpenProject: () {},
          onOpenSkillMarket: () {},
        ),
      ),
    ));

    await tester.tap(find.text('玄幻'));
    await tester.pump();

    expect(selected, isNull);
    expect(find.text('已选择玄幻'), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-with-template')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('continue-with-template')));

    expect(selected?.genreId, 'xuanhuan');
    expect(selected?.templateId, 'genre:xuanhuan');
  });

  testWidgets('brief sheet keeps genre and returns one complete brief',
      (tester) async {
    ProjectBrief? submitted;
    const template = ProjectTemplate(
      templateId: 'genre:xuanhuan',
      genreId: 'xuanhuan',
      genreLabel: '玄幻',
      description: '神秘大陆、修仙之路',
      icon: Icons.auto_stories_outlined,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProjectBriefSheet(
          template: template,
          onCancel: () {},
          onSubmit: (brief) => submitted = brief,
        ),
      ),
    ));

    expect(find.text('玄幻'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('project-title-field')),
      '万界守夜人',
    );
    await tester.tap(find.byKey(const ValueKey('project-create-submit')));
    await tester.pump();

    expect(submitted?.title, '万界守夜人');
    expect(submitted?.genreId, 'xuanhuan');
    expect(submitted?.templateId, 'genre:xuanhuan');
  });
}
