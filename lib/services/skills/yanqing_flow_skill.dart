/// 言情题材引导流程 Skill — 官方预装
///
/// 专属引导：感情线设计/CP互动模式/虐甜节奏/误会机制
library;

import 'package:lingbi/shared/models/guided_flow_definition.dart';

/// 言情长篇引导流程
const yanqingLongFlowDefinition = GuidedFlowDefinition(
  id: 'yanqing-long',
  genre: '言情',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'romance-core',
      name: '感情线设计',
      prompt: '你是一位言情小说架构师。引导用户设计核心感情线。\n\n'
          '需要覆盖：\n'
          '1. CP 模式（先婚后爱/欢喜冤家/破镜重圆/暗恋成真/契约恋爱）\n'
          '2. 核心吸引力（为什么是TA？不可替代性在哪里？）\n'
          '3. 核心障碍（为什么不能在一起？外在阻碍+内在心结）\n'
          '4. 虐甜比例（几分甜几分虐？虐点在哪里？甜点在哪里？）\n'
          '5. 感情升温节奏（初遇→心动→确认→危机→HE）\n\n'
          '先问用户想要什么口味（纯甜/先虐后甜/双向暗恋），再设计感情线。',
      constraints: [
        '必须有明确的 CP 互动模式',
        '核心障碍必须合理（不能是沟通就能解决的误会）',
        '必须有清晰的虐甜节奏设计',
        '感情升温必须有递进节点',
      ],
      completionCriteria: '用户已设计了完整感情线：包含CP模式、核心吸引力、'
          '核心障碍、虐甜比例、升温节奏。',
      outputs: [
        StepOutput(
          targetFile: 'romance_core.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"cpPattern": "CP模式", "attraction": "核心吸引力", '
              '"obstacles": {"external": "外在阻碍", "internal": "内在心结"}, '
              '"sweetAngstRatio": "虐甜比例", "progression": ["升温节点"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'conflict-mechanism',
      name: '冲突与误会机制',
      prompt: '你是一位言情小说冲突设计师。引导用户设计虐点机制和副线。\n\n'
          '需要覆盖：\n'
          '1. 误会机制（信息差/身份隐瞒/第三方搅局/过往创伤投射）\n'
          '2. 虐点设计（分离/误解/牺牲/错过）— 虐要有意义不是为虐而虐\n'
          '3. 副线冲突（事业线/家族线/友情线如何与感情线交织）\n'
          '4. 高潮设计（最大虐点→转折→HE 的情绪曲线）\n'
          '5. 配角功能（助攻/搅局/镜像对照）\n\n'
          '先问用户想要什么虐度（微虐/中虐/大虐大甜），再设计冲突。',
      constraints: [
        '误会机制必须有合理信息差基础',
        '虐点必须推动角色成长（不是为虐而虐）',
        '必须有至少一条与感情线交织的副线',
        '高潮必须有情绪曲线设计',
      ],
      completionCriteria: '用户已设计了冲突机制：包含误会机制、虐点设计、'
          '副线交织、高潮情绪曲线。',
      outputs: [
        StepOutput(
          targetFile: 'conflict_mechanism.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"misunderstanding": "误会机制", "angstPoints": ["虐点"], '
              '"subplots": ["副线"], "climaxCurve": "高潮曲线", '
              '"supportingRoles": ["配角功能"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位言情小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 女主：独立人格是什么？不依附男主的价值在哪里？成长弧线？\n'
          '2. 男主：为什么只对她不同？外冷内热还是外热内冷？创伤/心结？\n'
          '3. 化学反应：两人互动的独特模式（互怼/互补/互相救赎）\n'
          '4. 情敌/前任：存在意义是什么？如何推动主线？\n\n'
          '先问用户想要什么人设组合（强强/互补/救赎），再设计角色。',
      constraints: [
        '女主必须有独立于感情线的人格价值',
        '男主必须有只对她不同的合理原因',
        '两人互动必须有独特化学反应模式',
        '配角必须服务于主线推进',
      ],
      completionCriteria: '用户已创建核心角色：女主含独立人格/成长弧线、'
          '男主含心结/差异化对待、两人有独特互动模式。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"femaleLead": {"name": "", "personality": "独立人格", '
              '"growthArc": "成长弧线"}, "maleLead": {"name": "", '
              '"wound": "心结", "whyHer": "为什么是她"}, '
              '"chemistry": "互动模式", "rivals": ["情敌/前任"]}',
        ),
      ],
    ),
  ],
);
