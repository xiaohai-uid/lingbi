# LingBi 技能路由体系蒸馏规格 (蒸馏自 reverse-skill)

> 创建: 2026-08-04 | 作者: opencode (基于 reverse-skill 实战审计)
> 用途: 本文件是给下一个 AI 的完整实施规格。目标是让 LingBi 达到 reverse-skill 的"技能路由体系"级别。
> 蒸馏对象: https://github.com/zhaoxuya520/reverse-skill (已部署于本机, 仓库根: /mnt/c/Users/a1691/.codex/skills/reverse-skill)
> 目标工程: /mnt/c/Users/a1691/Documents/Qoder/lingbi-impl (Flutter, 256 个 dart 文件)

---

## 0. 审计结论 (2026-08-04 实测)

LingBi 的**技能引擎层已达标甚至超过** reverse-skill:
- `lib/features/skill/data/skill/skill_loader.dart` / `skill_executor.dart` / `skill_manifest.dart` — SKILL.md 式三级加载 ✅
- `lib/domain/security/capability_grant.dart` — 9 种细粒度能力授权 (比 reverse-skill 的 scope-contract 更细) 🏆
- `skill_permission.dart` / `skill_audit_log.dart` / `skill_marketplace.dart` — 授权/审计/市场 🏆

**缺失的三块 (本规格只蒸馏这三块, 其余不要倒退):**

| # | 缺失模块 | reverse-skill 对照 | 现状证据 |
|---|---|---|---|
| A | **任务路由矩阵** | `skills/routing.md` 三轴矩阵 + `MASTER-ROUTING.md` PRIMARY 阶梯 | `skill_action_service.dart` 注释明确: "AI 主动推荐不属于本轮" — 技能只能被斜杠命令/工具栏手动触发 |
| B | **工具自举** | `skills/tool-index.md` + `bootstrap-reverse.sh` 检测-安装循环 | 无任何"检测本机能力→缺则引导"机制 |
| C | **经验进化** | `skills/field-journal/` precedent 跨会话复用 | `skill_audit_log.dart` 只有审计记录, 无"任务开始先查历史经验"的复用逻辑 |

---

## 1. 模块 A: 任务路由矩阵 (Routing Matrix)

### 1.1 目标

让 AI 拿到用户任务时, **先路由后执行**: 自动从已安装技能中选出 PRIMARY, 而不是等用户手动触发。对应 reverse-skill 的执行契约第 1 条 "先路由后动手"。

### 1.2 数据结构 (新建 `lib/features/routing/route_engine.dart`)

```dart
/// 路由维度 — 复刻 reverse-skill 的三轴 (目标类型 × 用户意图 × 工具面)
class RouteDimension {
  final String id;          // 'scene' | 'intent' | 'input_scope'
  final String value;       // 场景值, 如 'novel_continuation'
  final double weight;      // 权重 0-1
}

/// 路由规则 — 一条规则 = 一组维度条件 + 命中的技能
class RouteRule {
  final String skillId;             // 命中技能的 id (对应 SkillManifest.id)
  final List<RouteDimension> dimensions;
  final double minScore;            // 达标阈值, 建议 0.6
  final String fallbackPrompt;      // 未完全命中时的引导语
}

/// 路由结果
class RouteResult {
  final String skillId;
  final double score;
  final List<String> matchedKeys;   // 命中的关键词证据 (用于可解释性)
}

/// 路由引擎 — 核心匹配逻辑
class RouteEngine {
  RouteEngine(this._rules, this._registry);

  final List<RouteRule> _rules;
  final SkillRegistry _registry;    // 现有技能注册表 (复用 skill_loader)

  /// 输入: 用户消息 + 上下文 (选区内容/当前场景/已装技能列表)
  RouteResult? route({
    required String userMessage,
    String? selection,              // 选区文本
    String currentScene = '',       // 当前编辑器场景
  }) {
    final scored = <(RouteRule, double)>[];
    for (final rule in _rules) {
      final score = _score(rule, userMessage, selection, currentScene);
      if (score >= rule.minScore) scored.add((rule, score));
    }
    if (scored.isEmpty) return null;  // 未命中 → 走 1.5 未命中处理
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return RouteResult(skillId: scored.first.$1.skillId, score: scored.first.$2, matchedKeys: []);
  }

  double _score(RouteRule rule, String msg, String? sel, String scene) {
    var total = 0.0, weightSum = 0.0;
    for (final d in rule.dimensions) {
      weightSum += d.weight;
      if (_match(d, msg, sel, scene)) total += d.weight;
    }
    return weightSum == 0 ? 0 : total / weightSum;
  }

  bool _match(RouteDimension d, String msg, String? sel, String scene) {
    // 关键词表 → 场景表 → 输入范围, 见 1.4
  }
}
```

### 1.3 集成点 (3 处, 按此改)

