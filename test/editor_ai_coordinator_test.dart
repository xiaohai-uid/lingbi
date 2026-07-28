/// EditorAiCoordinator 单元测试
///
/// 覆盖：
/// 1. 保存失败时不得调用 AI
/// 2. 生成任务绑定 projectId、chapterId、sourcePath
/// 3. 生成成功后暴露候选
/// 4. 拒绝候选后清空当前候选
/// 5. 取消任务进入 cancelled 状态
/// 6. 项目切换后旧任务不可采纳
/// 7. 服务返回版本冲突时不修改编辑器
/// 8. 错误通过映射转为用户可见错误
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/modules/pipeline/book_state.dart';
import 'package:lingbi/modules/pipeline/candidate_service.dart';
import 'package:lingbi/modules/pipeline/generation_context.dart';
import 'package:lingbi/modules/pipeline/novel_application_service.dart';
import 'package:lingbi/modules/pipeline/project_scope_api.dart';
import 'package:lingbi/ui_v2/controllers/editor_ai_coordinator.dart';

// ─── Fake 实现 ─────────────────────────────────────────────────

/// 可控管线 API
class FakePipelineApi implements NovelPipelineApi {
  bool prepareCalled = false;
  bool generateCalled = false;
  bool rejectCalled = false;
  bool adoptCalled = false;

  PipelineResult<ChapterWritePreparation>? prepareResult;
  Stream<PipelineResult<String>>? generateStream;
  List<CandidateEntry> candidates = [];
  PipelineResult<void> rejectResult = const PipelineResult.success(null);
  PipelineResult<String> adoptResult =
      const PipelineResult.success('adopted_content');

  @override
  Future<PipelineResult<ChapterWritePreparation>> prepareChapterWrite({
    required String chapterId,
    String? previousChapterId,
    String userInstruction = '',
  }) async {
    prepareCalled = true;
    return prepareResult ??
        const PipelineResult.failure(
            PipelineError(PipelineError.invalidState, 'no result configured'));
  }

  @override
  Stream<PipelineResult<String>> generateCandidate({
    required String chapterId,
    required dynamic context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  }) {
    generateCalled = true;
    return generateStream ?? const Stream.empty();
  }

  @override
  List<CandidateEntry> listCandidates(String chapterId) => candidates;

  @override
  PipelineResult<void> rejectCandidate(String candidateId, {String? reason}) {
    rejectCalled = true;
    return rejectResult;
  }

  @override
  Future<PipelineResult<String>> adoptCandidate({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) async {
    adoptCalled = true;
    return adoptResult;
  }

  @override
  bool canStartWriting() => true;
}

/// 最小 ProjectScopeApi 替身
class FakeProjectScope implements ProjectScopeApi {
  FakeProjectScope({required this.projectId});

  @override
  final String projectId;

  @override
  String? boundChapterId;

  @override
  String? boundFilePath;

  bool disposed = false;

  // novelService 不会被使用（因为注入了 FakePipelineApi）
  @override
  NovelApplicationService get novelService =>
      throw UnimplementedError('Use FakePipelineApi instead');

  @override
  void bindChapter({required String chapterId, required String filePath}) {
    boundChapterId = chapterId;
    boundFilePath = filePath;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

// ─── 辅助 ─────────────────────────────────────────────────────

PipelineResult<ChapterWritePreparation> _successPreparation() {
  return PipelineResult.success(ChapterWritePreparation(
    context: const GenerationContext(),
    fragments: const [],
    sourceVersion: 'v1-hash',
    bookState: BookState(),
  ));
}

// ─── 测试 ─────────────────────────────────────────────────────

void main() {
  late FakePipelineApi fakeApi;
  late FakeProjectScope fakeScope;
  late bool reloadCalled;

  EditorAiCoordinator createCoordinator({bool saveSuccess = true}) {
    reloadCalled = false;
    return EditorAiCoordinator(
      sessionScope: fakeScope,
      ensureDocumentSaved: () async => saveSuccess,
      reloadDocument: () async {
        reloadCalled = true;
      },
      pipelineApi: fakeApi,
    );
  }

  setUp(() {
    fakeApi = FakePipelineApi();
    fakeScope = FakeProjectScope(projectId: 'proj-1');
  });

  // ─── 测试 1: 保存失败时不得调用 AI ─────────────────────────────

  test('保存失败时不调用 AI 生成', () async {
    final coordinator = createCoordinator(saveSuccess: false);

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );

    expect(fakeApi.prepareCalled, isFalse, reason: '保存失败不应调用 prepare');
    expect(fakeApi.generateCalled, isFalse, reason: '保存失败不应调用 generate');
    expect(coordinator.state, AiCoordinatorState.error);
    expect(coordinator.error, isNotNull);
    expect(coordinator.error!.category, '保存失败');

    coordinator.dispose();
  });

  // ─── 测试 2: 生成任务绑定 projectId、chapterId、sourcePath ─────

  test('生成任务正确绑定项目和章节信息', () async {
    fakeApi.prepareResult = _successPreparation();
    fakeApi.generateStream = Stream.fromIterable([
      const PipelineResult.success('你好'),
      const PipelineResult.success('世界'),
    ]);
    fakeApi.candidates = [
      CandidateEntry(id: 'c1', chapterId: 'ch-1', content: '你好世界'),
    ];

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );

    // 等待流完成
    await Future.delayed(Duration.zero);

    expect(coordinator.activeProjectId, 'proj-1');
    expect(coordinator.activeChapterId, 'ch-1');
    expect(coordinator.activeSourcePath, '/tmp/ch1.md');
    expect(fakeScope.boundChapterId, 'ch-1');
    expect(fakeScope.boundFilePath, '/tmp/ch1.md');

    coordinator.dispose();
  });

