---
document: AI软件项目总控提示词
version: "2.0"
status: design-frozen
effective_level: bootstrap
updated_at: 2026-07-25
adr_range: ADR-0003..ADR-0009
---

# AI 软件项目总控提示词 V2.0

## 1 定位与适用范围

本文档是**跨项目工程治理协议**。它决定：做什么、走到哪一步、是否允许继续。

它**不**决定：谁做、怎么交接、如何升级——这些属于各仓库的执行协议（如 AGENTS.md 的 Multi-Agent Workflow Contract）。

适用对象：所有由 AI Agent 辅助执行的软件项目，无论单 Agent 还是多 Agent。

不适用：纯人工项目的管理流程。

## 2 文档治理

- **唯一载体**：仅存于 Obsidian，路径 `AI软件工程系统/00-AI软件项目总控提示词-V2.0.md`。
- **禁止复制**：不得将本文档全文复制到任何仓库。仓库只保存激活指针。
- **修改规则**：重大修改须更新版本号并记录关联 ADR；措辞修正不改变语义时可直接更新 `updated_at`。
- **生效等级**：文档头部 `effective_level` 标注当前实际激活的能力层级（bootstrap → m1-read-only → m2-state → m3-compliance → full）。

## 3 激活机制

### 3.1 全局 Skill

`/project-control` 是本文档的唯一激活入口。职责：

1. 定位并读取本文档；
2. 校验版本和生效等级；
3. 扫描当前仓库事实（AGENTS.md、CONTEXT.md、ADR、Issue、Git）；
4. 推断 Workstream 阶段和状态；
5. 区分客观证据与语义未知；
6. 路由至正确的下一步 Skill；
7. 报告自身当前能力边界。

### 3.2 治理文档定位优先级

```
显式调用参数 (--governance)
> 仓库级覆盖 (.ai/project-control.json)
> PROJECT_CONTROL_GOVERNANCE 环境变量
> OBSIDIAN_VAULT 环境变量 + 固定相对路径
> 用户级配置 (~/.project-control/config.json)
> 有限默认路径探测（多候选时须用户确认）
> 失败并报告
```

- AGENTS.md 只保存激活说明，不保存本机绝对路径。
- 仓库级覆盖文件若含本机路径应加入 `.gitignore`。
- CI 不运行 `/project-control`（CI 使用独立验证脚本 `project-control-validate`）。

### 3.3 触发时机

以下场景必须调用 `/project-control`：

- 新会话启动（第一个工作流动作）；
- 新项目或新 Workstream 启动；
- 阶段切换；
- 范围变更或方向调整；
- 上下文恢复（长时间中断后）。

### 3.4 失败处理

无法访问 Obsidian 或治理文档时：

- 必须明确报错，不得声称已遵循 V2.0；
- 不得使用仓库中可能过期的副本；
- 不得自行编造治理规则；
- 可降级为仅依赖 AGENTS.md 执行层规则，但须标注"治理层未激活"。

## 4 四档模式路由

| 模式 | 适用条件 | 核心特征 |
|------|----------|----------|
| Direct | 无产品语义、无架构影响、风险局部、验证明确 | Micro Brief 驱动，不创建 Workstream/Issue/state.json |
| Lite | 小型功能或修复，产品语义明确但需验证 | 轻量 Spec + 测试 + Review |
| Standard | 中等功能，涉及设计决策或多模块 | 完整 Spec → Design → Ticket → Implement → Review → Validate |
| Strict | 架构变更、安全、数据迁移、多 Agent 协作 | Standard + 审计日志 + 独立 Review + 受保护分支 + 人工发布 |

路由判断基于**风险和影响**，不基于文件数量。

## 5 Direct Change 路径

### 5.1 适用条件（全部满足）

1. 无产品语义变更；
2. 无架构或接口影响；
3. 无数据模型或迁移变更；
4. 无安全、账号或支付影响；
5. 影响范围局部且验证明确；
6. 不存在不可控运行时副作用。

### 5.2 流程

```
判定 Direct 资格（Agent 可自动判定，须报告理由）
→ 编写 Micro Brief（目标、允许路径、非目标、验证命令）
→ 执行变更
→ 运行验证
→ Diff 范围检查（实际 vs 声明）
→ 提交（commit message 引用 Micro Brief）
```

### 5.3 升级触发

执行中发现以下情况必须立即升级：

- 修改了未声明目录；
- 新增依赖或改变公共接口；
- 新增迁移；
- 修改安全/发布配置；
- 测试暴露额外行为变化；
- 语义或风险存在歧义。

### 5.4 Hotfix 区分

Hotfix ≠ Direct。紧急变更可压缩文档时间，但不可跳过：复现、回归测试、Diff 审核。

## 6 Workstream 生命周期

### 6.1 阶段序列

```
clarification → spec → design → ticketing → implementation → review → validation → release
```

Lite 模式可压缩为：`spec → implementation → review → validation`。

### 6.2 阶段状态

每个阶段的当前活跃 Attempt 使用以下状态：

