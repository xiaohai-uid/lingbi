/// 规则匹配引擎 — 对文本进行身份识别
library rule_matcher;

import 'identity_rules.dart';

/// 规则匹配器
class RuleMatcher {
  RuleMatcher({IdentityRuleSet? ruleSet})
      : ruleSet = ruleSet ?? IdentityRuleSet();
  final IdentityRuleSet ruleSet;

  /// 对文本进行匹配，返回身份候选列表
  List<IdentityCandidate> match({
    required String text,
    required List<String> sceneCharacterIds,
    Map<String, String>? characterNameMap, // characterId → 角色名称
  }) {
    if (text.isEmpty || sceneCharacterIds.isEmpty) return [];

    final candidates = <IdentityCandidate>[];

    for (final rule in ruleSet.rules) {
      if (!text.contains(rule.pattern)) continue;

      // 找到提到这个称呼的角色
      for (final charId in sceneCharacterIds) {
        final charName = characterNameMap?[charId] ?? '';
        if (charName.isEmpty) continue;

        // 检查称呼是否与角色相关
        // 例如文本中"林师妹" → 匹配 rule"师妹" → 关联角色"林师妹"
        final mentionPattern = '$charName${rule.pattern}';
        if (text.contains(mentionPattern) ||
            _isDirectAddress(text, rule.pattern)) {
          candidates.add(IdentityCandidate(
            characterId: charId,
            identityName: rule.identityName,
            confidence: 0.8,
            source: 'rule:${rule.pattern}',
            suggestedWeight: rule.weight,
          ));
        }
      }
    }

    return _deduplicate(candidates);
  }

  /// 检查是否是直接称呼（如"掌门！"或"掌门大人"）
  bool _isDirectAddress(String text, String pattern) {
    // 简单实现：检查 pattern 是否出现在文本开头或标点后
    final regex = RegExp('(?:^|[。！？，,\\n])$pattern');
    return regex.hasMatch(text);
  }

  /// 去重：同一角色的同一身份只保留最高置信度
  List<IdentityCandidate> _deduplicate(List<IdentityCandidate> candidates) {
    final map = <String, IdentityCandidate>{};
    for (final c in candidates) {
      final key = '${c.characterId}:${c.identityName}';
      if (!map.containsKey(key) || map[key]!.confidence < c.confidence) {
        map[key] = c;
      }
    }
    return map.values.toList();
  }
}
