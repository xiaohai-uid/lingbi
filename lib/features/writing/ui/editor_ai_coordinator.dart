/// 编辑器 AI 协调层
///
/// 负责 UI 状态协调，不负责：
/// - 自己保存候选文件
/// - 自己写 Markdown
/// - 自己创建快照
/// - 自己实现版本冲突检测
///
/// 这些行为继续由 NovelApplicationService 完成。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lingbi/shared/errors/ai_error.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/features/writing/data/pipeline/project_scope_api.dart';

/// 管线 API 抽象（NovelApplicationService 隐式满足）
///
/// 用于测试时注入受控响应。
abstract class NovelPipelineApi {
  Future<PipelineResult<ChapterWritePreparation>> prepareChapterWrite({
    required String chapterId,
    String? previousChapterId,
    String userInstruction = '',
  });

  Stream<PipelineResult<String>> generateCandidate({
    required String chapterId,
    required dynamic context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  });

  List<CandidateEntry> listCandidates(String chapterId);

  PipelineResult<void> rejectCandidate(String candidateId, {String? reason});

  Future<PipelineResult<String>> adoptCandidate({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  });

  bool canStartWriting();
}

/// 候选应用模式
enum CandidateApplyMode {
  /// 插入光标处（编辑器内存操作）
  insertAtCursor,

  /// 替换当前选区（编辑器内存操作）
  replaceSelection,

  /// 追加到章节末尾（编辑器内存操作）
  appendToDocument,

  /// 整章替换（文件级安全操作，走 NovelApplicationService）
  replaceWholeDocument,
}

/// AI 写作协调状态
enum AiCoordinatorState {
  /// 空闲，可发起生成
  idle,

  /// 正在准备上下文
  preparing,

  /// 正在生成
  generating,

  /// 候选就绪，等待用户决策
  candidateReady,

  /// 已取消
  cancelled,

  /// 出错
  error,
}

/// 用户可见的 AI 错误
class AiUiError {
  const AiUiError({
    required this.category,
    required this.message,
    required this.userHint,
    this.recoveryAction,
    this.contentPreserved = false,
  });

  /// 错误类别
  final String category;

  /// 技术错误信息
  final String message;

  /// 用户可理解的中文说明
  final String userHint;

  /// 建议恢复操作
  final RecoveryAction? recoveryAction;

  /// 已生成内容是否保留
  final bool contentPreserved;
}

/// 编辑器 AI 协调器
///
/// 项目级实例，由 EditorPage 持有。
/// 协调 NovelApplicationService 与 UI 状态之间的交互。
class EditorAiCoordinator extends ChangeNotifier {
  EditorAiCoordinator({
    required ProjectScopeApi sessionScope,
    required Future<bool> Function() ensureDocumentSaved,
    required Future<void> Function() reloadDocument,
    NovelPipelineApi? pipelineApi,
  })  : _sessionScope = sessionScope,
        _ensureDocumentSaved = ensureDocumentSaved,
        _reloadDocument = reloadDocument,
        _pipelineApi = pipelineApi ?? _RealPipelineApi(sessionScope.novelService);

  ProjectScopeApi _sessionScope;
  final Future<bool> Function() _ensureDocumentSaved;
  final Future<void> Function() _reloadDocument;
  NovelPipelineApi _pipelineApi;

  // ─── 状态 ─────────────────────────────────────────────────────

  AiCoordinatorState _state = AiCoordinatorState.idle;
  CandidateEntry? _activeCandidate;
  AiUiError? _error;
  String _streamingContent = '';
  String? _activeProjectId;
  String? _activeChapterId;
  String? _activeSourcePath;
  StreamSubscription<PipelineResult<String>>? _streamSubscription;

  /// 最近一次生成的参数（用于重试）
  _GenerateRequest? _lastRequest;

  // ─── Getters ──────────────────────────────────────────────────

  AiCoordinatorState get state => _state;
  CandidateEntry? get activeCandidate => _activeCandidate;
  AiUiError? get error => _error;
  String get streamingContent => _streamingContent;
  bool get isGenerating =>
      _state == AiCoordinatorState.generating ||
      _state == AiCoordinatorState.preparing;
  bool get isIdle => _state == AiCoordinatorState.idle;
  String? get activeProjectId => _activeProjectId;
  String? get activeChapterId => _activeChapterId;
  String? get activeSourcePath => _activeSourcePath;

  /// 当前项目会话
  ProjectScopeApi get sessionScope => _sessionScope;

  /// 底层 NovelApplicationService
  NovelApplicationService get novelService => _sessionScope.novelService;

  // ─── 项目切换 ─────────────────────────────────────────────────

