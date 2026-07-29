/// DistillationService — 蒸馏即创作
///
/// 从用户的 Canon（世界观）+ 写作风格自动生成轻量 SKILL.md，
/// 实现知识积累飞轮的核心能力：产品越用越懂用户。
///
/// 蒸馏出的 Skill 两者合一（Q7 决策）：
/// - 风格 prompt（句式/用词频率/修辞偏好）
/// - Canon 引用（角色/设定/世界观要素）
library;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/skill_marketplace.dart';

/// 蒸馏结果
class DistillationResult {
  const DistillationResult({
    required this.success,
    this.skillId = '',
    this.skillName = '',
    this.skillMdContent = '',
    this.error,
  });

  final bool success;
  final String skillId;
  final String skillName;
  final String skillMdContent;
  final String? error;
}

/// 蒸馏配置
class DistillationConfig {
  const DistillationConfig({
    required this.projectId,
    required this.projectName,
    this.documentPaths = const [],
    this.maxSampleChars = 6000,
    this.skillName = '',
  });

  /// 项目 ID
  final String projectId;

  /// 项目名称（用于生成 Skill 名称）
  final String projectName;

  /// 文档文件路径列表（用作用户写作风格样本）
  final List<String> documentPaths;

  /// 每个文档样本最大字符数（避免超出 token 限制）
  final int maxSampleChars;

  /// 自定义 Skill 名称（为空则自动生成）
  final String skillName;
}

/// 蒸馏服务 — Canon + 风格 → 自动生成 SKILL.md
class DistillationService {
  DistillationService({
    required CanonService canonService,
    required AIService aiService,
    required DocumentService documentService,
    required SkillMarketplace marketplace,
  })  : _canonService = canonService,
        _aiService = aiService,
        _documentService = documentService,
        _marketplace = marketplace;

  final CanonService _canonService;
  final AIService _aiService;
  final DocumentService _documentService;
  final SkillMarketplace _marketplace;

  /// 执行蒸馏：收集素材 → AI 分析 → 生成 SKILL.md → 保存并注册
  Future<DistillationResult> distill(DistillationConfig config) async {
    try {
      // 1. 收集 Canon 条目
      final canonSummary = await _collectCanon(config.projectId);

      // 2. 收集文档样本
      final writingSamples = await _collectWritingSamples(config);

      if (writingSamples.isEmpty && canonSummary.isEmpty) {
        return const DistillationResult(
          success: false,
          error: '没有可用的素材。请先创建正典条目或写一些文档。',
        );
      }

      // 3. AI 分析风格 + 生成 SKILL.md 内容
      final skillMdContent = await _generateSkillMd(
        config: config,
        canonSummary: canonSummary,
        writingSamples: writingSamples,
      );

      // 4. 确定 Skill ID 和名称
      final skillName = config.skillName.isNotEmpty
          ? config.skillName
          : '${config.projectName}风格';
      final skillId = _slugify(skillName);

      // 5. 以明确的 development 状态安装，并记录项目范围与来源元数据。
      final installed = await _marketplace.installDistilledSkill(
        skillId: skillId,
        projectId: config.projectId,
        content: skillMdContent,
      );
      if (!installed) {
        return const DistillationResult(
          success: false,
          error: '蒸馏结果未通过本地 Skill 安全校验。',
        );
      }

      return DistillationResult(
        success: true,
        skillId: skillId,
        skillName: skillName,
        skillMdContent: skillMdContent,
      );
    } catch (e) {
      return DistillationResult(success: false, error: '蒸馏失败: $e');
    }
  }

