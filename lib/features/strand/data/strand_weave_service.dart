/// StrandWeave 多线叙事节奏控制服务
///
/// 职责：
/// 1. 管理项目级 StrandWeaveConfig（CRUD + 持久化）
/// 2. 构建配比约束 prompt 文本供 ContextAssembler 注入
/// 3. 解析 AI 输出中的叙事线标注 [线:xxx]
/// 4. 红线约束检测：违反时拦截并提示
/// 5. 记录每章 strandDistribution 到 ChapterStateSnapshot
library;

import 'dart:convert';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/strand_weave_config.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

/// StrandWeave 多线叙事节奏控制服务
class StrandWeaveService {
  StrandWeaveService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  /// 存储文件名
  static const String _fileName = 'strand_weave.json';

  /// 更换 AI Provider
  set aiProvider(AIProvider provider) {
    _aiProvider = provider;
  }

  // ─── 1. 配置 CRUD ───

  /// 加载项目 StrandWeave 配置
  Future<StrandWeaveConfig> loadConfig(String projectId) async {
    final data = await _metaRepository.read(projectId, _fileName);
    if (data == null) return const StrandWeaveConfig();
    return StrandWeaveConfig.fromJson(data);
  }

  /// 保存项目 StrandWeave 配置
  Future<void> saveConfig(
      String projectId, StrandWeaveConfig config) async {
    await _metaRepository.write(projectId, _fileName, config.toJson());
  }

  /// 添加叙事线
  Future<StrandWeaveConfig> addStrand(
    String projectId, {
    required String name,
    required double ratio,
    String description = '',
    String color = '',
  }) async {
    final config = await loadConfig(projectId);
    final strand = Strand(
      name: name,
      ratio: ratio,
      description: description,
      color: color,
    );
    final updated = config.copyWith(strands: [...config.strands, strand]);
    await saveConfig(projectId, updated);
    return updated;
  }

  /// 更新叙事线比例
  Future<StrandWeaveConfig> updateStrandRatio(
    String projectId, {
    required String strandName,
    required double newRatio,
  }) async {
    final config = await loadConfig(projectId);
    final updatedStrands = config.strands.map((s) {
      if (s.name == strandName) return s.copyWith(ratio: newRatio);
      return s;
    }).toList();
    final updated = config.copyWith(strands: updatedStrands);
    await saveConfig(projectId, updated);
    return updated;
  }

  /// 删除叙事线
  Future<StrandWeaveConfig> removeStrand(
    String projectId,
    String strandName,
  ) async {
    final config = await loadConfig(projectId);
    final updatedStrands =
        config.strands.where((s) => s.name != strandName).toList();
    final updated = config.copyWith(strands: updatedStrands);
    await saveConfig(projectId, updated);
    return updated;
  }

  /// 添加红线约束
  Future<StrandWeaveConfig> addRedLine(
    String projectId, {
    required String strandName,
    required String description,
    int maxConsecutiveAbsence = 3,
  }) async {
    final config = await loadConfig(projectId);
    final redLine = RedLine(
      id: 'rl_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      strandName: strandName,
      maxConsecutiveAbsence: maxConsecutiveAbsence,
    );
    final updated =
        config.copyWith(redLines: [...config.redLines, redLine]);
    await saveConfig(projectId, updated);
    return updated;
  }

  /// 删除红线约束
  Future<StrandWeaveConfig> removeRedLine(
    String projectId,
    String redLineId,
  ) async {
    final config = await loadConfig(projectId);
    final updatedRedLines =
        config.redLines.where((r) => r.id != redLineId).toList();
    final updated = config.copyWith(redLines: updatedRedLines);
    await saveConfig(projectId, updated);
    return updated;
  }

  // ─── 2. 配比约束 prompt 构建 ───

  /// 构建叙事线配比约束文本（供 ContextAssembler 注入）
  Future<String> buildConstraintText(String projectId) async {
    final config = await loadConfig(projectId);
    if (!config.enabled || config.strands.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('【多线叙事配比约束 — 必须遵守】');
    buffer.writeln();
    buffer.writeln('本章生成必须遵守以下叙事线配比：');
    for (final strand in config.strands) {
      final percent = (strand.ratio * 100).round();
      final desc =
          strand.description.isNotEmpty ? '（${strand.description}）' : '';
      buffer.writeln('- ${strand.name}: $percent%$desc');
    }
    buffer.writeln();
    buffer.writeln(
        '请在每个段落末尾用 [线:叙事线名称] 标注该段落所属叙事线。');
    buffer.writeln(
        '示例：「他握紧了剑柄，目光坚定。[线:主线]」');

    // 红线约束
    if (config.redLines.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【红线约束 — 不可违反】');
      for (final rl in config.redLines) {
        buffer.writeln(
            '- ${rl.description}（${rl.strandName} 最多连续 ${rl.maxConsecutiveAbsence} 章缺席）');
      }
    }

    return buffer.toString();
  }

  // ─── 3. 叙事线标注解析 ───

  /// 解析 AI 输出中的 [线:xxx] 标注
  ///
  /// 返回段落级标注列表。
  List<StrandAnnotation> parseAnnotations(String aiOutput) {
    final annotations = <StrandAnnotation>[];
    final paragraphs = aiOutput.split('\n').where((p) => p.trim().isNotEmpty);
    final regex = RegExp(r'\[线:([^\]]+)\]');

    var index = 0;
    for (final para in paragraphs) {
      final match = regex.firstMatch(para);
      if (match != null) {
        annotations.add(StrandAnnotation(
          paragraphIndex: index,
          strandName: match.group(1)?.trim() ?? '',
        ));
      }
      index++;
    }
    return annotations;
  }

  /// 从标注列表计算分布
  StrandDistribution computeDistribution(
    List<StrandAnnotation> annotations,
    int totalParagraphs,
  ) {
    if (annotations.isEmpty || totalParagraphs == 0) {
      return const StrandDistribution();
    }

    final counts = <String, int>{};
    for (final a in annotations) {
      counts[a.strandName] = (counts[a.strandName] ?? 0) + 1;
    }

    final distribution = counts.map(
      (name, count) => MapEntry(name, count / totalParagraphs),
    );

    return StrandDistribution(
      distribution: distribution,
      annotations: annotations,
      totalParagraphs: totalParagraphs,
    );
  }

  /// 使用 AI 为无标注内容自动标注叙事线归属
  Future<List<StrandAnnotation>> autoAnnotate({
    required String projectId,
    required String content,
  }) async {
    final config = await loadConfig(projectId);
    if (config.strands.isEmpty) return [];

    final strandNames = config.strands.map((s) => s.name).join('、');
    final prompt = '''
请将以下章节内容的每个段落标注所属叙事线。
可用叙事线：$strandNames

以 JSON 数组格式输出：
[{"paragraphIndex": 0, "strandName": "主线", "confidence": 0.9}, ...]

章节内容：
${content.length > 4000 ? content.substring(0, 4000) : content}''';

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system', content: '你是叙事线分类器，只输出 JSON。'),
          ChatMessage(role: 'user', content: prompt),
        ],
      );

