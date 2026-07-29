import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/ui_v2/components/project_asset_card.dart';
import 'package:lingbi/ui_v2/components/project_tabs.dart';
import 'package:lingbi/features/project/ui/project_overview_page.dart';
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

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData(
        extensions: const [LingBiColors.light],
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('project navigation exposes exactly five primary stages',
      (tester) async {
    await tester.pumpWidget(
      _app(
        ProjectNavigationBar(
          currentTab: ProjectTab.overview,
          onTabChanged: (_) {},
        ),
      ),
    );

    for (final label in ['总览', '写作', '构思', '审稿', '发布']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(ProjectTab.values, hasLength(5));
  });

  testWidgets('asset cards expose all five states as text', (tester) async {
    const labels = {
      ProjectAssetState.notStarted: '未开始',
      ProjectAssetState.generating: '生成中',
      ProjectAssetState.editable: '可编辑',
      ProjectAssetState.awaitingConfirmation: '待确认',
      ProjectAssetState.failed: '失败',
    };
    await tester.pumpWidget(
      _app(
        ListView(
          children: labels.keys
              .map(
                (state) => ProjectAssetCard(
                  asset: ProjectAsset.initial(
                    projectId: 'p1',
                    type: ProjectAssetType.protagonist,
                  ).copyWith(state: state),
                ),
              )
              .toList(),
        ),
      ),
    );

    for (final label in labels.values) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('overview shows project brief assets and a local next action',
      (tester) async {
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
    );
    final project = Project(
      id: 'p1',
      name: '长夜城',
      directoryPath: 'C:/novels/long-night',
      genre: 'xuanhuan',
      targetPlatform: '起点',
      premise: '一座每夜移动的城。',
    );

    await tester.pumpWidget(
      _app(ProjectOverviewPage(project: project, repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('长夜城'), findsOneWidget);
    expect(find.textContaining('一座每夜移动的城'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('完善主角'), findsWidgets);
    expect(find.byType(ProjectAssetCard), findsNWidgets(5));
  });
}
