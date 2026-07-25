# V2.0 总控规则单源分发与激活架构

跨项目工程治理规则（V2.0）只在 Obsidian 中维护一份，通过全局轻量 Skill `/project-control` 按需激活，各仓库 `AGENTS.md` 仅保存项目专属事实并放置激活指针。冲突按职责范围裁决：流程问题以 V2.0 为准，项目事实以仓库文档为准，用户当前指令始终最高优先。

## Considered Options

- **Per-repo full copy**: 每个仓库的 AGENTS.md 包含完整 V2.0。 rejected: N 份副本同步维护成本高，规则漂移不可避免。
- **纯 Obsidian 无激活层**: 依赖用户每次手动粘贴。rejected: 无自动路由和阶段判断，容易遗漏。
- **Obsidian + 薄激活 Skill（adopted）**: 单源 + `/project-control` 读取并路由。trade-off: 运行时依赖 Obsidian 文件可达。

## 定位优先级

```
显式调用参数 (--governance)
> 仓库级覆盖 (.ai/project-control.json)
> PROJECT_CONTROL_GOVERNANCE 环境变量
> OBSIDIAN_VAULT 环境变量 + 固定相对路径
> 用户级配置 (~/.project-control/config.json)
> 有限默认路径探测（多候选时须用户确认）
> 失败并报告
```

AGENTS.md 只保存激活说明，不保存本机绝对路径。CI 不运行 `/project-control`。

## Consequences

- Agent 无法访问 Obsidian 时必须明确报告，不得声称已遵循 V2.0。
- 同一连续会话首次加载后无需每步重读全文，仅阶段切换时重新读取变化事实。
- 禁止在仓库中存放 V2.0 全文副本。
- 多机器迁移只需配置用户级 config 或环境变量，无需修改仓库。
- 仓库级覆盖文件若含本机路径应加入 .gitignore。
