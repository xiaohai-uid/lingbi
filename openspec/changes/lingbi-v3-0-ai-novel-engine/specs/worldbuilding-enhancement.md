# 世界构建增强 — Spec

## 目标

在现有 Codex 系统基础上，借鉴 AI_NovelGenerator 的世界构建体系，增强角色关系图谱、势力管理、时间线和伏笔追踪能力。

## 现状

当前灵笔的 Codex 系统支持 4 种条目类型：
- `character` — 角色
- `location` — 地点
- `lore` — 传说
- `plotNode` — 情节节点

每个条目有名称、描述、标签，支持语义搜索。

## 增强方向

### 1. 角色关系图谱

从 `character_graph.py`、`character_tracker.py` 借鉴：

```dart
class CharacterEdge {
  String sourceId;        // 源角色 ID
  String targetId;        // 目标角色 ID
  RelationshipType type;  // 师徒/敌对/恋人/家族/主仆/盟友
  int strength;           // 关系强度 1-10
  String description;     // 关系描述
  List<String> events;    // 关联事件 ID
}

enum RelationshipType {
  mentor,        // 师徒
  rival,         // 敌对
  lover,         // 恋人
  family,        // 家族
  servant,       // 主仆
  ally,          // 盟友
  neutral,       // 中立
}
```

### 2. 势力/组织管理

从 `faction_service.py`、`faction.py` 借鉴：

```dart
class Faction {
  String id;
  String name;
  String description;
  FactionType type;        // 宗门/国家/家族/组织
  int power;               // 势力值 1-100
  String territory;        // 势力范围
  List<String> memberIds;  // 成员角色 ID
  List<String> allyIds;    // 盟友势力 ID
  List<String> rivalIds;   // 敌对势力 ID
  Map<String, int> resources;  // 资源分布
}
```

### 3. 时间线增强

从 `timeline.py`、`event_service.py` 借鉴：

```dart
class TimelineEvent {
  String id;
  String title;
  String description;
  int chapter;             // 发生章节
  int scene;               // 发生场景
  List<String> involvedCharacters;  // 参与角色
  EventType type;          // 主线/支线/日常
  List<String> consequences;  // 后续影响的事件 ID
  List<String> foreshadowingRefs;  // 关联伏笔
}
```

### 4. 伏笔追踪

从 `foreshadowing_tracker.py` 借鉴：

```dart
class ForeshadowingEvent {
  String id;
  String description;
  ForeshadowingType type;  // 暗示/伏笔/误导
  int plantedChapter;      // 埋下章节
  int? payoffChapter;      // 回收章节（null=未回收）
  String? payoffDescription;
  bool isResolved;         // 是否已回收
  int importance;          // 重要性 1-10
}
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib/core/models/character_edge.dart` | 角色关系模型 |
| `lib/core/models/faction.dart` | 势力模型 |
| `lib/core/models/timeline_event.dart` | 时间线事件模型 |
| `lib/core/models/foreshadowing.dart` | 伏笔模型 |
| `lib/services/character_graph_service.dart` | 关系图谱服务 |
| `lib/services/faction_service.dart` | 势力管理服务 |
| `lib/services/timeline_service.dart` | 时间线服务（增强） |
| `lib/services/foreshadowing_service.dart` | 伏笔追踪服务 |
| `lib/ui/pages/character_graph_page.dart` | 关系图谱可视化 |
| `lib/ui/pages/faction_page.dart` | 势力管理页面 |
| 修改 `lib/ui/pages/codex_page.dart` | 集成新功能入口 |

## 测试

- 角色关系 CRUD 测试（5+）
- 势力管理测试（5+）
- 时间线事件关联测试（5+）
- 伏笔埋设/回收测试（5+）