/// IdentityDetector — 角色身份自动识别主类
///
/// 组装规则引擎 + LLM 兜底 + 缓存
library identity_detector;

import 'identity_rules.dart';
import 'rule_matcher.dart';
import 'detector_cache.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../../core/ai/retry_handler.dart';
import '../prompt_service.dart';
import '../../data/database/world_database.dart' show Character;
import 'package:drift/drift.dart';

/// 身份检测器
class IdentityDetector {
  final RuleMatcher _ruleMatcher;
  final DetectorCache _cache;
  final bool enableLlmFallback;

  IdentityDetector({
    RuleMatcher? ruleMatcher,
    DetectorCache? cache,
    this.enableLlmFallback = false,
  })  : _ruleMatcher = ruleMatcher ?? RuleMatcher(),
        _cache = cache ?? DetectorCache();

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
    List<IdentityCandidate> llmResults = [];
    if (enableLlmFallback && ruleResults.isEmpty) {
      llmResults = await _llmDetect(sceneText, sceneCharacters);
    }

    // 4. 合并结果
    final allCandidates = [...ruleResults, ...llmResults];
    final result = DetectionResult(
      sceneId: sceneId,
      candidates: allCandidates,
      source: ruleResults.isNotEmpty ? 'rule' : (llmResults.isNotEmpty ? 'llm' : 'none'),
    );

    // 5. 写入缓存
    _cache.set(sceneId, result);

    return result;
  }

  /// LLM 兜底检测
  Future<List<IdentityCandidate>> _llmDetect(
    String text,
    List<Character> sceneCharacters,
  ) async {
    final promptService = PromptService();
    final retryHandler = RetryHandler();

    final characterList = sceneCharacters.map((c) => '- ${c.name}').join('\n');

    final prompt = promptService.renderPrompt('identity_detect', {
      'text': text,
      'characters': characterList,
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.3,
      maxTokens: 1024,
    );

    try {
      final result = await retryHandler.execute(() =>
          LLMFactory.create('deepseek')
              .generateStructured<Map<String, dynamic>>(
                request,
                (json) => json,
              ));

      final candidates = <IdentityCandidate>[];
      final identities = result['identities'] as List? ?? [];

      for (final item in identities) {
        final characterName = item['characterName'] as String? ?? '';
        final identityName = item['identityName'] as String? ?? '';
        final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.5;

        final character = sceneCharacters.firstWhere(
          (c) => c.name == characterName,
          orElse: () => sceneCharacters.first,
        );

        candidates.add(IdentityCandidate(
          characterId: character.id,
          identityName: identityName,
          confidence: confidence,
          source: 'llm',
          suggestedWeight: (confidence * 100).round(),
        ));
      }

      return candidates;
    } catch (e) {
      return [];
    }
  }

  /// 清除场景缓存（用户编辑后调用）
  void invalidateScene(String sceneId) {
    _cache.invalidate(sceneId);
  }
}

/// 检测结果
class DetectionResult {
  final String sceneId;
  final List<IdentityCandidate> candidates;
  final String source; // 'rule' | 'llm' | 'none'

  const DetectionResult({
    required this.sceneId,
    this.candidates = const [],
    this.source = 'none',
  });

  bool get hasResults => candidates.isNotEmpty;

  /// 获取新身份（尚未写入数据库的）
  List<IdentityCandidate> get newIdentities => candidates;
}