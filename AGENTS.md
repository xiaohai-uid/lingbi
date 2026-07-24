# AGENTS.md

This file provides guidance to Lingma (lingma.aliyun.com) when working with code in this repository.

## Build & Test Commands

```powershell
# 依赖安装
flutter pub get

# 静态分析（仅客户端代码，CI 门禁）
flutter analyze lib/

# 运行全部测试
flutter test

# 运行单个测试文件
flutter test test/user_flow_test.dart

# 运行匹配名称的测试
flutter test --name "创建项目"

# 运行应用（Windows 桌面）
flutter run -d windows

# 发布构建
flutter build windows --release

# 微服务测试（进入对应目录后）
cd lingbi_server/microservices/<service>; dart pub get; dart test
```

Shell 环境为 **Windows PowerShell**，不支持 `&&`，用 `;` 分隔命令。不要使用 `head`、`ls -la` 等 POSIX 命令。

## Architecture Overview

灵笔是 **local-first Flutter Desktop** 小说写作工具。当前 P0 交付方向为本地 Markdown 项目 + AI 辅助，Docker/微服务不是运行前提。

### 依赖注入（ServiceLocator）

`lib/core/di/service_locator.dart` 是唯一的服务注册中心，`main()` 中 `await ServiceLocator.init()` 一次性按拓扑序创建全部服务。UI 层通过 `ServiceLocator.instance.xxxService` 获取服务，**不使用 Provider/InheritedWidget 注入服务**。`ProjectTabController` 也由 ServiceLocator 持有，页面不应自行创建或 dispose 它。

初始化失败时 `initSucceeded = false`，应用降级为纯本地 Markdown 编辑模式（`_LocalModeHome`），不依赖任何 Service。

### 分层结构

```
lib/
├── core/
│   ├── ai/           # AIProvider 接口 + 5 个实现 (Free/SenseNova/DeepSeek/OpenAI/Claude)
│   ├── database/     # ZVecService — zvec 原生或降级 JSON 文件存储
│   ├── di/           # ServiceLocator
│   ├── file_system/  # FileService, SyncService
│   ├── models/       # 领域模型 (Project, Document, CanonEntry, StoryBeat)
│   └── errors/       # Result<T> + AppError 层次
├── services/         # 业务服务（每个服务实现对应 interface）
└── ui/
    ├── layout/       # 三栏布局 MainScaffold: sidebar + editor + aiPanel
    ├── pages/        # HomePage (Tab 容器), ProjectPage, CanonPage, SettingsPage
    ├── widgets/      # 可复用组件
    └── theme/        # AppTheme.light / AppTheme.dark
```

### 关键数据流

1. **项目 → Tab → 页面**：`ProjectTabController`（ChangeNotifier）管理多项目 Tab。`HomePage` 监听它，`openProject()` 后自动切换到 `ProjectPage`。
2. **文档编辑 → 自动保存**：`EditorPanel` 内部用 `QuillController` + 30s Timer + `_saveGeneration` 计数器。文档切换时递增 generation 使旧异步保存失效。
3. **AI 上下文**：`AIPanel` 接收 `projectId`/`projectName`，`initState` 时调用 `AIService.setProjectContext()` 和 `CanonLinkingService.generateCanonSummary()`。
4. **设置 → 环境变量**：`SettingsService._load()` 先读 `Platform.environment`（SENSENOVA_API_KEY 等），再读 JSON 配置文件（不覆盖 env 值）。当前 provider 无有效 key 时自动切换到 env 提供的 provider。
5. **持久化**：Windows 上 ZVec 不可用，自动降级为 `StorageService`（`{用户文档}/lingbi_data/*.json`）。

### 领域术语（CONTEXT.md）

| 术语 | 含义 |
|------|------|
| Canon（正典） | 世界观条目：角色/地点/传说/情节节点。**不是** Codex |
| StoryBeat | 故事画布中的情节节拍单元 |
| ProjectTabController | 多项目 Tab 状态管理，由 ServiceLocator 持有 |

### 降级模式

`ServiceLocator.init()` 失败（如 path_provider 不可用）时，`LingBiApp` 渲染 `_LocalModeHome`：纯 `dart:io` 文件操作，不依赖任何注入服务。测试中可用 `ServiceLocator.failed()` 构造降级实例。

## Lint & CI

- `analysis_options.yaml` 基于 `flutter_lints` 加严，关键规则：`sort_constructors_first`、`avoid_void_async`、`eol_at_end_of_file`、`cancel_subscriptions`。
- CI（GitHub Actions, windows-latest）门禁：`flutter analyze lib/` + `flutter test`。
- 全仓库 `flutter analyze`（含 lingbi_server/）存在已知 baseline 告警，不属于客户端任务范围。

## Multi-Agent Workflow Contract

本仓库使用多 Agent 协作流程。Chat 历史不可靠，Git 文件和命令证据为权威。

### Roles

- **GPT/Codex:** 计划、分类、分配、最终 review 决策；不实现业务代码。
- **Qoder Quest:** 在专属 worktree 执行 `COMPLEX` 任务。
- **Qoder Ultra Review:** 独立只读 first-pass review，仅写 `QODER_REVIEW.md`。
- **OpenCode:** 执行 `SIMPLE` 任务或被重新分配的已释放任务。

### Key Rules

- 每个任务有唯一执行租约（lease），第二个执行者必须停止。
- 执行者不得 merge/push，需用户显式授权。
- 任务目录：`.ai/tasks/<TASK-ID>/`，模板在 `.ai/templates/`。
- 验收证据必须包含：Git SHA、diff 范围、命令 + 退出码 + 关键输出。
- 同一 blocker 最多自主尝试 2 次，失败后写 `BLOCKER.md` 停止。
- 不扩展任务范围、不替换关键模块、不降低验收标准。
- 保持无关脏文件不动，不 clean/reset/discard/commit 它们。

### Startup Sequence (for executors)

1. 本文件 → 2. `CONTEXT.md` + `docs/adr/` → 3. `.ai/PROJECT_MAP.md` → 4. 任务 `SPEC.md` → 5. `STATE.md` + `EVIDENCE.md` → 6. 最近 5 条 Git commit + `git status` + baseline diff

## Repository Conventions

- 提交信息使用 Conventional Commits（`feat:` / `fix:` / `refactor:` 等）。
- GitHub Issues 为外部 tracker，标签：`needs-triage`、`ready-for-agent`、`ready-for-human`、`wontfix`。
- PR 检查清单：`flutter analyze` 0 error + `flutter test` 全通过 + 无 Codex 残留引用（应为 Canon）。
- 环境变量 API Key 优先级高于 UI 设置页配置。

## Agent skills

### Issue tracker

Issues tracked in GitHub (`xiaohai-uid/lingbi`) via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` + `docs/adr/`. See `docs/agents/domain.md`.