  /// 切换到新的项目会话
  ///
  /// 取消旧任务，解绑旧状态，不删除已落盘候选。
  void switchProject(ProjectScopeApi newScope, {NovelPipelineApi? pipelineApi}) {
    _cancelStream();
    _sessionScope = newScope;
    _pipelineApi = pipelineApi ?? _RealPipelineApi(newScope.novelService);
    _state = AiCoordinatorState.idle;
    _activeCandidate = null;
    _error = null;
    _streamingContent = '';
    _activeProjectId = null;
    _activeChapterId = null;
    _activeSourcePath = null;
    _lastRequest = null;
    notifyListeners();
  }

  // ─── 核心操作 ─────────────────────────────────────────────────

  /// 发起 AI 生成
  ///
  /// 流程：确保文档已保存 → 准备上下文 → 流式生成 → 暴露候选
  Future<void> generate({
    required String projectId,
    required String chapterId,
    required String sourcePath,
    required String instruction,
    String? skillId,
    Map<String, Object?> parameters = const {},
  }) async {
    // 保存请求参数（用于重试）
    _lastRequest = _GenerateRequest(
      projectId: projectId,
      chapterId: chapterId,
      sourcePath: sourcePath,
      instruction: instruction,
      skillId: skillId,
      parameters: parameters,
    );

    // 1. 确保文档已保存
    _state = AiCoordinatorState.preparing;
    _error = null;
    _streamingContent = '';
    notifyListeners();

    final saved = await _ensureDocumentSaved();
    if (!saved) {
      _state = AiCoordinatorState.error;
      _error = const AiUiError(
        category: '保存失败',
        message: 'Document save failed before generation',
        userHint: '文档保存失败，无法基于过期内容生成。请先解决保存问题。',
      );
      notifyListeners();
      return;
    }

    // 2. 准备章节写作上下文
    final prepResult = await _pipelineApi.prepareChapterWrite(
      chapterId: chapterId,
      userInstruction: instruction,
    );

    if (prepResult.isFailure) {
      _state = AiCoordinatorState.error;
      _error = _mapPipelineError(prepResult.error!);
      notifyListeners();
      return;
    }

    final preparation = prepResult.data!;

    // 3. 绑定任务信息
    _activeProjectId = projectId;
    _activeChapterId = chapterId;
    _activeSourcePath = sourcePath;
    _sessionScope.bindChapter(chapterId: chapterId, filePath: sourcePath);

    // 4. 流式生成
    _state = AiCoordinatorState.generating;
    notifyListeners();

    final buffer = StringBuffer();
    final stream = _pipelineApi.generateCandidate(
      chapterId: chapterId,
      context: preparation.context,
      sourceVersion: preparation.sourceVersion,
    );

    _streamSubscription = stream.listen(
      (result) {
        if (result.isSuccess && result.data != null) {
          buffer.write(result.data);
          _streamingContent = buffer.toString();
          notifyListeners();
        } else if (result.isFailure) {
          _state = AiCoordinatorState.error;
          _error = _mapPipelineError(result.error!);
          notifyListeners();
        }
      },
      onDone: () {
        _streamSubscription = null;
        if (_state == AiCoordinatorState.generating) {
          // 生成完成，获取候选
          _loadLatestCandidate(chapterId);
        }
      },
      onError: (Object e) {
        _streamSubscription = null;
        _state = AiCoordinatorState.error;
        _error = AiUiError(
          category: '生成错误',
          message: e.toString(),
          userHint: '生成过程中发生错误：$e',
        );
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  /// 拒绝/丢弃当前候选
  void rejectCandidate() {
    final candidate = _activeCandidate;
    if (candidate != null) {
      _pipelineApi.rejectCandidate(candidate.id, reason: 'user_rejected');
    }
    _activeCandidate = null;
    _state = AiCoordinatorState.idle;
    _streamingContent = '';
    notifyListeners();
  }

  /// 整章采纳（文件级安全操作）
  ///
  /// 仅用于 [CandidateApplyMode.replaceWholeDocument]。
  /// 执行写锁、版本检查、快照和原子替换。
  Future<PipelineResult<String>> adoptWholeDocument() async {
    final candidate = _activeCandidate;
    if (candidate == null) {
      return const PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '无活跃候选',
      ));
    }

    // 验证项目/章节匹配
    if (_activeProjectId != _sessionScope.projectId ||
        _activeChapterId != _sessionScope.boundChapterId) {
      return const PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '项目或章节已切换，无法采纳旧候选',
      ));
    }

