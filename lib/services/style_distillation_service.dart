/// 风格蒸馏引擎服务
///
/// 职责：
/// 1. 从用户作品中提取文笔 DNA（句式/用词/节奏/修辞偏好）
/// 2. StyleProfile 存储为独立资产（全局级，跨项目引用）
/// 3. 项目绑定 StyleProfile（项目级引用）
/// 4. 构建风格约束 prompt 供 ContextAssembler 注入
/// 5. 支持用户编辑微调提取结果
library;

import 'dart:convert';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/style_profile.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

/// 风格蒸馏服务
class StyleDistillationService {
  StyleDistillationService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  /// 全局风格档案存储文件
  static const String _globalFile = 'style_profiles.json';

  /// 项目绑定文件
  static const String _bindingFile = 'style_binding.json';

  /// 最少源文本字数
  static const int minSourceWordCount = 5000;

  /// 更换 AI Provider
  set aiProvider(AIProvider provider) {
    _aiProvider = provider;
  }

  // ─── 1. 风格提取 ───

  /// 从用户作品中提取风格特征
  ///
  /// [sourceText] — 用户作品文本（至少 5000 字）
  /// [name] — 风格档案名称
  /// 返回提取到的 StyleProfile。
  Future<StyleProfile> extractStyle({
    required String sourceText,
    required String name,
  }) async {
    if (sourceText.length < minSourceWordCount) {
      throw ArgumentError(
          '源文本不足 $minSourceWordCount 字（当前 ${sourceText.length} 字），'
          '无法有效提取风格特征');
    }

    // 截取代表性片段（避免超出 token 限制）
    final sampleText = _selectRepresentativeSample(sourceText);

    final prompt = '''
你是一位文学风格分析专家。请从以下文本中提取作者的文笔 DNA，以 JSON 格式输出：

{
  "sentencePatterns": ["句式特征列表，如：短句为主、长短交替、善用倒装"],
  "vocabulary": [
    {"trait": "用词特征描述", "examples": ["示例词1", "示例词2"], "frequency": "高频/中频/偶尔"}
  ],
  "rhythm": {
    "avgSentenceLength": 15,
    "paragraphLength": "短段落/长段落/混合",
    "pacing": "紧凑/舒缓/张弛有度",
    "tensionCurve": "渐进式/波浪式/爆发式"
  },
  "rhetoricPreferences": [
    {"name": "修辞名称", "frequency": "高频/中频/偶尔", "example": "示例句"}
  ],
  "samples": [
    {"text": "代表性文段（50-100字）", "source": "来源位置", "highlight": "为何选此段"}
  ],
  "description": "一段话总结该作者的文风特点（100字以内）"
}

待分析文本：
$sampleText''';

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system', content: '你是文学风格分析专家，只输出 JSON。'),
          ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: 4096,
      );

