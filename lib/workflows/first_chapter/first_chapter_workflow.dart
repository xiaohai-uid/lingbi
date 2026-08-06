import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/shared/errors/ai_error.dart';
import 'first_chapter_event.dart';
import 'first_chapter_state_store.dart';

class FirstChapterPreparation {
  const FirstChapterPreparation({required this.sourceVersion, this.payload});
  final String sourceVersion;
  final Object? payload;
}

class FirstChapterCandidate {
  const FirstChapterCandidate({required this.id, required this.content});
  final String id;
  final String content;
}

class AdoptionResult {
  const AdoptionResult.success(this.targetFilePath)
      : isSuccess = true,
        code = null,
        message = '已安全采纳';
  const AdoptionResult.failure({required this.code, required this.message})
      : isSuccess = false,
        targetFilePath = null;

  final bool isSuccess;
  final String? targetFilePath;
  final String? code;
  final String message;
}

abstract interface class FirstChapterPipeline {
  Future<FirstChapterPreparation> prepare(FirstChapterRequest request);
  Stream<String> generate(
    FirstChapterRequest request,
    FirstChapterPreparation preparation,
  );
  Future<FirstChapterCandidate> latestCandidate(String chapterId);
  Future<AdoptionResult> adopt({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  });
  Future<void> reject(String candidateId);
  Future<void> cancel();
}

abstract interface class FirstChapterWorkflow {
  Stream<FirstChapterEvent> start(FirstChapterRequest request);
  Future<AdoptionResult> adopt(String candidateId);
  Future<void> reject(String candidateId);
  Future<FirstChapterState?> resume(String projectId);
  Future<void> cancel();
}

class FirstChapterWorkflowController implements FirstChapterWorkflow {
  FirstChapterWorkflowController({
    required FirstChapterPipeline pipeline,
    required FirstChapterStateStore stateStore,
  })  : _pipeline = pipeline,
        _stateStore = stateStore;

  final FirstChapterPipeline _pipeline;
  final FirstChapterStateStore _stateStore;
  FirstChapterState? _state;
  bool _cancelRequested = false;

  @override
  Stream<FirstChapterEvent> start(FirstChapterRequest request) async* {
    _cancelRequested = false;
    try {
      _state = FirstChapterState(
        projectId: request.projectId,
        chapterId: request.chapterId,
        targetFilePath: request.targetFilePath,
        stage: FirstChapterStage.readingAssets,
        updatedAt: DateTime.now().toUtc(),
      );
      await _stateStore.write(_state!);
      yield const FirstChapterEvent(
        stage: FirstChapterStage.readingAssets,
        message: '正在读取项目资产',
      );

      final preparation = await _pipeline.prepare(request);
      if (_cancelRequested) return;
      _state = _state!.copyWith(
        stage: FirstChapterStage.generating,
        sourceVersion: preparation.sourceVersion,
        clearError: true,
      );
      await _stateStore.write(_state!);
      yield const FirstChapterEvent(
        stage: FirstChapterStage.generating,
        message: '正在生成候选稿',
      );

      await for (final chunk in _pipeline.generate(request, preparation)) {
        if (_cancelRequested) return;
        yield FirstChapterEvent(
          stage: FirstChapterStage.generating,
          message: '正在生成候选稿',
          contentChunk: chunk,
        );
      }
      if (_cancelRequested) return;
      final candidate = await _pipeline.latestCandidate(request.chapterId);
      _state = _state!.copyWith(
        stage: FirstChapterStage.candidateReady,
        candidateId: candidate.id,
        candidateContent: candidate.content,
      );
      await _stateStore.write(_state!);
      yield FirstChapterEvent(
        stage: FirstChapterStage.candidateReady,
        message: '候选稿已生成',
        candidateId: candidate.id,
      );

      _state = _state!.copyWith(
        stage: FirstChapterStage.waitingForConfirmation,
      );
      await _stateStore.write(_state!);
      yield FirstChapterEvent(
        stage: FirstChapterStage.waitingForConfirmation,
        message: '等待作者确认',
        candidateId: candidate.id,
      );
    } catch (error) {
      final mapped = AiErrorMapper.map(error);
      final failed = (_state ??
              FirstChapterState(
                projectId: request.projectId,
                chapterId: request.chapterId,
                targetFilePath: request.targetFilePath,
                stage: FirstChapterStage.failed,
                updatedAt: DateTime.now().toUtc(),
              ))
          .copyWith(stage: FirstChapterStage.failed, error: mapped.userHint);
      _state = failed;
      try {
        await _stateStore.write(failed);
      } catch (_) {}
      yield FirstChapterEvent(
        stage: FirstChapterStage.failed,
        message: mapped.userHint,
      );
    }
  }

