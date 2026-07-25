/// 写作流水线状态机
///
/// 借鉴 OpenWrite BookStage + WorkflowScheduler 设计思想。
/// 管理章节从预检到结算的完整生命周期。
library;

/// 写作流水线阶段
enum PipelineStage {
  /// 空闲，等待用户指令
  idle,

  /// 预检：组装 Context Packet，验证前置条件
  preflight,

  /// AI 正在生成候选正文
  writing,

  /// 审稿 Agent 评估候选
  reviewing,

  /// 等待作者采纳/拒绝
  awaitingAdoption,

  /// 作者已采纳，候选成为正文
  adopted,

  /// 作者拒绝，候选归档
  rejected,

  /// 提取事实，更新运行态
  settling,

  /// 结算完成
  settled,

  /// 回滚到写前快照
  rollback,

  /// 出错
  error,
}

/// 章节工作流记录
class ChapterWorkflow {
  ChapterWorkflow({
    required this.chapterId,
    this.currentStage = PipelineStage.idle,
    this.stages = const [],
    this.error,
    this.createdAt,
    this.updatedAt,
  });

  factory ChapterWorkflow.fromJson(Map<String, dynamic> json) =>
      ChapterWorkflow(
        chapterId: json['chapter_id'] as String? ?? '',
        currentStage: PipelineStage.values.firstWhere(
          (s) => s.name == json['current_stage'],
          orElse: () => PipelineStage.idle,
        ),
        stages: (json['stages'] as List? ?? [])
            .map((s) => StageRecord.fromJson(s as Map<String, dynamic>))
            .toList(),
        error: json['error'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  final String chapterId;
  PipelineStage currentStage;
  List<StageRecord> stages;
  String? error;
  DateTime? createdAt;
  DateTime? updatedAt;

  /// 推进到下一阶段
  void advanceTo(PipelineStage next, {String? message}) {
    stages = [
      ...stages,
      StageRecord(
        stage: currentStage,
        status: StageStatus.completed,
        message: message ?? '',
        timestamp: DateTime.now(),
      ),
    ];
    currentStage = next;
    updatedAt = DateTime.now();
  }

  /// 标记失败
  void fail(String errorMessage) {
    currentStage = PipelineStage.error;
    error = errorMessage;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'current_stage': currentStage.name,
        'stages': stages.map((s) => s.toJson()).toList(),
        if (error != null) 'error': error,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// 阶段执行记录
class StageRecord {
  const StageRecord({
    required this.stage,
    required this.status,
    this.message = '',
    this.data = const {},
    required this.timestamp,
  });

  factory StageRecord.fromJson(Map<String, dynamic> json) => StageRecord(
        stage: PipelineStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => PipelineStage.idle,
        ),
        status: StageStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => StageStatus.pending,
        ),
        message: json['message'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        timestamp: DateTime.parse(json['timestamp'] as String? ?? ''),
      );

  final PipelineStage stage;
  final StageStatus status;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'status': status.name,
        'message': message,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 阶段状态
enum StageStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}

/// 写作流水线状态机
///
/// 管理单本书的写作流水线状态转换。
/// 合法转换：
/// idle → preflight → writing → reviewing → awaitingAdoption
/// awaitingAdoption → adopted → settling → settled → idle
/// awaitingAdoption → rejected → idle
/// 任何阶段 → rollback → idle
/// 任何阶段 → error → idle
class WritingPipelineStateMachine {
  WritingPipelineStateMachine({required this.projectDir});

  final String projectDir;

  /// 当前活跃工作流（同一时间只允许一个）
  ChapterWorkflow? _activeWorkflow;

  ChapterWorkflow? get activeWorkflow => _activeWorkflow;

  /// 是否空闲
  bool get isIdle => _activeWorkflow == null;

  /// 是否忙碌
  bool get isBusy => _activeWorkflow != null;

  /// 合法状态转换表
  static const Map<PipelineStage, List<PipelineStage>> _transitions = {
    PipelineStage.idle: [PipelineStage.preflight],
    PipelineStage.preflight: [
      PipelineStage.writing,
      PipelineStage.rollback,
      PipelineStage.error,
    ],
    PipelineStage.writing: [
      PipelineStage.reviewing,
      PipelineStage.rollback,
      PipelineStage.error,
    ],
    PipelineStage.reviewing: [
      PipelineStage.awaitingAdoption,
      PipelineStage.rollback,
      PipelineStage.error,
    ],
    PipelineStage.awaitingAdoption: [
      PipelineStage.adopted,
      PipelineStage.rejected,
      PipelineStage.error,
    ],
    PipelineStage.adopted: [
      PipelineStage.settling,
      PipelineStage.error,
    ],
    PipelineStage.settling: [
      PipelineStage.settled,
      PipelineStage.error,
    ],
    PipelineStage.settled: [PipelineStage.idle],
    PipelineStage.rejected: [PipelineStage.idle],
    PipelineStage.rollback: [PipelineStage.idle],
    PipelineStage.error: [PipelineStage.idle],
  };

  /// 检查转换是否合法
  bool canTransition(PipelineStage from, PipelineStage to) {
    return _transitions[from]?.contains(to) ?? false;
  }

  /// 开始新的写作工作流
  ChapterWorkflow startWorkflow(String chapterId) {
    if (isBusy) {
      throw StateError(
        '已有写作任务正在运行: ${_activeWorkflow!.chapterId} '
        '(阶段: ${_activeWorkflow!.currentStage.name})',
      );
    }
    _activeWorkflow = ChapterWorkflow(
      chapterId: chapterId,
      currentStage: PipelineStage.preflight,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _activeWorkflow!;
  }

  /// 推进到下一阶段
  void advance(PipelineStage next, {String? message}) {
    final workflow = _activeWorkflow;
    if (workflow == null) {
      throw StateError('没有活跃的写作工作流');
    }
    if (!canTransition(workflow.currentStage, next)) {
      throw StateError(
        '非法状态转换: ${workflow.currentStage.name} → ${next.name}',
      );
    }
    workflow.advanceTo(next, message: message);

    // 终态清理
    if (next == PipelineStage.idle) {
      _activeWorkflow = null;
    }
  }

  /// 标记失败并回滚
  void failAndRollback(String errorMessage) {
    final workflow = _activeWorkflow;
    if (workflow == null) return;
    workflow.fail(errorMessage);
    _activeWorkflow = null;
  }

  /// 完成工作流（settled → idle）
  void complete() {
    advance(PipelineStage.idle, message: 'workflow completed');
  }
}
