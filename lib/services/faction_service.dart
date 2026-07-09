import 'dart:math';
import '../core/models/faction.dart';

/// 势力管理服务
class FactionService {
  final Map<String, Faction> _factions = {};

  List<Faction> get allFactions => _factions.values.toList();

  Faction? get(String id) => _factions[id];

  Faction create(Faction faction) {
    _factions[faction.id] = faction;
    return faction;
  }

  Faction? update(Faction faction) {
    if (!_factions.containsKey(faction.id)) return null;
    _factions[faction.id] = faction;
    return faction;
  }

  void delete(String id) => _factions.remove(id);

  /// 获取势力的盟友和敌对列表
  List<Faction> getAllies(String factionId) {
    final f = _factions[factionId];
    if (f == null) return [];
    return f.allyIds.map((id) => _factions[id]).whereType<Faction>().toList();
  }

  List<Faction> getRivals(String factionId) {
    final f = _factions[factionId];
    if (f == null) return [];
    return f.rivalIds.map((id) => _factions[id]).whereType<Faction>().toList();
  }

  /// 获取某角色所属的势力
  List<Faction> getFactionsForCharacter(String characterId) =>
      _factions.values.where((f) => f.memberIds.contains(characterId)).toList();

  /// 计算势力关系评分 (0-100)
  int getRelationshipScore(String factionA, String factionB) {
    final a = _factions[factionA];
    final b = _factions[factionB];
    if (a == null || b == null) return 0;
    if (a.allyIds.contains(factionB)) return 80 + Random().nextInt(20);
    if (a.rivalIds.contains(factionB)) return Random().nextInt(20);
    return 40 + Random().nextInt(30);
  }
}
