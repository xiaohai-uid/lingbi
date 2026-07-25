# 灵笔 (Lingbi)

> AI 赋能的小说创作桌面工具 — Flutter Desktop · Local-First

灵笔是一款面向网络小说作者的开源桌面写作工具，融合 AI 辅助创作、市场情报、Skill 生态与专业的写作管理功能。

## 下载安装

**→ [下载 Lingbi-Setup-1.0.0.exe（Windows x64）](https://github.com/xiaohai-uid/lingbi/releases/latest)**

双击安装即可使用，无需配置运行环境。

## 功能特性

### 核心写作

- ✍️ **WYSIWYG 编辑器** — 基于 flutter_quill 的所见即所得富文本编辑
- 🤖 **AI 写作助手** — 智能续写、风格分析、模糊请求前置提问（Clarity Check）
- 📚 **世界构建 (Canon)** — 角色、地点、传说、情节线索管理
- 🎨 **故事画布** — 可视化情节节拍编排与拖拽排序
- 📄 **文档管理** — 项目/文档树组织，多项目 Tab 并行
- 💾 **自动保存** — 30 秒定时 + Ctrl+S + 版本快照
- 📤 **导出/导入** — Markdown/TXT/PDF 导出，.md/.txt 批量导入
- 🌙 **深色模式** — 系统/亮色/暗色主题切换

### 写作流水线（Pipeline）

- 🔄 **上下文组装** — 自动收集前文、大纲、角色、伏笔、风格、世界观
- 🎯 **创作罗盘** — 作者意图 + 当前焦点永不截断
- 📊 **Token 预算裁剪** — 按优先级智能裁剪，确保关键信息不丢失
- 📈 **市场情报注入** — 自动加载平台热门趋势数据到 AI 上下文
- ✅ **候选管理** — AI 输出只写候选区，人工确认后才采纳
- 🔒 **写锁 + 源版本追踪** — 防止并发冲突

### Skill 生态系统

- 🧩 **17 个可安装技能** — 社区贡献的写作辅助 Skill
- 📦 **Skill Store** — 一键安装/卸载，实时刷新
- ⚗️ **蒸馏创作** — 从你的 Canon + 文档中 AI 提炼出专属 SKILL.md
- 🔐 **声明式权限** — 轻量 Skill 只读，重量 Skill 按需授权

### 市场情报

- 📊 **热门趋势** — 起点/番茄/七猫平台榜单
- 🏷️ **热门标签** — 当前题材流行元素
- 📏 **章长统计** — 同类型平均章长参考
- 🤖 **AI 上下文注入** — 一键将市场数据注入写作 prompt

### 云同步 & 订阅

- ☁️ **WebDAV 云同步** — 支持坚果云/Nextcloud/ownCloud
- 🔑 **Free/Pro 分层** — Free 本地编辑 + 自带 Key；Pro 解锁云同步/高级导出/批量操作
- 📜 **离线许可证** — 格式验证 + 机器指纹绑定，无需联网激活
- 🕵️ **匿名数据贡献** — Opt-in 式不可逆聚合统计

## 快速开始（开发者）

### 前置要求

- Flutter SDK ≥3.38
- Windows 10/11 (x64)

### 从源码运行

```bash
git clone https://github.com/xiaohai-uid/lingbi.git
cd lingbi
flutter pub get
flutter run -d windows
```

### 配置 AI

1. 启动应用后进入 **设置 → AI 模型** 选择提供商
2. 在 **API 密钥** 页输入对应 Key
3. 也可通过环境变量配置（优先级更高）：
   - `SENSENOVA_API_KEY`
   - `DEEPSEEK_API_KEY`
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY`

### 构建安装包

```powershell
flutter build windows --release
cd installer
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" lingbi_setup.iss
# 输出: installer\Output\Lingbi-Setup-x.x.x.exe
```

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.38 | 桌面框架 (Windows) |
| flutter_quill | WYSIWYG 富文本编辑器 |
| ServiceLocator | 依赖注入（拓扑序初始化） |
| ZVec / JSON 文件 | 数据持久化（自动降级） |
| dart:io HttpClient | WebDAV 同步 / 市场情报 API |
| Inno Setup 6 | Windows 安装包打包 |

## 项目结构

```
lingbi/
├── lib/
│   ├── core/               # AI Providers、数据库、DI、领域模型
│   ├── modules/pipeline/   # 写作流水线（上下文组装→生成→候选→结算）
│   ├── services/           # 业务服务层
│   │   ├── skill/          # Skill 运行时（manifest/permission/loader/executor/distillation）
│   │   └── sync/           # WebDAV 云同步
│   ├── ui_v2/              # 新版 UI（组件化 + Design Tokens）
│   │   ├── components/     # 可复用组件（AI助手/市场面板/ProGate）
│   │   ├── pages/          # 页面（编辑器/设置/技能市场）
│   │   └── theme/          # 主题 Tokens + 图标
│   └── utils/
├── test/                   # 516 个测试用例
├── community/skills/       # 17 个社区 Skill
├── launcher/               # 一键启动器
├── installer/              # Inno Setup 安装脚本
├── lingbi_server/          # 可选微服务（Docker 部署）
└── docs/                   # ADR + 决策文档
```

## 微服务（可选）

灵笔为 **local-first** 架构，微服务不是运行前提。如需多设备协作或部署云端：

```bash
cp .env.example .env
docker-compose up -d
```

详见 [DEPLOY.md](DEPLOY.md)

## 贡献指南

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

[MIT](LICENSE)

## 相关链接

- [Release 下载](https://github.com/xiaohai-uid/lingbi/releases)
- [领域语言 (CONTEXT.md)](CONTEXT.md)
- [部署指南 (DEPLOY.md)](DEPLOY.md)
- [安全说明 (SECURITY.md)](SECURITY.md)

## 安全说明

- **API Key 存储**：本地 JSON (`{用户文档}/lingbi_data/settings.json`)，环境变量优先级更高。
- **离线优先**：许可证验证、Skill 执行、写作流水线均不依赖网络。
- **报告漏洞**：请参阅 [SECURITY.md](SECURITY.md)