/// Prompt 模板管理服务
///
/// 管理从 YAML 文件加载的类型化 Prompt 模板库。
/// 模板来源：AI_NovelGenerator prompt_definitions/prompt_default.yaml
library prompt_service;

/// 类型化 Prompt 模板
class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.constraints = const PromptConstraints(),
  });
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final PromptConstraints constraints;
}

/// Prompt 生成约束
class PromptConstraints {
  const PromptConstraints({
    this.minChars = 500,
    this.maxChars = 30000,
    this.rules = const [],
  });
  final int minChars;
  final int maxChars;
  final List<String> rules;
}

/// 写作类型指南
class GenreGuide {
  const GenreGuide({
    required this.id,
    required this.name,
    required this.description,
    this.corePrinciples = const [],
    this.conventions = const [],
    this.designPatterns = const {},
  });
  final String id;
  final String name;
  final String description;
  final List<String> corePrinciples;
  final List<String> conventions;
  final Map<String, String> designPatterns;
}

/// Prompt 服务
class PromptService {
  PromptService() {
    _initBuiltinTemplates();
    _initBuiltinGenres();
  }
  final Map<String, PromptTemplate> _templates = {};
  final Map<String, GenreGuide> _genres = {};

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
    if (template == null) return '';

    var prompt = template.systemPrompt;
    for (final entry in variables.entries) {
      prompt = prompt.replaceAll('{{${entry.key}}}', entry.value);
    }
    return prompt;
  }

  void _initBuiltinTemplates() {
    _templates['expand_idea'] = const PromptTemplate(
      id: 'expand_idea',
      name: '创意展开',
      description: '从用户创意展开为完整故事梗概',
      systemPrompt: '''你是一名资深网文编辑，擅长将创意转化为爆款故事。

【创作理念】
- 冲突前置：开篇必须有强力冲突
- 金手指设计：主角有独特优势
- 期待感：每个章节结尾留钩子
- 打脸爽感：主角反击反派的场景要有张力

【标准输出】
请输出：故事梗概(500-1000字) + 核心人设(3-8个) + 世界设定 + 核心主题

用户创意：{{idea}}
类型：{{genre}}
风格：{{style}}''',
      constraints: PromptConstraints(
        rules: [
          '冲突前置：开篇3-5%篇幅内出现强力冲突',
          '金手指设计：主角有独特优势',
          '期待感：每个章节结尾留下钩子',
          '打脸爽感：主角反击场景要有张力',
        ],
      ),
    );

    _templates['style_analysis'] = const PromptTemplate(
      id: 'style_analysis',
      name: '风格分析',
      description: '分析文本的写作风格特征',
      systemPrompt: '''你是一个文学风格分析专家。

请分析以下文本的写作风格，包括：
1. 用词特点（词汇丰富度、常用词）
2. 句式结构（长短句比例、复杂度）
3. 语气语调（正式/口语、情感色彩）
4. 修辞手法（比喻、排比等使用频率）
5. 节奏感（叙述密度、高潮分布）

请用中文输出结构化分析报告。

文本：
{{text}}''',
    );

    _templates['novel_deconstruction'] = const PromptTemplate(
      id: 'novel_deconstruction',
      name: '小说拆解',
      description: '分析小说的结构和叙事手法',
      systemPrompt: '''你是一个小说结构分析专家。

请从以下文本中识别：
1. 角色系统（主角/配角/反派的设定与弧光）
2. 情节线（主线/支线的交织）
3. 章节结构（起承转合、钩子位置）
4. 叙事视角（人称、视点切换）
5. 主题表达（核心主题与副主题）
6. 冲突类型（人物/社会/内心冲突）

请用中文输出结构化报告。

文本：
{{text}}''',
    );

    // ─── v3.1 新增模板 ───

    _templates['generate_outline'] = const PromptTemplate(
      id: 'generate_outline',
      name: '生成卷章细纲',
      description: '从故事梗概生成完整的卷-章-场景细纲结构',
      systemPrompt: '''你是一名资深网文编辑，擅长将故事梗概扩展为完整的卷章细纲。

【输入】
故事梗概：{{synopsis}}
卷数：{{numVolumes}}
每卷章数：{{chaptersPerVolume}}
每章场景数：{{scenesPerChapter}}

【创作要求】
1. 每卷有明确的故事弧（起承转合）
2. 每章有清晰的核心冲突和钩子
3. 每章至少 {{scenesPerChapter}} 个场景
4. 角色出场频率合理，主角戏份集中
5. 情节推进有节奏感：小高潮→铺垫→大高潮

【JSON 输出格式】
严格按照以下 JSON 结构输出，不要输出额外内容：
```json
{
  "volumes": [
    {
      "volumeNumber": 1,
      "title": "卷标题",
      "summary": "卷概要300-800字",
      "chapters": [
        {
          "chapterNumber": 1,
          "title": "章标题",
          "summary": "章概要200-500字",
          "hook": "章末钩子",
          "scenes": [
            {
              "sceneNumber": 1,
              "title": "场景标题",
              "summary": "场景概要100-300字",
              "characters": ["角色名"],
              "location": "场景地点",
              "mood": "氛围",
              "conflict": "冲突描述"
            }
          ]
        }
      ]
    }
  ]
}
```''',
    );

    _templates['stream_scene'] = const PromptTemplate(
      id: 'stream_scene',
      name: '生成场景正文',
      description: '基于场景细纲流式生成正文内容',
      systemPrompt: '''你是一名网文写手，根据场景细纲创作正文。

【场景信息】
场景：{{sceneTitle}}
概要：{{sceneSummary}}
人物：{{characters}}
地点：{{location}}
氛围：{{mood}}
冲突：{{conflict}}

【故事上下文】
梗概：{{synopsis}}
角色档案：{{characterContext}}
前情提要：{{previousSceneSummary}}

【创作要求】
1. 每段 200-500 字，流畅自然
2. 保持人物性格一致性
3. 对话真实，符合角色身份
4. 氛围描写到位，增强代入感
5. 如有冲突，写出生动感
6. 结尾自然过渡到下一场景

直接输出正文内容，不要标题、不要解说。''',
    );

    _templates['character_check'] = const PromptTemplate(
      id: 'character_check',
      name: '角色一致性检测',
      description: '检测文本中的角色行为是否与人设一致',
      systemPrompt: '''你是一名角色一致性检测专家。

【角色人设】
{{profiles}}

【待检测文本】
{{text}}

请逐角色分析其行为是否符合人设，输出 JSON：
```json
{
  "isConsistent": true/false,
  "deviationScore": 0-100,
  "issues": [
    {
      "type": "personality/motivation/dialogue_style/emotion",
      "description": "问题描述",
      "severity": 1-10
    }
  ],
  "suggestions": ["建议1", "建议2"]
}
```''',
    );

    _templates['identity_detect'] = const PromptTemplate(
      id: 'identity_detect',
      name: '身份识别',
      description: '分析场景中角色的身份称谓',
      systemPrompt: '''你是一位专业的文学分析助手。请分析以下场景文本中每个角色被称呼的身份。

【场景角色列表】
{{characters}}

【场景文本】
{{text}}

请输出以下 JSON 格式：
{
  "identities": [
    {
      "characterName": "角色名（必须来自角色列表）",
      "identityName": "识别出的身份称谓",
      "confidence": 0.0-1.0
    }
  ]
}

规则：
1. 只分析角色列表中出现的角色
2. identityName 应为具体的身份称谓（如"掌门"、"师妹"、"将军"等）
3. confidence 表示识别置信度
4. 如果无法确定身份，可以跳过该角色
5. 只输出 JSON，不要包含其他内容''',
    );

    _templates['butterfly_effect'] = const PromptTemplate(
      id: 'butterfly_effect',
      name: '蝴蝶效应分析',
      description: '分析时间线事件变更对剧情走向和角色权重的影响',
      systemPrompt: '''你是一位专业的文学分析助手。请分析以下时间线事件如果发生变更，会对整个故事产生怎样的蝴蝶效应。

【事件标题】
{{eventTitle}}

【事件描述】
{{eventDescription}}

【事件变更描述】
{{changeDescription}}

【涉及角色】
{{characterContext}}

请输出以下 JSON 格式：
{
  "predictedDirection": "剧情走向预测",
  "impacts": [
    {
      "characterId": "角色ID",
      "characterName": "角色名",
      "weightDelta": -100到100之间的整数（权重变化，正数为增强，负数为削弱）,
      "reason": "影响原因",
      "direction": "positive/negative/neutral"
    }
  ],
  "tokenCost": 0,
  "estimatedCost": 0.0
}

规则：
1. predictedDirection 应简明扼要地预测剧情走向
2. weightDelta 范围 -100 到 +100，正数表示角色权重增强，负数表示削弱
3. direction 只能取 positive、negative、neutral
4. 只输出 JSON，不要包含其他内容''',
    );
  }

  void _initBuiltinGenres() {
    _genres['fantasy'] = const GenreGuide(
      id: 'fantasy',
      name: '奇幻',
      description: '架空世界、魔法系统、种族文明',
      corePrinciples: [
        '桑德森第一定律：读者对魔法的享受程度与理解程度成正比',
        '桑德森第二定律：限制比能力更有趣',
        '桑德森第三定律：在添加新内容之前先拓展已有内容',
      ],
      conventions: [
        '魔法系统必须有清晰规则',
        '世界设定必须内在一致',
        '种族/生物要独特且有逻辑',
        '至少三代历史积淀',
      ],
      designPatterns: {
        'magic_source': '魔法来源？有限还是无限？',
        'magic_rules': '谁能使用？需要什么条件？',
        'magic_cost': '使用魔法的代价是什么？',
        'magic_limits': '明确什么是做不到的',
      },
    );

    _genres['mystery'] = const GenreGuide(
      id: 'mystery',
      name: '悬疑',
      description: '推理破案、线索布局、真相揭晓',
      corePrinciples: [
        'Fair Play 原则：读者必须与侦探同时获得所有线索',
        '逻辑推导：解决方案必须能从已呈现的事实中推导出',
        '禁止 Deus Ex Machina：不能凭空出现新角色作为凶手',
      ],
      conventions: [
        '触发事件在开篇 10% 内发生',
        '误导线索 3-5 条贯穿全文',
        '真实线索在 75% 前全部呈现',
        '真相在 85-95% 揭晓',
      ],
      designPatterns: {
        'false_lead': '误导线索设计',
        'fair_play_clue': '公平线索放置',
        'red_herring': '烟雾弹设置',
        'final_twist': '结局反转',
      },
    );

    _genres['urban'] = const GenreGuide(
      id: 'urban',
      name: '都市',
      description: '现代都市背景，现实与超现实的交织',
      corePrinciples: [
        '真实感：都市背景要有现实细节支撑',
        '代入感：主角的困境要让读者感同身受',
        '成长线：从平凡到不凡的清晰路径',
      ],
      conventions: [
        '开篇展现主角的日常困境',
        '金手指隐藏在都市背景中',
        '冲突来自社会阶层/人性',
      ],
      designPatterns: {
        'daily_life': '日常生活描写',
        'special_ability': '都市异能设计',
        'social_conflict': '社会阶层冲突',
      },
    );
  }
}
