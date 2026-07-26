/// 批量生成 + 任务队列服务
///
/// 提供：
/// - 后台异步任务队列（不阻塞 UI）
/// - 批量生成多章草稿
/// - 取消/重试/查看进度
/// - 失败自动重试（最多 3 次）
/// - 每章生成仍走完整流水线
library;

import 'dart:async';
import 'dart:collection';

// ─── 数据模型 ───

/// 任务状态
enum TaskStatus {
  pending,
  running,
  done,
  failed,
  cancelled;

  static TaskStatus fromString(String s) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// 任务类型
enum TaskType {
  batchGenerate,
  singleChapter,
  analysis,
  rebuild,
  custom;

  static TaskType fromString(String s) {
    return TaskType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskType.custom,
    );
  }
}

/// 任务队列条目
class TaskQueueItem {
  TaskQueueItem({
    required this.id,
    required this.type,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.result = '',
    this.error = '',
    this.label = '',
    this.createdAt = '',
    this.startedAt = '',
    this.completedAt = '',
    this.metadata = const {},
  });

  factory TaskQueueItem.fromJson(Map<String, dynamic> json) {
    return TaskQueueItem(
      id: json['id'] as String? ?? '',
      type: TaskType.fromString(json['type'] as String? ?? 'custom'),
      status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      retryCount: json['retry_count'] as int? ?? 0,
      maxRetries: json['max_retries'] as int? ?? 3,
      result: json['result'] as String? ?? '',
      error: json['error'] as String? ?? '',
      label: json['label'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  final String id;
  final TaskType type;
  TaskStatus status;
  double progress;
  int retryCount;
  final int maxRetries;
  String result;
  String error;
  final String label;
  final String createdAt;
  String startedAt;
  String completedAt;
  final Map<String, dynamic> metadata;

  bool get canRetry => retryCount < maxRetries;
  bool get isTerminal =>
      status == TaskStatus.done ||
      status == TaskStatus.failed ||
      status == TaskStatus.cancelled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'progress': progress,
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'result': result,
        'error': error,
        'label': label,
        'created_at': createdAt,
        'started_at': startedAt,
        'completed_at': completedAt,
        'metadata': metadata,
      };
}

/// 批量生成请求
class BatchGenerateRequest {
  const BatchGenerateRequest({
    required this.projectId,
    required this.chapterIds,
    this.userInstruction = '',
    this.targetWordsPerChapter = 6000,
  });

  final String projectId;
  final List<String> chapterIds;
  final String userInstruction;
  final int targetWordsPerChapter;
}

// ─── 服务 ───

/// 任务执行函数签名
typedef TaskExecutor = Future<String> Function(
  TaskQueueItem task,
  void Function(double progress) reportProgress,
);

/// 任务队列服务
///
/// 后台异步执行任务，支持取消/重试/进度上报。
class TaskQueueService {
  TaskQueueService({
    this.maxConcurrent = 1,
  });

  /// 最大并发数（默认串行）
  final int maxConcurrent;

  final Queue<TaskQueueItem> _queue = Queue();
  final Map<String, TaskQueueItem> _allTasks = {};
  final Map<String, TaskExecutor> _executors = {};
  final Map<String, Completer<String>> _completers = {};

  int _runningCount = 0;
  bool _disposed = false;

  /// 变更通知回调（UI 层监听）
  void Function()? onChanged;

  // ─── 1. 任务注册 ───

  /// 注册任务执行器
  void registerExecutor(TaskType type, TaskExecutor executor) {
    _executors[type.name] = executor;
  }

  /// 提交任务到队列
  TaskQueueItem enqueue({
    required TaskType type,
    String label = '',
    Map<String, dynamic> metadata = const {},
    int maxRetries = 3,
  }) {
    final task = TaskQueueItem(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${_allTasks.length}',
      type: type,
      label: label,
      maxRetries: maxRetries,
      createdAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );

    _allTasks[task.id] = task;
    _queue.add(task);
    _completers[task.id] = Completer();
    onChanged?.call();
    _processNext();
    return task;
  }

  /// 批量提交（返回所有任务 ID）
  List<String> enqueueBatch({
    required TaskType type,
    required List<String> labels,
    List<Map<String, dynamic>> metadataList = const [],
  }) {
    final ids = <String>[];
    for (var i = 0; i < labels.length; i++) {
      final meta = i < metadataList.length ? metadataList[i] : <String, dynamic>{};
      final task = enqueue(type: type, label: labels[i], metadata: meta);
      ids.add(task.id);
    }
    return ids;
  }

  // ─── 2. 任务控制 ───

  /// 取消任务
  bool cancel(String taskId) {
    final task = _allTasks[taskId];
    if (task == null || task.isTerminal) return false;

    if (task.status == TaskStatus.pending) {
      task.status = TaskStatus.cancelled;
      _queue.removeWhere((t) => t.id == taskId);
      _completeTask(taskId, '');
    } else if (task.status == TaskStatus.running) {
      task.status = TaskStatus.cancelled;
      _runningCount--;
      _completeTask(taskId, '');
      _processNext();
    }
    onChanged?.call();
    return true;
  }

  /// 批量取消
  int cancelAll() {
    var count = 0;
    for (final task in _queue.toList()) {
      if (cancel(task.id)) count++;
    }
    return count;
  }

  /// 重试失败任务
  bool retry(String taskId) {
    final task = _allTasks[taskId];
    if (task == null) return false;
    if (task.status != TaskStatus.failed) return false;

    task.status = TaskStatus.pending;
    task.progress = 0;
    task.error = '';
    task.startedAt = '';
    task.completedAt = '';
    _queue.add(task);
    if (_completers[taskId] == null || _completers[taskId]!.isCompleted) {
      _completers[taskId] = Completer();
    }
    onChanged?.call();
    _processNext();
    return true;
  }

  // ─── 3. 查询 ───

  /// 获取所有任务
  List<TaskQueueItem> getTasks() => _allTasks.values.toList();

  /// 获取指定任务
  TaskQueueItem? getTask(String taskId) => _allTasks[taskId];

  /// 获取队列中待执行任务数
  int get pendingCount =>
      _queue.where((t) => t.status == TaskStatus.pending).length;

  /// 获取正在运行的任务数
  int get runningCount => _runningCount;

  /// 等待任务完成
  Future<String> waitForTask(String taskId) {
    final completer = _completers[taskId];
    if (completer == null || completer.isCompleted) {
      return Future.value(_allTasks[taskId]?.result ?? '');
    }
    return completer.future;
  }

  // ─── 4. 批量生成编排 ───

  /// 创建批量生成任务组
  ///
  /// 为每个章节创建独立任务，串行执行。
  List<String> createBatchGeneration(BatchGenerateRequest request) {
    final labels = request.chapterIds
        .map((id) => '生成章节: $id')
        .toList();
    final metadataList = request.chapterIds
        .map((id) => {
              'project_id': request.projectId,
              'chapter_id': id,
              'user_instruction': request.userInstruction,
              'target_words': request.targetWordsPerChapter,
            })
        .toList();

    return enqueueBatch(
      type: TaskType.singleChapter,
      labels: labels,
      metadataList: metadataList,
    );
  }

  // ─── 内部调度 ───

  void _processNext() {
    if (_disposed) return;
    while (_runningCount < maxConcurrent && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (task.status != TaskStatus.pending) continue;
      _executeTask(task);
    }
  }

  Future<void> _executeTask(TaskQueueItem task) async {
    final executor = _executors[task.type.name];
    if (executor == null) {
      task.status = TaskStatus.failed;
      task.error = 'No executor registered for ${task.type.name}';
      _completeTask(task.id, '');
      onChanged?.call();
      _processNext();
      return;
    }

    _runningCount++;
    task.status = TaskStatus.running;
    task.startedAt = DateTime.now().toIso8601String();
    onChanged?.call();

    try {
      final result = await executor(task, (progress) {
        if (task.status == TaskStatus.cancelled) return;
        task.progress = progress;
        onChanged?.call();
      });

      if (task.status == TaskStatus.cancelled) {
        _runningCount--;
        _processNext();
        return;
      }

      task.status = TaskStatus.done;
      task.progress = 1.0;
      task.result = result;
      task.completedAt = DateTime.now().toIso8601String();
      _completeTask(task.id, result);
    } catch (e) {
      if (task.status == TaskStatus.cancelled) {
        _runningCount--;
        _processNext();
        return;
      }

      task.retryCount++;
      if (task.canRetry) {
        // 自动重试
        task.status = TaskStatus.pending;
        task.progress = 0;
        task.error = e.toString();
        _queue.addFirst(task);
      } else {
        task.status = TaskStatus.failed;
        task.error = e.toString();
        task.completedAt = DateTime.now().toIso8601String();
        _completeTask(task.id, '');
      }
    }

    _runningCount--;
    onChanged?.call();
    _processNext();
  }

  void _completeTask(String taskId, String result) {
    final completer = _completers[taskId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void dispose() {
    _disposed = true;
    _queue.clear();
  }
}
