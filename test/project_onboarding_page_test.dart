import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/features/onboarding/data/project_onboarding_workflow.dart';
import 'package:lingbi/features/onboarding/ui/project_onboarding_page.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class _MemoryMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> values = {};
  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async =>
      values['$projectId/$fileName'];
  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
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
      String projectId, WorldConstitution constitution) async {}
}

void main() {
  testWidgets('question card advances and keeps manual and skip exits visible',
      (tester) async {
    final meta = _MemoryMetaRepository();
    final workflow = ProjectOnboardingWorkflow(
      metaRepository: meta,
      assetRepository: ProjectAssetRepository(metaRepository: meta),
    );
    var manualWriting = false;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [LingBiColors.light]),
      home: ProjectOnboardingPage(
        projectId: 'p1',
        genreId: 'xuanhuan',
        workflow: workflow,
        modelReady: false,
        onConfigureModel: () {},
        onManualWriting: () => manualWriting = true,
        onCompleted: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('玄幻开局：主角最想实现什么？'), findsOneWidget);
    expect(find.text('守护宗族'), findsOneWidget);
    expect(find.text('灵根被夺'), findsNothing);
    expect(find.text('跳过这题'), findsOneWidget);
    expect(find.text('直接写作'), findsOneWidget);
    expect(find.text('模型未配置'), findsOneWidget);
    expect(find.text('配置模型'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '救回故乡');
    await tester.tap(find.text('保存并继续'));
    await tester.pumpAndSettle();
    expect(find.text('什么阻碍了主角？'), findsOneWidget);
    expect(find.textContaining('救回故乡'), findsOneWidget);

    await tester.tap(find.text('直接写作'));
    expect(manualWriting, isTrue);
  });
}
