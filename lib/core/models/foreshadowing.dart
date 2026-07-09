/// 伏笔追踪模型
///
/// 用于管理故事中的伏笔埋设和回收。
/// 每个伏笔关联两个时间线事件：埋设事件和回收事件。
library foreshadowing;

/// 伏笔状态
enum ForeshadowStatus {
  planted('planted', '已埋设'),
  growing('growing', '发展中'),
  harvested('harvested', '已回收'),
  abandoned('abandoned', '已废弃');

  const ForeshadowStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static ForeshadowStatus fromString(String s) => values.firstWhere(
        (t) => t.value == s,
        orElse: () => ForeshadowStatus.planted,
      );
}

/// 伏笔
class Foreshadowing {
  Foreshadowing({
    String? id,
    required this.worldId,
    required this.plantedEventId,
    this.harvestedEventId,
    this.status = ForeshadowStatus.planted,
    this.subtlety = 5,
    this.description = '',
    this.note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _generateId(worldId, plantedEventId),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Foreshadowing.fromJson(Map<String, dynamic> json) => Foreshadowing(
        id: json['id'] as String,
        worldId: json['worldId'] as String,
        plantedEventId: json['plantedEventId'] as String,
        harvestedEventId: json['harvestedEventId'] as String?,
        status: ForeshadowStatus.fromString(json['status'] as String? ?? ''),
        subtlety: json['subtlety'] as int? ?? 5,
        description: json['description'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  final String id;
  final String worldId;
  final String plantedEventId; // 埋设事件 ID
  String? harvestedEventId; // 回收事件 ID（为 null 时表示未回收）
  ForeshadowStatus status;
  int subtlety; // 隐蔽度 1-10，越高越难察觉
  String description;
  String note; // 创作者备注（提示如何回收）
  final DateTime createdAt;
  DateTime updatedAt;

  static String _generateId(String worldId, String eventId) =>
      'fsh-${worldId.hashCode.toRadixString(16)}-${eventId.hashCode.toRadixString(16)}';

  /// 回收伏笔
  void harvest(String eventId) {
    harvestedEventId = eventId;
    status = ForeshadowStatus.harvested;
    updatedAt = DateTime.now();
  }

  /// 废弃伏笔
  void abandon() {
    status = ForeshadowStatus.abandoned;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'plantedEventId': plantedEventId,
        'harvestedEventId': harvestedEventId,
        'status': status.value,
        'subtlety': subtlety,
        'description': description,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
