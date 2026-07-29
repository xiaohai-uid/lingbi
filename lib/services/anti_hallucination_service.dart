/// 反幻觉三定律 + 监督智能体
///
/// 职责：
/// 1. 约束注入：将世界宪法 Hard Invariants + 当前大纲注入生成 prompt
/// 2. 反幻觉指令：在 system prompt 中嵌入三定律
/// 3. 发明标识：检测 AI 输出中的新设定并标记为 [发明]
/// 4. 状态回写：每章生成后写入 ChapterStateSnapshot
/// 5. 监督 Agent：生成后检查人设/背景一致性，输出修改建议
library;

import 'dart:convert';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/chapter_state_snapshot.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

/// 反幻觉三定律 prompt 指令
const antiHallucinationLaws = '''
【反幻觉三定律 — 不可违反】

第一定律·大纲即法律：
你生成的内容必须严格遵循已确认的大纲。不得偏离大纲中已确定的情节走向、'
角色命运和关键事件。如果用户指令与大纲冲突，以大纲为准并提醒用户。

第二定律·设定即物理：
世界观硬规则（Hard Invariants）如同物理定律，绝对不可违反。'
角色不能做出违反世界规则的行为，除非有已确认的特殊解释。

第三定律·发明需标识：
如果你需要引入大纲和设定中未提及的新元素（新角色/新地点/新规则/新物品），'
必须用 [发明] 标记。例如：[发明] 在山脉深处发现了一座上古遗迹。'
用户将决定是否接受这些发明。''';

/// 监督 Agent 检查结果
class SupervisionIssue {
  const SupervisionIssue({
    required this.type,
    required this.location,
    required this.description,
    required this.suggestion,
    this.severity = IssueSeverity.warning,
  });

  factory SupervisionIssue.fromJson(Map<String, dynamic> json) {
    return SupervisionIssue(
      type: json['type'] as String? ?? '其他',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      severity: IssueSeverity.fromString(json['severity'] as String? ?? 'warning'),
    );
  }

  /// 问题类型（人设漂移/背景矛盾/规则违反/逻辑断裂）
  final String type;

  /// 定位到段落
  final String location;

  /// 问题描述
  final String description;

  /// 修改建议
  final String suggestion;

  /// 严重程度
  final IssueSeverity severity;

  Map<String, dynamic> toJson() => {
        'type': type,
        'location': location,
        'description': description,
        'suggestion': suggestion,
        'severity': severity.value,
      };
}

/// 问题严重程度
enum IssueSeverity {
  info,
  warning,
  error;

  static IssueSeverity fromString(String value) {
    switch (value) {
      case 'error':
        return IssueSeverity.error;
      case 'info':
        return IssueSeverity.info;
      default:
        return IssueSeverity.warning;
    }
  }

  String get value => name;
}

/// 监督 Agent 检查报告
class SupervisionReport {
  const SupervisionReport({
    this.issues = const [],
    this.overallConsistency = 1.0,
    this.summary = '',
  });

  factory SupervisionReport.fromJson(Map<String, dynamic> json) {
    return SupervisionReport(
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => SupervisionIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      overallConsistency:
          (json['overallConsistency'] as num?)?.toDouble() ?? 1.0,
      summary: json['summary'] as String? ?? '',
    );
  }

  /// 发现的问题列表
  final List<SupervisionIssue> issues;

  /// 整体一致性评分 (0.0 ~ 1.0)
  final double overallConsistency;

  /// 总结
  final String summary;

  /// 是否有严重问题
  bool get hasCriticalIssues =>
      issues.any((i) => i.severity == IssueSeverity.error);

  Map<String, dynamic> toJson() => {
        'issues': issues.map((i) => i.toJson()).toList(),
        'overallConsistency': overallConsistency,
        'summary': summary,
      };
}

/// 反幻觉服务
class AntiHallucinationService {
  AntiHallucinationService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  /// 更换 AI Provider
  set aiProvider(AIProvider provider) {
    _aiProvider = provider;
  }

  // ─── 1. 约束注入 ───