```
in_progress | awaiting_approval | approved | verified | rejected | failed | superseded | cancelled | blocked
```

- `approved`：语义或设计获得授权（人类决策）。
- `verified`：具有客观工程证据（机器可验证）。
- 不得使用模糊的 `done` 覆盖上述差异。

### 6.3 Attempt 与 Cycle

每个阶段允许多个 Attempt。重开阶段时 `cycle + 1`，旧 Attempt 关闭并记录 result 和 reason。

```json
{
  "phase": "design",
  "currentAttempt": 2,
  "attempts": [
    { "attempt": 1, "result": "superseded", "reason": "..." },
    { "attempt": 2, "result": "in_progress" }
  ]
}
```

### 6.4 阶段门禁

每个阶段只有在满足前置条件后才能推进到下一阶段。门禁由证据驱动，不由时间驱动。

## 7 非线性推进

### 7.1 四种分离动作

| 动作 | 含义 | 触发者 |
|------|------|--------|
| 阶段内迭代 | 当前阶段未通过，继续修复 | Agent 可自主 |
| 阶段重开 | 前面阶段结论须重新处理 | 用户/技术负责人 |
| 代码回滚 | Git 操作撤销代码 | 遵循仓库权限 |
| 发布回滚 | 已部署版本恢复 | 用户/维护者 |

### 7.2 最早失效假设原则

回退目标 = 最早出现错误且必须重新决策的阶段。不机械返回前一阶段。

### 7.3 重开传播

重开较早阶段时，后续依赖产物进入 `stale`（不删除）。须进行影响分析：仍然有效 / 需要修改 / 需要重新验证 / 完全废弃。

### 7.4 不可逆事实

已发生的 Commit、已执行的数据迁移、已发布的版本、已产生的外部副作用——只能通过补偿动作处理，不能改写为"从未发生"。

### 7.5 Workstream 新建 vs 保留

- Destination 未改变 → 保留原 Workstream，阶段重开。
- Destination 改变 → 关闭原 Workstream（cancelled/superseded），新建并关联。

## 8 分层状态模型

### 8.1 三层结构

| 层级 | 存储 | 内容 |
|------|------|------|
| 项目级 | state.json | 运行状态（active/paused/archived）+ 当前模式 |
| Workstream 级 | state.json | phase × status × attempt × cycle |
| Task 级 | .ai/tasks/<ID>/STATE.md | 执行细节、Lease、证据引用 |

### 8.2 核心规则

- 状态文件是**索引**而非权威源——不得凌驾于代码、测试、Issue、PR、CI 证据之上。
- 每个 Skill 只能更新自己有权证明的阶段。
- 状态转换必须原子：先产出产物、获取证据，再更新状态、提交。
- 状态漂移以实际证据为准降级。
- Strict 模式追加 `transitions.jsonl` 审计日志。

### 8.3 受控转换（M2 起生效）

Agent 不得直接手写推进 `verified`/`released`/`complete` 状态。正式转换必须通过受控工具（`project_control transition`）。

允许 Agent 手工更新：说明文字、阻塞摘要、引用信息、不影响门禁的元数据。

## 9 治理-执行分层

### 9.1 职责边界

| 治理层（V2.0） | 执行层（AGENTS.md） |
|----------------|---------------------|
| 模式路由 | 角色分配 |
| Workstream 生命周期 | Task Lease |
| 跨项目门禁 | 交接协议 |
| 阶段判定 | 升级路径 |
| 合规策略 | 具体命令和工具 |

### 9.2 接口契约

通过 `docs/agents/project-control-interface.md` 连接。该文档定义：

- Workstream → Task 映射规则；
- Task 完成 → Workstream 阶段推进条件；
- Blocker 分层（Task 级 vs Workstream 级）；
- 当前生效能力声明。

### 9.3 冲突裁决

- 跨项目流程问题 → V2.0 为准；
- 项目专属事实 → AGENTS.md / CONTEXT.md / ADR 为准；
- 用户当前指令 → 始终最高优先。

### 9.4 单 Agent 项目

无需 Multi-Agent Contract，V2.0 仍可独立运行。

## 10 合规体系

### 10.1 四层结构

```
第一层：启动前置检查（新会话强制恢复）
第二层：本地变更约束（受控转换脚本 + Git Hooks 提醒）
第三层：CI 远端验证（证据存在性 + 转换合法性）
第四层：GitHub 平台强制（分支保护 + 人工审批）
```

### 10.2 新会话恢复（M1 起生效）

每个新 Agent 会话的第一个工作流动作必须是 `/project-control`。恢复前只允许只读探索（读取 AGENTS.md、state、Git status 等）。

恢复前禁止：修改文件、获取 Lease、修改 state.json、Commit、Push、创建/更新 PR。

### 10.3 证据要求

证据必须是机器可读记录：

```json
{
  "command": "flutter test",
  "exitCode": 0,
  "startedAt": "ISO-8601",
  "completedAt": "ISO-8601",
  "gitHead": "abc1234",
  "summary": "270 tests passed",
  "artifact": "path-or-ci-url"
}
```

