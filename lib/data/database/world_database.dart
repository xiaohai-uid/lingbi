/// 灵笔数据库 — Drift (SQLite) 定义
///
/// 存储所有结构化数据：角色、身份、地点、时间线、作品结构等。
/// 正文内容独立存储为 .md 文件。
library world_database;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'world_database.g.dart';

// ============================================================
// 表定义
// ============================================================

/// 角色表
@DataClassName('Character')
class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get role => text()(); // 主角/配角/反派/路人
  TextColumn get personality => text()();
  TextColumn? get backstory => text()();
  TextColumn? get motivation => text()();
  TextColumn? get arc => text()();
  IntColumn get baseWeight => integer()(); // 派生值，由身份权重 max 计算
  IntColumn? get tempWeight => integer()();
  TextColumn? get currentStatus => text()();
  TextColumn? get currentLocationId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 身份表
@DataClassName('Identity')
class Identities extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get name => text()(); // "道侣" / "青云宗掌门"
  TextColumn get description => text()();
  IntColumn get weight => integer()(); // 0-100
  BoolColumn get autoDetected => boolean()();
  TextColumn? get organizationId => text()();
  TextColumn? get establishedAfterEventId => text()();
  TextColumn? get expiresAfterEventId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 权重特殊说明表
@DataClassName('WeightSpec')
class WeightSpecs extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get description => text()();
  TextColumn? get volumeId => text()();
  TextColumn? get eventId => text()();
  TextColumn? get chapterId => text()();
  IntColumn? get weightDelta => integer()();
  BoolColumn? get promoteToMain => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 角色关系表
@DataClassName('CharacterRelation')
class CharacterRelations extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get relatedCharacterId => text()();
  TextColumn get relationType => text()(); // 师徒/恋人/仇敌
  IntColumn get intimacy => integer()(); // 0-100
  TextColumn? get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 关系阶段演进表
@DataClassName('RelationStage')
class RelationStages extends Table {
  TextColumn get id => text()();
  TextColumn get relationId => text()();
  IntColumn get atIntimacy => integer()();
  TextColumn get stageName => text()();
  DateTimeColumn get reachedAt => dateTime()();
  TextColumn? get triggerEventId => text()();
  BoolColumn get confirmed => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 地点表
@DataClassName('Location')
class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 传说/设定表
@DataClassName('Lore')
class Lores extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // character / location / item / rule / event
  TextColumn get description => text()();
  TextColumn get triggerKeywords => text()(); // 逗号分隔的关键词
  BoolColumn get enabled => boolean()(); // 是否启用
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 世界观规则表
@DataClassName('WorldRule')
class WorldRules extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn? get scope => text()(); // 适用场景/卷ID
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 时间线事件表
@DataClassName('TimelineEvent')
class TimelineEvents extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get orderKey => text()(); // 分数索引
  TextColumn? get inStoryDate => text()();
  IntColumn? get inStoryDay => integer()();
  TextColumn? get duration => text()();
  TextColumn? get chapterAnchor => text()();
  TextColumn? get branchId => text()();
  TextColumn? get parentEventId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 作品表
@DataClassName('Work')
class Works extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get title => text()();
  TextColumn? get description => text()();
  TextColumn get type => text()(); // novel | script | interactive
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 卷表
@DataClassName('Volume')
class Volumes extends Table {
  TextColumn get id => text()();
  TextColumn get workId => text()();
  IntColumn get volumeNumber => integer()();
  TextColumn get title => text()();
  TextColumn? get synopsis => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 章节表
@DataClassName('Chapter')
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get volumeId => text()();
  IntColumn get chapterNumber => integer()();
  TextColumn get title => text()();
  TextColumn? get synopsis => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 场景表
@DataClassName('Scene')
class Scenes extends Table {
  TextColumn get id => text()();
  TextColumn get chapterId => text()();
  IntColumn get sceneNumber => integer()();
  TextColumn get title => text()();
  TextColumn? get outlineDescription => text()();
  TextColumn? get locationId => text()();
  TextColumn? get timelineEventId => text()();
  TextColumn get documentId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 文档索引表
@DataClassName('Document')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get workId => text()();
  TextColumn get filePath => text()();
  TextColumn? get currentSceneId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 势力表
@DataClassName('Faction')
class Factions extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get type => text()(); // sect / nation / clan / organization
  IntColumn get power => integer()(); // 1-100
  TextColumn? get territory => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 伏笔表
@DataClassName('Foreshadowing')
class Foreshadowings extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get plantedEventId => text()();
  TextColumn? get harvestedEventId => text()();
  TextColumn get status =>
      text()(); // planted / growing / harvested / abandoned
  IntColumn get subtlety => integer()(); // 1-10
  TextColumn get description => text()();
  TextColumn? get note => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 蝴蝶效应分析表
@DataClassName('ButterflyAnalysis')
class ButterflyAnalyses extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get eventId => text()(); // 触发事件
  TextColumn get analysisText => text()(); // LLM 分析结果
  TextColumn get predictedDirection => text()(); // 剧情走向预测
  IntColumn get tokenCost => integer()(); // 消耗 token 数
  RealColumn get estimatedCost => real()(); // 预估费用
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 场景摘要表 — 存储场景级结构化摘要
@DataClassName('SceneSummary')
class SceneSummaries extends Table {
  // ── 标识 ──
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get chapterId => text()();
  TextColumn get worldId => text()();

