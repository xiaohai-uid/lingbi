/// 都市题材引导流程 Skill — 官方预装
///
/// 专属引导：职业体系/都市势力/现实规则/金手指设定
library;

import 'package:lingbi/core/models/guided_flow_definition.dart';

/// 都市长篇引导流程
const dushiLongFlowDefinition = GuidedFlowDefinition(
  id: 'dushi-long',
  genre: '都市',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'golden-finger',
      name: '金手指与职业',
      prompt: '你是一位都市小说架构师。引导用户设计主角的金手指和职业体系。\n\n'
          '需要覆盖：\n'
          '1. 金手指类型（系统/重生记忆/异能/传承/空间）\n'
          '2. 金手指的限制和成长曲线（不能一开始就无敌）\n'
          '3. 主角职业定位（医生/兵王/厨神/鉴宝/商战）\n'
          '4. 职业领域的专业深度（读者要学到东西）\n'
          '5. 金手指如何与职业结合产生化学反应\n\n'
          '先问用户想要什么类型的爽点（打脸/装逼/逆袭/种田），再设计金手指。',
      constraints: [
        '金手指必须有明确限制（不能万能）',
        '必须有成长曲线（初期弱→逐步解锁）',
        '职业领域必须有专业细节支撑',
        '金手指与职业必须有有机结合',
      ],
      completionCriteria: '用户已设计了金手指（含限制和成长曲线）和职业体系'
          '（含专业领域细节）。金手指与职业有机结合。',
      outputs: [
        StepOutput(
          targetFile: 'golden_finger.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"goldenFinger": {"type": "类型", "limitation": "限制", '
              '"growthCurve": "成长曲线"}, "profession": "职业", '
              '"professionalDepth": "专业细节", "synergy": "结合点"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'urban-factions',
      name: '都市势力',
      prompt: '你是一位都市小说势力架构师。引导用户设计都市势力格局。\n\n'
          '需要覆盖：\n'
          '1. 明面势力（商业集团/官方机构/行业龙头）\n'
          '2. 暗面势力（地下组织/隐世家族/特殊部门）\n'
          '3. 主角起步的社会阶层和上升路径\n'
          '4. 核心冲突源（商业竞争/阶层碾压/恩怨纠葛）\n'
          '5. 都市规则（为什么不能直接动武？权力如何运作？）\n\n'
          '先问用户想要什么格局（纯商战/都市异能/兵王回归），再设计势力。',
      constraints: [
        '必须有明暗两层势力体系',
        '主角必须有明确的阶层起点',
        '必须有不能随意动武的合理约束',
        '势力冲突必须层层递进',
      ],
      completionCriteria: '用户已设计了都市势力格局：包含明暗势力、'
          '主角起点、冲突递进路径、都市规则约束。',
      outputs: [
        StepOutput(
          targetFile: 'urban_factions.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"surfaceFactions": ["明面势力"], "hiddenFactions": ["暗面势力"], '
              '"protagonistStart": "起始阶层", "conflictLadder": ["冲突递进"], '
              '"urbanRules": "都市规则"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位都市小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 主角：为什么隐忍/低调？底线在哪里？爆发点是什么？\n'
          '2. 女主/后宫：每个女性角色的独立价值（不是花瓶）\n'
          '3. 兄弟/搭档：为什么跟主角？各自的诉求？\n'
          '4. 反派层次：小反派（打脸用）→中反派（势力代表）→大反派（终极BOSS）\n\n'
          '先问用户想要什么主角人设（隐忍型/霸道型/腹黑型），再设计角色网。',
      constraints: [
        '主角必须有隐忍/低调的合理原因',
        '女性角色必须有独立人格和诉求',
        '反派必须分层（不能一个BOSS打到底）',
        '必须有兄弟情义线',
      ],
      completionCriteria: '用户已创建核心角色群像：主角含人设/底线/爆发点、'
          '至少一个有深度的女性角色、分层反派。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "定位", '
              '"personality": "性格", "motivation": "诉求", '
              '"relationship": "与主角关系"}], "villainLayers": ["反派层次"]}',
        ),
      ],
    ),
  ],
);
