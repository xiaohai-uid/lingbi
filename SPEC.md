# 灵笔 P0 — 开发规格说明

> 生成于 Superpowers 工作流 | 基于 README.md + architecture.md + roadmap.md

## 1. 目标

实现可运行的 Flutter Desktop 编辑器，支持新建/打开项目，编辑/保存文档为 .md 文件。

## 2. 技术栈

| 层 | 选择 |
|---|---|
| 框架 | Flutter 3.x (Dart) with Windows Desktop |
| 数据库 | ZVec v0.5.1 (阿里开源向量DB) |
| 编辑器 | flutter_quill (WYSIWYG 富文本) |
| 状态管理 | Provider |
| 窗口管理 | window_manager |
| 文件管理 | path_provider + file_picker |

## 3. 架构分层

```
UI (Flutter Widgets)
  → Services (业务逻辑)
    → Data (ZVec + FileSystem)
```

### UI 层
- **MainScaffold**: 三栏布局 (Sidebar + Editor + AIPanel)
- **Sidebar**: 左侧项目/文档树 + 新建/打开项目按钮
- **EditorPanel**: WYSIWYG 编辑器 + 字数统计工具栏
- **AIPanel**: 右侧预留空壳

### 业务服务层
- **ProjectService**: 项目 CRUD + 默认路径 `Documents/灵笔/`
- **DocumentService**: 文档 CRUD + .md 文件存储
- **SyncService**: 文件系统 ↔ ZVec 双向同步

### 数据层
- **ZVecService**: 引擎初始化 + 集合管理 (projects, documents, settings)
- **FileService**: .md 文件读写 + 字数统计
- **Models**: Project, Document, CodexEntry

## 4. 实现清单

| # | 模块 | 文件 | 状态 |
|---|---|---|---|
| 1 | 项目配置 | pubspec.yaml, analysis_options.yaml | ✅ |
| 2 | 目录结构 | lib/ 全子目录 | ✅ |
| 3 | 数据模型 | project.dart, document.dart, codex_entry.dart | ✅ |
| 4 | 数据库层 | zvec_service.dart, collections.dart | ✅ |
| 5 | 文件系统 | file_service.dart, sync_service.dart | ✅ |
| 6 | AI 抽象 | ai_provider.dart | ⏳ |
| 7 | 业务服务 | project_service.dart, document_service.dart | ⏳ |
| 8 | 主题系统 | app_theme.dart, dark_theme.dart | ⏳ |
| 9 | UI 框架 | main_scaffold.dart, sidebar, editor, ai_panel | ⏳ |
| 10 | 页面 | main.dart, app.dart, home_page.dart, project_page.dart, settings_page.dart | ⏳ |
| 11 | 工具 | markdown_helper.dart, file_utils.dart | ⏳ |
| 12 | 测试 | test/widget_test.dart | ⏳ |
| 13 | 文档 | 补充关键文件注释 | ⏳ |

## 5. 质量标准

- 启动 < 2 秒
- 输入延迟 < 16ms
- 空闲内存 < 200MB
- 文档存为纯 .md
- 所有错误优雅降级 (try-catch + 用户提示)