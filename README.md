# 灵笔 (Lingbi)

> AI 赋能的小说创作桌面工具 — Flutter Desktop

灵笔是一款面向小说作者的开源桌面写作工具，融合 AI 辅助创作与专业的写作管理功能。

## 功能特性

- ✍️ **WYSIWYG 编辑器** — 基于 flutter_quill 的所见即所得富文本编辑
- 🤖 **AI 写作助手** — 智能续写、风格分析、小说结构拆解（支持 DeepSeek/OpenAI/Claude/SenseNova）
- 📚 **世界构建 (Canon)** — 角色、地点、传说、情节线索管理
- 🎨 **故事画布** — 可视化情节节拍编排与拖拽排序
- 🔍 **联网搜索** — DuckDuckGo 集成搜索
- 📄 **文档管理** — 项目/文档树组织
- 💾 **自动保存** — 30 秒定时 + Ctrl+S 快捷键
- 📝 **版本历史** — 每次保存自动快照，支持预览和恢复
- 📤 **导出** — 支持 Markdown/TXT/PDF 格式导出
- 📥 **导入** — 支持 .md/.txt 文件批量导入
- 📑 **多项目并行** — Tab 式切换多个项目
- 🌙 **深色模式** — 支持系统/亮色/暗色主题切换

## 快速开始

### 前置要求

- Flutter SDK 3.38+
- Windows 10/11

### 安装运行

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/lingbi.git
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

### 打包发布

```bash
flutter build windows --release
```

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.38 | 跨平台桌面框架 |
| flutter_quill | WYSIWYG 富文本编辑器 |
| Provider | 状态管理 |
| ZVec / JSON 文件 | 数据持久化 |
| file_picker | 文件选择与保存 |
| pdf | PDF 导出 |

## 微服务架构

灵笔后端采用 11 微服务架构，通过 API Gateway 统一路由：

| 服务 | 端口 | 运行时 | 职责 |
|------|------|--------|------|
| API Gateway | 8080 | Dart Frog | 统一路由代理 |
| AI Provider | 8081 | Dart Frog | AI 模型调用 |
| Project | 8082 | Dart Frog | 项目 CRUD + 树形结构 |
| Document | 8083 | Dart Frog | 文档管理 + FTS5 搜索 |
| Canon | 8084 | Dart Frog | 正典条目 + 语义搜索 |
| Export | 8085 | Dart Frog | MD/TXT/PDF 导出 |
| Version | 8086 | Dart Frog | 版本快照 + LZO 压缩 |
| Settings | 8087 | Node.js | 用户设置 + AES-256 加密 |
| Quota | 8088 | Dart Frog | AI 调用配额 |
| Storage | 8089 | Dart Frog | 向量存储 + 余弦搜索 |
| Sync | 8090 | Dart Frog | 文件双向同步 |
| Canvas | 8091 | Node.js | 故事画布布局算法 |

### Docker 一键部署

```bash
cp .env.example .env
# 编辑 .env 填入 API Keys
docker-compose up -d
docker-compose ps   # 确认全部 healthy
```

详见 [DEPLOY.md](DEPLOY.md)

## 项目结构

```
lingbi/
├── lib/                  # 客户端 (Flutter Desktop)
│   ├── core/             # 核心：AI Providers、数据库、DI
│   ├── services/         # 业务服务层
│   ├── ui/               # UI 组件
│   │   ├── layout/       # 布局组件
│   │   ├── pages/        # 页面
│   │   ├── widgets/      # 可复用组件
│   │   └── theme/        # 主题配置
│   └── utils/            # 工具函数
├── test/                 # 客户端测试
├── lingbi_server/        # 服务端 (Dart Frog + Node.js)
│   ├── lib/              # API Gateway + 代理
│   ├── microservices/    # 11 个微服务
│   └── test/             # 服务端集成测试
├── launcher/             # 一键启动器 (Flutter Desktop)
├── community/            # 社区资源
│   ├── skill-registry.json
│   └── website/          # 社区网站 (GitHub Pages)
├── docker-compose.yml    # Docker 编排
└── .env.example          # 环境变量模板
```

## 贡献指南

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

[MIT](LICENSE)

## 相关链接

- [部署指南 (DEPLOY.md)](DEPLOY.md)
- [领域语言 (CONTEXT.md)](CONTEXT.md)
- [社区网站](community/website/index.html)

## 安全说明

- **API Key 安全**：API Key 存储在本地 JSON 文件 (`{用户文档}/lingbi_data/settings.json`) 中，未加密。
  建议在生产环境中使用 OS 密钥链或 `flutter_secure_storage`。
- **环境变量**：可通过 `SENSENOVA_API_KEY`、`DEEPSEEK_API_KEY` 等环境变量传入 API Key，
  优先级高于设置页配置。
- **报告漏洞**：请参阅 [SECURITY.md](SECURITY.md)