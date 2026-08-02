/// 工作流审批
///
/// 蓝图/卷/章节审批流（草稿→待审→通过/拒绝）：
/// - 状态流转：draft → pending → approved/rejected
/// - 拒绝时附带修改意见
/// - AI 据修改意见重新生成
/// - 门禁：只有 approved 才进入后续流水线
library;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 审批目标类型
enum ApprovalTargetType {
  blueprint,
  volume,
  chapter;

  String get label => switch (this) {
        ApprovalTargetType.blueprint => '蓝图',
        ApprovalTargetType.volume => '卷',
        ApprovalTargetType.chapter => '章节',
      };

  static ApprovalTargetType fromString(String s) {
    return ApprovalTargetType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ApprovalTargetType.chapter,
    );
  }
}

/// 审批状态
enum ApprovalStatus {
  draft,
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        ApprovalStatus.draft => '草稿',
        ApprovalStatus.pending => '待审',
        ApprovalStatus.approved => '已通过',
        ApprovalStatus.rejected => '已拒绝',
      };

  /// 是否为终态
  bool get isTerminal => this == approved || this == rejected;

  static ApprovalStatus fromString(String s) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ApprovalStatus.draft,
    );
  }
}

/// 审批记录
class ApprovalRecord {
  const ApprovalRecord({
    required this.targetId,
    required this.targetType,
    this.status = ApprovalStatus.draft,
    this.feedback = '',
    this.content = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.history = const [],
  });