      final jsonStr = _extractJson(result);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as List<dynamic>;
        return data
            .map((e) => StrandAnnotation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // AI 标注失败不阻断
    }
    return [];
  }

  // ─── 4. 红线约束检测 ───

  /// 检测红线违反
  ///
  /// [recentDistributions] — 最近 N 章的叙事线分布（按时间顺序）
  /// 返回所有违反的红线。
  List<RedLineViolation> detectRedLineViolations({
    required StrandWeaveConfig config,
    required List<StrandDistribution> recentDistributions,
    required List<String> chapterIds,
  }) {
    final violations = <RedLineViolation>[];

    for (final redLine in config.redLines) {
      final maxAbsence = redLine.maxConsecutiveAbsence;
      var consecutiveAbsence = 0;
      var lastPresentChapter = '（无记录）';

      // 从最近章节向前扫描
      for (var i = recentDistributions.length - 1; i >= 0; i--) {
        final dist = recentDistributions[i];
        final strandRatio = dist.distribution[redLine.strandName] ?? 0.0;

        if (strandRatio > 0) {
          lastPresentChapter =
              i < chapterIds.length ? chapterIds[i] : '第${i + 1}章';
          break;
        }
        consecutiveAbsence++;
      }

      if (consecutiveAbsence >= maxAbsence) {
        violations.add(RedLineViolation(
          redLine: redLine,
          consecutiveAbsence: consecutiveAbsence,
          lastPresentChapter: lastPresentChapter,
        ));
      }
    }

    return violations;
  }

  /// 生成门禁检查 — 在生成前检测红线
  ///
  /// 返回 null 表示通过，否则返回违反信息列表。
  Future<List<RedLineViolation>?> preGenerationGate(
      String projectId) async {
    final config = await loadConfig(projectId);
    if (!config.enabled || config.redLines.isEmpty) return null;

    // 读取最近章节的分布记录
    final distributions = await _loadRecentDistributions(projectId);
    if (distributions.isEmpty) return null;

    final chapterIds = distributions.keys.toList();
    final distValues = distributions.values.toList();

    final violations = detectRedLineViolations(
      config: config,
      recentDistributions: distValues,
      chapterIds: chapterIds,
    );

    return violations.isEmpty ? null : violations;
  }

  // ─── 5. 分布记录 ───

  /// 记录章节叙事线分布
  Future<void> recordDistribution({
    required String projectId,
    required String chapterId,
    required StrandDistribution distribution,
  }) async {
    await _metaRepository.write(
      projectId,
      'strand_dist_$chapterId.json',
      distribution.toJson(),
    );
  }

  /// 读取章节分布记录
  Future<StrandDistribution?> loadDistribution({
    required String projectId,
    required String chapterId,
  }) async {
    final data = await _metaRepository.read(
        projectId, 'strand_dist_$chapterId.json');
    if (data == null) return null;
    return StrandDistribution.fromJson(data);
  }

  // ─── 辅助方法 ───

  /// 加载最近章节的分布记录
  Future<Map<String, StrandDistribution>> _loadRecentDistributions(
      String projectId) async {
    final files = await _metaRepository.list(projectId);
    final distFiles =
        files.where((f) => f.startsWith('strand_dist_')).toList()
          ..sort();

    // 最多取最近 10 章
    final recent = distFiles.length > 10
        ? distFiles.sublist(distFiles.length - 10)
        : distFiles;

    final result = <String, StrandDistribution>{};
    for (final file in recent) {
      final data = await _metaRepository.read(projectId, file);
      if (data != null) {
        final chapterId = file
            .replaceFirst('strand_dist_', '')
            .replaceFirst('.json', '');
        result[chapterId] = StrandDistribution.fromJson(data);
      }
    }
    return result;
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

    final bracketStart = text.indexOf('[');
    final bracketEnd = text.lastIndexOf(']');
    if (bracketStart != -1 && bracketEnd > bracketStart) {
      return text.substring(bracketStart, bracketEnd + 1);
    }

    return null;
  }
}
