# project-control 独立源码仓库设计

## 1 定位

| 事实源 | 职责 | 存储内容 |
|--------|------|----------|
| Obsidian Vault | 治理规则唯一权威源 | V2.0 正文、治理 ADR |
| **project-control 仓库** | **Skill 实现唯一源码源** | **SKILL.md、脚本、Schema、测试、安装工具** |
| 各 Agent Skill 目录 | 安装副本或受管理分发 | 由安装器写入，不手工编辑 |
| 各业务仓库 | 项目集成配置和状态 | `.ai/project-control/`、AGENTS.md 入口 |

## 2 仓库结构

```
project-control/
├── skills/
│   └── project-control/
│       ├── SKILL.md              # Skill 定义（Agent 读取的入口）
│       └── assets/               # Skill 附属资源（可选）
├── src/
│   ├── config_resolver.py        # 配置发现和优先级链
│   ├── governance_reader.py      # 治理文档读取和验证
│   ├── repo_scanner.py           # 仓库只读扫描
│   ├── workstream_inferrer.py    # Workstream 推断（纯函数）
│   ├── skill_router.py           # Skill 路由（纯函数）
│   ├── output_formatter.py       # 输出格式化
│   ├── state_transition.py       # 受控状态转换（M2）
│   ├── evidence_runner.py        # 证据包装执行（M3）
│   └── validator.py              # CI 验证逻辑（M3）
├── schemas/
│   ├── config.schema.json        # 用户配置 Schema
│   ├── repo-config.schema.json   # 仓库级覆盖 Schema
│   ├── state.schema.json         # state.json Schema（M2）
│   ├── evidence.schema.json      # 证据记录 Schema（M3）
│   └── transition.schema.json    # 状态转换事件 Schema（M2）
├── scripts/
│   ├── project_control.py        # CLI 入口（transition/check/bootstrap/run-evidence）
│   ├── install.ps1               # Windows 安装脚本
│   ├── install.sh                # Unix 安装脚本（未来）
│   └── uninstall.ps1             # 卸载脚本
├── tests/
│   ├── test_config_resolver.py
│   ├── test_governance_reader.py
│   ├── test_repo_scanner.py
│   ├── test_workstream_inferrer.py
│   ├── test_skill_router.py
│   ├── test_state_transition.py  # M2
│   ├── test_validator.py         # M3
│   └── fixtures/
│       ├── valid-governance.md
│       ├── empty-governance.md
│       ├── v1-governance.md
│       ├── valid-config.json
│       ├── invalid-config.json
│       ├── sample-state.json
│       └── sample-repo/          # 模拟仓库结构
├── docs/
│   ├── ARCHITECTURE.md           # 内部架构说明
│   ├── INSTALL.md                # 安装指南
│   └── CHANGELOG.md              # 变更日志
├── installer/
│   ├── codex/                    # Codex 适配（M1 Canary）
│   │   └── README.md
│   ├── qoder/                    # Qoder 适配（M4）
│   └── opencode/                 # OpenCode 适配（M4）
├── .github/
│   └── workflows/
│       └── ci.yml                # 本仓库 CI（测试 + lint）
├── .gitignore
├── AGENTS.md                     # 本仓库自身的 Agent 规则
├── LICENSE
├── README.md
├── pyproject.toml                # Python 项目配置
└── requirements-dev.txt          # 开发依赖
```

## 3 模块职责与依赖

```
config_resolver ──→ governance_reader ──→ repo_scanner
                                              │
                                              ▼
                                    workstream_inferrer
                                              │
                                              ▼
                                       skill_router
                                              │
                                              ▼
                                    output_formatter
```

- M1 只实现上半部分（config → governance → scan → infer → route → output）
- M2 增加 `state_transition` + `schemas/state.schema.json`
- M3 增加 `evidence_runner` + `validator`

## 4 技术选型

| 决策 | 选择 | 理由 |
|------|------|------|
| 实现语言 | Python 3.10+ | 跨平台、无编译步骤、Agent 环境普遍可用 |
| 测试框架 | pytest | 标准、fixture 支持好 |
| Schema 验证 | jsonschema | 轻量、标准 |
| CLI 框架 | argparse（标准库） | 无额外依赖 |
| 包管理 | pip + pyproject.toml | 标准 |
| CI | GitHub Actions | 与灵笔一致 |

## 5 安装与分发

### 5.1 M1 安装方式（手动）

```powershell
# 1. 克隆仓库
git clone <project-control-repo> C:\tools\project-control

# 2. 安装 Skill 到 Codex
Copy-Item -Recurse skills\project-control <codex-skills-dir>\project-control

# 3. 创建用户配置
New-Item -Path "$env:USERPROFILE\.project-control" -ItemType Directory
# 写入 config.json
```

### 5.2 未来安装方式（M4）

```powershell
# 一键安装
.\scripts\install.ps1 --agent codex
.\scripts\install.ps1 --agent qoder
.\scripts\install.ps1 --agent opencode
```

### 5.3 卸载

```powershell
.\scripts\uninstall.ps1 --agent codex
# 删除 Skill 目录副本，保留用户配置
```

## 6 版本管理

- 仓库使用语义化版本标签（`v0.1.0-m1`、`v0.2.0-m2` 等）
- SKILL.md 头部包含版本号
- `/project-control` 运行时报告自身版本
- 治理文档版本（V2.0）与 Skill 实现版本独立

## 7 与业务仓库的集成

业务仓库（如灵笔）只包含：

```
.ai/project-control/
├── state.json              # M2 起
├── bootstrap-proposal.md   # M1 可选输出
└── runtime.local.json      # M2 起，.gitignore

.ai/project-control.json    # 仓库级覆盖（可选，.gitignore）
docs/agents/project-control-interface.md  # 接口契约
AGENTS.md                   # 含 Cross-project workflow 段落
```

不包含：Skill 源码、测试、Schema 定义、安装脚本。

## 8 Canary 策略

M1 仅安装到 Codex 环境：

1. 在 Codex 中验证全部 TC-01 至 TC-24
2. 通过后记录验收证据
3. M4 阶段再适配 Qoder 和 OpenCode
4. 各 Agent 适配器的差异仅在 SKILL.md 的调用约定，核心逻辑共享
