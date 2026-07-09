/// WritingContext — 写作上下文数据
library writing_context;

import '../../data/database/world_database.dart';

/// 写作上下文 — 当前场景所需的全部注入信息
class WritingContext {
  const WritingContext({
    required this.scene,
    required this.chapterTitle,
    required this.volumeTitle,
    this.location,
    this.characters = const [],
    this.activeIdentities = const {},
    this.relevantRules = const [],
    this.recentEvents = const [],
  });

  /// 场景信息
  final Scene scene;
  final String chapterTitle;
  final String volumeTitle;

  /// 地点信息
  final Location? location;

  /// 角色信息（按有效权重降序）
  final List<ScopedCharacter> characters;

  /// 活跃身份
  final Map<String, List<Identity>>
      activeIdentities; // characterId → identities

  /// 世界观规则
  final List<WorldRule> relevantRules;

  /// 时间线上下文
  final List<TimelineEvent> recentEvents;

  /// 获取优先级最高的 N 个角色
  List<ScopedCharacter> topCharacters(int n) {
    if (n >= characters.length) return characters;
    return characters.sublist(0, n);
  }
}

/// 场景中的角色（含权重和身份）
class ScopedCharacter {
  const ScopedCharacter({
    required this.character,
    required this.effectiveWeight,
    this.activeIdentities = const [],
    this.primaryIdentity,
  });
  final Character character;
  final int effectiveWeight;
  final List<Identity> activeIdentities;
  final Identity? primaryIdentity;
}
