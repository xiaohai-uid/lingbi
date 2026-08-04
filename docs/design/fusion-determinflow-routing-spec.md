# LingBi 融合规格:技能路由 × 确定性工作流运行时

> 创建: 2026-08-04 | 作者: opencode
> 用途: 给下一个 AI 的完整实施规格 + 给 LingBi 小说生产链路的工作流参考。把「技能路由体系」(蒸馏自 reverse-skill, 见 `distill-reverse-skill-routing-spec.md`)与「确定性工作流运行时」(参考 DeterminFlow, 见 OB: DeterminFlow 调研)融合成一份规格。
> 蓝本: https://github.com/alikon-art/DeterminFlow (AGPL-3.0, 只借鉴思想与接口形状, 不复刻代码)
> 目标工程: /mnt/c/Users/a1691/Documents/Qoder/lingbi-impl (Flutter, 256 个 dart 文件)

---

## 0. 融合定位:两个体系各解决一半问题

| 体系 | 解决的问题 | 落在 LingBi 的对应物 |
|---|---|---|
| reverse-skill 路由体系 (原规格 A/B/C) | **AI 拿到任务后怎么选技能**、缺工具怎么自举、经验怎么跨会话复用 | 技能引擎 (loader/executor/manifest/permission/audit/marketplace) 已达标, 缺路由/自举/经验三块 |
| DeterminFlow 工作流运行时 | **选中的技能/流程怎么稳定跑完**: 节点化编排、校验修复、断点恢复、Token 账本、对外交付 | LingBi 已有 pipeline/checkpoint/approval/agent_loop, 缺节点级上下文契约、输出校验门、拒绝返工、账本 |

**融合公式**: 路由矩阵选「流程入口」而非「单个技能」; 经验库在路由前注入上下文; 工具自举在节点执行前置检测; DeterminFlow 的四个杀手级能力蒸馏为模块 D/E/F, 且**大部分是补齐 LingBi 已有机制的语义, 不是新造引擎**。

---

## 0.1 现状盘点: LingBi 已有的 DeterminFlow 等价物 (不要再造)

| DeterminFlow 概念 | LingBi 已有实现 | 差距 |
|---|---|---|
| 检查点/崩溃恢复 | `lib/domain/runtime/checkpoint.dart` + `lib/services/runtime/file_checkpoint_store.dart` + `run_models` (事件序列+哈希) | 已有; 只缺「节点级恢复语义」对齐 (模块 F) |
| 编排/状态机 | `lib/features/writing/data/pipeline/` (generation_context / context_assembler / writing_pipeline_state / write_lock / candidate / book_state / creative_compass) | 已有; 缺节点上下文契约与账本 (模块 D) |
| Agent Node (沙箱工具) | `lib/features/writing/services/agent/agent_tool_loop.dart` | 已有 |
| Approval Node (人工审批) | `lib/features/collaboration/data/workflow_approval_service.dart` | 已有 |
| 任务队列/重试 | `lib/services/task_queue_service.dart` (批量/取消/重试≤3 次) | 已有; 补「失败节点≠整链失败」语义 |
| 模型能力路由 | `lib/services/capability_router.dart` (按能力探测选 Provider) | 已有, 模块 B 复用其探测结果 |
| JSON 输出校验+自动修复+定向重试 | 无 | **新增模块 E** |
| 下游拒绝→上游定向返工 | 无 (candidate 有采纳, 无拒绝原因回传) | **新增模块 E** |
| 节点级 Token 账本 | 无 | **新增模块 D** |
| 路由矩阵/工具自举/经验库 | 无 | 原规格 A/B/C |

---

## 1. 融合架构总览

