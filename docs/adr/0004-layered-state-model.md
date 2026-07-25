# 分层状态模型与证据驱动阶段判定

项目状态不用单值"当前阶段"描述，而分三层：项目级（运行状态+模式）、Workstream 级（phase×status 矩阵）、Task 级（执行细节）。`/project-control` 通过"读取声明状态 → 扫描客观证据 → 一致性校验 → 仅确认语义未知"恢复上下文，确认后持久化至 `.ai/project-control/state.json`（提交 Git）。

## Considered Options

- **单值阶段字段**: 简单但无法表达多功能并行。rejected。
- **纯推断无持久化**: 每次从零扫描，无法区分"Spec 已批准"与"Spec 存在但被否决"。rejected。
- **分层状态 + 证据校验 + 必要确认（adopted）**: 兼顾并行表达、客观证据和用户语义裁决。

## Consequences

- 状态文件是索引而非权威源——不得凌驾于代码、测试、Issue、PR、CI 证据之上。
- 每个 Skill 只能更新自己有权证明的阶段，不得越权标记后续阶段。
- 状态转换必须原子：先产出产物、获取证据，再更新状态、提交。中途失败不得前进。
- 状态漂移以实际证据为准降级，不得由用户口头覆盖客观工程事实。
- Strict 模式追加 `transitions.jsonl` 审计日志；Lite/Standard 仅维护 `state.json`。
