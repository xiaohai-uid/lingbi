# /project-control M1 实施 Spec：只读 Canary 版本

## 1 目标

在一个全新 Agent 会话中，安全地读取治理规则和项目事实，恢复上下文，并给出有证据的下一步 Skill 建议。**不修改任何正式项目文件。**

## 2 用户场景

| # | 场景 | 触发 |
|---|------|------|
| S1 | 新会话启动，Agent 需要知道"我在哪、该做什么" | 用户调用 `/project-control` |
| S2 | 长时间中断后恢复上下文 | 用户调用 `/project-control` |
| S3 | 切换仓库后确认治理规则仍然有效 | 用户调用 `/project-control` |
| S4 | 验证治理文档是否可达且版本正确 | 用户调用 `/project-control --check` |

## 3 输入

### 3.1 调用参数

| 参数 | 必选 | 说明 |
|------|------|------|
| `--governance <path>` | 否 | 显式指定治理文档路径（最高优先级） |
| `--check` | 否 | 仅验证配置和文档可达性，不做仓库扫描 |
| `--verbose` | 否 | 输出详细扫描过程 |

### 3.2 隐式输入

- 当前工作目录（仓库根）
- 文件系统（Obsidian Vault、用户配置）
- Git 状态（分支、HEAD、工作区）

## 4 输出

### 4.1 正常输出格式

```
【Project Control Recovery】

治理文档：<路径或来源标识>
文档版本：<version>
生效等级：<effective_level>
配置来源：<user-config | env | repo-override | explicit>

当前仓库：<repo-name>
当前分支：<branch>
Git HEAD：<short-sha>
工作区状态：<clean | N files modified>

读取到的项目资料：
- AGENTS.md: <found | missing>
- CONTEXT.md: <found | missing>
- ADR: <N files found | none>
- Task 状态: <N active | none>
- Git 证据: <recent commits summary>

发现的 Workstream：
- 名称: <name>
  推断阶段: <phase>
  推断状态: <status>
  客观证据: <list>
  语义未知: <list>
  状态冲突: <list | none>

推荐下一 Skill: <skill-name>
推荐原因: <reason>

当前能力: 只读推断（M1）
禁止行为: 不写入 state.json、不推进阶段、不修改 Issue、不领取 Lease
```

### 4.2 候选基线报告（可选输出）

首次对某仓库运行时，可输出：

```
.ai/project-control/bootstrap-proposal.md
```

该文件为建议性文档，须用户批准后方可在 M2 转化为正式 state.json。M1 不自动创建此文件，仅在用户请求时生成。

## 5 治理文档定位优先级

按以下顺序尝试，首个成功即停止：

1. `--governance <path>` 显式参数
2. `.ai/project-control.json` 中的 `governancePath` 字段
3. `PROJECT_CONTROL_GOVERNANCE` 环境变量
4. `OBSIDIAN_VAULT` 环境变量 + `AI软件工程系统/00-AI软件项目总控提示词-V2.0.md`
5. `~/.project-control/config.json` 中的 `vaultPath` + `governanceRelativePath`
6. 有限默认路径探测（`~/Documents/Obsidian Vault/` 等候选，多候选时须用户确认）
7. 失败并报告

## 6 配置文件格式

### 6.1 用户级配置 `~/.project-control/config.json`

```json
{
  "schemaVersion": 1,
  "vaultPath": "C:\\Users\\<user>\\Documents\\Obsidian Vault",
  "governanceRelativePath": "AI软件工程系统/00-AI软件项目总控提示词-V2.0.md"
}
```

### 6.2 仓库级覆盖 `.ai/project-control.json`

```json
{
  "schemaVersion": 1,
  "governancePath": "optional-absolute-or-relative-path",
  "repositoryOverrides": {
    "defaultMode": "standard"
  }
}
```

仓库级覆盖若含本机绝对路径，应加入 `.gitignore`。

## 7 治理文档验证规则

读取治理文档后执行以下检查：

| 检查项 | 失败行为 |
|--------|----------|
| 文件存在且非空 | 报错：治理文档不可达 |
| YAML frontmatter 可解析 | 报错：文档格式无效 |
| `document` 字段匹配预期值 | 报错：文档标识不匹配 |
| `version` 字段存在且可解析 | 报错：版本无法确定 |
| `status` 不是 `deprecated` | 报错：文档已废弃 |
| `effective_level` 存在 | 警告：无法确定生效能力 |

版本不匹配（如找到 V1.0）时：报告版本差异，不伪装为 V2.0。

## 8 仓库扫描范围

M1 只读扫描以下位置：

| 路径 | 目的 |
|------|------|
| `AGENTS.md` | 执行层规则、Multi-Agent Contract |
| `CONTEXT.md` | 领域术语 |
| `docs/adr/` | 架构决策记录 |
| `.ai/tasks/*/STATE.md` | Task 状态 |
| `.ai/project-control/state.json` | 已持久化状态（若存在） |
| `.ai/project-control/bootstrap-proposal.md` | 候选基线（若存在） |
| Git: `git branch --show-current` | 当前分支 |
| Git: `git rev-parse --short HEAD` | HEAD SHA |
| Git: `git status --porcelain` | 工作区状态 |
| Git: `git log --oneline -10` | 最近提交 |
| `openspec/changes/` | Spec 文件（若存在） |
| `.github/workflows/` | CI 配置概况 |

不扫描：源代码实现细节、node_modules、build 产物、.env 文件内容。

## 9 Workstream 只读推断逻辑

### 9.1 推断来源优先级

