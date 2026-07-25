/// 悬疑题材引导流程 Skill — 官方预装
///
/// 专属引导：诡计类型/线索管理/叙述性诡计/解谜节奏
library;

import 'package:lingbi/core/models/guided_flow_definition.dart';

/// 悬疑长篇引导流程
const xuanyiLongFlowDefinition = GuidedFlowDefinition(
  id: 'xuanyi-long',
  genre: '悬疑',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'mystery-core',
      name: '核心诡计',
      prompt: '你是一位悬疑小说诡计设计师。引导用户设计核心诡计。\n\n'
          '需要覆盖：\n'
          '1. 诡计类型（密室/不在场证明/身份替换/叙述性诡计/日常之谜）\n'
          '2. 核心谜题（What happened? Who did it? How?）\n'
          '3. 真相的层次（表面真相→深层真相→终极反转）\n'
          '4. 诡计的公平性（读者能否通过线索推理出来？）\n'
          '5. 犯罪动机（为什么必须用这种手法？动机是否令人共情？）\n\n'
          '先问用户偏好本格推理还是社会派，再设计诡计结构。',
      constraints: [
        '必须有明确的核心谜题（一句话能说清）',
        '诡计必须有物理/逻辑可行性',
        '必须设计至少两层真相（表面+深层）',
        '犯罪动机必须有人性深度',
      ],
      completionCriteria: '用户已设计了核心诡计：包含诡计类型、核心谜题、'
          '真相层次、公平性考量、犯罪动机。',
      outputs: [
        StepOutput(
          targetFile: 'mystery_core.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"trickType": "诡计类型", "coreMystery": "核心谜题", '
              '"truthLayers": ["真相层次"], "fairness": "公平性设计", '
              '"motive": "犯罪动机"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'clue-structure',
      name: '线索与节奏',
      prompt: '你是一位悬疑小说结构师。引导用户设计线索网络和叙事节奏。\n\n'
          '需要覆盖：\n'
          '1. 线索分类（真线索/误导线索/隐藏线索/读者已知线索）\n'
          '2. 线索投放节奏（何时给？给多少？如何伪装？）\n'
          '3. 红鲱鱼设计（合理的误导方向）\n'
          '4. 解谜节奏（发现→推理→验证→反转的节拍）\n'
          '5. 叙述视角（第一人称/多视角/不可靠叙述者）\n\n'
          '先问用户想要什么节奏（快节奏惊悚/慢热本格），再设计线索网。',
      constraints: [
        '必须有至少3条真线索和2条误导线索',
        '线索投放必须有节奏设计（不能一次性全给）',
        '必须有至少一个红鲱鱼（合理误导）',
        '叙事视角选择必须服务于诡计',
      ],
      completionCriteria: '用户已设计了线索网络：包含真假线索分类、投放节奏、'
          '红鲱鱼、解谜节拍、叙事视角。',
      outputs: [
        StepOutput(
          targetFile: 'clue_structure.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"trueClues": ["真线索"], "falseClues": ["误导线索"], '
              '"redHerrings": ["红鲱鱼"], "pacing": "解谜节奏", '
              '"narrativePOV": "叙事视角"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位悬疑小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 侦探/主角：推理风格（逻辑型/直觉型/共情型）？缺陷是什么？\n'
          '2. 嫌疑人群像：每个人都有动机，但只有一个是真凶\n'
          '3. 受害者：为什么是TA？TA的秘密是什么？\n'
          '4. 真凶：为什么是TA？读者会不会同情TA？\n\n'
          '先问用户想要什么类型的侦探（专业/业余/被迫卷入），再设计嫌疑人。',
      constraints: [
        '侦探必须有推理风格和人性缺陷',
        '至少3个嫌疑人且各有动机',
        '受害者必须有隐藏秘密',
        '真凶的动机必须令人意外又合理',
      ],
      completionCriteria: '用户已创建核心角色：侦探含风格/缺陷、'
          '至少3个有动机的嫌疑人、有秘密的受害者、意外又合理的真凶。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"detective": {"name": "", "style": "推理风格", "flaw": "缺陷"}, '
              '"suspects": [{"name": "", "motive": "动机", "alibi": "不在场证明"}], '
              '"victim": {"name": "", "secret": "秘密"}, '
              '"culprit": {"name": "", "trueMotive": "真实动机"}}',
        ),
      ],
    ),
  ],
);