```
用户任务 (消息 + 选区 + 当前场景)
  │
  ▼
[模块 C] ExperienceJournal.search(scene) ──命中──> 注入历史经验摘要到上下文
  │
  ▼
[模块 A] RouteEngine.route() ──命中──> 返回 WorkflowEntry(流程入口, 不再是单个技能)
  │                                    │
  │ miss                               └─> [模块 B] ToolBootstrap.detect(entry.requiresTools)
  ▼                                         │ 缺工具 → installHint, 拒绝执行
RouteMiss 记录 → 聚合 → 新技能建议           ▼
  │                                   节点链执行 (复用现有 pipeline/agent_loop)
  │                                   每节点: [模块 D] 局部上下文契约 + Token 账本
  │                                   节点输出: [模块 E] OutputGate 校验 → 修复回环 → 定向重试
  │                                   失败: [模块 F] 节点级检查点, 恢复时只重跑失败节点
  ▼                                           ▼
直通现有手动入口                        下游节点可 reject → 携带原因向上游返工
                                           ▼
                                    候选区 → 交付 (沿用现有 candidate/review 链路)
```

核心变化一句话: **从「选技能手动跑」升级为「路由选流程入口 → 确定性跑完 → 断点可续 → 经验可复」**。

---

## 2. 模块 A: 任务路由矩阵 (来自原规格, 升级返回值)

沿用原规格 `distill-reverse-skill-routing-spec.md` §1 的完整设计 (RouteDimension 场景0.5/意图0.3/输入范围0.2, 加权打分 ≥0.6 命中, `lib/features/routing/route_engine.dart` + `default_rules.dart`, 关键词表可配置)。三处集成点照旧:
1. `lib/features/skill/data/skill_action_service.dart` — 入口前置路由, 并**删掉注释「AI 主动推荐不属于本轮」** (第 5 行)。
2. `lib/services/ai_service.dart` — 消息循环进 LLM 前先路由, 命中注入 system prompt (base_prompt + Available Tools + Available Skills + Current Context)。
3. `lib/features/skill/ui/skill_market_page.dart` — 技能市场要求携带 RouteRule 元数据。

### 融合升级点 (本规格新增)

**路由结果从 `skillId` 升级为 `WorkflowEntry`**: 命中返回的不再是单个技能, 而是「流程入口」——一次续写 = 多个节点的链 (例: 上下文组装 → 大纲确认 → 正文生成 → 校验门 → 落候选区)。数据形状:

```dart
/// 流程入口 — 路由命中返回的对象 (模块 A × DeterminFlow 融合点)
class WorkflowEntry {
  final String entryId;           // 对应 RouteRule.skillId, 向后兼容
  final String displayName;
  final List<NodeSpec> nodes;     // 节点链; 单技能 = 单节点链
  final List<ToolRequirement> requiresTools; // 模块 B 前置检测用
  final List<String> contextKeys; // 模块 D 契约: 入口声明的上下文需求
}

class NodeSpec {
  final String nodeId;            // 'context_assembly' | 'draft' | 'validate' | 'candidate'
  final String nodeType;          // 'agent' | 'script' | 'approval' | 'gate'
  final List<String> inputs;      // 只读这些上下文键
  final List<String> outputs;     // 只产出这些键
  final int maxRounds;            // 最大重试轮次
}
```

首版不强制全部节点类型, 单技能流程 (润色/摘要等) 就是 `[gate → agent → candidate]` 三节点链, 复用现有 executor; 多技能流程 (续写→润色→去AI味) 是链式组合。

**未命中处理不变**: 返回 null, 记 RouteMiss, 不硬塞。

---

## 3. 模块 B: 工具自举 (来自原规格, 无改动)

沿用原规格 §2 完整设计 (`lib/features/routing/tool_bootstrap.dart`, `SkillManifest.requiresTools` 扩展, `skill_executor.dart` 前置 detect, 设置页能力状态面板)。首版能力清单不变: git / python / crawl4ai 服务 (`curl http://127.0.0.1:11235/health`) / LLM 网关 (感知 429 限流)。

**融合补充**: `WorkflowEntry.requiresTools` 与 `SkillManifest.requiresTools` 共用同一张声明表; 检测结果可复用 `capability_router.dart` 已有的探测结果, 不重复探测。

---

## 4. 模块 C: 经验进化 (来自原规格, 无改动)