  // ── 核心内容 ──
  TextColumn get summary => text()();
  TextColumn get keywords => text()();
  TextColumn get characters => text()();
  TextColumn get location => text()();
  TextColumn get mood => text()();

  // ── 时间与因果 ──
  TextColumn get inStoryDay => text()();
  TextColumn get causeEvent => text()();
  TextColumn get effectEvent => text()();

  // ── 情感与冲突 ──
  TextColumn get characterEmotions => text()();
  TextColumn get conflictType => text()();
  TextColumn get suspenseTags => text()();

  // ── 内容亮点 ──
  TextColumn get keyDialogues => text()();
  TextColumn get signatureMoments => text()();
  TextColumn get foreshadowingIds => text()();
  TextColumn get embeddingId => text().nullable()(); // Qdrant point ID

  // ── 元数据 ──
  IntColumn get wordCount => integer()();
  IntColumn get sceneOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 章节摘要表 — 聚合场景摘要生成章级摘要
@DataClassName('ChapterSummary')
class ChapterSummaries extends Table {
  TextColumn get id => text()();
  TextColumn get chapterId => text()();
  TextColumn get volumeId => text()();
  TextColumn get worldId => text()();
  TextColumn get summary => text()();
  TextColumn get hook => text()();
  TextColumn get majorEvents => text()();
  TextColumn get characterArcs => text()();
  TextColumn get conflictResolution => text()();
  TextColumn get emotionalClimax => text()();
  TextColumn get unansweredQuestions => text()();
  IntColumn get sceneCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 卷摘要表 — 聚合章摘要生成卷级摘要
@DataClassName('VolumeSummary')
class VolumeSummaries extends Table {
  TextColumn get id => text()();
  TextColumn get volumeId => text()();
  TextColumn get worldId => text()();
  TextColumn get summary => text()();
  TextColumn get status => text()();
  TextColumn get mainCharacters => text()();
  TextColumn get storyArc => text()();
  TextColumn get majorPlotPoints => text()();
  TextColumn get unresolvedThreads => text()();
  IntColumn get chapterCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// 数据库定义
// ============================================================

@DriftDatabase(
  tables: [
    Characters,
    Identities,
    WeightSpecs,
    CharacterRelations,
    RelationStages,
    Locations,
    Lores,
    WorldRules,
    TimelineEvents,
    Factions,
    Foreshadowings,
    ButterflyAnalyses,
    SceneSummaries,
    ChapterSummaries,
    VolumeSummaries,
    Works,
    Volumes,
    Chapters,
    Scenes,
    Documents,
  ],
)
class WorldDatabase extends _$WorldDatabase {
  WorldDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy();
}

/// 打开指定世界的数据库文件
///
/// 数据库路径：Documents/灵笔/Worlds/{worldId}/world.db
Future<QueryExecutor> openWorldDatabase(String worldId) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, '灵笔', 'Worlds', worldId, 'world.db');

  // 确保目录存在
  await Directory(p.dirname(dbPath)).create(recursive: true);

  return NativeDatabase(File(dbPath));
}

/// 创建默认世界数据库（首次启动时使用）
Future<WorldDatabase> createDefaultDatabase() async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, '灵笔', 'Worlds', 'default', 'world.db');

  await Directory(p.dirname(dbPath)).create(recursive: true);

  return WorldDatabase(NativeDatabase(File(dbPath)));
}
