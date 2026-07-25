# 四档模式路由与 Direct Change 快速路径

项目路由从三档（Lite/Standard/Strict）扩展为四档：Direct → Lite → Standard → Strict。Direct Change 用于无产品语义变更、无架构影响、风险局部且验证明确的确定性小变更，通过 Micro Brief 驱动而非正式 Spec/Ticket。Hotfix 独立于 Direct，表示紧急但仍需诊断和回归验证。

## Considered Options

- **三档不变，小变更强行 Lite**: 产生纯形式 Spec 和 Ticket，增加摩擦且鼓励绕开流程。rejected。
- **无限制快速通道**: 任何变更都可跳过流程。rejected: 无法防止错误降级。
- **受控 Direct + 严格资格 + 升级触发（adopted）**: 平衡效率与治理，核心判断基于风险而非文件数。

## Consequences

- Direct 判定基于"是否存在产品语义、架构、数据、安全或不可控影响"，文件数仅为辅助信号。
- Agent 可自动判定 Direct 但必须报告理由；语义或风险歧义时须用户确认。
- Direct 不创建 Workstream、不写 state.json、不创建 Issue；证据存于 Git。
- 执行中发现超出 Micro Brief 范围必须立即升级到对应模式，不得沿用未审核假设。
- Hotfix ≠ Direct：紧急变更可压缩文档时间但不可跳过复现、回归测试和 Diff 审核。
