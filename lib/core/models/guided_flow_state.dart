/// 引导流程运行时状态 — 支持暂停/恢复
///
/// 持久化到 project_meta/guided_flow_state.json
library;

/// 流程运行状态
enum GuidedFlowStatus {
  /// 尚未开始
  notStarted,

  /// 正在进行中
  inProgress,

  /// 用户主动暂停
  paused,

  /// 全部步骤完成
  completed;

  static GuidedFlowStatus fromString(String value) {
    switch (value) {
      case 'inProgress':
        return GuidedFlowStatus.inProgress;
      case 'paused':
        return GuidedFlowStatus.paused;
      case 'completed':
        return GuidedFlowStatus.completed;
      default:
        return GuidedFlowStatus.notStarted;
    }
  }

  String get value => name;
}

/// 引导流程运行时状态
class GuidedFlowState {
  GuidedFlowState({
    required this.flowId,
    required this.projectId,
    this.currentStepIndex = 0,
    this.status = GuidedFlowStatus.notStarted,
    this.conversationHistory = const [],
    Map<String, String>? stepOutputs,
    DateTime? startedAt,
    DateTime? updatedAt,
  })  : stepOutputs = stepOutputs ?? {},
        startedAt = startedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory GuidedFlowState.fromJson(Map<String, dynamic> json) {
    return GuidedFlowState(
      flowId: json['flowId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      status: GuidedFlowStatus.fromString(
          json['status'] as String? ?? 'notStarted'),
      conversationHistory: (json['conversationHistory'] as List<dynamic>?)
              ?.map((e) => ConversationTurn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stepOutputs: (json['stepOutputs'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 关联的流程定义 ID
  final String flowId;

  /// 关联的项目 ID
  final String projectId;

  /// 当前步骤索引（0-based）
  int currentStepIndex;

  /// 流程状态
  GuidedFlowStatus status;

  /// 当前步骤的对话历史（用于 AI 上下文）
  List<ConversationTurn> conversationHistory;

  /// 已完成步骤的产出摘要（stepId -> summary）
  Map<String, String> stepOutputs;

  /// 开始时间
  final DateTime startedAt;

  /// 最后更新时间
  DateTime updatedAt;

  /// 是否已完成
  bool get isCompleted => status == GuidedFlowStatus.completed;

  /// 是否处于活跃状态（进行中或暂停）
  bool get isActive =>
      status == GuidedFlowStatus.inProgress || status == GuidedFlowStatus.paused;

  /// 标记为进行中
  void markInProgress() {
    status = GuidedFlowStatus.inProgress;
    updatedAt = DateTime.now();
  }

  /// 暂停
  void pause() {
    status = GuidedFlowStatus.paused;
    updatedAt = DateTime.now();
  }

  /// 恢复
  void resume() {
    status = GuidedFlowStatus.inProgress;
    updatedAt = DateTime.now();
  }

  /// 推进到下一步
  void advanceToNextStep() {
    currentStepIndex++;
    conversationHistory = [];
    updatedAt = DateTime.now();
  }

  /// 标记完成
  void markCompleted() {
    status = GuidedFlowStatus.completed;
    updatedAt = DateTime.now();
  }

  /// 添加对话记录
  void addConversationTurn(ConversationTurn turn) {
    conversationHistory = [...conversationHistory, turn];
    updatedAt = DateTime.now();
  }

  /// 清空当前步骤对话（步骤切换时）
  void clearConversation() {
    conversationHistory = [];
  }

  Map<String, dynamic> toJson() => {
        'flowId': flowId,
        'projectId': projectId,
        'currentStepIndex': currentStepIndex,
        'status': status.value,
        'conversationHistory':
            conversationHistory.map((t) => t.toJson()).toList(),
        'stepOutputs': stepOutputs,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// 单轮对话记录
class ConversationTurn {
  const ConversationTurn({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    return ConversationTurn(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }

  /// 角色：user / assistant
  final String role;

  /// 内容
  final String content;

  /// 时间戳
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}