    final targetPath = _sessionScope.boundFilePath;
    if (targetPath == null) {
      return const PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '未绑定章节文件路径',
      ));
    }

    final result = await _pipelineApi.adoptCandidate(
      candidateId: candidate.id,
      chapterId: candidate.chapterId,
      targetFilePath: targetPath,
    );

    if (result.isSuccess) {
      _activeCandidate = null;
      _state = AiCoordinatorState.idle;
      _streamingContent = '';
      // 重新加载编辑器内容
      await _reloadDocument();
    } else {
      _error = _mapPipelineError(result.error!);
      _state = AiCoordinatorState.error;
    }
    notifyListeners();
    return result;
  }

  /// 重试上次生成
  Future<void> retry() async {
    final request = _lastRequest;
    if (request == null) return;
    await generate(
      projectId: request.projectId,
      chapterId: request.chapterId,
      sourcePath: request.sourcePath,
      instruction: request.instruction,
      skillId: request.skillId,
      parameters: request.parameters,
    );
  }

  /// 取消当前生成
  void cancel() {
    _cancelStream();
    _state = AiCoordinatorState.cancelled;
    _streamingContent = '';
    notifyListeners();
  }

  /// 恢复未处理候选（重启后调用）
  void restorePendingCandidates(String chapterId) {
    final candidates = _pipelineApi.listCandidates(chapterId);
    final pending = candidates
        .where((c) => c.status == CandidateStatus.pending)
        .toList();
    if (pending.isNotEmpty) {
      _activeCandidate = pending.first;
      _activeChapterId = chapterId;
      _activeProjectId = _sessionScope.projectId;
      _state = AiCoordinatorState.candidateReady;
      notifyListeners();
    }
  }

  /// 释放资源
  void disposeProjectSession() {
    _cancelStream();
    _sessionScope.dispose();
  }

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }

  // ─── 内部方法 ─────────────────────────────────────────────────

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  void _loadLatestCandidate(String chapterId) {
    final candidates = _pipelineApi.listCandidates(chapterId);
    if (candidates.isNotEmpty) {
      // 取最新的 pending 候选
      final pending = candidates
          .where((c) => c.status == CandidateStatus.pending)
          .toList();
      if (pending.isNotEmpty) {
        _activeCandidate = pending.first;
        _state = AiCoordinatorState.candidateReady;
      } else {
        _state = AiCoordinatorState.idle;
      }
    } else {
      _state = AiCoordinatorState.idle;
    }
    notifyListeners();
  }

  AiUiError _mapPipelineError(PipelineError error) {
    switch (error.code) {
      case PipelineError.sourceVersionConflict:
        return AiUiError(
          category: '版本冲突',
          message: error.message,
          userHint: '章节在生成后被修改，候选基于旧版本。请重新生成或手动合并。',
          contentPreserved: true,
        );
      case PipelineError.projectBusy:
        return AiUiError(
          category: '项目忙碌',
          message: error.message,
          userHint: '项目正在处理其他操作，请稍后重试。',
        );
      case PipelineError.aiError:
        return AiUiError(
          category: 'AI 错误',
          message: error.message,
          userHint: 'AI 生成失败，请检查网络连接和 API Key 后重试。',
          recoveryAction: RecoveryAction.retry,
        );
      default:
        return AiUiError(
          category: '操作失败',
          message: error.message,
          userHint: error.message,
        );
    }
  }
}

/// 生成请求参数（用于重试）
class _GenerateRequest {
  const _GenerateRequest({
    required this.projectId,
    required this.chapterId,
    required this.sourcePath,
    required this.instruction,
    this.skillId,
    this.parameters = const {},
  });

  final String projectId;
  final String chapterId;
  final String sourcePath;
  final String instruction;
  final String? skillId;
  final Map<String, Object?> parameters;
}

/// 真实管线 API 实现（委托给 NovelApplicationService）
class _RealPipelineApi implements NovelPipelineApi {
  _RealPipelineApi(this._service);

  final NovelApplicationService _service;

  @override
  Future<PipelineResult<ChapterWritePreparation>> prepareChapterWrite({
    required String chapterId,
    String? previousChapterId,
    String userInstruction = '',
  }) =>
      _service.prepareChapterWrite(
        chapterId: chapterId,
        previousChapterId: previousChapterId,
        userInstruction: userInstruction,
      );

  @override
  Stream<PipelineResult<String>> generateCandidate({
    required String chapterId,
    required dynamic context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  }) =>
      _service.generateCandidate(
        chapterId: chapterId,
        context: context,
        sourceVersion: sourceVersion,
        temperature: temperature,
        maxTokens: maxTokens,
      );

  @override
  List<CandidateEntry> listCandidates(String chapterId) =>
      _service.listCandidates(chapterId);

  @override
  PipelineResult<void> rejectCandidate(String candidateId, {String? reason}) =>
      _service.rejectCandidate(candidateId, reason: reason);

  @override
  Future<PipelineResult<String>> adoptCandidate({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) =>
      _service.adoptCandidate(
        candidateId: candidateId,
        chapterId: chapterId,
        targetFilePath: targetFilePath,
      );

  @override
  bool canStartWriting() => _service.canStartWriting();
}
