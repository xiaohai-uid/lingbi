/// 历史题材引导流程 Skill — 官方预装
///
/// 专属引导：朝代背景/官制/军事/经济/文化考据
library;

import 'package:lingbi/shared/models/guided_flow_definition.dart';

/// 历史长篇引导流程
const lishiLongFlowDefinition = GuidedFlowDefinition(
  id: 'lishi-long',
  genre: '历史',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'dynasty-setting',
      name: '朝代与时代',
      prompt: '你是一位历史小说世界观架构师。引导用户确定朝代背景和时代设定。\n\n'
          '需要覆盖：\n'
          '1. 朝代选择（真实朝代/架空朝代/朝代末期/乱世）\n'
          '2. 政治格局（中央集权/藩镇割据/南北对峙/外族入侵）\n'
          '3. 官制体系（三省六部/内阁/军机处/科举制度）\n'
          '4. 经济基础（农业/商业/盐铁/漕运/货币制度）\n'
          '5. 文化氛围（儒释道/理学/心学/文人集团/党争）\n\n'
          '先问用户想要真实历史还是架空，哪个朝代/时期，再深入设定。',
      constraints: [
        '必须明确朝代/时期和政治格局',
        '官制必须有层级（不能只有皇帝和百姓）',
        '必须有经济基础设定（钱从哪来）',
        '必须有文化/思想背景',
      ],
      completionCriteria: '用户已确定了朝代设定：包含政治格局、官制体系、'
          '经济基础、文化氛围。设定内部逻辑自洽。',
      outputs: [
        StepOutput(
          targetFile: 'dynasty_setting.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"dynasty": "朝代/时期", "politicalLandscape": "政治格局", '
              '"officialSystem": "官制", "economy": "经济基础", '
              '"culture": "文化氛围", "coreConflict": "时代核心矛盾"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'power-struggle',
      name: '权谋与军事',
      prompt: '你是一位历史小说权谋架构师。引导用户设计权力斗争和军事格局。\n\n'
          '需要覆盖：\n'
          '1. 权力结构（皇权/相权/军权/外戚/宦官/士族如何博弈）\n'
          '2. 主角的权力起点和上升路径（科举/军功/皇族/商贾）\n'
          '3. 军事设定（兵种/战术/后勤/兵法运用）\n'
          '4. 核心政治矛盾（改革vs守旧/中央vs地方/文vs武）\n'
          '5. 权谋手段（阳谋/阴谋/制衡/借刀/釜底抽薪）\n\n'
          '先问用户想要什么类型（种田发展/权谋争霸/军事征服），再设计。',
      constraints: [
        '必须有清晰的权力博弈结构',
        '主角上升路径必须合理（不能一步登天）',
        '军事设定必须有后勤/地理约束',
        '权谋必须有代价（不是主角永远赢）',
      ],
      completionCriteria: '用户已设计了权谋格局：包含权力结构、主角路径、'
          '军事设定、核心矛盾、权谋手段。',
      outputs: [
        StepOutput(
          targetFile: 'power_struggle.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"powerStructure": "权力结构", "protagonistPath": "上升路径", '
              '"military": "军事设定", "coreConflict": "核心矛盾", '
              '"stratagems": ["权谋手段"]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位历史小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 主角：身份定位（穿越者/土著/重生）？核心优势是什么？\n'
          '   历史知识如何利用？局限性在哪里？\n'
          '2. 君主/上位者：雄主还是庸主？与主角的关系（信任/猜忌/利用）\n'
          '3. 对手：政治对手的理念（不是坏人，是立场不同）\n'
          '4. 武将/谋士：各有性格和诉求（不是工具人）\n\n'
          '先问用户想要什么主角类型（文臣/武将/皇帝/商人），再设计角色。',
      constraints: [
        '主角必须有合理的能力边界',
        '君主与主角的关系必须有张力',
        '对手必须有合理政治理念（不是脸谱化）',
        '配角必须有独立诉求',
      ],
      completionCriteria: '用户已创建核心角色：主角含身份/优势/局限、'
          '君主含关系张力、对手含合理理念、配角有独立诉求。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "定位", '
              '"identity": "身份", "advantage": "优势", "limitation": "局限", '
              '"politicalStance": "政治立场"}], '
              '"rulerRelation": "与君主关系", "coreTension": "核心张力"}',
        ),
      ],
    ),
  ],
);