沿用原规格 §3 完整设计 (`ExperienceEntry` / `ExperienceJournal`, 存储 `~/Documents/lingbi_data/experience/` JSON 行式; 三个回写钩子: 执行完成/路由 miss/执行失败; 路由前先 `search(scene)` 注入上下文)。

**融合补充**: 经验条目新增两个字段——`nodeChain` (本条经验对应的节点链摘要, 供模块 E 修复回环参考) 与 `outputGateResult` (输出校验门是否通过/修复了几轮, 让后续任务直接沿用有效修复模式)。

---

## 5. 模块 D (新): 节点级上下文契约 + Token 账本

> 蒸馏自 DeterminFlow: 「每个 Agent Node 只看自己的局部上下文」「每个节点、尝试和模型调用单独记账」。这是 DeterminFlow 声称省 70–89% Token 的机制来源。

### 5.1 数据形状 (新建 `lib/features/routing/node_context_contract.dart`)

```dart
/// 节点上下文契约 — 节点只读 inputs 里的键, 只产 outputs 里的键
final class NodeContextContract {
  final String nodeId;
  final List<String> inputs;   // 如 ['chapter_draft', 'world_state']
  final List<String> outputs;  // 如 ['polished_text']
}

/// Token 账本 — 一次模型调用的账目
final class TokenLedgerEntry {
  final String runId;
  final String nodeId;
  final int attempt;              // 第几次尝试 (0 起)
  final String modelCallId;       // 对应 ai_service 的单次调用
  final int promptTokens;
  final int completionTokens;
  final String providerId;        // 复用 capability_router 的 provider 体系
  final DateTime createdAt;

  Map<String, dynamic> toJson();
  factory TokenLedgerEntry.fromJson(Map<String, dynamic> json);
}

/// 账本存取 — 行式 JSON 追加, 按 run/node 聚合
final class TokenLedger {
  Future<void> append(TokenLedgerEntry e);
  Future<TokenUsage> summarize(String runId);           // 按 run 汇总
  Future<TokenUsage> summarizeByNode(String runId);     // 按 run+node 汇总
}
```

存储: `~/Documents/lingbi_data/token_ledger/`, 与 experience/ 同级, 行式 JSON。

### 5.2 集成点

1. **`context_assembler.dart`** — 现有 ContextAssembler 已经按需组装; 新增「契约校验」: 节点执行前断言其 inputs 键在上下文中存在, 缺失则走模块 F 的「从上一个产出该键的节点续跑」, 而不是静默吞掉。
2. **`ai_service.dart`** — 每次模型调用返回 token 用量 (现有 provider 层已能拿到 usage), 由调用方记账到 `TokenLedger`。
3. **`lib/features/writing/ui/` (进度/统计面板)** — 按 run+node 展示 Token 账本 (对应 DeterminFlow 的「按 Workflow/Task/Node/尝试/模型调用查看状态与用量」), 首版只读。

### 5.3 验收标准

- 一次 3 节点流程跑完, `summarizeByNode` 能给出每节点 token; 节点重试轮次独立记账。
- 用真实续写任务对比「整链长上下文」与「节点级契约」的 token 差, 落一份实测报告 (DeterminFlow 声称 70–89%, 落地后以自己账本为准, 不背书其估算)。

---

## 6. 模块 E (新): 输出校验门 + 下游拒绝返工

> 蒸馏自 DeterminFlow: 「JSON 输出检测、解析、修复和模型重试」「下游节点可以拒绝结果, 让上游定向返工」。

### 6.1 输出校验门 (OutputGate)

`NodeSpec` 可携带 `gate` 声明 (JSON Schema 或断言函数表), 节点输出先过门:

```
节点输出 → ValidateGate
  ├─ 通过 → 交付下游
  ├─ 失败(可修复) → 把「校验错误 + 当前输出」回喂模型 → 重试 (≤ maxRounds)
  ├─ 失败(不可修复) → 标记失败, 走模块 F 恢复语义 (不整链重跑)
  └─ 超轮次 → 转人工 (挂到现有 intent_confirmation/approval 链路)
```

数据形状 (新建 `lib/features/routing/output_gate.dart`):

