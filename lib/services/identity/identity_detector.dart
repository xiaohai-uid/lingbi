/// IdentityDetector — 角色身份自动识别主类
///
/// 组装规则引擎 + LLM 兜底 + 缓存。
/// 当前为 stub 实现，待依赖模块（规则引擎、LLM 工厂、世界数据库）完成后替换。
library identity_detector;


/// 角色信息（stub — 待 world_database.dart 实现后替换）
class Character {

  const Character({required this.id, required this.name});
  final String id;
  final String name;
}

/// 身份候选
class IdentityCandidate {

  const IdentityCandidate({
    required this.characterId,
    required this.identityName,
    this.confidence = 0.5,
    this.source = 'rule',
    this.suggestedWeight = 50,
  });
  final String characterId;
  final String identityName;
  final double confidence;
  final String source; // 'rule' | 'llm'
  final int suggestedWeight;
}

/// 规则匹配器（stub）
class RuleMatcher {
  List<IdentityCandidate> match({
    required String text,
    required List<String> sceneCharacterIds,
    required Map<String, String> characterNameMap,
  }) {
    // TODO: 实现基于 identity_rules.dart 的规则匹配
    return [];
  }
}

/// 检测结果缓存（stub）
class DetectorCache {
  final Map<String, DetectionResult> _store = {};

  DetectionResult? get(String sceneId) => _store[sceneId];
  void set(String sceneId, DetectionResult result) => _store[sceneId] = result;
  void invalidate(String sceneId) => _store.remove(sceneId);
  void clear() => _store.clear();
}

/// 身份检测器
class IdentityDetector {

  IdentityDetector({
    RuleMatcher? ruleMatcher,
    DetectorCache? cache,
    this.enableLlmFallback = false,
  })  : _ruleMatcher = ruleMatcher ?? RuleMatcher(),
        _cache = cache ?? DetectorCache();
  final RuleMatcher _ruleMatcher;
  final DetectorCache _cache;
  final bool enableLlmFallback;

  /// 分析场景中的角色身份
  Future<DetectionResult> detect({
    required String sceneText,
    required List<Character> sceneCharacters,
    required String sceneId,
    required String volumeId,
  }) async {
    // 1. 检查缓存
    final cached = _cache.get(sceneId);
    if (cached != null) return cached;

    // 2. 规则匹配
    final characterNameMap = {
      for (final c in sceneCharacters) c.id: c.name,
    };
    final ruleResults = _ruleMatcher.match(
      text: sceneText,
      sceneCharacterIds: sceneCharacters.map((c) => c.id).toList(),
      characterNameMap: characterNameMap,
    );

    // 3. LLM 兜底（可选，默认关闭）
    // TODO: 待 llm_factory.dart 和 retry_handler.dart 实现后启用
    final List<IdentityCandidate> llmResults = [];

    // 4. 合并结果
    final allCandidates = [...ruleResults, ...llmResults];
    final result = DetectionResult(
      sceneId: sceneId,
      candidates: allCandidates,
      source: ruleResults.isNotEmpty
          ? 'rule'
          : (llmResults.isNotEmpty ? 'llm' : 'none'),
    );

    // 5. 写入缓存
    _cache.set(sceneId, result);

    return result;
  }

  /// 清除场景缓存（用户编辑后调用）
  void invalidateScene(String sceneId) {
    _cache.invalidate(sceneId);
  }
}

/// 检测结果
class DetectionResult { // 'rule' | 'llm' | 'none'

  const DetectionResult({
    required this.sceneId,
    this.candidates = const [],
    this.source = 'none',
  });
  final String sceneId;
  final List<IdentityCandidate> candidates;
  final String source;

  bool get hasResults => candidates.isNotEmpty;

  /// 获取新身份（尚未写入数据库的）
  List<IdentityCandidate> get newIdentities => candidates;
}
