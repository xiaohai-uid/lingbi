/// Skill 类型
enum SkillType {
  /// 轻量级 Skill（纯 prompt 模板）
  lightweight,

  /// 重量级 Skill（含代码插件）
  heavyweight,
}

/// Skill 清单数据类，描述一个 Skill 的元数据
class SkillManifest {
  const SkillManifest({
    required this.id,
    required this.name,
    required this.description,
    required this.promptTemplate,
    this.type = SkillType.lightweight,
    this.category,
    this.version,
  });

  /// 唯一标识符
  final String id;

  /// 显示名称
  final String name;

  /// 简短描述
  final String description;

  /// Prompt 模板内容
  final String promptTemplate;

  /// Skill 类型，默认 lightweight
  final SkillType type;

  /// 分类（可选）
  final String? category;

  /// 版本号（可选）
  final String? version;
}

/// SKILL.md 内容解析器，支持 Anthropic frontmatter 和纯 Markdown 两种格式
class SkillManifestParser {
  SkillManifestParser._();

  /// 解析 SKILL.md 内容为 [SkillManifest]
  ///
  /// [content] — SKILL.md 的原始文本内容
  /// [skillId] — Skill 的唯一标识符（通常来自目录名）
  static SkillManifest parse(String content, String skillId) {
    if (content.trim().isEmpty) {
      throw const FormatException('SKILL.md 内容不能为空');
    }
    // 检测 Anthropic frontmatter（以 --- 开头）
    if (content.startsWith('---')) {
      return _parseFrontmatter(content, skillId);
    }
    // fallback: 纯 Markdown 社区格式
    return _parseMarkdown(content, skillId);
  }

  /// 解析含 YAML frontmatter 的格式
  ///
  /// ```
  /// ---
  /// name: skill-name
  /// description: A description
  /// ---
  /// Markdown body...
  /// ```
  static SkillManifest _parseFrontmatter(String content, String skillId) {
    final endOfFrontmatter = content.indexOf('---', 3);
    if (endOfFrontmatter == -1) {
      throw const FormatException('frontmatter 未闭合');
    }
    final yaml = content.substring(3, endOfFrontmatter).trim();
    final body = content.substring(endOfFrontmatter + 3).trim();

    final name = _extractYamlField(yaml, 'name') ?? skillId;
    final description = _extractYamlField(yaml, 'description') ?? '';

    return SkillManifest(
      id: skillId,
      name: name,
      description: description,
      promptTemplate: body,
    );
  }

  /// 解析纯 Markdown 社区格式
  ///
  /// ```
  /// # Skill 名称
  ///
  /// > 一句话描述
  ///
  /// ## 适用场景
  /// ...
  /// ```
  static SkillManifest _parseMarkdown(String content, String skillId) {
    final lines = content.split('\n');
    String name = skillId;
    String description = '';
    final bodyBuffer = StringBuffer();
    bool foundTitle = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!foundTitle && line.startsWith('# ')) {
        name = line.substring(2).trim();
        foundTitle = true;
      } else if (foundTitle && description.isEmpty && line.startsWith('> ')) {
        description = line.substring(2).trim();
      } else if (foundTitle) {
        bodyBuffer.writeln(line);
      }
    }

    if (!foundTitle) {
      throw const FormatException('SKILL.md 缺少标题行（# 开头）');
    }

    return SkillManifest(
      id: skillId,
      name: name,
      description: description,
      promptTemplate: bodyBuffer.toString().trim(),
    );
  }

  /// 从简单 YAML 文本中提取 key: value 字段值
  static String? _extractYamlField(String yaml, String key) {
    final regex = RegExp('^$key:\\s*(.+)\$', multiLine: true);
    final match = regex.firstMatch(yaml);
    return match?.group(1)?.trim();
  }
}