      final jsonStr = _extractJson(result);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final now = DateTime.now();
        return StyleProfile(
          id: 'sp_${now.millisecondsSinceEpoch}',
          name: name,
          sentencePatterns: (data['sentencePatterns'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
          vocabulary: (data['vocabulary'] as List<dynamic>?)
                  ?.map((e) =>
                      VocabularyTrait.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          rhythm: data['rhythm'] != null
              ? RhythmProfile.fromJson(data['rhythm'] as Map<String, dynamic>)
              : const RhythmProfile(),
          rhetoricPreferences: (data['rhetoricPreferences'] as List<dynamic>?)
                  ?.map((e) => RhetoricPreference.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
          samples: (data['samples'] as List<dynamic>?)
                  ?.map(
                      (e) => StyleSample.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          description: data['description'] as String? ?? '',
          sourceWordCount: sourceText.length,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (_) {
      // AI 提取失败，返回空档案
    }

    // 降级：返回基础档案
    return StyleProfile(
      id: 'sp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: '风格提取未能完成（AI 响应异常），请手动编辑。',
      sourceWordCount: sourceText.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ─── 2. 全局存储（跨项目） ───

  /// 获取所有风格档案
  Future<List<StyleProfile>> listProfiles(String projectId) async {
    final data = await _metaRepository.read(projectId, _globalFile);
    if (data == null) return [];
    return (data['profiles'] as List<dynamic>?)
            ?.map((e) => StyleProfile.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// 保存风格档案（新增或更新）
  Future<void> saveProfile(
      String projectId, StyleProfile profile) async {
    final profiles = await listProfiles(projectId);
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _metaRepository.write(projectId, _globalFile, {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 删除风格档案
  Future<void> deleteProfile(String projectId, String profileId) async {
    final profiles = await listProfiles(projectId);
    profiles.removeWhere((p) => p.id == profileId);
    await _metaRepository.write(projectId, _globalFile, {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 获取指定风格档案
  Future<StyleProfile?> getProfile(
      String projectId, String profileId) async {
    final profiles = await listProfiles(projectId);
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  // ─── 3. 项目绑定 ───

  /// 绑定风格档案到项目
  Future<void> bindProfile(
      String projectId, String profileId) async {
    await _metaRepository.write(projectId, _bindingFile, {
      'profileId': profileId,
      'boundAt': DateTime.now().toIso8601String(),
    });
  }

  /// 解绑风格档案
  Future<void> unbindProfile(String projectId) async {
    await _metaRepository.delete(projectId, _bindingFile);
  }

  /// 获取项目当前绑定的风格档案
  Future<StyleProfile?> getBoundProfile(String projectId) async {
    final binding = await _metaRepository.read(projectId, _bindingFile);
    if (binding == null) return null;
    final profileId = binding['profileId'] as String? ?? '';
    if (profileId.isEmpty) return null;
    return getProfile(projectId, profileId);
  }

  // ─── 4. ContextAssembler 集成 ───

  /// 构建风格约束 prompt 文本（供 ContextAssembler 注入）
  Future<String> buildStyleConstraintText(String projectId) async {
    final profile = await getBoundProfile(projectId);
    if (profile == null) return '';
    return profile.toPromptText();
  }

  // ─── 5. 编辑微调 ───

  /// 更新风格档案（用户编辑微调）
  Future<StyleProfile> updateProfile(
    String projectId,
    StyleProfile updated,
  ) async {
    final withTimestamp = StyleProfile(
      id: updated.id,
      name: updated.name,
      sentencePatterns: updated.sentencePatterns,
      vocabulary: updated.vocabulary,
      rhythm: updated.rhythm,
      rhetoricPreferences: updated.rhetoricPreferences,
      samples: updated.samples,
      description: updated.description,
      sourceWordCount: updated.sourceWordCount,
      createdAt: updated.createdAt,
      updatedAt: DateTime.now(),
    );
    await saveProfile(projectId, withTimestamp);
    return withTimestamp;
  }

  // ─── 辅助方法 ───

  /// 选取代表性文本片段
  String _selectRepresentativeSample(String text) {
    // 取前中后各一段，总计约 6000 字
    if (text.length <= 6000) return text;

    const partLen = 2000;
    final start = text.substring(0, partLen);
    final midStart = (text.length - partLen) ~/ 2;
    final mid = text.substring(midStart, midStart + partLen);
    final end = text.substring(text.length - partLen);

    return '$start\n\n…（中段）…\n\n$mid\n\n…（末段）…\n\n$end';
  }

  /// 从 AI 输出中提取 JSON
  String? _extractJson(String text) {
    try {
      jsonDecode(text);
      return text;
    } catch (_) {}

    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }

    final braceStart = text.indexOf('{');
    final braceEnd = text.lastIndexOf('}');
    if (braceStart != -1 && braceEnd > braceStart) {
      return text.substring(braceStart, braceEnd + 1);
    }

    return null;
  }
}
