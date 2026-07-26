# 灵笔 (Lingbi)

> AI 赋能的小说创作桌面工具 — Flutter Desktop · Local-First · Skill 生态

灵笔是一款面向网络小说作者的开源桌面写作工具，融合 AI 辅助创作、写作流水线、市场情报、Skill 生态与专业的全流程写作管理功能。从世界观构建到分镜成剧，从长篇连载到短篇精修，一站式覆盖。

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
- 📤 **导出/导入** — Markdown/TXT/Word 导出，.md/.txt 批量导入
- 🌙 **深色模式** — 系统/亮色/暗色主题切换

### 写作流水线（Pipeline）

- 🔄 **上下文组装** — 自动收集前文、大纲、角色、伏笔、风格、世界观、RAG 召回
- 🎯 **创作罗盘** — 作者意图 + 当前焦点永不截断
- 📊 **Token 预算裁剪** — 按优先级智能裁剪，确保关键信息不丢失
- 📈 **市场情报注入** — 自动加载平台热门趋势数据到 AI 上下文
- ✅ **候选管理** — AI 输出只写候选区，人工确认后才采纳
- 🔒 **写锁 + 源版本追踪** — 防止并发冲突
- 🛡️ **反幻觉三定律** — 约束注入/发明标识/状态回写，AI 不编造设定

### AI 智能体

- 🧠 **多模型路由** — 规划/正文/审阅三槽位独立配置，自动降级
- 🔍 **六维审稿** — 爽点/一致性/节奏/OOC/连续性/追读力评分 + 问题定位
- ✨ **去AI味引擎** — 规则库检测 + AI 改写，消除模板化表达
- 📡 **变更传播** — 设定修改后 RAG 语义检索影响范围，逐章修复建议
- 🚫 **反幻觉监督** — 硬约束注入 + 发明标识 + 一致性审校

### 知识 & 素材

- 📖 **向量知识库 (RAG)** — 纯 Dart 余弦相似度语义检索，增量索引/全量重建
- 📚 **拆书知识库** — 参考书管理/断点续爬/四层深度分析（风格/人物/情节/氛围）
- 🌐 **AI 联网搜索** — SearXNG/AnySearch 多后端，结果注入上下文
- 📊 **市场情报扫榜** — 起点/番茄/七猫趋势 + AI 分析 + ContextAssembler 注入
- 🎨 **风格蒸馏** — 从 Canon + 文档中 AI 提炼专属写作风格 Profile

### 叙事管理

- 🎭 **伏笔全生命周期** — 埋设/回收/逾期检测/活跃伏笔自动注入
- 🎵 **StrandWeave 节奏控制** — 多线叙事配比约束/红线门禁/分布记录
- 🌳 **平行世界** — 剧情分支/上下文快照继承/多线并行/差异对比/成剧下游
- 🕸️ **角色关系图谱** — 力导向布局/关系类型可视化/AI 自动提取/高亮交互

### 创作模式

- 📝 **长篇模式** — 世界观→大纲→章节的标准引导流程
- ⚡ **短篇模式** — 情绪设计→反转构思→精修出稿，聚焦故事核和情绪曲线
- 📋 **短篇拆文** — 五维拆解：故事核/结构/情感线/反转设计/共鸣点
- 📈 **短篇扫榜** — 知乎盐言/番茄短篇风口趋势分析
- 🎬 **一键成剧** — 小说→角色提示词卡 + 分镜脚本 + 场景描述（国漫/日漫/写实/3D）

### 引导 & 工作流

- 🧭 **GuidedFlowEngine** — 题材引导状态机，AI 判定步骤完成度
- 🎯 **7 个官方题材 Skill** — 玄幻/仙侠/都市/悬疑/言情/科幻/历史
- ✅ **工作流审批** — 草稿→待审→通过/拒绝，拒绝附意见 + AI 重生成
- 🚦 **流水线门禁** — 只有 approved 内容才进入后续生产环节
- 📦 **批量生成 + 任务队列** — 异步调度/取消/自动重试/批量编排/进度上报

### Skill 生态系统

- 🧩 **17+ 可安装技能** — 社区贡献的写作辅助 Skill
- 📦 **Skill Store** — 一键安装/卸载，GitHub 基础设施分发
- ⚗️ **蒸馏创作** — 从你的 Canon + 文档中 AI 提炼出专属 SKILL.md
- 🔐 **声明式权限** — 轻量 Skill 只读，重量 Skill 沙箱执行
- 🎬 **重量 Skill** — 一键成剧等复杂 Skill 走 SandboxedSkillApi

### 云同步 & 商业化

- ☁️ **WebDAV 云同步** — 增量同步/冲突检测/时间戳优先策略
- 🔑 **Free/Pro 分层** — Free 本地编辑 + 自带 Key；Pro 解锁高级功能
- 🎁 **公益模型配额** — 无 Key 用户每日/每月免费额度，自动切换
- 📜 **离线许可证** — 格式验证 + 机器指纹绑定，无需联网激活

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

### 运行测试

```powershell
# 静态分析（CI 门禁）
flutter analyze lib/

# 全量测试（847 个用例）
flutter test

# 单个测试文件
flutter test test/workflow_approval_test.dart
```

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
| ServiceLocator | 依赖注入（拓扑序初始化，30+ 服务） |
| ZVec / JSON 文件 | 数据持久化（自动降级） |
| IProjectMetaRepository | 项目级结构化元数据存储 |
| ContextAssembler | 写作流水线上下文组装（含 RAG 注入） |
| GuidedFlowEngine | 题材引导状态机 |
| SkillExecutor + Sandbox | Skill 声明式执行沙箱 |
| dart:io HttpClient | WebDAV 同步 / 市场情报 / 联网搜索 |
| Inno Setup 6 | Windows 安装包打包 |

## 项目结构

```
lingbi/
├── lib/
│   ├── core/               # AI Providers（5个）、数据库、DI、领域模型
│   ├── modules/pipeline/   # 写作流水线（上下文组装→生成→候选→结算）
│   ├── services/           # 业务服务层（30+ 服务）
│   │   ├── skill/          # Skill 运行时（manifest/permission/loader/executor/distillation）
│   │   ├── skills/         # 7 个官方题材 GuidedFlow Skill
│   │   ├── sync/           # WebDAV 云同步
│   │   └── interfaces/     # 服务接口定义
│   ├── ui_v2/              # 新版 UI（组件化 + Design Tokens）
│   │   ├── components/     # 可复用组件（18个服务面板 + 工具箱）
│   │   ├── pages/          # 页面（编辑器/设置/技能市场）
│   │   └── theme/          # 主题 Tokens + 图标
│   └── utils/
├── test/                   # 847 个测试用例
├── installer/              # Inno Setup 安装脚本
└── windows/                # Flutter Windows 平台层
```

## 许可证

[MIT](LICENSE)

## 安全说明

- **API Key 存储**：本地 JSON (`{用户文档}/lingbi_data/settings.json`)，环境变量优先级更高。
- **离线优先**：许可证验证、Skill 执行、写作流水线均不依赖网络。