  /// 收集项目的所有 Canon 条目，生成结构化摘要
  Future<String> _collectCanon(String projectId) async {
    try {
      final allEntries = await _canonService.getAllForProject(projectId);
      final buffer = StringBuffer();

      for (final type in CanonEntryType.values) {
        final entries = allEntries[type] ?? [];
        if (entries.isEmpty) continue;

        final typeLabel = _typeLabel(type);
        buffer.writeln('### $typeLabel');
        for (final entry in entries.take(10)) {
          buffer.writeln('- ${entry.name}: ${entry.description}');
          if (entry.attributes.isNotEmpty) {
            final attrs = entry.attributes.entries
                .take(5)
                .map((e) => '${e.key}=${e.value}')
                .join(', ');
            buffer.writeln('  属性: $attrs');
          }
        }
        buffer.writeln();
      }

      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// 收集文档写作样本
  Future<String> _collectWritingSamples(DistillationConfig config) async {
    final buffer = StringBuffer();

    for (final path in config.documentPaths.take(3)) {
      try {
        final content = await _documentService.readContent(path);
        final truncated = content.length > config.maxSampleChars
            ? content.substring(0, config.maxSampleChars)
            : content;
        buffer.writeln('--- 样本 ---');
        buffer.writeln(truncated);
        buffer.writeln();
      } catch (_) {
        // 单个文档读取失败不阻断
      }
    }

    return buffer.toString().trim();
  }

  /// 调用 AI 生成 SKILL.md 内容
  Future<String> _generateSkillMd({
    required DistillationConfig config,
    required String canonSummary,
    required String writingSamples,
  }) async {
    final skillName = config.skillName.isNotEmpty
        ? config.skillName
        : '${config.projectName}风格';

    final prompt = StringBuffer();
    prompt.writeln('你是一个 Skill 生成专家。请根据以下素材，生成一个 SKILL.md 文件内容。');
    prompt.writeln();
    prompt.writeln('## 要求');
    prompt.writeln('1. 使用 Anthropic 标准 SKILL.md 格式（YAML frontmatter + Markdown 正文）');
    prompt.writeln('2. frontmatter 包含 name 和 description');
    prompt.writeln('3. 正文是一个写作风格模仿 prompt 模板');
    prompt.writeln('4. 风格 prompt 必须包含：句式特征、用词偏好、修辞手法、节奏感');
    prompt.writeln('5. 必须包含世界观引用部分（角色/设定/世界观要素）');
    prompt.writeln('6. 使用 input 作为占位符表示用户输入的续写前文');
    prompt.writeln('7. 使用 canon_summary 作为占位符表示世界观摘要');
    prompt.writeln();
    prompt.writeln('## 输出格式（严格遵守）');
    prompt.writeln('```');
    prompt.writeln('---');
    prompt.writeln('name: $skillName');
    prompt.writeln('description: 基于《${config.projectName}》蒸馏的写作风格技能');
    prompt.writeln('---');
    prompt.writeln('（这里是 prompt 模板正文，包含风格指令和占位符）');
    prompt.writeln('```');
    prompt.writeln();

    if (canonSummary.isNotEmpty) {
      prompt.writeln('## 世界观素材（Canon）');
      prompt.writeln(canonSummary);
      prompt.writeln();
    }

    if (writingSamples.isNotEmpty) {
      prompt.writeln('## 写作风格样本');
      prompt.writeln(writingSamples);
      prompt.writeln();
    }

    prompt.writeln('请直接输出 SKILL.md 的完整内容（包含 --- frontmatter ---），不要添加额外说明。');

    final messages = [
      const ChatMessage(
        role: 'system',
        content: '你是一个 AI 写作工具的 Skill 生成器。你的任务是从用户的写作样本和世界观设定中'
            '蒸馏出一个可复用的写作风格 Skill。输出必须是合法的 SKILL.md 格式。',
      ),
      ChatMessage(role: 'user', content: prompt.toString()),
    ];

    final result = await _aiService.currentProvider.chatSync(
      messages: messages,
    );

    // 清理 AI 输出（去除可能的代码块包裹）
    return _cleanSkillMdOutput(result);
  }

  /// 清理 AI 输出中可能的代码块包裹
  String _cleanSkillMdOutput(String output) {
    var cleaned = output.trim();
    // 去除 ```markdown ... ``` 或 ``` ... ``` 包裹
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }
    return cleaned;
  }

  /// 将名称转为合法的目录名（slug）
  String _slugify(String name) {
    // 保留中文、英文、数字、连字符
    final slug = name
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();
    return slug.isEmpty ? 'my-style-skill' : slug;
  }

  /// Canon 类型中文标签
  String _typeLabel(CanonEntryType type) {
    switch (type) {
      case CanonEntryType.character:
        return '角色';
      case CanonEntryType.location:
        return '地点';
      case CanonEntryType.lore:
        return '传说';
      case CanonEntryType.plotNode:
        return '情节节点';
    }
  }
}