  /// 构建约束前缀（注入到 system prompt 最前面）
  ///
  /// 包含：反幻觉三定律 + 世界宪法 Hard Invariants + 当前大纲
  Future<String> buildConstraintPreamble(String projectId) async {
    final buffer = StringBuffer();

    // 反幻觉三定律
    buffer.writeln(antiHallucinationLaws);
    buffer.writeln();

    // 世界宪法 Hard Invariants
    final constitution = await _metaRepository.readConstitution(projectId);
    if (constitution != null && constitution.hardInvariants.isNotEmpty) {
      buffer.writeln('【世界宪法 — 硬规则（绝对不可违反）】');
      for (final rule in constitution.hardInvariants) {
        buffer.writeln('- $rule');
      }
      buffer.writeln();
    }

    // 当前大纲
    final outline = await _metaRepository.read(projectId, 'outline.json');
    if (outline != null) {
      final outlineText = outline['content'] as String? ??
          jsonEncode(outline);
      if (outlineText.isNotEmpty) {
        buffer.writeln('【当前大纲 — 情节走向不可偏离】');
        // 截断过长大纲
        final truncated = outlineText.length > 2000
            ? '${outlineText.substring(0, 2000)}…'
            : outlineText;
        buffer.writeln(truncated);
        buffer.writeln();
      }
    }

    // 已拒绝的发明（后续不应再出现）
    final snapshot = await _readLatestSnapshot(projectId);
    if (snapshot != null) {
      final rejected = snapshot.newInventions
          .where((i) => i.status == InventionStatus.rejected)
          .toList();
      if (rejected.isNotEmpty) {
        buffer.writeln('【已拒绝的发明 — 不得再使用】');
        for (final inv in rejected) {
          buffer.writeln('- ${inv.content}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  // ─── 2. 发明检测 ───

  /// 检测 AI 输出中的 [发明] 标记
  ///
  /// 返回提取到的发明列表。
  List<Invention> detectInventions(String aiOutput) {
    final inventions = <Invention>[];
    final regex = RegExp(r'\[发明\]\s*([^\n。]+)');
    for (final match in regex.allMatches(aiOutput)) {
      final content = match.group(1)?.trim() ?? '';
      if (content.isNotEmpty) {
        inventions.add(Invention(
          content: content,
          category: _categorizeInvention(content),
        ));
      }
    }
    return inventions;
  }

  /// 简单分类发明内容
  String _categorizeInvention(String content) {
    if (content.contains('角色') ||
        content.contains('人物') ||
        content.contains('名字')) {
      return '角色';
    }
    if (content.contains('地点') ||
        content.contains('城市') ||
        content.contains('山') ||
        content.contains('遗迹')) {
      return '地点';
    }
    if (content.contains('规则') ||
        content.contains('体系') ||
        content.contains('法则')) {
      return '规则';
    }
    if (content.contains('物品') ||
        content.contains('武器') ||
        content.contains('丹药') ||
        content.contains('法宝')) {
      return '物品';
    }
    return '其他';
  }

  // ─── 3. 状态回写 ───

  /// 每章生成后写入状态快照
  ///
  /// 调用 AI 从生成内容中提取结构化状态。
  Future<ChapterStateSnapshot> writeChapterSnapshot({
    required String projectId,
    required String chapterId,
    required String generatedContent,
    List<Invention> inventions = const [],
  }) async {
    // 调用 AI 提取状态
    final extractPrompt = '''
从以下章节内容中提取结构化状态信息，以 JSON 格式输出：
{
  "appearingCharacters": ["出场角色名列表"],
  "emotionArc": "情绪走向（一句话）",
  "unresolvedForeshadowing": ["未解伏笔/悬念"],
  "timelinePosition": "时间线位置（如：第三天傍晚）",
  "keyEvents": ["关键事件列表"],
  "locationChanges": ["场景变化"]
}

章节内容：
${generatedContent.length > 4000 ? generatedContent.substring(0, 4000) : generatedContent}''';

    List<String> characters = [];
    String emotionArc = '';
    List<String> foreshadowing = [];
    String timeline = '';
    List<String> events = [];
    List<String> locations = [];

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(role: 'system', content: '你是小说状态提取器，只输出 JSON。'),
          ChatMessage(role: 'user', content: extractPrompt),
        ],
      );

      final jsonStr = _extractJson(result);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        characters = (data['appearingCharacters'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        emotionArc = data['emotionArc'] as String? ?? '';
        foreshadowing = (data['unresolvedForeshadowing'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        timeline = data['timelinePosition'] as String? ?? '';
        events =
            (data['keyEvents'] as List<dynamic>?)?.cast<String>() ?? [];
        locations = (data['locationChanges'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
      }
    } catch (_) {
      // AI 提取失败不阻断，使用空状态
    }

    final snapshot = ChapterStateSnapshot(
      chapterId: chapterId,
      projectId: projectId,
      appearingCharacters: characters,
      emotionArc: emotionArc,
      unresolvedForeshadowing: foreshadowing,
      timelinePosition: timeline,
      newInventions: inventions,
      keyEvents: events,
      locationChanges: locations,
      timestamp: DateTime.now(),
    );

    // 写入 ProjectMetaRepository
    await _metaRepository.write(
      projectId,
      'snapshot_$chapterId.json',
      snapshot.toJson(),
    );

    return snapshot;
  }

  // ─── 4. 监督 Agent ───

  /// 运行监督 Agent 检查生成内容的一致性
  ///
  /// 检查：人设漂移、背景矛盾、规则违反、逻辑断裂
  Future<SupervisionReport> runSupervision({
    required String projectId,
    required String generatedContent,
    String? previousSnapshotJson,
  }) async {
    // 收集约束上下文
    final constitution = await _metaRepository.readConstitution(projectId);
    final hardRules = constitution?.hardInvariants ?? [];

    final supervisionPrompt = '''
你是一位严格的小说一致性审校编辑。请检查以下生成内容是否存在一致性问题。

【世界硬规则（不可违反）】
${hardRules.isEmpty ? '（暂无）' : hardRules.map((r) => '- $r').join('\n')}

${previousSnapshotJson != null ? '【上一章状态】\n$previousSnapshotJson\n' : ''}
【待检查内容】
${generatedContent.length > 5000 ? generatedContent.substring(0, 5000) : generatedContent}

请检查以下维度：
1. 人设漂移：角色性格/能力/关系是否与前文一致
2. 背景矛盾：场景/时间/地理是否前后矛盾
3. 规则违反：是否违反世界硬规则
4. 逻辑断裂：情节因果是否合理

以 JSON 格式输出：
{
  "issues": [
    {"type": "问题类型", "location": "定位（引用原文片段）", "description": "问题描述", "suggestion": "修改建议", "severity": "info/warning/error"}
  ],
  "overallConsistency": 0.0到1.0的一致性评分,
  "summary": "一句话总结"
}

如果没有问题，issues 为空数组，overallConsistency 为 1.0。''';

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system', content: '你是小说一致性审校专家，只输出 JSON。'),
          ChatMessage(role: 'user', content: supervisionPrompt),
        ],
      );

      final jsonStr = _extractJson(result);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return SupervisionReport.fromJson(data);
      }
    } catch (_) {
      // 监督失败不阻断
    }

    return const SupervisionReport(
      summary: '监督检查未能完成（AI 响应异常）',
    );
  }

  // ─── 辅助方法 ───

  /// 读取最新快照
  Future<ChapterStateSnapshot?> _readLatestSnapshot(String projectId) async {
    final files = await _metaRepository.list(projectId);
    final snapshotFiles =
        files.where((f) => f.startsWith('snapshot_')).toList()
          ..sort();
    if (snapshotFiles.isEmpty) return null;

    final data = await _metaRepository.read(projectId, snapshotFiles.last);
    if (data == null) return null;
    return ChapterStateSnapshot.fromJson(data);
  }

  /// 从 AI 输出中提取 JSON
  String? _extractJson(String text) {
    // 尝试直接解析
    try {
      jsonDecode(text);
      return text;
    } catch (_) {}

    // 尝试提取 ```json ... ``` 块
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }

    // 尝试提取 { ... } 块
    final braceStart = text.indexOf('{');
    final braceEnd = text.lastIndexOf('}');
    if (braceStart != -1 && braceEnd > braceStart) {
      return text.substring(braceStart, braceEnd + 1);
    }

    return null;
  }
}
