/// 默认引导流程定义 — 通用长篇/短篇模板
///
/// 当没有题材专属 Skill 时使用此通用流程。
/// 题材 Skill 加载后会替换为专属定义。
library;

import 'package:lingbi/shared/models/guided_flow_definition.dart';

/// 通用长篇引导流程（世界观 + 核心角色）
const defaultLongFlowDefinition = GuidedFlowDefinition(
  id: 'default-long',
  genre: '通用',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'worldbuilding',
      name: '世界观构建',
      prompt: '引导用户构建小说的世界观设定。包括：故事发生的时代背景、地理环境、'
          '社会结构、核心规则（如修炼体系/科技水平/魔法系统等）。'
          '通过提问帮助用户逐步完善世界观。',
      constraints: [
        '必须明确故事发生的时代和地点',
        '必须有一个核心力量/规则体系',
        '至少描述一个主要势力或组织',
      ],
      completionCriteria: '用户已描述了完整的世界观：包含时代背景、地理环境、'
          '核心力量体系、至少一个主要势力。信息足够开始创作。',
      outputs: [
        StepOutput(
          targetFile: 'worldbuilding.json',
          extractPrompt: '从对话中提取世界观设定，以 JSON 格式输出：'
              '{"era": "时代背景", "geography": "地理环境", "powerSystem": "力量/规则体系", '
              '"factions": ["势力/组织列表"], "rules": ["世界运行规则"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'characters',
      name: '核心角色',
      prompt: '引导用户创建核心角色。包括：主角（姓名、性格、动机、背景故事）、'
          '主要配角、核心反派。通过提问帮助用户赋予角色生命力。',
      constraints: [
        '至少创建一个有完整设定的主角',
        '主角必须有明确的动机和目标',
        '至少有一个核心冲突关系',
      ],
      completionCriteria: '用户已创建了至少一个主角（含姓名、性格、动机、背景），'
          '以及至少一个与主角有冲突关系的角色。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "主角/配角/反派", '
              '"personality": "性格", "motivation": "动机", "backstory": "背景故事", '
              '"relationships": [{"target": "对象", "type": "关系类型"}]}]}',
        ),
      ],
    ),
  ],
);

/// 通用短篇引导流程（情绪设计 + 反转构思）
const defaultShortFlowDefinition = GuidedFlowDefinition(
  id: 'default-short',
  genre: '通用',
  type: GuidedFlowType.short,
  steps: [
    GuidedFlowStep(
      id: 'emotion',
      name: '情绪设计',
      prompt: '引导用户设计短篇故事的情绪曲线。包括：故事核心情感、'
          '开头钩子、情绪高潮点、结尾余韵。短篇重在情绪密度。',
      constraints: [
        '必须明确故事的核心情感（如遗憾/释然/震撼）',
        '必须设计至少一个情绪转折点',
      ],
      completionCriteria: '用户已设计了完整的情绪曲线：核心情感明确，'
          '有开头钩子、情绪高潮和结尾设计。',
      outputs: [
        StepOutput(
          targetFile: 'emotion_design.json',
          extractPrompt: '从对话中提取情绪设计，以 JSON 格式输出：'
              '{"coreEmotion": "核心情感", "hook": "开头钩子", '
              '"climax": "情绪高潮", "ending": "结尾设计", '
              '"turningPoints": ["转折点列表"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'twist',
      name: '反转构思',
      prompt: '引导用户构思故事反转。包括：反转类型（身份/认知/时间线）、'
          '伏笔布局、读者预期管理。好的反转 = 意料之外 + 情理之中。',
      constraints: [
        '反转必须有前文伏笔支撑',
        '必须考虑读者预期如何被引导和打破',
      ],
      completionCriteria: '用户已确定反转方案：反转类型明确，'
          '有对应的伏笔设计，读者预期管理策略清晰。',
      outputs: [
        StepOutput(
          targetFile: 'twist_design.json',
          extractPrompt: '从对话中提取反转设计，以 JSON 格式输出：'
              '{"twistType": "反转类型", "description": "反转描述", '
              '"foreshadowing": ["伏笔列表"], "readerExpectation": "读者预期管理"}',
        ),
      ],
    ),
  ],
);

/// 注册默认流程定义到引擎
void registerDefaultFlows(GuidedFlowEngineAccessor engine) {
  engine.register(defaultLongFlowDefinition);
  engine.register(defaultShortFlowDefinition);
}

/// 引擎访问接口（避免循环依赖）
abstract class GuidedFlowEngineAccessor {
  void register(GuidedFlowDefinition definition);
}
