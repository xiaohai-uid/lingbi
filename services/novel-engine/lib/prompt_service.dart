/// Prompt 模板管理服务 — 三层生成管线专用
///
/// 内置小说生成所需的核心 Prompt 模板。
/// 未来可从 YAML 文件加载（当前以硬编码兜底）。
library prompt_service;

/// 生成约束
class PromptConstraints {
  final int minChars;
  final int maxChars;
  final List<String> rules;

  const PromptConstraints({
    this.minChars = 500,
    this.maxChars = 30000,
    this.rules = const [],
  });
}

/// 类型化 Prompt 模板
class PromptTemplate {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final PromptConstraints constraints;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.constraints = const PromptConstraints(),
  });
}

/// 写作类型指南
class GenreGuide {
  final String id;
  final String name;
  final String description;
  final List<String> corePrinciples;
  final List<String> conventions;
  final Map<String, String> designPatterns;

  const GenreGuide({
    required this.id,
    required this.name,
    required this.description,
    this.corePrinciples = const [],
    this.conventions = const [],
    this.designPatterns = const {},
  });
}

/// Prompt 服务
class PromptService {
  final Map<String, PromptTemplate> _templates = {};
  final Map<String, GenreGuide> _genres = {};

  PromptService() {
    _initBuiltinTemplates();
    _initBuiltinGenres();
  }

  /// 获取指定 ID 的 Prompt 模板
  PromptTemplate? getTemplate(String id) => _templates[id];

  /// 获取所有可用模板
  List<PromptTemplate> get allTemplates => _templates.values.toList();

  /// 获取指定 ID 的类型指南
  GenreGuide? getGenre(String id) => _genres[id];

  /// 获取所有类型指南
  List<GenreGuide> get allGenres => _genres.values.toList();

  /// 渲染 Prompt：将变量替换为实际值
  String renderPrompt(String templateId, Map<String, String> variables) {
    final template = _templates[templateId];
    if (template == null) {
      throw ArgumentError('Prompt template not found: $templateId');
    }
    var result = template.systemPrompt;
    for (final entry in variables.entries) {
      final value = entry.value.isNotEmpty ? entry.value : '（未提供）';
      result = result.replaceAll('{{${entry.key}}}', value);
    }
    return result;
  }

  /// 初始化内置模板
  void _initBuiltinTemplates() {
    _templates['expand_idea'] = PromptTemplate(
      id: 'expand_idea',
      name: '创意扩展',
      description: '将用户创意扩展为故事梗概和核心角色',
      systemPrompt: _buildExpandIdeaPrompt(),
      constraints: const PromptConstraints(minChars: 500, maxChars: 10000),
    );

    _templates['generate_outline'] = PromptTemplate(
      id: 'generate_outline',
      name: '细纲生成',
      description: '基于梗概生成分卷分章细纲',
      systemPrompt: _buildGenerateOutlinePrompt(),
      constraints: const PromptConstraints(minChars: 1000, maxChars: 30000),
    );

    _templates['stream_scene'] = PromptTemplate(
      id: 'stream_scene',
      name: '场景流式生成',
      description: '基于细纲流式生成场景正文',
      systemPrompt: _buildStreamScenePrompt(),
      constraints: const PromptConstraints(minChars: 100, maxChars: 5000),
    );
  }

  /// 初始化内置类型指南
  void _initBuiltinGenres() {
    _genres['fantasy'] = GenreGuide(
      id: 'fantasy',
      name: '玄幻',
      description: '东方玄幻/奇幻',
      corePrinciples: ['修炼体系清晰', '世界观宏大', '战斗场面精彩'],
      conventions: ['炼气/筑基/金丹/元婴等级', '宗门/家族/王朝势力', '法宝/丹药/阵法'],
      designPatterns: {
        'qidian': '起点流 — 升级打脸、爽点密集',
        'traditional': '传统玄幻 — 修炼体系严谨',
      },
    );

    _genres['xianxia'] = GenreGuide(
      id: 'xianxia',
      name: '仙侠',
      description: '修仙/仙侠',
      corePrinciples: ['修仙等级清晰', '因果循环', '大道无情'],
      conventions: ['练气/筑基/金丹/元婴/化神', '洞天福地', '渡劫飞升'],
    );

    _genres['urban'] = GenreGuide(
      id: 'urban',
      name: '都市',
      description: '都市异能/职场',
      corePrinciples: ['贴近生活', '爽点现实化', '情感细腻'],
    );

    _genres['scifi'] = GenreGuide(
      id: 'scifi',
      name: '科幻',
      description: '硬科幻/软科幻',
      corePrinciples: ['逻辑自洽', '科技设定严谨', '人文思考'],
    );
  }

  // ── Prompt 模板构建 ──────────────────────────────────────────────────────

  String _buildExpandIdeaPrompt() =>
      '''你是一位专业的小说策划编辑。请根据用户的创意，扩展成一个完整的故事梗概和核心角色设定。

## 用户创意
{{idea}}

## 写作类型：{{genre}}
## 风格：{{style}}

## 输出要求
请严格按以下 JSON 格式输出：

{
  "synopsis": "500-1000字的故事梗概，包括背景、主线冲突、核心转折",
  "setting": "时代背景和世界观设定（200字以内）",
  "themes": ["主题1", "主题2", "主题3"],
  "characters": [
    {
      "name": "角色名",
      "role": "主角/配角/反派",
      "age": 年龄数字或null,
      "personality": "性格描述",
      "backstory": "背景故事",
      "motivation": "核心动机",
      "arc": "角色弧光"
    }
  ]
}

## 写作指南
{{genreGuide}}

请确保输出是合法的 JSON，不要包含任何其他内容。''';

  String _buildGenerateOutlinePrompt() => '''你是一位专业的小说大纲设计师。请根据故事梗概，生成完整的分卷分章细纲。

## 故事梗概
{{synopsis}}

## 设定
{{setting}}

## 主题
{{themes}}

## 结构要求
- 总卷数：{{numVolumes}}
- 每卷章节数：{{numChaptersPerVolume}}
- 每章包含 3-6 个场景

## 输出要求
请输出以下 JSON 格式：

{
  "volumes": [
    {
      "title": "卷名",
      "summary": "卷概要（50字以内）",
      "chapters": [
        {
          "title": "章名",
          "summary": "章概要（100字以内）",
          "scenes": [
            {
              "title": "场景标题",
              "summary": "场景描述（100-300字）",
              "characters": ["出现角色"],
              "location": "发生地点",
              "mood": "场景氛围",
              "conflict": "冲突点"
            }
          ]
        }
      ]
    }
  ]
}

请确保输出是合法的 JSON，不要包含任何其他内容。''';

  String _buildStreamScenePrompt() => '''你是一位专业的小说作家。请根据场景大纲，撰写场景正文。

## 场景信息
- 场景标题：{{sceneTitle}}
- 场景概要：{{sceneSummary}}
- 涉及角色：{{characters}}
- 发生地点：{{location}}
- 氛围：{{mood}}
- 冲突：{{conflict}}

## 上下文
- 故事梗概：{{synopsis}}
- 前情摘要：{{previousSceneSummary}}

## 写作要求
- 直接输出正文，不要包含任何元数据
- 字数 500-2000 字
- 对话要生动，描写要细腻
- 保持与整体故事风格一致（{{genre}} / {{style}}）''';
}
