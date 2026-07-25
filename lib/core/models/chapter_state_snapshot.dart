/// 章节状态快照 — 每章生成后自动回写的结构化状态
///
/// 记录出场角色、情绪走向、未解伏笔、时间线位置等，
/// 供后续章节生成和监督 Agent 使用。
library;

/// 章节状态快照
class ChapterStateSnapshot {
  const ChapterStateSnapshot({
    required this.chapterId,
    required this.projectId,
    this.appearingCharacters = const [],
    this.emotionArc = '',
    this.unresolvedForeshadowing = const [],
    this.timelinePosition = '',
    this.newInventions = const [],
    this.keyEvents = const [],
    this.locationChanges = const [],
    this.timestamp,
  });

  factory ChapterStateSnapshot.fromJson(Map<String, dynamic> json) {
    return ChapterStateSnapshot(
      chapterId: json['chapterId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      appearingCharacters: (json['appearingCharacters'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      emotionArc: json['emotionArc'] as String? ?? '',
      unresolvedForeshadowing:
          (json['unresolvedForeshadowing'] as List<dynamic>?)
                  ?.cast<String>() ??
              const [],
      timelinePosition: json['timelinePosition'] as String? ?? '',
      newInventions: (json['newInventions'] as List<dynamic>?)
              ?.map((e) => Invention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      keyEvents:
          (json['keyEvents'] as List<dynamic>?)?.cast<String>() ?? const [],
      locationChanges: (json['locationChanges'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// 章节 ID
  final String chapterId;

  /// 项目 ID
  final String projectId;

  /// 出场角色列表
  final List<String> appearingCharacters;

  /// 情绪走向描述
  final String emotionArc;

  /// 未解伏笔
  final List<String> unresolvedForeshadowing;

  /// 时间线位置
  final String timelinePosition;

  /// 本章新发明（AI 创造的新设定）
  final List<Invention> newInventions;

  /// 关键事件
  final List<String> keyEvents;

  /// 场景/地点变化
  final List<String> locationChanges;

  /// 快照时间
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'projectId': projectId,
        'appearingCharacters': appearingCharacters,
        'emotionArc': emotionArc,
        'unresolvedForeshadowing': unresolvedForeshadowing,
        'timelinePosition': timelinePosition,
        'newInventions': newInventions.map((i) => i.toJson()).toList(),
        'keyEvents': keyEvents,
        'locationChanges': locationChanges,
        'timestamp': timestamp?.toIso8601String(),
      };
}

/// AI 发明的新设定（需用户确认）
class Invention {
  const Invention({
    required this.content,
    this.category = '其他',
    this.status = InventionStatus.pending,
  });

  factory Invention.fromJson(Map<String, dynamic> json) {
    return Invention(
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? '其他',
      status: InventionStatus.fromString(json['status'] as String? ?? 'pending'),
    );
  }

  /// 发明内容描述
  final String content;

  /// 分类（角色/地点/规则/物品/其他）
  final String category;

  /// 用户确认状态
  final InventionStatus status;

  Invention copyWith({InventionStatus? status}) => Invention(
        content: content,
        category: category,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'category': category,
        'status': status.value,
      };
}

/// 发明确认状态
enum InventionStatus {
  /// 待用户确认
  pending,

  /// 用户已接受（纳入正典）
  accepted,

  /// 用户已拒绝（后续生成不应再使用）
  rejected;

  static InventionStatus fromString(String value) {
    switch (value) {
      case 'accepted':
        return InventionStatus.accepted;
      case 'rejected':
        return InventionStatus.rejected;
      default:
        return InventionStatus.pending;
    }
  }

  String get value => name;
}