  // ─── 测试 3: 生成成功后暴露候选 ───────────────────────────────

  test('生成成功后暴露候选条目', () async {
    fakeApi.prepareResult = _successPreparation();
    fakeApi.generateStream = Stream.fromIterable([
      const PipelineResult.success('生成内容'),
    ]);
    fakeApi.candidates = [
      CandidateEntry(
          id: 'c1',
          chapterId: 'ch-1',
          content: '生成内容'),
    ];

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );

    await Future.delayed(Duration.zero);

    expect(coordinator.state, AiCoordinatorState.candidateReady);
    expect(coordinator.activeCandidate, isNotNull);
    expect(coordinator.activeCandidate!.content, '生成内容');

    coordinator.dispose();
  });

  // ─── 测试 4: 拒绝候选后清空当前候选 ───────────────────────────

  test('拒绝候选后清空状态', () async {
    fakeApi.prepareResult = _successPreparation();
    fakeApi.generateStream =
        Stream.fromIterable([const PipelineResult.success('x')]);
    fakeApi.candidates = [
      CandidateEntry(
          id: 'c1',
          chapterId: 'ch-1',
          content: 'x'),
    ];

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );
    await Future.delayed(Duration.zero);

    expect(coordinator.activeCandidate, isNotNull);

    coordinator.rejectCandidate();

    expect(coordinator.activeCandidate, isNull);
    expect(coordinator.state, AiCoordinatorState.idle);
    expect(fakeApi.rejectCalled, isTrue);

    coordinator.dispose();
  });

  // ─── 测试 5: 取消任务进入 cancelled 状态 ──────────────────────

  test('取消生成进入 cancelled 状态', () async {
    fakeApi.prepareResult = _successPreparation();
    final controller = StreamController<PipelineResult<String>>();
    fakeApi.generateStream = controller.stream;

    final coordinator = createCoordinator();

    // 不 await，让生成在后台运行
    unawaited(coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    ));

    // 等待进入 generating 状态
    await Future.delayed(const Duration(milliseconds: 50));

    coordinator.cancel();

    expect(coordinator.state, AiCoordinatorState.cancelled);
    expect(coordinator.streamingContent, isEmpty);

    await controller.close();
    coordinator.dispose();
  });

  // ─── 测试 6: 项目切换后旧任务不可采纳 ─────────────────────────

  test('项目切换后旧候选不可采纳', () async {
    fakeApi.prepareResult = _successPreparation();
    fakeApi.generateStream =
        Stream.fromIterable([const PipelineResult.success('x')]);
    fakeApi.candidates = [
      CandidateEntry(
          id: 'c1',
          chapterId: 'ch-1',
          content: 'x'),
    ];

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );
    await Future.delayed(Duration.zero);

    // 切换到新项目
    final newScope = FakeProjectScope(projectId: 'proj-2');
    coordinator.switchProject(newScope, pipelineApi: fakeApi);

    expect(coordinator.activeCandidate, isNull);
    expect(coordinator.state, AiCoordinatorState.idle);
    expect(coordinator.activeProjectId, isNull);

    coordinator.dispose();
  });

  // ─── 测试 7: 版本冲突时不修改编辑器 ───────────────────────────

  test('整章采纳遇到版本冲突不修改编辑器', () async {
    fakeApi.prepareResult = _successPreparation();
    fakeApi.generateStream =
        Stream.fromIterable([const PipelineResult.success('x')]);
    fakeApi.candidates = [
      CandidateEntry(
          id: 'c1',
          chapterId: 'ch-1',
          content: 'x'),
    ];
    fakeApi.adoptResult = const PipelineResult.failure(PipelineError(
      PipelineError.sourceVersionConflict,
      '源章节在候选生成后被修改',
    ));

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );
    await Future.delayed(Duration.zero);

    // 绑定章节
    fakeScope.bindChapter(chapterId: 'ch-1', filePath: '/tmp/ch1.md');

    final result = await coordinator.adoptWholeDocument();

    expect(result.isFailure, isTrue);
    expect(result.error!.code, PipelineError.sourceVersionConflict);
    expect(reloadCalled, isFalse, reason: '版本冲突不应重新加载编辑器');
    expect(coordinator.state, AiCoordinatorState.error);
    expect(coordinator.error!.category, '版本冲突');

    coordinator.dispose();
  });

  // ─── 测试 8: 错误映射为用户可见错误 ───────────────────────────

  test('AI 错误映射为用户可理解的中文提示', () async {
    fakeApi.prepareResult = const PipelineResult.failure(PipelineError(
      PipelineError.aiError,
      'AI 生成失败: connection timeout',
    ));

    final coordinator = createCoordinator();

    await coordinator.generate(
      projectId: 'proj-1',
      chapterId: 'ch-1',
      sourcePath: '/tmp/ch1.md',
      instruction: '续写',
    );

    expect(coordinator.state, AiCoordinatorState.error);
    expect(coordinator.error, isNotNull);
    expect(coordinator.error!.category, 'AI 错误');
    expect(coordinator.error!.userHint, contains('重试'));

    coordinator.dispose();
  });
}
