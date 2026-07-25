# 框架渐进交付路线与 Bootstrap 策略

治理框架自身按 M0（设计冻结）→ M1（只读最小激活）→ M2（状态持久化与受控转换）→ M3（证据/CI/远端门禁）→ M4（多 Agent 分发，可选）渐进交付。整体为 Strict Workstream，拆为独立可验收 Ticket。M1 之前框架实施以现有 AGENTS.md + 已批准 ADR 为临时治理依据；M1 验收后 `/project-control` 仅提供只读推断；M2 后才启用正式状态写入。

## Considered Options

- **一次性全面上线**: 全部能力同时启用。rejected: 未验证的 Skill 直接获得状态写入权风险过高。
- **纯设计文档先行，工具后补**: rejected: 没有可运行工具的治理规则无法被验证。
- **渐进交付 + 权限逐级放开（adopted）**: 每个里程碑只授予已验证的能力，降级行为明确。

## Consequences

- `/project-control` 源码存放在独立仓库，不散落在各 Agent Skill 目录或 Obsidian 中。
- M1 只在单一执行环境（Codex）做 Canary 验证，通过后再适配其他 Agent。
- 灵笔现有开发不因框架建设停止；M1 上线前继续按当前 AGENTS.md 运行。
- M1 不写 state.json、不接管 Lease、不推进阶段、不修改 Issue。
- 框架实施 Ticket 不因修改文件少而降级为 Direct；整体保持 Strict 治理。
- V2.0 文档头部标注 `effective_level`，随里程碑推进更新生效能力。
