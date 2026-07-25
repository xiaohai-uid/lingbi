# M0 四项产物一致性审查

## 审查范围

| 产物 | 文件 |
|------|------|
| V2.0 正文 | Obsidian: `AI软件工程系统/00-AI软件项目总控提示词-V2.0.md` |
| M1 Spec | `.ai/project-control/m1-implementation-spec.md` |
| 测试矩阵 | `.ai/project-control/m1-test-matrix.md` |
| 仓库设计 | `.ai/project-control/m0-repo-design.md` |

## 1. V2.0 是否准确反映七份 ADR

| ADR | V2.0 对应章节 | 覆盖 |
|-----|---------------|------|
| 0003 单源分发 | §2 文档治理 + §3 激活机制 | ✓ |
| 0004 分层状态 | §8 分层状态模型 | ✓ |
| 0005 四档路由 | §4 模式路由 + §5 Direct | ✓ |
| 0006 治理-执行分层 | §9 治理-执行分层 | ✓ |
| 0007 合规体系 | §10 合规体系 | ✓ |
| 0008 非线性推进 | §6 生命周期 + §7 非线性推进 | ✓ |
| 0009 渐进交付 | §13 交付路线 + §14 Bootstrap | ✓ |

## 2. ADR 一致性矩阵歧义是否已澄清

| # | 歧义 | V2.0 处理 | 状态 |
|---|------|-----------|------|
| 1 | state.json 写入时机 | §8.3 标注"M2 起生效" | ✓ |
| 2 | M1 前无 /project-control | §14 Bootstrap 规则 | ✓ |
| 3 | CI 不运行 Skill vs CI 验证 | §3.2 明确 `project-control-validate` 为独立脚本 | ✓ |
| 4 | status vs result 语义 | §6.2 + §6.3 分别定义 | ✓ |
| 5 | Direct 不创建 Task | §5.2 流程中无 Task/Issue 创建 | ✓ |

## 3. M1 Spec 与 V2.0 一致性

| 检查项 | 结果 |
|--------|------|
| 定位优先级链与 V2.0 §3.2 一致 | ✓ |
| 只读约束与 V2.0 §13 M1 定义一致 | ✓ |
| 失败处理与 V2.0 §3.4 一致 | ✓ |
| 非目标与 V2.0 §13 + ADR-0009 一致 | ✓ |
| Skill 路由表与 V2.0 §11 一致 | ✓ |
| 隐私限制未超出 V2.0 范围 | ✓ |

## 4. 测试矩阵对 M1 Spec 的覆盖

| Spec 模块 | 覆盖用例 | 完整 |
|-----------|----------|------|
| 配置发现（§5） | TC-01~04 | ✓ |
| 文档验证（§7） | TC-07~11 | ✓ |
| 仓库扫描（§8） | TC-05, TC-12~16 | ✓ |
| Workstream 推断（§9） | TC-17, TC-19 | ✓ |
| Skill 路由（§10） | TC-06 | ✓ |
| 错误降级（§11） | TC-07~12, TC-23 | ✓ |
| 隐私（§12） | TC-21 | ✓ |
| 只读保证（§13） | TC-20 | ✓ |
| 边界（--check 等） | TC-22, TC-24 | ✓ |

轻微缺口：`--verbose` 模式无独立用例。不阻塞 M1，实施时补充。

## 5. 仓库设计对 M1 Spec 测试 Seam 的支撑

| Spec Seam | 仓库模块 | 匹配 |
|-----------|----------|------|
| ConfigResolver | src/config_resolver.py | ✓ |
| GovernanceReader | src/governance_reader.py | ✓ |
| RepoScanner | src/repo_scanner.py | ✓ |
| WorkstreamInferrer | src/workstream_inferrer.py | ✓ |
| SkillRouter | src/skill_router.py | ✓ |
| OutputFormatter | src/output_formatter.py | ✓ |

## 6. 治理层与执行层无重复定义

| 规则 | V2.0 定义 | AGENTS.md 定义 | 重复 |
|------|-----------|----------------|------|
| 模式路由 | §4-5 | 不定义 | 无 |
| Workstream 生命周期 | §6-7 | 不定义 | 无 |
| Task Lease | 不定义 | Multi-Agent Contract | 无 |
| 角色分配 | 不定义 | Multi-Agent Contract | 无 |
| 构建命令 | 不定义 | Build & Test | 无 |
| 证据持久化（通用要求） | §10.3 | 具体格式 | 互补 |

## 7. 结论

四项产物内部一致，无阻塞性缺陷。一个轻微缺口（--verbose 测试）不影响 M1 启动。