1. **`lib/features/skill/data/skill_action_service.dart`** — 在斜杠命令/工具栏入口**之前**插入 `RouteEngine.route()`: 用户消息先过路由, 命中则自动执行/推荐, 未命中再回退现有手动入口。同时删掉注释里 "AI 主动推荐不属于本轮" 的约束。
2. **`lib/services/ai_service.dart`** — AI 对话主循环: 消息进入 LLM 前先路由, 把命中技能注入 system prompt (即 reverse-skill 的 "Available Skills" 注入模式, 参照 OpenWrite 的 system_message 组装: base_prompt + Available Tools + Available Skills + Current Context)。
3. **`lib/features/skill/ui/skill_market_page.dart`** — 技能市场新增技能时, 自动要求携带 RouteRule 元数据 (否则路由引擎不命中新技能)。

### 1.4 初始矩阵数据 (新建 `lib/features/routing/default_rules.dart`)

以现有技能和写作场景为轴, 首版覆盖 (字段: 维度 → 关键词 → 权重):

| 技能 (SkillManifest.id) | 场景维度 (scene, w=0.5) | 意图维度 (intent, w=0.3) | 输入范围 (input_scope, w=0.2) |
|---|---|---|---|
| 智能续写 | novel_continuation: 续写/接着写/继续/下一段 | create: 生成/创作 | selection 或全文档 |
| 文本润色 | polish: 润色/改一下/优化/通顺 | edit: 修改/改进 | selection |
| 降低AI痕迹 | deai: 降低AI痕迹/像人写/去AI味 | edit | selection |
| 章节摘要 | summary: 摘要/总结/概括 | analyze | 全文档 |
| 人物库维护 | character: 人物/角色 | update | canon |
| 世界观维护 | worldview: 世界观/设定/背景 | update | canon |

关键词表要可配置 (JSON/常量), 便于后续加技能时扩展。**匹配算法用加权打分 (≥0.6 命中), 不用精确匹配** — 这是 reverse-skill 三轴矩阵的实质。

### 1.5 未命中处理 (对应 reverse-skill "未命中 → 提议新 skill, 禁止硬塞")

`route()` 返回 null 时: 不执行任何技能, 记录一次 `RouteMiss` (技能名+消息摘要) 到经验日志 (模块 C), 每积累 N 次同场景 miss 就建议用户创建新技能 (可接现有 skill-creator)。

---

## 2. 模块 B: 工具自举 (Tool Bootstrap)

### 2.1 目标

对应 reverse-skill 的 `tool-index.md + bootstrap-reverse.sh`: **先检测本机有什么能力, 缺的引导安装, 全程不猜路径**。LingBi 是桌面 App, 场景是: 技能需要的运行时能力 (如 git、外部 CLI、Python、网络服务)。

### 2.2 数据结构 (新建 `lib/features/routing/tool_bootstrap.dart`)

```dart
/// 能力声明 — SkillManifest 可扩展声明 requiresTools
class ToolRequirement {
  final String toolId;        // 'git' | 'python' | 'node' | 'any_llm_gateway'
  final String displayName;   // 用户可读名
  final String? probeCommand; // 检测命令, 如 'git --version'
  final String installHint;   // 安装引导文案 (Windows 下提示下载链接)
}

/// 检测-安装循环 (复刻 bootstrap 语义)
class ToolBootstrap {
  /// 1) 检测: 逐个 probe, 产出工具状态表 (与 reverse-skill tool-index.md 同构)
  Future<Map<String, ToolStatus>> detect(List<ToolRequirement> reqs);

  /// 2) 自举: 缺失项尝试自动安装 (仅限已知安全的渠道), 失败给引导文案
  Future<BootstrapResult> bootstrap(String toolId);
}
```

### 2.3 集成点

1. **`skill_executor.dart`** — Skill 执行前先过 `ToolBootstrap.detect(manifest.requiresTools)`, 缺失则**拒绝执行并给出 installHint** (而不是运行时才炸)。
2. **`skill_manifest.dart`** — `SkillManifest` 增加可选字段 `requiresTools: List<ToolRequirement>` (JSON 反序列化兼容旧清单, 缺省空)。
3. **设置页** — 新增"能力状态"面板, 显示 detect 结果表 (类似 reverse-skill tool-index.md 渲染)。

### 2.4 首版能力清单

| toolId | probeCommand (Windows) | 用途 |
|---|---|---|
| git | `git --version` | 技能市场/项目版本管理 |
| python | `python --version` | 脚本类技能 |
| crawl4ai 服务 | `curl http://127.0.0.1:11235/health` | 网页抓取类技能 (本机已有, 见 OB: crawl4ai 本地微服务使用指南) |
| LLM 网关 | POST /v1/models 可达性 | 免费模型 (已由 FreeProvider 处理, 但路由层应感知其 429 限流状态) |