  @override
  Future<AdoptionResult> adopt(String candidateId) async {
    final state = _state;
    if (state == null || state.candidateId != candidateId) {
      return const AdoptionResult.failure(
        code: 'INVALID_STATE',
        message: '候选稿不存在或已过期',
      );
    }
    final writing = state.copyWith(
      stage: FirstChapterStage.writing,
      clearError: true,
    );
    await _stateStore.write(writing);
    _state = writing;
    final result = await _pipeline.adopt(
      candidateId: candidateId,
      chapterId: state.chapterId,
      targetFilePath: state.targetFilePath,
    );
    if (!result.isSuccess) {
      _state = state.copyWith(
        stage: FirstChapterStage.waitingForConfirmation,
        error: result.message,
      );
      await _stateStore.write(_state!);
      return result;
    }
    _state = writing.copyWith(stage: FirstChapterStage.completed);
    await _stateStore.write(_state!);
    return result;
  }

  @override
  Future<void> reject(String candidateId) async {
    final state = _state;
    if (state == null || state.candidateId != candidateId) return;
    await _pipeline.reject(candidateId);
    _state = state.copyWith(stage: FirstChapterStage.rejected);
    await _stateStore.write(_state!);
  }

  @override
  Future<FirstChapterState?> resume(String projectId) async {
    _state = await _stateStore.read(projectId);
    return _state;
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    await _pipeline.cancel();
    if (_state != null) {
      _state = _state!.copyWith(stage: FirstChapterStage.cancelled);
      await _stateStore.write(_state!);
    }
  }
}

class NovelFirstChapterPipeline implements FirstChapterPipeline {
  NovelFirstChapterPipeline(this._application);
  final NovelApplicationService _application;

  @override
  Future<FirstChapterPreparation> prepare(FirstChapterRequest request) async {
    final result = await _application.prepareChapterWrite(
      chapterId: request.chapterId,
      previousChapterId: request.previousChapterId,
      userInstruction: request.instruction,
    );
    if (result.isFailure) throw StateError(result.error!.message);
    return FirstChapterPreparation(
      sourceVersion: result.data!.sourceVersion,
      payload: result.data,
    );
  }

  @override
  Stream<String> generate(
    FirstChapterRequest request,
    FirstChapterPreparation preparation,
  ) async* {
    final prepared = preparation.payload as ChapterWritePreparation?;
    if (prepared == null) throw StateError('缺少已准备的上下文');
    await for (final result in _application.generateCandidate(
      chapterId: request.chapterId,
      context: prepared.context,
      sourceVersion: preparation.sourceVersion,
    )) {
      if (result.isFailure) throw StateError(result.error!.message);
      yield result.data!;
    }
  }

  @override
  Future<FirstChapterCandidate> latestCandidate(String chapterId) async {
    final candidates = _application.listCandidates(chapterId)
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    if (candidates.isEmpty) throw StateError('生成完成但未找到候选稿');
    return FirstChapterCandidate(
      id: candidates.first.id,
      content: candidates.first.content,
    );
  }

  @override
  Future<AdoptionResult> adopt({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) async {
    final result = await _application.adoptCandidate(
      candidateId: candidateId,
      chapterId: chapterId,
      targetFilePath: targetFilePath,
    );
    if (result.isSuccess) return AdoptionResult.success(result.data!);
    return AdoptionResult.failure(
      code: result.error!.code,
      message: result.error!.message,
    );
  }

  @override
  Future<void> reject(String candidateId) async {
    final result = _application.rejectCandidate(candidateId);
    if (result.isFailure) throw StateError(result.error!.message);
  }

  @override
  Future<void> cancel() async => _application.cancelGeneration();
}
