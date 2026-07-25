# ADR 一致性矩阵：ADR-0003 至 ADR-0009

M0 设计冻结前置检查。确认七份 ADR 之间无不可调和冲突，明确扩展、细化和时序关系。

## 一、交叉关系总表

| 关系类型 | 源 ADR | 目标 ADR | 说明 |
|----------|--------|----------|------|
| 扩展 | 0008 | 0004 | 0004 定义 phase×status 矩阵；0008 在每个 phase 内增加 Attempt 数组和 Cycle 计数。0004 的模型是 0008 的子集。 |
| 时序细化 | 0009 | 0004 | 0004 描述稳态行为（/project-control 写入 state.json）；0009 规定该能力在 M2 才激活，M1 只读。 |
| 时序细化 | 0009 | 0007 | 0007 描述完整合规四层；0009 规定第一层（会话恢复）M1 生效，第二层（受控转换）M2 生效，第三/四层（CI/平台）M3 生效。 |
| 兼容约束 | 0003 | 0007 | 0003 说"CI 不运行 /project-control"；0007 说"CI 重复验证"。两者兼容：CI 运行独立验证脚本 `project-control-validate`，不是完整 Skill。需在 V2.0 中明确命名区分。 |
| 兼容约束 | 0005 | 0007 | 0005 说 Direct 不写 state.json；0007 说受控工具才能推进状态。兼容：Direct 完全绕过状态系统，0007 约束的是 Lite/Standard/Strict 路径。 |
| 显式覆盖 | 0009 | 0005 | 0005 允许小变更走 Direct；0009 显式声明框架实施 Ticket 不降级为 Direct。这是用户明确决策，不是逻辑冲突。 |
| 接口依赖 | 0006 | 0003 | 0006 的接口文档 `project-control-interface.md` 需要引用 0003 的定位优先级链。 |
| 接口依赖 | 0006 | 0004 | 0006 的"Task 完成 ≠ Workstream 阶段完成"依赖 0004 的三层模型。 |
| 接口依赖 | 0008 | 0007 | 0008 的阶段重开是正式状态转换，必须通过 0007 的受控转换工具。 |
| 互补 | 0005 | 0008 | 0005 定义 Direct 升级触发；0008 定义升级后进入哪个模式/阶段。 |

## 二、潜在歧义（非冲突，需在 V2.0 中澄清）

| # | 歧义描述 | 涉及 ADR | 澄清方案 |
|---|----------|----------|----------|
| 1 | ADR-0004 写"确认后持久化至 state.json"，可能被误读为 M1 即写入 | 0004, 0009 | V2.0 正文在状态模型章节标注"写入能力自 M2 起生效" |
| 2 | ADR-0007 写"新会话第一个动作必须是 /project-control 恢复"，M1 之前该 Skill 不存在 | 0007, 0009 | V2.0 标注"Bootstrap 期间以 AGENTS.md + ADR 为临时恢复依据" |
| 3 | "CI 不运行 /project-control" vs "CI 验证状态转换" | 0003, 0007 | V2.0 明确：CI 运行 `project-control-validate`（独立脚本），不调用 Skill 本身 |
| 4 | ADR-0004 的 `status` 字段与 ADR-0008 的 Attempt `result` 字段语义重叠 | 0004, 0008 | V2.0 定义：phase 级 `status` 描述当前活跃 Attempt 的状态；`result` 描述已关闭 Attempt 的最终结论 |
| 5 | ADR-0005 的 Direct "不创建 Issue" 与 ADR-0006 的 "Task 由 AGENTS.md 管理" | 0005, 0006 | V2.0 明确：Direct 不创建 Task/Issue/Workstream，其证据仅存于 Git commit message 和 Micro Brief |

## 三、术语一致性检查

| 术语 | 使用位置 | 一致性 |
|------|----------|--------|
| Workstream | 0004, 0005, 0006, 0007, 0008, 0009 | 一致：跨阶段工作单元 |
| Phase | 0004, 0008 | 一致：Workstream 内生命周期阶段 |
| Task | 0004, 0006 | 一致：执行层工作单元，由 AGENTS.md 管理 |
| Direct Change | 0005, 0009 | 一致：无产品语义的确定性小变更 |
| `/project-control` | 0003, 0004, 0006, 0007, 0009 | 一致：全局治理 Skill |
| state.json | 0004, 0005, 0007, 0009 | 一致：`.ai/project-control/state.json` |
| Micro Brief | 0005 | 唯一使用，无冲突 |
| Attempt / Cycle | 0008 | 唯一使用，扩展 0004 模型 |
| stale / superseded | 0008 | 唯一使用，无冲突 |
| effective_level | 0009 | 唯一使用，V2.0 元数据字段 |
| transitions.jsonl | 0004 | 唯一使用，Strict 模式审计日志 |
| runtime.local.json | 0007（用户决定） | 本机会话记录，.gitignore |
| project-control-validate | 0007（用户决定） | CI 独立验证脚本，非 Skill |

## 四、不可调和冲突

**未发现。**

所有看似矛盾的点均为时序细化（能力分阶段激活）或显式覆盖（用户明确决策），不存在逻辑上无法同时满足的约束对。

## 五、结论

七份 ADR 内部一致，可作为 M0 设计冻结的正式输入。上述五项歧义在 V2.0 正文整理时统一澄清，不需要重开架构讨论。
