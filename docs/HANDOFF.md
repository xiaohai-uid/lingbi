# Handoff：灵笔 V2 全面蒸馏 OpenWrite

> 本文档是下一位 AI 开发者的入口。读完本文档 + 引用的文档后，你拥有继续开发所需的全部上下文。

## 必读文档（按顺序）

1. **本文档** — 全局概览
2. `AGENTS.md` — 构建命令、架构、CI 门禁、多 Agent 协作规则
3. `CONTEXT.md` — 领域术语表（GuidedFlow、EndpointConfig 等新术语）
4. `docs/adr/0001~0005` — 5 个架构决策记录（已锁定，不可更改）
5. **GitHub Issue #3** — 完整 Spec（93 个 User Stories，P0/P1/P2）
6. **GitHub Issues #4~#13** — P0 批次的 10 个可执行工单

## 项目当前状态

- **阶段**：规划完成，实现未开始
- **分支**：`lingbi-review-v1-mvr` worktree
- **P0 工单全部 `ready-for-agent`**，可直接 `/implement`

## 核心决策摘要

| 决策 | 结论 | ADR |
|------|------|-----|
| 引导式 AI 架构 | 三层混合：编排层(GuidedFlowEngine) + 内容层(题材Skill) + 执行层(AIService) | 0001 |
| 供应商 | 统一化 EndpointConfig + OpenAI/Anthropic 双协议 + 模型自动发现 | 0002 |
| 产出物存储 | 项目级结构化文件(project_meta/*.json) + Canon 轻量索引 | 0003 |
| 差异化 | Skill生态(预装官方题材) + 一键成剧(重量Skill) + 平行世界(双定位) + local-first分阶段 | 0004 |
| 引导 UI | 混合：首次全屏(世界观+角色) → 后续 AI Panel | 0005 |

## P0 工单依赖图

```
#4 → #5 → #6 ──→ #10 → #11
         ↘ #7    ↗
#8 → #9 ────────┘
         ↘ #12 → #13
```

**可立即并行启动**：#4（供应商基础）和 #8（存储层）

## 功能来源说明

- **蒸馏自 OpenWrite**（http://111.170.163.42:4650/，v1.2.6）：统一供应商、引导式创作、风格蒸馏、Skill广场、WebDAV、AI搜索、Word导出、思考模型管理、停止保护、公益模型
- **蒸馏自竞品**（NovelBuilder、oh-story-claudecode、蛙趣拼文）：RAG、扫榜、参考书管理、角色图谱、工作流审批、批量生成、去AI味、短篇支持
- **超出竞品的差异化新增**：一键成剧（源自2026年AI漫剧行业）、平行世界（源自红果短剧）、Skill生态飞轮

## 关键约束

- OpenWrite 有的功能，灵笔必须达到同等完备度（用户明确要求）
- 预装题材 Skill 质量 = OpenWrite 内置引导水平
- 环境变量 API Key 优先级高于 UI 配置
- CI 门禁：`flutter analyze lib/` 0 error + `flutter test` 全通过
- Shell 为 Windows PowerShell，不支持 `&&`，用 `;` 分隔

## 下一步

1. 从 #4 或 #8 开始 `/implement`（两者无 blocker，可并行）
2. 每个工单在独立会话中实现（清除上下文）
3. P0 全部完成后再拆 P1 工单