Agent 自然语言报告只能作为摘要，不能作为唯一证明。

### 10.4 用户最终边界

以下操作必须由用户或指定维护者显式批准：

- 产品方向改变；Spec 正式批准；重大架构决策；
- 接受已知高风险；数据破坏性操作；生产发布；
- Merge 到受保护主分支；绕过失败质量门禁。

用户可接受风险（`riskAccepted: true`），但不可将失败证据篡改为成功。

### 10.5 现实限制

在没有受信任外部执行器和文件权限隔离时，单靠 Prompt 无法从技术上阻止拥有完整仓库权限的 Agent 违规。因此：Prompt 负责行为指导，脚本负责合法转换，Hooks 负责本地预防，CI 负责自动验证，GitHub 权限负责最终拦截，用户负责产品和发布裁决。

## 11 Skill 路由规则

`/project-control` 根据当前阶段和状态推荐下一步 Skill：

| 阶段/状态 | 推荐 Skill |
|-----------|------------|
| clarification 未完成 | /grill-me 或 /grill-with-docs |
| spec 待编写 | /to-spec |
| design 待进行 | /codebase-design 或 /design-an-interface |
| 技术不确定性 | /prototype |
| ticketing 待拆分 | /to-tickets |
| implementation 待执行 | /implement 或 /tdd |
| review 待进行 | /code-review |
| Bug 诊断 | /diagnosing-bugs |
| CI 失败修复 | /gh-fix-ci |
| 架构改进 | /improve-codebase-architecture |

非线性推进后的路由依据**失败类型**重新选择，不简单重复上次 Skill。

## 12 违规处理

发现 Agent 跳过流程时：

```
冻结状态推进
→ 记录违规
→ 检查实际 Diff
→ 确定应属于哪个模式
→ 补充缺失 Spec/测试/Review
→ 重新验证
→ 通过后恢复正式流程
```

未经补充验证：不得标记 Task 完成、不得推进 Workstream、不得 Merge。

违规代码可保留为候选实现，标记为 `unverified`，不自动丢弃。

## 13 交付路线

| 里程碑 | 内容 | 激活能力 |
|--------|------|----------|
| M0 | 设计冻结 | 无（文档产出） |
| M1 | 只读最小激活 | 会话恢复 + 推断 + Skill 路由建议 |
| M2 | 状态持久化与受控转换 | state.json + transition + bootstrap |
| M3 | 证据/CI/远端门禁 | run-evidence + validate + Hooks + 分支保护 |
| M4 | 多 Agent 分发（可选） | 完整适配 + 安装器 |

当前 `effective_level: bootstrap`——框架实施以现有 AGENTS.md + 已批准 ADR 为临时治理依据。

## 14 Bootstrap 期间规则

M1 验收前：

- 现有 AGENTS.md 是执行权威；
- ADR-0003 至 ADR-0009 是设计权威；
- 不要求调用尚不存在的 `/project-control`；
- 灵笔现有开发继续按当前规则运行。

## 附录 A：术语表

| 术语 | 含义 |
|------|------|
| Workstream | 跨阶段工作单元，从 clarification 到 release |
| Phase | Workstream 内的生命周期阶段 |
| Attempt | 同一阶段的一次尝试，可被关闭和重开 |
| Cycle | 阶段重开计数器 |
| Task | 执行层工作单元，由仓库执行协议管理 |
| Direct Change | 无产品语义的确定性小变更 |
| Micro Brief | Direct Change 的驱动文档 |
| Hotfix | 紧急修复，可压缩文档但不可跳过验证 |
| Destination | Workstream 的最终目标状态 |
| stale | 引用了已失效上游产物的待重新验证状态 |
| effective_level | V2.0 当前实际激活的能力层级 |

## 附录 B：ADR 索引

| ADR | 标题 | 核心决策 |
|-----|------|----------|
| 0003 | 单源分发与激活架构 | Obsidian 唯一载体 + /project-control 薄激活 |
| 0004 | 分层状态模型 | 项目/Workstream/Task 三层 + 证据驱动 |
| 0005 | 四档模式路由 | Direct → Lite → Standard → Strict |
| 0006 | 治理-执行分层 | V2.0 治理 + AGENTS.md 执行 + 接口契约 |
| 0007 | 分层合规体系 | 审计 + 技术门禁 + 用户裁决 |
| 0008 | 非线性推进 | 阶段重开 + Attempt + 不可逆补偿 |
| 0009 | 渐进交付 | M0-M4 + 权限逐级放开 |

## 附录 C：当前生效能力

```yaml
effective_level: bootstrap
active:
  - 模式路由判断（人工）
  - ADR 作为设计权威
  - AGENTS.md 作为执行权威
pending_m1:
  - /project-control 只读恢复
  - Workstream 推断
  - Skill 路由建议
pending_m2:
  - state.json 正式写入
  - 受控状态转换
  - 阶段重开工具
pending_m3:
  - CI 验证
  - Git Hooks
  - run-evidence
  - 分支保护
```
