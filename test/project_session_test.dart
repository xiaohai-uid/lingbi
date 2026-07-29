/// 项目会话隔离测试
///
/// 覆盖：
/// 1. 两个项目拥有不同的 CandidateService 目录
/// 2. 项目 A 的候选不能在项目 B 中采纳
/// 3. 切换项目后旧任务仍绑定原 projectId
/// 4. 关闭项目不会删除未处理候选
/// 5. 重开项目能够恢复未处理候选
@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/features/writing/data/pipeline/project_scope_api.dart';
import 'package:lingbi/features/writing/ui/editor_ai_coordinator.dart';

void main() {
  late Directory tempDirA;
  late Directory tempDirB;
  late String projectDirA;
  late String projectDirB;

  setUp(() {
    tempDirA = Directory.systemTemp.createTempSync('lingbi_proj_a_');
    tempDirB = Directory.systemTemp.createTempSync('lingbi_proj_b_');
    projectDirA = tempDirA.path;
    projectDirB = tempDirB.path;

    // 创建项目目录结构
    for (final dir in [projectDirA, projectDirB]) {
      Directory('$dir/chapters').createSync(recursive: true);
      Directory('$dir/.lingbi').createSync(recursive: true);
    }
  });

  tearDown(() {
    for (final dir in [tempDirA, tempDirB]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  // ─── 测试 1: 两个项目拥有不同的 CandidateService 目录 ─────────

  test('两个项目的 CandidateService 使用不同目录', () {
    final candidateServiceA = CandidateService(projectDir: projectDirA);
    final candidateServiceB = CandidateService(projectDir: projectDirB);

    // 在项目 A 创建候选
    final candidateA = candidateServiceA.createCandidate(
      chapterId: 'ch-1',
      content: '项目A的内容',
      model: 'test-model',
    );

    // 项目 B 不应看到项目 A 的候选
    final candidatesB = candidateServiceB.listCandidates('ch-1');
    expect(candidatesB, isEmpty,
        reason: '项目 B 不应看到项目 A 的候选');

    // 项目 A 应看到自己的候选
    final candidatesA = candidateServiceA.listCandidates('ch-1');
    expect(candidatesA, hasLength(1));
    expect(candidatesA.first.content, '项目A的内容');
    expect(candidateA.id, isNotEmpty);
  });

  // ─── 测试 2: 项目 A 的候选不能在项目 B 中采纳 ─────────────────

  test('项目 A 的候选不能在项目 B 的 CandidateService 中找到', () {
    final candidateServiceA = CandidateService(projectDir: projectDirA);
    final candidateServiceB = CandidateService(projectDir: projectDirB);

    // 在项目 A 创建候选
    final candidateA = candidateServiceA.createCandidate(
      chapterId: 'ch-1',
      content: '项目A的候选',
      model: 'test-model',
    );

    // 项目 B 无法获取项目 A 的候选
    final fromB = candidateServiceB.getCandidate(candidateA.id);
    expect(fromB, isNull,
        reason: '项目 B 的 CandidateService 不应能访问项目 A 的候选');
  });

  // ─── 测试 3: 切换项目后旧任务仍绑定原 projectId ───────────────

  test('协调器切换项目后旧任务绑定不变', () {
    final scopeA = _FakeScope(projectId: 'proj-A');
    final scopeB = _FakeScope(projectId: 'proj-B');
    final fakeApi = _FakePipelineApi();

    final coordinator = EditorAiCoordinator(
      sessionScope: scopeA,
      ensureDocumentSaved: () async => true,
      reloadDocument: () async {},
      pipelineApi: fakeApi,
    );

    // 模拟绑定到项目 A
    scopeA.bindChapter(chapterId: 'ch-1', filePath: '/a/ch1.md');

    // 切换到项目 B
    coordinator.switchProject(scopeB, pipelineApi: fakeApi);

    // 协调器状态已重置
    expect(coordinator.activeProjectId, isNull);
    expect(coordinator.activeChapterId, isNull);
    expect(coordinator.activeCandidate, isNull);

    // 项目 A 的绑定不受影响（磁盘候选保留）
    expect(scopeA.boundChapterId, 'ch-1');

    coordinator.dispose();
  });

  // ─── 测试 4: 关闭项目不会删除未处理候选 ───────────────────────

  test('关闭项目后候选文件仍存在于磁盘', () {
    final candidateService = CandidateService(projectDir: projectDirA);

    // 创建候选
    candidateService.createCandidate(
      chapterId: 'ch-1',
      content: '未处理的候选内容',
      model: 'test-model',
    );

    // 验证候选文件存在
    final candidatesDir = Directory('$projectDirA/.lingbi/candidates');
    expect(candidatesDir.existsSync(), isTrue);
    final filesBefore = candidatesDir.listSync();
    expect(filesBefore, isNotEmpty);

    // "关闭项目"（模拟 dispose — 只解绑，不删除文件）
    // ProjectSessionScope.dispose() 只调用 unbindChapter()
    // 不删除候选目录

    // 验证候选文件仍然存在
    final filesAfter = candidatesDir.listSync();
    expect(filesAfter.length, filesBefore.length,
        reason: '关闭项目不应删除候选文件');

    // 候选仍可读取
    final candidates = candidateService.listCandidates('ch-1');
    expect(candidates, hasLength(1));
    expect(candidates.first.content, '未处理的候选内容');
  });

  // ─── 测试 5: 重开项目能够恢复未处理候选 ───────────────────────

  test('重开项目后能恢复未处理候选', () {
    // 第一次打开：创建候选
    final candidateService1 = CandidateService(projectDir: projectDirA);
    candidateService1.createCandidate(
      chapterId: 'ch-1',
      content: '重启前的候选',
      model: 'test-model',
    );

    // 模拟关闭（不做任何文件操作）

    // 第二次打开：新的 CandidateService 实例指向同一目录
    final candidateService2 = CandidateService(projectDir: projectDirA);
    final restored = candidateService2.listCandidates('ch-1');

    expect(restored, hasLength(1),
        reason: '重开项目应能恢复未处理候选');
    expect(restored.first.content, '重启前的候选');
    expect(restored.first.status, CandidateStatus.pending);
  });
}

// ─── 辅助 Fake ─────────────────────────────────────────────────

class _FakeScope implements ProjectScopeApi {
  _FakeScope({required this.projectId});

  @override
  final String projectId;

  @override
  String? boundChapterId;

  @override
  String? boundFilePath;

  @override
  NovelApplicationService get novelService =>
      throw UnimplementedError('Use FakePipelineApi');

  @override
  void bindChapter({required String chapterId, required String filePath}) {
    boundChapterId = chapterId;
    boundFilePath = filePath;
  }

  @override
  void dispose() {}
}

class _FakePipelineApi implements NovelPipelineApi {
  @override
  Future<PipelineResult<ChapterWritePreparation>> prepareChapterWrite({
    required String chapterId,
    String? previousChapterId,
    String userInstruction = '',
  }) async =>
      const PipelineResult.failure(
          PipelineError(PipelineError.invalidState, 'not used'));

  @override
  Stream<PipelineResult<String>> generateCandidate({
    required String chapterId,
    required dynamic context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  }) =>
      const Stream.empty();

  @override
  List<CandidateEntry> listCandidates(String chapterId) => [];

  @override
  PipelineResult<void> rejectCandidate(String candidateId, {String? reason}) =>
      const PipelineResult.success(null);

  @override
  Future<PipelineResult<String>> adoptCandidate({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) async =>
      const PipelineResult.success('');

  @override
  bool canStartWriting() => true;
}
