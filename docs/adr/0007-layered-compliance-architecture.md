# 分层合规体系：审计 + 技术门禁 + 用户裁决

合规不依赖单一机制，而分四层：启动前置检查（新会话强制恢复）→ 本地变更约束（受控状态转换脚本 + Git Hooks 提醒）→ CI 远端验证（证据存在性和转换合法性）→ GitHub 平台强制（分支保护 + 人工审批）。高风险操作由平台权限技术拦截；语义性规则由审计和用户裁决。

## Considered Options

- **纯 Prompt 信任**: 规则写在提示词中，依赖 Agent 自觉。rejected: 多 Agent 和长会话中违规风险不可接受。
- **中心网关强制**: 所有 Skill 调用必须经过 /project-control 中转。rejected: 当前 Skill 架构无运行时拦截层，不可行。
- **分层合规 C+（adopted）**: 预防 + 审计 + 技术强制 + 用户兜底，承认"Agent 承诺 ≠ 安全保证"。

## Consequences

- 新会话第一个动作必须是 `/project-control` 恢复；恢复前只允许只读探索。
- Agent 不得直接手写推进 `state.json` 中的 verified/released/complete 状态；正式转换必须通过受控工具。
- 证据必须是机器可读记录（命令 + 退出码 + SHA + 时间），Agent 自然语言仅为摘要。
- CI 重复验证状态转换合法性和证据存在性；本地 Hooks 仅为提醒，可被跳过。
- GitHub 分支保护是最终技术门禁：即使 Agent 跳过所有本地检查，不合规变更无法进入受保护主分支。
- 违规产出标记为 `unverified`，进入隔离审计流程，补充验证后可恢复，不自动丢弃。
- 用户可接受风险（`riskAccepted: true`）但不可将失败证据篡改为成功。
