/// CanonService — 世界正典管理服务
///
/// v3.2+ 替代旧的 CodexService。
/// 角色/地点/传说/规则 分散到独立 Drift 表存储。
/// 通过 CanonRepository 操作，ZVec 仅保留语义搜索。
library;

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../core/database/database_manager.dart';
import '../data/repositories/canon_repository.dart';
import '../data/database/world_database.dart';

const _uuid = Uuid();

/// 世界正典管理服务
class CanonService {
  CanonService({
    required this.databaseManager,
    required this.canonRepository,
  });
  final DatabaseManager databaseManager;
  final CanonRepository canonRepository;

  // ============================================================
  // 角色
  // ============================================================

  /// 创建角色
  Future<void> createCharacter({
    required String worldId,
    required String name,
    String description = '',
    String role = '配角',
    String personality = '',
    String? backstory,
    String? motivation,
    String? arc,
  }) async {
    final now = DateTime.now();
    await canonRepository.createCharacter(CharactersCompanion.insert(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      role: role,
      personality: personality,
      backstory: backstory ?? '',
      motivation: motivation ?? '',
      arc: arc ?? '',
      baseWeight: 50,
      tempWeight: 0,
      currentStatus: '',
      currentLocationId: '',
      createdAt: now,
      updatedAt: now,
    ));
  }

  /// 获取世界的所有角色
  Future<List<Character>> getCharacters(String worldId) {
    return canonRepository.getCharacters(worldId);
  }

  /// 获取单个角色（含身份）
  Future<CharacterWithIdentities?> getCharacter(String id) {
    return canonRepository.getCharacter(id);
  }

  /// 更新角色
  Future<void> updateCharacter(
    String id, {
    String? name,
    String? description,
    String? personality,
    String? backstory,
    String? motivation,
    String? arc,
    String? role,
    int? tempWeight,
  }) async {
    final companion = CharactersCompanion(
      updatedAt: Value(DateTime.now()),
    );
    if (name != null) companion.name = Value(name);
    if (description != null) companion.description = Value(description);
    if (role != null) companion.role = Value(role);
    if (personality != null) companion.personality = Value(personality);
    if (backstory != null) companion.backstory = Value(backstory);
    if (motivation != null) companion.motivation = Value(motivation);
    if (arc != null) companion.arc = Value(arc);
    if (tempWeight != null) companion.tempWeight = Value(tempWeight);

    await canonRepository.updateCharacter(id, companion);
  }

  /// 删除角色
  Future<void> deleteCharacter(String id) {
    return canonRepository.deleteCharacter(id);
  }

  // ─── 地点 ───

  Future<void> updateLocation(
    String id, {
    String? name,
    String? description,
  }) async {
    final companion = LocationsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await canonRepository.updateLocation(id, companion);
  }

  Future<void> deleteLocation(String id) {
    return canonRepository.deleteLocation(id);
  }

  // ─── 传说 ───

  Future<void> updateLore(
    String id, {
    String? name,
    String? description,
  }) async {
    final companion = LoresCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await canonRepository.updateLore(id, companion);
  }

  Future<void> deleteLore(String id) {
    return canonRepository.deleteLore(id);
  }

  // ─── 世界观规则 ───

  Future<void> updateWorldRule(
    String id, {
    String? name,
    String? description,
    String? scope,
  }) async {
    final companion = WorldRulesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      scope: scope != null ? Value(scope) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await canonRepository.updateWorldRule(id, companion);
  }

  Future<void> deleteWorldRule(String id) {
    return canonRepository.deleteWorldRule(id);
  }

  // ============================================================
  // 身份
  // ============================================================

  /// 为角色添加身份
  Future<void> addIdentity({
    required String characterId,
    required String name,
    String description = '',
    int weight = 50,
    bool autoDetected = false,
    String? organizationId,
  }) async {
    final db = await databaseManager.getDefaultDatabase();
    await db.into(db.identities).insert(IdentitiesCompanion.insert(
          id: _uuid.v4(),
          characterId: characterId,
          name: name,
          description: description,
          weight: weight,
          autoDetected: autoDetected,
          organizationId: organizationId ?? '',
          establishedAfterEventId: '',
          expiresAfterEventId: '',
        ));

    // 重新计算 baseWeight = max(identity.weights)
    await _recalculateBaseWeight(characterId, db);
  }

  /// 重新计算角色的 baseWeight = max(identity.weights)
  Future<void> _recalculateBaseWeight(
      String characterId, WorldDatabase db) async {
    final identities = await (db.select(db.identities)
          ..where((t) => t.characterId.equals(characterId)))
        .get();

    final maxWeight = identities.isEmpty
        ? 50
        : identities.map((i) => i.weight).reduce((a, b) => a > b ? a : b);

    await (db.update(db.characters)..where((t) => t.id.equals(characterId)))
        .write(CharactersCompanion(baseWeight: Value(maxWeight)));
  }

  // ============================================================
  // 地点
  // ============================================================

  Future<void> createLocation({
    required String worldId,
    required String name,
    String description = '',
  }) async {
    await canonRepository.createLocation(LocationsCompanion.insert(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<List<Location>> getLocations(String worldId) {
    return canonRepository.getLocations(worldId);
  }

  // ============================================================
  // 传说
  // ============================================================

  Future<void> createLore({
    required String worldId,
    required String name,
    String type = 'location',
    String description = '',
  }) async {
    await canonRepository.createLore(LoresCompanion.insert(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      type: type,
      description: description,
      triggerKeywords: '',
      enabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<List<Lore>> getLores(String worldId) {
    return canonRepository.getLores(worldId);
  }

  // ============================================================
  // 世界观规则
  // ============================================================

  Future<void> createRule({
    required String worldId,
    required String name,
    required String description,
    String? scope,
  }) async {
    await canonRepository.createWorldRule(WorldRulesCompanion.insert(
      id: _uuid.v4(),
      worldId: worldId,
      name: name,
      description: description,
      scope: scope ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<List<WorldRule>> getRulesForScene(String worldId,
      {String? sceneId}) async {
    if (sceneId != null) {
      final db = await databaseManager.getDefaultDatabase();
      final query = db.select(db.worldRules)
        ..where((t) => t.worldId.equals(worldId))
        ..where((t) => t.scope.equals(sceneId));
      return query.get();
    }
    return canonRepository.getWorldRules(worldId);
  }

  // ============================================================
  // 语义搜索（ZVec 保留）
  // ============================================================

  Future<List<String>> searchCharacters(String worldId, String query) async {
    // TODO: 调用 ZVec 做语义搜索
    // 当前回退到 Drift 简单文本搜索
    final db = await databaseManager.getDefaultDatabase();
    final results = await (db.select(db.characters)
          ..where((t) => t.worldId.equals(worldId))
          ..where((t) => t.name.contains(query)))
        .get();
    return results.map((c) => c.id).toList();
  }
}