```dart
/// 校验结果 — 可解释的失败原因, 喂回模型修复
final class GateResult {
  final bool passed;
  final List<String> errors;      // 每条 = 一条可喂回模型的校验错误
  final String? repairedOutput;   // 修复后的输出
  final int repairRounds;
}
```

首版门类型: 结构门 (JSON 可解析/必填字段存在, 对应现有技能的结构化输出约定)、长度门 (章节字数区间)、风格门 (去AI味技能的朴素度检查, 首版可只做规则近似)。

### 6.2 下游拒绝返工 (DownstreamReject)

新增「拒绝原因」对象, 下游节点 (整合器/润色器/人工) 可携带原因 reject 上游产出:

```dart
final class RejectReason {
  final String fromNodeId;    // 谁拒绝
  final String targetNodeId;  // 拒绝谁
  final String reason;        // 定向返工依据 (注入被拒绝节点的重试 prompt)
}
```

集成点:
- `lib/features/writing/data/pipeline/candidate_service.dart` — 候选区拒绝时挂载 `RejectReason` (首版只存不动作)。
- 润色/去AI味节点收到 reject 时, 把 reason 注入修复轮次 prompt (复用模块 E 修复回环)。

### 6.3 验收标准

- 构造一个「模型输出缺字段」用例: 门拦截 → 自动修复 → 通过, 全程用户无感; 超轮次转人工不卡死。
- 下游 reject 后, 只有被拒节点重跑, 上游已完成节点不重跑 (与模块 F 互验)。

---

## 7. 模块 F (新): 节点级恢复语义对齐

> 蒸馏自 DeterminFlow: 「Task 启动时冻结 Workflow 定义和输入」「跨进程重启保存执行检查点」「并行、循环和子流程拥有独立的尝试历史」。

LingBi 已有 checkpoint (`lib/domain/runtime/checkpoint.dart`) 和事件序列 (`run_models`), **本模块只做语义对齐, 不重写**:

1. **冻结语义**: Task 启动时快照「流程定义 + 输入参数」写入 run 记录 (checkpoint 已有 projectBriefRevision/Hash; 补: 节点链定义版本)。恢复时以冻结版为准, 不被运行中的修改干扰。
2. **恢复粒度 = 节点**: `checkpoint.lastEventSequence` 已按事件推进; 新增约定——失败恢复从「最后一个未成功节点」继续, 已完成节点标记 `completedReceiptIds` (字段已存在) 跳过。
3. **尝试历史独立**: 每节点尝试次数独立计数 (token 账本 `attempt` 字段同源), 节点失败 ≠ 整链失败 (与 `task_queue_service.dart` 的整任务重试语义区分开, 注释里写清)。
4. **进程重启恢复**: `file_checkpoint_store` 已支持; 验收时跑「杀掉进程→重启→从失败节点续跑」用例。

---

## 8. 实施顺序与验收标准

| 阶段 | 内容 | 验收标准 |
|---|---|---|
| P1 | 模块 A: RouteEngine + WorkflowEntry + default_rules + SkillActionService/AIService/市场三处集成 | 「帮我续写下一章」自动命中续写流程入口 (无需斜杠命令);「润色这段」命中润色;「今天天气」返回 null 且不误触发; 旧入口可用 |
| P2 | 模块 C: ExperienceJournal + 3 回写钩子 + 路由前注入 | 技能跑完自动落 1 条经验; 同场景第二次任务上下文含历史摘要; 失败也回写 |
| P3 | 模块 B: ToolBootstrap + requiresTools + 设置页能力面板 | 有/无 git 两机行为正确; 缺工具拒绝执行并给 installHint |
| P4 | 模块 D: NodeContextContract + TokenLedger + 面板 | 3 节点流程按节点出账; 缺 inputs 键时走上游续跑而非静默 |
| P5 | 模块 E: OutputGate + RejectReason | 缺字段自动修复; 超轮次转人工; 拒绝只重跑被拒节点 |
| P6 | 模块 F: 节点级恢复语义对齐 (只加约定与测试) | 杀进程重启后从失败节点续跑, 已完成节点跳过 |
| P7 | 路由 miss 聚合 → 新技能建议; 全量验收 | 同场景 miss 3 次提示可创建新技能; `flutter test` 全绿 (test/ 127 文件不回归) |

