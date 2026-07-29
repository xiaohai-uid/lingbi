import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/features/onboarding/data/project_onboarding_workflow.dart';

class _MemoryMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> values = {};
  int writes = 0;

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async {
    final data = values['$projectId/$fileName'];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    writes++;
    values['$projectId/$fileName'] = Map<String, dynamic>.from(data);
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
  test('answers persist one asset revision and resume at the next question',
      () async {
    final meta = _MemoryMetaRepository();
    final assets = ProjectAssetRepository(metaRepository: meta);
    final workflow = ProjectOnboardingWorkflow(
      metaRepository: meta,
      assetRepository: assets,
    );

    final initial = await workflow.resume('p1');
    expect(initial.currentQuestion, OnboardingQuestion.protagonistGoal);

    final afterGoal = await workflow.answer('p1', '找到失踪的妹妹');
    expect(afterGoal.currentQuestion, OnboardingQuestion.coreObstacle);
    expect(afterGoal.answers[OnboardingQuestion.protagonistGoal], '找到失踪的妹妹');

    final restored = await ProjectOnboardingWorkflow(
      metaRepository: meta,
      assetRepository: assets,
    ).resume('p1');
    expect(restored.currentQuestion, OnboardingQuestion.coreObstacle);
    expect(
      meta.values['p1/characters.json']?['protagonistGoal'],
      '找到失踪的妹妹',
    );
  });

  test('repeating the same answer is idempotent', () async {
    final meta = _MemoryMetaRepository();
    final assets = ProjectAssetRepository(metaRepository: meta);
    final workflow = ProjectOnboardingWorkflow(
      metaRepository: meta,
      assetRepository: assets,
    );

    await workflow.answer('p1', '活下去');
    final assetAfterFirst = (await assets.list('p1')).first;
    await workflow.answerQuestion(
      'p1',
      OnboardingQuestion.protagonistGoal,
      '活下去',
    );
    final assetAfterRepeat = (await assets.list('p1')).first;

    expect(assetAfterFirst.revision, 1);
    expect(assetAfterRepeat.revision, 1);
  });

  test('skip is durable and completing three questions ends onboarding',
      () async {
    final meta = _MemoryMetaRepository();
    final workflow = ProjectOnboardingWorkflow(
      metaRepository: meta,
      assetRepository: ProjectAssetRepository(metaRepository: meta),
    );

    await workflow.skip('p1');
    await workflow.answer('p1', '城里每个人都会忘记昨天');
    final completed = await workflow.answer('p1', '主角收到了自己的讣告');
    final restored = await workflow.resume('p1');

    expect(completed.isCompleted, isTrue);
    expect(restored.isCompleted, isTrue);
    expect(restored.skipped, contains(OnboardingQuestion.protagonistGoal));
  });
}
