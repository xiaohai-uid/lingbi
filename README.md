# 灵笔 (Lingbi)

> AI 赋能的小说创作桌面工具 — Flutter Desktop + Dart Frog Microservices

灵笔是一款面向小说作者的开源桌面写作工具，融合 AI 辅助创作与专业的写作管理功能。v4.0 引入微服务架构，支持三层 AI 生成管线、质量评审、蝴蝶效应分析等高级功能。

## 功能特性

- ✍️ **WYSIWYG 编辑器** — 基于 flutter_quill 的所见即所得富文本编辑
- 🤖 **AI 写作助手** — 三层生成管线（梗概→大纲→场景流式生成），支持 DeepSeek/OpenAI/Claude
- 📚 **世界构建 (Codex)** — 角色、地点、传说、时间线、势力、伏笔、蝴蝶效应管理
- 🎨 **故事画布** — 可视化情节节拍编排与拖拽排序
- 🔍 **联网搜索** — DuckDuckGo 集成搜索
- 📄 **文档管理** — 项目/文档树组织
- 💾 **自动保存** — 30 秒定时 + Ctrl+S 快捷键
- 📝 **版本历史** — 每次保存自动快照，支持预览和恢复
- 📤 **多格式导出** — 支持 Markdown/TXT/PDF/DOCX/EPUB 格式导出
- 📥 **导入** — 支持 .md/.txt 文件批量导入
- 🧠 **质量评审** — 角色一致性、Hook 密度、格式规范自动检测
- 🦋 **蝴蝶效应** — AI 分析时间线事件变更对剧情和角色的影响
- 🪪 **身份识别** — 写作时自动检测角色身份称呼（掌门/师尊/陛下等），气泡提示并确认入库
- 🕸️ **角色关系图谱** — 可视化角色关系网络，支持点击高亮与手动添加关系
- 🦋 **蝴蝶效应** — AI 分析时间线事件变更对剧情和角色的影响
- 📑 **多项目并行** — Tab 式切换多个项目
- 🌙 **深色模式** — 支持系统/亮色/暗色主题切换

## 快速开始

### 前置要求

- Flutter SDK 3.6+
- Dart SDK 3.6+
- Windows 10/11
- LiteLLM Gateway (可选，用于 AI 功能)

### 安装运行

```bash
# 克隆仓库
git clone https://github.com/xiaohai-uid/lingbi.git
cd lingbi

# 安装依赖
flutter pub get

# 运行
flutter run -d windows
```

### 配置 AI

1. 启动应用后点击右上角 ⚙️ 进入设置
2. 在「AI 模型」中选择提供商
3. 输入对应 API Key 并保存
4. 也可通过环境变量配置：`SENSENOVA_API_KEY`、`DEEPSEEK_API_KEY` 等

### 微服务架构（可选）

灵笔 v4.0 支持本地微服务架构，提供更强大的 AI 生成能力：

```bash
# 启动 LiteLLM Gateway
docker compose up litellm -d

# 启动 Novel Engine（三层 AI 生成管线）
cd services/novel-engine
dart run main.dart

# 启动 Quality Review（质量评审）
cd services/quality-review
dart run main.dart
```

### 打包发布

```bash
flutter build windows --release
```

或使用 MSIX 打包：

```bash
flutter pub run msix:create
```

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.6+ | 跨平台桌面框架 |
| flutter_quill | WYSIWYG 富文本编辑器 |
| Provider | 状态管理 |
| Drift 2.28 | SQLite ORM（World 级数据库） |
| dart_frog | 后端微服务框架 |
| LiteLLM | LLM 统一网关 |
| http | HTTP 客户端 |
| pdf | PDF 导出 |
| archive | DOCX/EPUB 导出 |

## 项目结构

```
lingbi/
├── lib/
│   ├── core/          # 核心：AI Providers、数据库、文件系统
│   ├── data/          # 数据层：Drift 数据库、Repositories
│   ├── services/      # 业务服务层
│   ├── ui/            # UI 组件
│   │   ├── layout/    # 布局组件
│   │   ├── pages/     # 页面
│   │   ├── widgets/   # 可复用组件
│   │   └── theme/     # 主题配置
│   └── utils/         # 工具函数
├── services/          # 后端微服务
│   ├── novel-engine/  # AI 生成引擎（三层管线）
│   └── quality-review/# 质量评审服务
├── test/              # 测试
├── docs/              # 文档
└── docker-compose.yml # 微服务编排
```

## 贡献指南

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

[MIT](LICENSE)

## 支持开发

灵笔是开源免费软件。如果你觉得它有用，欢迎通过 **爱发电** 捐赠支持持续开发：

- 爱发电：https://afdian.com/a/lingbi
- 捐赠后可获得 tokens.json 会员令牌，在「设置 → AI 调用配额」中激活，解锁无限调用等会员权益。

## 安全说明

- **API Key 安全**：API Key 存储在本地 JSON 文件 (`{用户文档}/lingbi_data/settings.json`) 中，未加密。
  建议在生产环境中使用 OS 密钥链或 `flutter_secure_storage`。
- **环境变量**：可通过 `SENSENOVA_API_KEY`、`DEEPSEEK_API_KEY` 等环境变量传入 API Key，
  优先级高于设置页配置。
- **报告漏洞**：请参阅 [SECURITY.md](SECURITY.md)