### 全量验收清单 (对照两份蓝本契约)

1. 先路由后动手, 不依赖手动触发 ✅ (P1)
2. 未命中不硬塞: null + RouteMiss ✅ (P1/P7)
3. 工具路径只认检测结果, 缺则引导 ✅ (P3)
4. 经验跨会话复用 ✅ (P2)
5. 节点只读所需上下文 + 逐节点 Token 账本 ✅ (P4)
6. 输出校验→修复→定向重试; 下游拒绝→上游返工 ✅ (P5)
7. 失败从节点恢复, 已完成不重跑, 进程重启可续 ✅ (P6)
8. 全部旧测试不回归: `flutter test` 全绿 ✅

---

## 9. 给下一位 AI 的实施注意 (红线)

1. **只动规格列出的文件, 不要重构现有引擎**: capability_grant / skill_permission / skill_marketplace / skill_audit_log / pipeline / checkpoint / agent_tool_loop / capability_router 均已达标,**只在其上加语义 (契约/账本/门/拒绝原因), 不改其内部实现**。
2. **代码风格**: dartdoc 注释 + 不可变类 (const/final) + 依赖注入 (http.Client / 存储路径可注入以便测试), 照现有代码写。
3. **测试优先**: 每个模块先写测试再实现, 参照 `test/agent_tool_loop_test.dart` 的风格; 跑法 `cd /mnt/c/Users/a1691/Documents/Qoder/lingbi-impl && flutter test` (127 个测试文件必须全绿)。
4. **关键词表/契约/门规则全部可配置** (JSON 或常量表), 不写死在匹配函数里。
5. **DeterminFlow 是 AGPL-3.0**: 只借鉴思想与接口形状, 不复刻其代码; Token 对比 (70–89%) 是其 README 估算值, 落地后以自己 TokenLedger 实测为准。
6. **参照文件** (本机可读):
   - 原规格: `docs/design/distill-reverse-skill-routing-spec.md` (A/B/C 细节全量沿用)
   - DeterminFlow 蓝本: https://github.com/alikon-art/DeterminFlow (README 已调研, 见 OB: DeterminFlow 调研)
   - 本机 reverse-skill 对照: `/mnt/c/Users/a1691/.codex/skills/reverse-skill/skills/routing.md` + `MASTER-ROUTING.md` + `field-journal/_template.md`
   - LingBi 相关既有实现: `lib/domain/runtime/checkpoint.dart` / `lib/features/writing/data/pipeline/` / `lib/services/task_queue_service.dart` / `lib/services/capability_router.dart`

---

## 附录: DeterminFlow 蓝本要点速查 (2026-08-04 抓取 README)

- 定位: 面向生产的 AI 工作流运行时; 四类 Core Node (Agent / Script / Approval / Subprocess), 可视化编排, 变量/条件/并行/循环/人工审批/子流程。
- 可靠性: Task 启动冻结定义与输入; 自动重试/人工重试/跳过/从失败节点恢复; 跨进程重启检查点; 并行与循环独立尝试历史。
- LLM 边界: 每 Agent Node 独立会话 + Token 账本; 工具白/黑名单、Workspace、最大轮次按节点配置; JSON 输出检测/解析/修复/重试; 下游可拒绝 → 上游定向返工。
- 交付: FastAPI / React 控制台 / Cron / WebSocket / 健康检查; Plugin 打包 (Workflow+Agent+Prompt+Skill+Rule+DB 迁移)。
- 案例: 笔枢写作 (bishuxiezuo.cn) 真实小说正文生产, 11 个模型会话共 176,584 Token; 声称对比长链单智能体省 70–89% Token (估算值)。
- 规模: 139 stars / 22 forks / 11 commits (2026-08-04), AGPL-3.0, v0.1.0 前。