  factory ApprovalRecord.fromJson(Map<String, dynamic> json) {
    return ApprovalRecord(
      targetId: json['target_id'] as String? ?? '',
      targetType: ApprovalTargetType.fromString(
          json['target_type'] as String? ?? 'chapter'),
      status: ApprovalStatus.fromString(json['status'] as String? ?? 'draft'),
      feedback: json['feedback'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      history: (json['history'] as List<dynamic>?)
              ?.map((e) =>
                  ApprovalHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String targetId;
  final ApprovalTargetType targetType;
  final ApprovalStatus status;

  /// 最近一次修改意见（拒绝时必填）
  final String feedback;

  /// 当前内容快照
  final String content;

  final String createdAt;
  final String updatedAt;

  /// 审批历史
  final List<ApprovalHistoryEntry> history;

  /// 是否可进入后续流水线
  bool get isApproved => status == ApprovalStatus.approved;

  Map<String, dynamic> toJson() => {
        'target_id': targetId,
        'target_type': targetType.name,
        'status': status.name,
        'feedback': feedback,
        'content': content,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'history': history.map((h) => h.toJson()).toList(),
      };

  ApprovalRecord copyWith({
    ApprovalStatus? status,
    String? feedback,
    String? content,
    List<ApprovalHistoryEntry>? history,
  }) {
    return ApprovalRecord(
      targetId: targetId,
      targetType: targetType,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      history: history ?? this.history,
    );
  }
}

/// 审批历史条目
class ApprovalHistoryEntry {
  const ApprovalHistoryEntry({
    required this.action,
    this.feedback = '',
    this.timestamp = '',
  });

  factory ApprovalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryEntry(
      action: ApprovalStatus.fromString(json['action'] as String? ?? 'draft'),
      feedback: json['feedback'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  final ApprovalStatus action;
  final String feedback;
  final String timestamp;

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'feedback': feedback,
        'timestamp': timestamp,
      };
}

/// 状态流转异常
class InvalidTransitionException implements Exception {
  InvalidTransitionException(this.from, this.to);

  final ApprovalStatus from;
  final ApprovalStatus to;

  @override
  String toString() => 'InvalidTransition: ${from.label} → ${to.label} 不合法';
}

/// 缺少修改意见异常
class MissingFeedbackException implements Exception {
  @override
  String toString() => '拒绝时必须附带修改意见';
}

// ─── 服务 ───

/// 工作流审批服务
class WorkflowApprovalService {
  WorkflowApprovalService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;

  static const _storageKey = 'workflow_approvals';

  /// 合法状态转换表
  static const _validTransitions = {
    ApprovalStatus.draft: [ApprovalStatus.pending],
    ApprovalStatus.pending: [ApprovalStatus.approved, ApprovalStatus.rejected],
    ApprovalStatus.rejected: [ApprovalStatus.pending],
    ApprovalStatus.approved: <ApprovalStatus>[],
  };

  // ─── 1. CRUD ───

  /// 获取项目所有审批记录
  Future<List<ApprovalRecord>> listRecords(String projectId) async {
    final data = await _metaRepository.read(projectId, _storageKey);
    if (data == null) return [];
    final list = (data['records'] as List<dynamic>?) ?? [];
    return list
        .map((e) => ApprovalRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 创建审批记录（初始为草稿）
  Future<ApprovalRecord> createRecord({
    required String projectId,
    required String targetId,
    required ApprovalTargetType targetType,
    String content = '',
  }) async {
    final records = await listRecords(projectId);
    final now = DateTime.now().toIso8601String();

    final record = ApprovalRecord(
      targetId: targetId,
      targetType: targetType,
      content: content,
      createdAt: now,
      updatedAt: now,
      history: [
        ApprovalHistoryEntry(
          action: ApprovalStatus.draft,
          timestamp: now,
        ),
      ],
    );

    records.add(record);
    await _save(projectId, records);
    return record;
  }

  /// 获取单个记录
  Future<ApprovalRecord?> getRecord(
    String projectId,
    String targetId,
  ) async {
    final records = await listRecords(projectId);
    return records.where((r) => r.targetId == targetId).firstOrNull;
  }

  /// 获取待审列表
  Future<List<ApprovalRecord>> getPendingList(String projectId) async {
    final records = await listRecords(projectId);
    return records.where((r) => r.status == ApprovalStatus.pending).toList();
  }

  // ─── 2. 状态流转 ───

  /// 提交审批（draft/rejected → pending）
  Future<ApprovalRecord> submitForReview(
    String projectId,
    String targetId,
  ) async {
    return _transition(projectId, targetId, ApprovalStatus.pending);
  }

  /// 通过审批（pending → approved）
  Future<ApprovalRecord> approve(
    String projectId,
    String targetId,
  ) async {
    return _transition(projectId, targetId, ApprovalStatus.approved);
  }

  /// 拒绝审批（pending → rejected，必须附带意见）
  Future<ApprovalRecord> reject(
    String projectId,
    String targetId, {
    required String feedback,
  }) async {
    if (feedback.trim().isEmpty) {
      throw MissingFeedbackException();
    }
    return _transition(
      projectId,
      targetId,
      ApprovalStatus.rejected,
      feedback: feedback,
    );
  }

  // ─── 3. 门禁 ───

  /// 检查内容是否已通过审批（可进入流水线）
  Future<bool> isApprovedForPipeline(
    String projectId,
    String targetId,
  ) async {
    final record = await getRecord(projectId, targetId);
    return record?.isApproved ?? false;
  }

  /// 批量门禁检查
  Future<Map<String, bool>> checkPipelineGate(
    String projectId,
    List<String> targetIds,
  ) async {
    final records = await listRecords(projectId);
    final result = <String, bool>{};
    for (final id in targetIds) {
      final record = records.where((r) => r.targetId == id).firstOrNull;
      result[id] = record?.isApproved ?? false;
    }
    return result;
  }

  // ─── 4. 拒绝后 AI 重新生成 ───

  /// 根据修改意见重新生成内容
  Future<String> regenerateWithFeedback({
    required String originalContent,
    required String feedback,
    String context = '',
  }) async {
    try {
      final prompt = StringBuffer();
      prompt.writeln('【修改意见】\n$feedback');
      if (context.isNotEmpty) {
        prompt.writeln('\n【上下文】\n$context');
      }
      prompt.writeln('\n【原始内容】\n$originalContent');
      prompt.writeln('\n请根据修改意见重新生成内容，只输出新内容。');

      return await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是专业写作助手。根据审稿人的修改意见对内容进行修订。'
                '保持整体结构，针对性地修改问题部分。',
          ),
          ChatMessage(role: 'user', content: prompt.toString()),
        ],
      );
    } catch (_) {
      return originalContent; // 失败时返回原文
    }
  }

  /// 拒绝并自动重新生成
  Future<ApprovalRecord> rejectAndRegenerate(
    String projectId,
    String targetId, {
    required String feedback,
  }) async {
    // 先拒绝
    final rejected = await reject(projectId, targetId, feedback: feedback);

    // AI 重新生成
    final newContent = await regenerateWithFeedback(
      originalContent: rejected.content,
      feedback: feedback,
    );

    // 更新内容并重新提交
    final records = await listRecords(projectId);
    final idx = records.indexWhere((r) => r.targetId == targetId);
    if (idx == -1) return rejected;

    final updated = records[idx].copyWith(
      content: newContent,
      status: ApprovalStatus.pending,
      history: [
        ...records[idx].history,
        ApprovalHistoryEntry(
          action: ApprovalStatus.pending,
          feedback: 'AI已根据意见重新生成',
          timestamp: DateTime.now().toIso8601String(),
        ),
      ],
    );
    records[idx] = updated;
    await _save(projectId, records);
    return updated;
  }

  // ─── 辅助 ───

  Future<ApprovalRecord> _transition(
    String projectId,
    String targetId,
    ApprovalStatus to, {
    String feedback = '',
  }) async {
    final records = await listRecords(projectId);
    final idx = records.indexWhere((r) => r.targetId == targetId);
    if (idx == -1) {
      throw StateError('审批记录不存在: $targetId');
    }

    final current = records[idx];
    final allowed = _validTransitions[current.status] ?? [];
    if (!allowed.contains(to)) {
      throw InvalidTransitionException(current.status, to);
    }

    final now = DateTime.now().toIso8601String();
    final updated = current.copyWith(
      status: to,
      feedback: feedback.isNotEmpty ? feedback : current.feedback,
      history: [
        ...current.history,
        ApprovalHistoryEntry(
          action: to,
          feedback: feedback,
          timestamp: now,
        ),
      ],
    );

    records[idx] = updated;
    await _save(projectId, records);
    return updated;
  }

  Future<void> _save(String projectId, List<ApprovalRecord> records) async {
    final data = {'records': records.map((r) => r.toJson()).toList()};
    await _metaRepository.write(projectId, _storageKey, data);
  }
}
