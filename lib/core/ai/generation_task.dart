/// 生成任务模型
///
/// 每个 AI 生成任务绑定到具体的项目、章节、源文件和唯一任务 ID。
/// 项目或章节切换时，通过 taskId 和绑定信息确保候选不写入错误文档。
library;

/// 生成任务状态
enum GenerationTaskStatus {
  /// 已创建，等待执行
  pending,

  /// 正在生成中
  generating,

  /// 生成完成，候选已就绪
  completed,

  /// 用户取消
  cancelled,

  /// 生成失败
  failed,

  /// 候选已采纳
  adopted,

  /// 候选已丢弃
  discarded,
}

/// 生成任务 — 绑定生成请求与目标文档
class GenerationTask {
  GenerationTask({
    required this.taskId,
    required this.projectId,
    required this.chapterId,
    required this.sourcePath,
    required this.sourceHash,
    this.skillId = '',
    this.userInstruction = '',
    this.status = GenerationTaskStatus.pending,
    this.candidateId,
    this.partialContent = '',
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  /// 唯一任务 ID
  final String taskId;

  /// 绑定的项目 ID
  final String projectId;

  /// 绑定的章节 ID
  final String chapterId;

  /// 源文件路径（生成时的章节文件）
  final String sourcePath;

  /// 源文件哈希（生成时的内容快照，用于冲突检测）
  final String sourceHash;

  /// 触发此任务的技能 ID（空表示自由对话）
  final String skillId;

  /// 用户指令
  final String userInstruction;

  /// 当前状态
  GenerationTaskStatus status;

  /// 关联的候选 ID（生成完成后填入）
  String? candidateId;

  /// 部分生成内容（取消时保留）
  String partialContent;

  /// 错误信息
  String? errorMessage;

  /// 创建时间
  DateTime? createdAt;

  /// 更新时间
  DateTime? updatedAt;

  /// 是否仍在活跃状态（未完成/未取消/未失败）
  bool get isActive =>
      status == GenerationTaskStatus.pending ||
      status == GenerationTaskStatus.generating;

  /// 是否可取消
  bool get isCancellable => status == GenerationTaskStatus.generating;

  /// 检查任务是否仍绑定到指定项目和章节
  bool isBoundTo({required String projectId, required String chapterId}) {
    return this.projectId == projectId && this.chapterId == chapterId;
  }

  /// 标记为生成中
  void markGenerating() {
    status = GenerationTaskStatus.generating;
    updatedAt = DateTime.now();
  }

  /// 标记为完成
  void markCompleted(String candidateId) {
    status = GenerationTaskStatus.completed;
    this.candidateId = candidateId;
    updatedAt = DateTime.now();
  }

  /// 标记为取消（保留部分内容）
  void markCancelled({String partial = ''}) {
    status = GenerationTaskStatus.cancelled;
    if (partial.isNotEmpty) partialContent = partial;
    updatedAt = DateTime.now();
  }

  /// 标记为失败
  void markFailed(String error) {
    status = GenerationTaskStatus.failed;
    errorMessage = error;
    updatedAt = DateTime.now();
  }

  /// 标记为已采纳
  void markAdopted() {
    status = GenerationTaskStatus.adopted;
    updatedAt = DateTime.now();
  }

  /// 标记为已丢弃
  void markDiscarded() {
    status = GenerationTaskStatus.discarded;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'project_id': projectId,
        'chapter_id': chapterId,
        'source_path': sourcePath,
        'source_hash': sourceHash,
        'skill_id': skillId,
        'user_instruction': userInstruction,
        'status': status.name,
        if (candidateId != null) 'candidate_id': candidateId,
        if (partialContent.isNotEmpty) 'partial_content': partialContent,
        if (errorMessage != null) 'error_message': errorMessage,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory GenerationTask.fromJson(Map<String, dynamic> json) =>
      GenerationTask(
        taskId: json['task_id'] as String? ?? '',
        projectId: json['project_id'] as String? ?? '',
        chapterId: json['chapter_id'] as String? ?? '',
        sourcePath: json['source_path'] as String? ?? '',
        sourceHash: json['source_hash'] as String? ?? '',
        skillId: json['skill_id'] as String? ?? '',
        userInstruction: json['user_instruction'] as String? ?? '',
        status: GenerationTaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => GenerationTaskStatus.pending,
        ),
        candidateId: json['candidate_id'] as String?,
        partialContent: json['partial_content'] as String? ?? '',
        errorMessage: json['error_message'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  /// 创建新任务（工厂方法）
  static GenerationTask create({
    required String projectId,
    required String chapterId,
    required String sourcePath,
    required String sourceHash,
    String skillId = '',
    String userInstruction = '',
  }) {
    final now = DateTime.now();
    final seq = GenerationTaskManager._nextSeq();
    return GenerationTask(
      taskId: 'task_${now.millisecondsSinceEpoch}_${seq}_${projectId.hashCode.abs()}',
      projectId: projectId,
      chapterId: chapterId,
      sourcePath: sourcePath,
      sourceHash: sourceHash,
      skillId: skillId,
      userInstruction: userInstruction,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 计算内容哈希（用于源版本比对）
  static String computeHash(String content) {
    // 简单哈希：长度 + 首尾字符 + 中间采样
    if (content.isEmpty) return 'empty';
    final len = content.length;
    final firstChar = content.codeUnitAt(0);
    final lastChar = content.codeUnitAt(len - 1);
    final midChar = len > 10 ? content.codeUnitAt(len ~/ 2) : 0;
    return '${len}_${firstChar}_${midChar}_${lastChar}';
  }

  @override
  String toString() =>
      'GenerationTask($taskId, project=$projectId, chapter=$chapterId, status=${status.name})';
}

/// 生成任务管理器 — 追踪活跃任务，防止跨文档写入
class GenerationTaskManager {
  GenerationTaskManager();

  static int _taskCounter = 0;

  /// 生成递增序号保证 taskId 唯一
  static int _nextSeq() => _taskCounter++;

  final Map<String, GenerationTask> _tasks = {};
  GenerationTask? _activeTask;

  /// 当前活跃任务
  GenerationTask? get activeTask => _activeTask;

  /// 是否有活跃任务
  bool get hasActiveTask => _activeTask != null && _activeTask!.isActive;

  /// 创建并注册新任务
  GenerationTask createTask({
    required String projectId,
    required String chapterId,
    required String sourcePath,
    required String sourceHash,
    String skillId = '',
    String userInstruction = '',
  }) {
    // 如果有活跃任务，先取消
    if (_activeTask != null && _activeTask!.isActive) {
      _activeTask!.markCancelled(partial: _activeTask!.partialContent);
    }

    final task = GenerationTask.create(
      projectId: projectId,
      chapterId: chapterId,
      sourcePath: sourcePath,
      sourceHash: sourceHash,
      skillId: skillId,
      userInstruction: userInstruction,
    );
    _tasks[task.taskId] = task;
    _activeTask = task;
    return task;
  }

  /// 验证任务是否仍绑定到当前上下文
  ///
  /// 项目或章节切换后，旧任务不再有效。
  bool isTaskStillValid(String taskId, {
    required String currentProjectId,
    required String currentChapterId,
  }) {
    final task = _tasks[taskId];
    if (task == null) return false;
    return task.isBoundTo(
      projectId: currentProjectId,
      chapterId: currentChapterId,
    );
  }

  /// 取消活跃任务
  void cancelActiveTask({String partial = ''}) {
    _activeTask?.markCancelled(partial: partial);
    _activeTask = null;
  }

  /// 获取任务
  GenerationTask? getTask(String taskId) => _tasks[taskId];

  /// 获取指定章节的任务列表
  List<GenerationTask> getTasksForChapter(String chapterId) {
    return _tasks.values
        .where((t) => t.chapterId == chapterId)
        .toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }

  /// 清理已完成/取消的旧任务（保留最近 20 个）
  void pruneOldTasks({int keep = 20}) {
    final completed = _tasks.values
        .where((t) => !t.isActive)
        .toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    if (completed.length > keep) {
      for (final task in completed.skip(keep)) {
        _tasks.remove(task.taskId);
      }
    }
  }
}
