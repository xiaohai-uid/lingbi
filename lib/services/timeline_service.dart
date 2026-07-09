/// 事件类型
enum EventType { mainPlot, sidePlot, daily, turningPoint }

/// 时间线事件
class TimelineEvent {
  // 关联伏笔 ID

  TimelineEvent({
    String? id,
    required this.title,
    this.description = '',
    required this.chapter,
    this.scene = 0,
    this.involvedCharacters = const [],
    this.type = EventType.mainPlot,
    this.consequences = const [],
    this.foreshadowingRefs = const [],
  }) : id = id ?? 'evt-${_generateId(title)}';

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        chapter: json['chapter'] as int,
        scene: json['scene'] as int? ?? 0,
        involvedCharacters:
            (json['involvedCharacters'] as List?)?.cast<String>() ?? [],
        type: EventType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => EventType.mainPlot,
        ),
        consequences: (json['consequences'] as List?)?.cast<String>() ?? [],
        foreshadowingRefs:
            (json['foreshadowingRefs'] as List?)?.cast<String>() ?? [],
      );
  final String id;
  final String title;
  final String description;
  final int chapter;
  final int scene;
  final List<String> involvedCharacters;
  final EventType type;
  final List<String> consequences; // 后续影响的事件 ID
  final List<String> foreshadowingRefs;

  static String _generateId(String title) => title.hashCode.toRadixString(16);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'chapter': chapter,
        'scene': scene,
        'involvedCharacters': involvedCharacters,
        'type': type.name,
        'consequences': consequences,
        'foreshadowingRefs': foreshadowingRefs,
      };
}

/// 伏笔类型
enum ForeshadowingType {
  hint('hint', '暗示'),
  foreshadowing('foreshadowing', '伏笔'),
  misdirection('misdirection', '误导');

  const ForeshadowingType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// 伏笔事件
class ForeshadowingEvent {
  // 1-10

  ForeshadowingEvent({
    String? id,
    required this.description,
    this.type = ForeshadowingType.foreshadowing,
    required this.plantedChapter,
    this.payoffChapter,
    this.payoffDescription,
    this.isResolved = false,
    this.importance = 5,
  }) : id = id ?? 'fsh-${_generateId(description)}';

  factory ForeshadowingEvent.fromJson(Map<String, dynamic> json) =>
      ForeshadowingEvent(
        id: json['id'] as String,
        description: json['description'] as String,
        type: ForeshadowingType.values.firstWhere(
          (t) => t.value == json['type'],
          orElse: () => ForeshadowingType.foreshadowing,
        ),
        plantedChapter: json['plantedChapter'] as int,
        payoffChapter: json['payoffChapter'] as int?,
        payoffDescription: json['payoffDescription'] as String?,
        isResolved: json['isResolved'] as bool? ?? false,
        importance: json['importance'] as int? ?? 5,
      );
  final String id;
  final String description;
  final ForeshadowingType type;
  final int plantedChapter;
  final int? payoffChapter;
  final String? payoffDescription;
  final bool isResolved;
  final int importance;

  static String _generateId(String desc) => desc.hashCode.toRadixString(16);

  /// 回收伏笔
  ForeshadowingEvent resolve(int chapter, String description) =>
      ForeshadowingEvent(
        id: id,
        description: description,
        type: type,
        plantedChapter: plantedChapter,
        payoffChapter: chapter,
        payoffDescription: description,
        isResolved: true,
        importance: importance,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type.value,
        'plantedChapter': plantedChapter,
        'payoffChapter': payoffChapter,
        'payoffDescription': payoffDescription,
        'isResolved': isResolved,
        'importance': importance,
      };
}

/// 时间线服务
class TimelineService {
  final Map<String, TimelineEvent> _events = {};

  List<TimelineEvent> get allEvents => _events.values.toList();

  TimelineEvent? get(String id) => _events[id];

  TimelineEvent add(TimelineEvent event) {
    _events[event.id] = event;
    return event;
  }

  void delete(String id) => _events.remove(id);

  /// 按章节排序获取事件
  List<TimelineEvent> getEventsByChapter(int chapter) =>
      _events.values.where((e) => e.chapter == chapter).toList()
        ..sort((a, b) => a.scene.compareTo(b.scene));

  /// 获取角色的所有参与事件
  List<TimelineEvent> getEventsForCharacter(String characterId) =>
      _events.values
          .where(
            (e) => e.involvedCharacters.contains(characterId),
          )
          .toList();
}

/// 伏笔追踪服务
class ForeshadowingService {
  final Map<String, ForeshadowingEvent> _foreshadowings = {};

  List<ForeshadowingEvent> get allForeshadowings =>
      _foreshadowings.values.toList();

  ForeshadowingEvent? get(String id) => _foreshadowings[id];

  ForeshadowingEvent plant(ForeshadowingEvent event) {
    _foreshadowings[event.id] = event;
    return event;
  }

  /// 回收伏笔
  ForeshadowingEvent? resolve(String id, int chapter, String description) {
    final event = _foreshadowings[id];
    if (event == null) return null;
    final resolved = event.resolve(chapter, description);
    _foreshadowings[id] = resolved;
    return resolved;
  }

  /// 获取未回收的伏笔
  List<ForeshadowingEvent> getUnresolved() =>
      _foreshadowings.values.where((f) => !f.isResolved).toList()
        ..sort((a, b) => a.plantedChapter.compareTo(b.plantedChapter));

  /// 获取特定章节埋下的伏笔
  List<ForeshadowingEvent> getPlantedInChapter(int chapter) =>
      _foreshadowings.values.where((f) => f.plantedChapter == chapter).toList();

  /// 计算伏笔回收率
  double getResolveRate() {
    if (_foreshadowings.isEmpty) return 1;
    final resolved = _foreshadowings.values.where((f) => f.isResolved).length;
    return resolved / _foreshadowings.length;
  }
}