---

## 3. 模块 C: 经验进化 (Experience Journal)

### 3.1 目标

对应 reverse-skill `field-journal/`: **任务完成把经验沉淀为可复用记录, 下次任务开始先查历史**。LingBi 已有 `skill_audit_log.dart` (审计), 本模块在其上扩展"经验"层 — 审计是记流水, 经验是给未来的自己用。

### 3.2 数据结构 (扩展 `lib/features/skill/data/skill/skill_audit_log.dart` 或新建 `experience_journal.dart`)

```dart
/// 经验条目 — 复刻 reverse-skill field-journal 模板的精华字段
class ExperienceEntry {
  final String id;
  final String sceneCategory;   // 场景分类 (与路由矩阵 scene 维度对齐)
  final String goalSummary;     // 目标一句话
  final String chain;           // 完整执行链 (步骤列表)
  final List<String> pitfalls;  // 坑
  final String reusablePattern; // 可复用模式 (如 "写反派时先立 3 个动机")
  final DateTime createdAt;

  Map<String, dynamic> toJson();
  factory ExperienceEntry.fromJson(Map<String, dynamic> json);
}

/// 经验库 — 存取 + 检索
class ExperienceJournal {
  Future<void> append(ExperienceEntry e);          // 回写
  Future<List<ExperienceEntry>> search(String scene); // 任务开始前按场景检索
}
```

### 3.3 回写钩子 (3 处)

1. **技能执行完成** (`skill_executor.dart` 执行结束路径): 自动 append 一条 (scene + chain + 结果摘要), 用户可手动补充 pitfalls。
2. **路由 miss** (`route_engine.dart` 未命中路径): 记录 RouteMiss → 聚合成新技能建议。
3. **技能执行失败**: 强制记录失败原因 (reverse-skill 规则: 失败但失败原因有参考价值也必须回写)。

### 3.4 复用时机

**路由引擎工作流最前面加一步**: `ExperienceJournal.search(scene)` → 有历史则把历史经验摘要注入 AI 上下文 (reverse-skill 规则: "任务开始前检查 field-journal/_index.md")。存储位置建议 `~/Documents/lingbi_data/experience/` (与现有 lingbi_data 对齐), JSON 行式存储。

---

## 4. 实施顺序与验收标准

### 顺序 (依赖关系: A → C → B 交叉)

| 阶段 | 内容 | 验收标准 |
|---|---|---|
| P1 | 模块 A: RouteEngine + default_rules + SkillActionService 集成 | 输入"帮我续写下一章" 自动命中续写技能 (无需斜杠命令); 输入"润色这段" 命中润色; 输入"今天天气" 返回 null 且不误触发 |
| P2 | 模块 C: ExperienceJournal + 回写钩子 | 技能跑完自动落 1 条经验; 同场景第二次任务时上下文含历史经验摘要 |
| P3 | 模块 B: ToolBootstrap + manifest.requiresTools | 有 git/无 git 两种机器上行为正确; 缺工具时拒绝执行并给 installHint |
| P4 | 路由 miss 聚合 → 新技能建议 | 同场景 miss 3 次后提示可创建新技能 |

### 全量验收 (对照 reverse-skill 契约)

1. 先路由后动手: AI 对话中自动路由, 不依赖手动触发 ✅ (P1)
2. 未命中不硬塞: 返回 null + 记录 miss ✅ (P1)
3. 工具路径只认检测结果, 缺则引导: ✅ (P3)
4. 经验跨会话复用: ✅ (P2)
5. 全部旧测试不回归: `flutter test` 全绿 (现有 test/ 有 40+ 测试文件)

---

## 5. 给下一位 AI 的实施注意

1. **只动三块, 不要重构现有引擎**: capability_grant / skill_permission / skill_marketplace / skill_audit_log 已达标, 不要动。
2. **代码风格**: 现有代码用 dartdoc 注释 + 不可变类 (const 构造) + 依赖注入 (http.Client 可注入以便测试), 新代码照此。
3. **测试优先**: LingBi 测试文化很重 (test/ 40+ 文件), 每个模块先写测试再实现, 参照 `test/agent_tool_loop_test.dart` 的风格。
4. **路由矩阵关键词表要可配置** (JSON 或常量表), 方便用户改, 不要写死在匹配函数里。
5. **参考对照文件** (本机可读):
   - reverse-skill 路由矩阵: `/mnt/c/Users/a1691/.codex/skills/reverse-skill/skills/routing.md`
   - PRIMARY 阶梯: `.../skills/MASTER-ROUTING.md`
   - field-journal 模板: `.../skills/field-journal/_template.md`
   - 工具索引生成: `.../skills/scripts/refresh-tool-index.sh`
6. **验收跑法**: `cd /mnt/c/Users/a1691/Documents/Qoder/lingbi-impl && flutter test`
