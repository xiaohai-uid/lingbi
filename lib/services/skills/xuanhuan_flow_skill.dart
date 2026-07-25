/// 玄幻题材引导流程 Skill — 官方预装
///
/// 包含玄幻题材专属引导步骤：修炼体系、宗门势力、地理种族、核心角色。
/// 问题具有题材专业性，不是通用问题套玄幻皮。
library;

import 'package:lingbi/core/models/guided_flow_definition.dart';

/// 玄幻长篇引导流程
///
/// 4 步：修炼体系 → 宗门势力 → 地理种族 → 核心角色
const xuanhuanLongFlowDefinition = GuidedFlowDefinition(
  id: 'xuanhuan-long',
  genre: '玄幻',
  type: GuidedFlowType.long,
  steps: [
    GuidedFlowStep(
      id: 'cultivation-system',
      name: '修炼体系',
      prompt: '你是一位玄幻小说世界观架构师。引导用户设计修炼体系。\n\n'
          '需要覆盖：\n'
          '1. 修炼境界划分（如：炼气→筑基→金丹→元婴→化神…）\n'
          '2. 每个大境界的突破条件和标志\n'
          '3. 修炼资源（灵石/丹药/功法/天材地宝）\n'
          '4. 修炼流派（剑修/体修/魂修/阵修等）\n'
          '5. 战力越级规则（为什么主角能越级战斗）\n\n'
          '先问用户想要什么风格的修炼体系（传统仙侠式/自创体系/游戏化），'
          '再逐步深入每个维度。',
      constraints: [
        '必须有清晰的境界划分（至少5个大境界）',
        '必须说明突破瓶颈的条件',
        '必须有至少一种核心修炼资源',
        '必须解释越级战斗的合理性',
      ],
      completionCriteria: '用户已设计了完整的修炼体系：包含至少5个境界层级、'
          '突破条件、核心资源类型、至少一个修炼流派特色。'
          '体系内部逻辑自洽，能支撑长篇升级节奏。',
      outputs: [
        StepOutput(
          targetFile: 'cultivation_system.json',
          extractPrompt: '从对话中提取修炼体系设定，以 JSON 格式输出：'
              '{"realms": [{"name": "境界名", "level": 1, "breakthroughCondition": "突破条件", '
              '"markers": ["境界标志"]}], "resources": ["修炼资源类型"], '
              '"schools": [{"name": "流派名", "specialty": "特色"}], '
              '"powerScaling": "越级战斗规则", "coreLogic": "体系核心逻辑"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'sects-factions',
      name: '宗门势力',
      prompt: '你是一位玄幻小说势力架构师。引导用户设计宗门和势力格局。\n\n'
          '需要覆盖：\n'
          '1. 顶级势力（圣地/帝级宗门）及其底蕴\n'
          '2. 主角所在宗门的定位和特色\n'
          '3. 势力等级体系（散修→小家族→中等宗门→顶级圣地）\n'
          '4. 势力间关系（同盟/敌对/附庸/暗中角力）\n'
          '5. 宗门内部结构（外门/内门/核心/长老/宗主）\n\n'
          '先问用户想要多大的势力格局（单一大陆/多界域），'
          '再设计主角起步的宗门和远期目标势力。',
      constraints: [
        '必须有至少3个不同等级的势力',
        '主角宗门必须有明确特色和当前困境',
        '必须有势力间的核心矛盾/冲突源',
        '宗门内部等级必须与修炼体系挂钩',
      ],
      completionCriteria: '用户已设计了完整的势力格局：包含至少3个层级分明的势力、'
          '主角宗门的定位和特色、势力间核心矛盾、宗门内部晋升结构。',
      outputs: [
        StepOutput(
          targetFile: 'factions.json',
          extractPrompt: '从对话中提取势力设定，以 JSON 格式输出：'
              '{"factions": [{"name": "势力名", "tier": "等级", "specialty": "特色", '
              '"leader": "掌权者", "strength": "底蕴"}], '
              '"protagonistFaction": {"name": "", "position": "", "crisis": ""}, '
              '"conflicts": ["核心矛盾"], "hierarchy": "势力等级体系"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'geography-races',
      name: '地理与种族',
      prompt: '你是一位玄幻小说世界地理师。引导用户设计世界地理和种族。\n\n'
          '需要覆盖：\n'
          '1. 世界结构（大陆/星域/位面/小千世界）\n'
          '2. 核心地域划分（东荒/南域/北原/中州…）及灵气浓度差异\n'
          '3. 种族设定（人族/妖族/魔族/灵族/远古种族）\n'
          '4. 种族天赋与限制（为什么人族需要修炼而妖族靠血脉）\n'
          '5. 秘境/禁地/上古遗迹（升级地图）\n\n'
          '先问用户偏好什么规模的世界（单大陆/多界域/宇宙级），'
          '再设计地理层次和种族生态。',
      constraints: [
        '必须有清晰的世界层级结构',
        '至少设计3个有特色的地域',
        '至少2个非人种族且有独特天赋',
        '必须有至少一个秘境/禁地作为剧情驱动',
      ],
      completionCriteria: '用户已设计了完整的世界地理：包含世界结构、'
          '至少3个特色地域、种族设定（含天赋差异）、至少一个秘境/禁地。',
      outputs: [
        StepOutput(
          targetFile: 'geography_races.json',
          extractPrompt: '从对话中提取地理种族设定，以 JSON 格式输出：'
              '{"worldStructure": "世界层级", '
              '"regions": [{"name": "地域名", "feature": "特色", "spiritDensity": "灵气浓度"}], '
              '"races": [{"name": "种族", "talent": "天赋", "limitation": "限制"}], '
              '"secretRealms": [{"name": "秘境名", "danger": "危险等级", "reward": "机缘"}]}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-characters',
      name: '核心角色',
      prompt: '你是一位玄幻小说角色设计师。引导用户创建核心角色。\n\n'
          '需要覆盖：\n'
          '1. 主角：金手指/机缘是什么？性格内核（隐忍/霸道/腹黑/赤子）？\n'
          '   起始境界和初期目标？核心驱动力（复仇/守护/求道/自由）？\n'
          '2. 女主/重要配角：与主角的关系张力\n'
          '3. 初期反派：压迫感来源（境界碾压/势力碾压/血脉碾压）\n'
          '4. 师父/引路人：为什么帮主角？有何隐藏目的？\n\n'
          '先问用户想要什么类型的主角（废柴逆袭/天才降临/重生复仇），'
          '再设计配套的角色关系网。',
      constraints: [
        '主角必须有明确的"金手指"或核心机缘',
        '主角性格必须有内在矛盾（不是完美人设）',
        '必须有至少一个有压迫感的初期反派',
        '角色关系必须能产生持续冲突',
      ],
      completionCriteria: '用户已创建了核心角色群像：主角含金手指/性格/驱动力、'
          '至少一个配角/女主、一个初期反派。角色间有明确冲突关系。',
      outputs: [
        StepOutput(
          targetFile: 'characters.json',
          extractPrompt: '从对话中提取角色设定，以 JSON 格式输出：'
              '{"characters": [{"name": "姓名", "role": "主角/配角/反派/引路人", '
              '"cultivation": "当前境界", "personality": "性格内核", '
              '"motivation": "核心驱动力", "cheat": "金手指/机缘（主角专属）", '
              '"conflicts": ["与其他角色的冲突"]}], '
              '"relationshipWeb": "核心关系网描述"}',
        ),
      ],
    ),
  ],
);

/// 玄幻短篇引导流程（精简版：修炼设定 + 核心冲突）
const xuanhuanShortFlowDefinition = GuidedFlowDefinition(
  id: 'xuanhuan-short',
  genre: '玄幻',
  type: GuidedFlowType.short,
  steps: [
    GuidedFlowStep(
      id: 'quick-worldbuilding',
      name: '修炼速设',
      prompt: '你是一位玄幻短篇架构师。短篇不需要宏大世界观，'
          '但需要一个精巧的修炼设定作为故事引擎。\n\n'
          '引导用户快速确定：\n'
          '1. 核心修炼概念（一个就够，如：吞噬/时间/因果）\n'
          '2. 主角当前境界和瓶颈\n'
          '3. 打破瓶颈的契机（故事起点）\n\n'
          '短篇重在"一个设定的极致演绎"，不要贪多。',
      constraints: [
        '只聚焦一个核心修炼概念',
        '必须明确主角的起始困境',
      ],
      completionCriteria: '用户已确定核心修炼概念、主角起始境界和困境、'
          '以及打破困境的契机。',
      outputs: [
        StepOutput(
          targetFile: 'quick_world.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"coreConcept": "核心修炼概念", "protagonistRealm": "起始境界", '
              '"dilemma": "当前困境", "catalyst": "破局契机"}',
        ),
      ],
    ),
    GuidedFlowStep(
      id: 'core-conflict',
      name: '核心冲突',
      prompt: '引导用户设计短篇的核心冲突和情绪高潮。\n\n'
          '玄幻短篇的冲突模式：\n'
          '- 越级挑战（以弱胜强的爽感）\n'
          '- 身份揭露（隐藏血脉/前世）\n'
          '- 抉择（修炼代价/道心考验）\n\n'
          '问用户想要哪种情绪体验（燃/虐/爽/悟），再设计冲突结构。',
      constraints: [
        '冲突必须在1-2个场景内爆发',
        '必须有明确的情绪高潮点',
      ],
      completionCriteria: '用户已确定冲突类型、情绪基调、高潮场景设计。',
      outputs: [
        StepOutput(
          targetFile: 'conflict_design.json',
          extractPrompt: '从对话中提取，以 JSON 格式输出：'
              '{"conflictType": "冲突类型", "emotionTone": "情绪基调", '
              '"climaxScene": "高潮场景", "resolution": "结局走向"}',
        ),
      ],
    ),
  ],
);
