/// 科幻题材引导流程 Skill — 官方预装
///
/// 专属引导：科技树/星际政治/AI伦理/硬科幻约束
library;

import 'package:lingbi/shared/models/guided_flow_definition.dart';

/// 科幻长篇引导流程
const kehuanLongFlowDefinition = GuidedFlowDefinition(
  id: 'kehuan-long',
  genre: '科幻',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'tech-tree',
      name: '科技树设定',
      prompt: '你是一位科幻小说世界观架构师。引导用户设计科技树。\n\n'
          '需要覆盖：\n'
          '1. 核心科技突破（FTL/意识上传/基因编辑/纳米技术/戴森球）\n'
          '2. 科技对社会的影响（经济/政治/伦理/阶层如何被重塑）\n'
          '3. 硬科幻约束（能量守恒/光速限制/热力学定律如何遵守或绕过）\n'
          '4. 科技等级（人类当前→近未来→远未来→星际文明）\n'
          '5. 科技的双刃剑效应（同一技术如何同时造福和毁灭）\n\n'
          '先问用户偏好硬科幻还是软科幻，再设计科技树。',
      constraints: [
        '必须有至少一个核心科技突破点',
        '必须说明科技对社会结构的冲击',
        '硬科幻必须有物理约束说明',
        '科技必须有双刃剑效应',
      ],
      completionCriteria: '用户已设计了科技树：包含核心突破、社会影响、'
          '物理约束、科技等级、双刃剑效应。',
      outputs: [
        StepOutput(
          targetFile: 'tech_tree.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"coreBreakthrough": "核心科技", "socialImpact": "社会影响", '
              '"constraints": "物理约束", "techLevels": ["科技等级"], '
              '"doubleEdge": "双刃剑效应"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'interstellar-politics',
      name: '星际政治与文明',
      prompt: '你是一位科幻小说文明架构师。引导用户设计星际政治格局。\n\n'
          '需要覆盖：\n'
          '1. 文明形态（联邦/帝国/AI治理/企业联合体/后人类共同体）\n'
          '2. 星际政治格局（多极/单极/冷战/热战边缘）\n'
          '3. 核心矛盾（资源争夺/意识形态/AI权利/基因歧视）\n'
          '4. 费米悖论解答（外星文明存在吗？为什么没接触？）\n'
          '5. 人类在宇宙中的定位（渺小/特殊/先驱/遗产继承者）\n\n'
          '先问用户想要什么尺度（近未来地球/太阳系/银河系），再设计政治。',
      constraints: [
        '必须有明确的文明治理形态',
        '必须有至少两个势力/阵营的核心矛盾',
        '必须回答费米悖论（或明确不回答）',
        '政治格局必须受科技水平约束',
      ],
      completionCriteria: '用户已设计了星际政治：包含文明形态、政治格局、'
          '核心矛盾、费米悖论立场、人类定位。',
      outputs: [
        StepOutput(
          targetFile: 'interstellar_politics.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"civilization": "文明形态", "politicalLandscape": "政治格局", '
              '"coreConflicts": ["核心矛盾"], "fermiParadox": "费米悖论解答", '
              '"humanPosition": "人类定位"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位科幻小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 主角：在科技洪流中的定位（科学家/军人/普通人/AI/后人类）\n'
          '   核心困境（人性vs技术/个体vs文明/自由vs安全）\n'
          '2. AI角色：如果有AI，它的人格/权利/与人类的关系\n'
          '3. 对手：代表另一种文明路径或价值观\n'
          '4. 科幻命题的人格化（如何通过角色展现科技伦理困境）\n\n'
          '先问用户想要什么主角类型（硬汉/学者/反英雄/AI视角），再设计。',
      constraints: [
        '主角必须面临科技伦理困境',
        '必须有代表对立价值观的对手',
        '角色命运必须与核心科技紧密绑定',
        '必须通过角色展现科幻命题',
      ],
      completionCriteria: '用户已创建核心角色：主角含科技伦理困境、'
          '对手含对立价值观、角色命运与科技绑定。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "定位", '
              '"techRelation": "与核心科技关系", "ethicalDilemma": "伦理困境", '
              '"values": "价值观"}], "coreQuestion": "核心科幻命题"}',
        ),
      ],
    ),
  ],
);