1. `state.json` 中的声明状态（若存在）
2. Task STATE.md 中的阶段标记
3. Git 分支命名模式（如 `feat/onboarding-*`）
4. Issue/PR 标签和状态（若可访问）
5. Spec 文件存在性和内容
6. ADR 最近修改

### 9.2 推断规则

- 有 state.json 且与证据一致 → 报告声明状态
- 有 state.json 但与证据冲突 → 报告冲突，标注 `stateDrift`
- 无 state.json → 纯推断，标注"推断，未经确认"
- 证据不足 → 标注"语义未知，需用户确认"

### 9.3 事实与推断的区分

输出中必须明确标注每条信息的来源：

- `[事实]`：直接来自文件或 Git 命令输出
- `[推断]`：基于证据链的逻辑推断
- `[未知]`：需要用户语义确认

## 10 Skill 路由建议

基于推断的阶段和状态，推荐下一步 Skill：

| 推断结果 | 推荐 |
|----------|------|
| 无活跃 Workstream，有新需求信号 | `/grill-me` 或 `/grill-with-docs` |
| clarification 完成，无 Spec | `/to-spec` |
| Spec 存在且已批准，无设计 | `/codebase-design` |
| 设计完成，无 Ticket | `/to-tickets` |
| Ticket 为 ready-for-agent | `/implement` 或 `/tdd` |
| 存在非空 Diff 和比较基点 | `/code-review` |
| 测试失败或 Bug 报告 | `/diagnosing-bugs` |
| CI 失败 | `/gh-fix-ci` |
| 无法确定 | 报告不确定原因，请求用户指引 |

M1 只推荐，不自动调用。

## 11 错误和降级行为

| 错误类型 | 行为 |
|----------|------|
| Vault 不可访问 | 报错 + 降级为仅 AGENTS.md 模式，标注"治理层未激活" |
| 治理文档为空或格式错误 | 报错 + 同上降级 |
| 版本不匹配 | 报告差异 + 询问用户是否继续 |
| 非 Git 仓库 | 报告 + 跳过 Git 扫描，仅文件系统推断 |
| AGENTS.md 不存在 | 警告 + 继续（执行层规则缺失） |
| CONTEXT.md 不存在 | 警告 + 继续 |
| 无任何 Task 状态 | 正常（可能是新项目） |
| state.json 格式无效 | 警告 + 忽略该文件，纯推断 |
| 多个活跃 Workstream | 全部列出，请用户指定关注哪个 |
| 权限不足无法读取文件 | 跳过该项 + 报告 |

**核心原则**：任何失败都不导致静默假装成功。宁可报告"我不知道"，也不编造状态。

## 12 隐私与路径输出限制

- 输出中不暴露完整本机用户名路径（用 `<user>` 替代）
- 不输出 `.env` 文件内容
- 不输出 API Key 或 Token
- 配置来源只报告类型（user-config / env / repo-override），不输出完整路径（除非 `--verbose`）
- Git 远程 URL 若含凭据则脱敏

## 13 明确非目标（M1 不做）

- 不写入 `state.json`
- 不执行受控状态转换
- 不自动修改 Issue（创建、关闭、标签）
- 不领取 Task Lease
- 不自动 Commit、Push 或 Merge
- 不运行 CI 门禁
- 不安装或检查 Git Hooks
- 不适配多个 Agent 环境（仅 Codex Canary）
- 不自动调用推荐的 Skill
- 不创建 Workstream
- 不修改 AGENTS.md 或 CONTEXT.md
- 不实现 `run-evidence` 或 `project-control-validate`

## 14 测试 Seam

为支持自动化测试，实现须暴露以下 Seam：

| Seam | 说明 |
|------|------|
| `ConfigResolver` | 可注入的配置解析器，测试时可替换文件系统 |
| `GovernanceReader` | 可注入的文档读取器，测试时可返回预设内容 |
| `RepoScanner` | 可注入的仓库扫描器，测试时可模拟 Git 状态 |
| `WorkstreamInferrer` | 纯函数推断逻辑，输入扫描结果，输出推断 |
| `SkillRouter` | 纯函数路由逻辑，输入推断结果，输出推荐 |
| `OutputFormatter` | 可替换的输出格式化器 |

所有外部 I/O（文件、Git 命令）通过接口隔离，核心推断逻辑为纯函数。

## 15 M1 验收标准

### 15.1 通过条件（全部满足）

1. 全新会话中调用 `/project-control` 成功完成恢复
2. 正确定位并读取 V2.0 治理文档
3. 正确解析 frontmatter 并报告版本和生效等级
4. 正确扫描灵笔仓库（AGENTS.md、CONTEXT.md、ADR、Git）
5. 推断至少一个 Workstream 并标注证据来源
6. 区分事实、推断和未知
7. 推荐下一步 Skill 并给出理由
8. 明确报告自身为只读模式
9. 不修改任何正式项目文件（Git 工作区验证）
10. Vault 不可达时安全失败
11. 文档版本错误时正确报告
12. 存在状态冲突时显示冲突而非忽略
13. 独立 Review 通过
14. 源码已 Commit 到独立仓库
15. 安装和卸载方法明确

### 15.2 失败路径验证

- Vault 不存在 → 安全报错
- 文档为空 → 报错
- 非 Git 目录 → 降级运行
- 缺少 AGENTS.md → 警告继续
- state.json 与 Git 冲突 → 显示冲突

## 16 技术约束

- 实现语言：与 Skill 执行环境兼容（Markdown SKILL.md + 辅助脚本）
- 辅助脚本语言：Python 3.10+（跨平台）或 Dart（与灵笔一致）
- 不引入网络依赖
- 不要求管理员权限
- Windows 优先（当前环境），但不硬编码路径分隔符
- 首次运行耗时目标 < 10 秒
