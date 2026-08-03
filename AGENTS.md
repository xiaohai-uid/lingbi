# 灵笔 AGENTS.md

## 项目概述
灵笔（LingBi）是 Windows 桌面小说写作工具，Flutter Desktop 实现。
核心卖点：正典（Canon）驱动的 AI 辅助写作、候选正文机制、14 个功能域专业工具。

## 构建与验证
```powershell
# 构建
flutter pub get --enforce-lockfile
flutter run -d windows

# 验证（每次代码变更后必须运行）
flutter analyze lib/
flutter test --exclude-tags network
flutter build windows --release
```

## 架构约束
- Feature-first 分层：shared → domain → features → services → ui_v2
- features/ 下按功能域组织（14 个）：
  writing, canon, skill, settings, project, onboarding, sync,
  import_export, strand, review, style, parallel_world, knowledge, collaboration
- 每个 feature 内部结构：data/（服务+仓库）+ ui/（页面+面板）
- 上层只允许依赖下层，不可反向依赖
- Feature 之间不直接 import 对方 data/ 内部类，通过 shared/interfaces/ 解耦
- UI 不得绕过 NovelApplicationService 直接操作文件系统
- AI 生成内容必须经过候选正文机制（candidate_store），不可直接落盘
- service_locator.dart 是唯一的 DI 注入点

## 共享层说明
- lib/services/：跨功能基础设施（AI调度、文件存储、文档CRUD、模型路由、许可证、任务队列等）
- lib/ui_v2/components/：App Shell 组件（scaffold、sidebar、topbar、命令面板、工具箱入口等）
- lib/shared/：通用工具（AI provider、models、interfaces、DI、errors）

## AI Provider 架构
- 7 个供应商：OpenAI / Anthropic / DeepSeek / SenseNova / Claude / OpenAI-Compatible / Free
- 所有供应商继承 AIProvider 基类（shared/ai/ai_provider.dart）
- 运行时模型选择通过 RuntimeModelSelection 配置
- 新增供应商步骤：继承基类 → 注册到 ProviderFactory → 更新 ModelRegistry

## 编码规范
- Dart >=3.6，使用 ES module 风格 import
- features/ 内统一使用 package:lingbi/ 绝对导入
- 每个服务必须有对应的接口（shared/interfaces/）
- 错误处理使用 Result 模式（shared/errors/result.dart），不抛异常
- 文件命名：snake_case
- 类命名：PascalCase
- 变量和函数：camelCase（Dart 惯例）

## 核心数据流
- 写作管线：UI → NovelApplicationService → NovelWritingLoop → AIProvider → candidate_store → 用户确认 → 原子写入
- 上下文编译：ContextCompiler 收集 Canon + 前文 + 大纲 → token 预算裁剪 → 组装提示词
- 模型切换：SettingsService → RuntimeModelSelection → 所有管线同步

## 新增功能的标准步骤
1. 在 shared/interfaces/ 定义接口
2. 在 features/<name>/data/ 实现服务
3. 在 features/<name>/ui/ 实现 UI
4. 在 shared/di/service_locator.dart 注册
5. 运行 flutter analyze lib/ 和 flutter test --exclude-tags network

## PR 检查清单
- [ ] flutter analyze lib/ 零错误
- [ ] flutter test --exclude-tags network 全部通过
- [ ] 没有绕过 NovelApplicationService 直接操作文件系统
- [ ] AI 生成内容经过候选正文机制
- [ ] 新增 Provider 已覆盖全部 7 个供应商

## 已知技术债务
- settings_page.dart (52KB) / ai_assistant.dart (43KB) / onboarding_wizard.dart (41KB) 需拆分
- settings_service.dart (636行) 承担了过多职责：主题、API Key、快捷键、WebDAV、模型
- service_locator.dart (467行) 集中注册 50+ 服务，应拆分

## 禁止事项
- 不要在未运行 flutter analyze lib/ 的情况下提交代码
- 不要让 UI 直接调用 services/ 或绕过 NovelApplicationService
- 不要让 AI 生成内容未经用户确认就写入项目文件
- 不要修改 shared/ai/ai_provider.dart 的接口签名（会影响全部 7 个供应商）
- 不要在没有 --enforce-lockfile 的情况下运行 flutter pub get

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **lingbi** (9082 symbols, 20950 relationships, 454 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/lingbi/context` | Codebase overview, check index freshness |
| `gitnexus://repo/lingbi/clusters` | All functional areas |
| `gitnexus://repo/lingbi/processes` | All execution flows |
| `gitnexus://repo/lingbi/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
