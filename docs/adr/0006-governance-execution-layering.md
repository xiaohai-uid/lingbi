# 治理层与执行层分离及接口契约

V2.0 是跨项目治理协议（决定做什么、走到哪一步、是否允许继续），仓库 AGENTS.md 的 Multi-Agent Workflow Contract 是项目级执行协议（决定谁做、怎么交接、如何升级）。两者共存、不合并、不互相复制，通过 `docs/agents/project-control-interface.md` 连接。

## Considered Options

- **V2.0 吞并 Multi-Agent Contract**: 一份文档管所有。rejected: V2.0 变成灵笔专属，丧失跨项目可移植性；角色和 Lease 机制因项目而异。
- **Multi-Agent Contract 吞并 V2.0**: 治理规则写入 AGENTS.md。rejected: 与 ADR-0003 单源分发决策冲突；N 个仓库重复维护。
- **分层共存 + 接口契约（adopted）**: V2.0 可移植，AGENTS.md 可替换，接口文档适配两端。

## Consequences

- V2.0 只保留通用执行要求（唯一所有者、审核分离、证据持久化），不定义具体角色和 Lease 格式。
- AGENTS.md 不重复模式路由、Workstream 生命周期和跨项目门禁。
- Task 完成 ≠ Workstream 阶段完成；`/project-control` 读取 Task 证据后才推动 Workstream。
- Blocker 分层：Task 级由 AGENTS.md 管理，Workstream 级由 V2.0 管理，升级条件明确。
- Skill ≠ Agent 角色：Skill 决定方法，角色决定执行者。
- 单 Agent 项目无需 Multi-Agent Contract，V2.0 仍可独立运行。
