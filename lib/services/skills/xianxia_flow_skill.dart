/// 仙侠题材引导流程 Skill — 官方预装
///
/// 专属引导：修炼境界/仙门/法宝/天道/劫难
library;

import 'package:lingbi/shared/models/guided_flow_definition.dart';

/// 仙侠长篇引导流程
const xianxiaLongFlowDefinition = GuidedFlowDefinition(
  id: 'xianxia-long',
  genre: '仙侠',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'cultivation-realm',
      name: '修仙体系',
      prompt: '你是一位仙侠小说世界观架构师。引导用户设计修仙体系。\n\n'
          '需要覆盖：\n'
          '1. 修仙境界（练气→筑基→结丹→元婴→化神→渡劫→大乘→飞升）\n'
          '2. 天劫设定（每个大境界的劫难形式：雷劫/心魔劫/天火劫）\n'
          '3. 灵根/体质设定（五行灵根/变异灵根/特殊体质）\n'
          '4. 功法品阶（凡级/灵级/仙级/太古级）\n'
          '5. 丹药/法宝/符箓/阵法等辅助体系\n\n'
          '先问用户偏好传统修仙还是创新体系，再逐步深入。',
      constraints: [
        '必须有清晰的境界划分（至少6个大境界）',
        '必须设计天劫/瓶颈机制（不能无脑升级）',
        '必须有灵根或天赋差异化设定',
        '功法/法宝必须有品阶体系',
      ],
      completionCriteria: '用户已设计了完整修仙体系：包含境界划分、天劫机制、'
          '灵根设定、功法品阶。体系有内在逻辑，升级有代价。',
      outputs: [
        StepOutput(
          targetFile: 'cultivation_system.json',
          extractPrompt: '从对话中提取修仙体系，以 JSON 格式输出：'
              '{"realms": [{"name": "境界", "tribulation": "劫难"}], '
              '"spiritRoots": ["灵根类型"], "techniqueGrades": ["功法品阶"], '
              '"auxiliarySystems": ["辅助体系"], "coreLogic": "核心逻辑"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'sects-immortal',
      name: '仙门与天道',
      prompt: '你是一位仙侠世界势力架构师。引导用户设计仙门格局和天道规则。\n\n'
          '需要覆盖：\n'
          '1. 仙门等级（散修→小门派→中等仙门→顶级仙门→仙界势力）\n'
          '2. 主角所在仙门的道统特色和当前危机\n'
          '3. 天道规则（为什么不能随意杀凡人？因果报应如何运作？）\n'
          '4. 仙界/魔界/妖界的三界关系\n'
          '5. 上古大能留下的传承/禁地\n\n'
          '先问用户想要什么格局（凡界→仙界/单界/多界），再设计势力。',
      constraints: [
        '必须有至少3个不同定位的仙门/势力',
        '必须有天道/因果等约束规则',
        '主角仙门必须有道统特色和困境',
        '必须有至少一个上古传承/秘境',
      ],
      completionCriteria: '用户已设计了仙门格局和天道规则：包含势力层级、'
          '天道约束、三界关系、上古传承。',
      outputs: [
        StepOutput(
          targetFile: 'sects_dao.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"sects": [{"name": "仙门", "dao": "道统", "tier": "等级"}], '
              '"heavenlyDao": "天道规则", "realms": ["界域"], '
              '"ancientLegacies": ["上古传承"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位仙侠小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 主角：灵根/体质是什么？修仙动机（长生/复仇/护道/逍遥）？\n'
          '   道心是否坚定？有何心魔？\n'
          '2. 道侣/红颜：与主角的缘分（前世/因果/共同历练）\n'
          '3. 师兄/同门：竞争还是互助？道统之争？\n'
          '4. 魔道对手：理念冲突（何为正道？何为魔道？）\n\n'
          '先问用户想要什么类型的主角（凡人流/天才流/重生流），再设计角色。',
      constraints: [
        '主角必须有明确的修仙动机和道心考验',
        '必须有理念冲突（不是单纯善恶对立）',
        '至少一个有深度的对手/魔修',
        '角色关系必须与修仙体系挂钩',
      ],
      completionCriteria: '用户已创建核心角色：主角含灵根/动机/道心、'
          '至少一个道侣或同门、一个理念对手。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "定位", '
              '"spiritRoot": "灵根/体质", "dao": "道", "motivation": "动机", '
              '"innerDemon": "心魔"}], "conflicts": ["核心冲突"]}',
        ),
      ],
    ),
  ],
);
