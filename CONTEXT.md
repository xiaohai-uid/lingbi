# 灵笔领域语言 (Ubiquitous Language)

## 核心概念

| 术语 | 定义 |
|------|------|
| **Project (项目)** | 一部小说/作品的容器，包含文档、Canon 条目和设置 |
| **Document (文档)** | 项目中的一个章节/片段，以 .md 文件存储 |
| **CanonEntry (正典条目)** | 世界观元素：角色/地点/传说/情节节点 |
| **StoryBeat (故事节拍)** | 故事画布中的一个情节单元 |
| **AI Provider (AI 提供商)** | 提供 AI 能力的模型服务接口 |
| **EndpointConfig (端点配置)** | 供应商统一抽象：{ id, name, baseUrl, apiKey, protocol(openai/anthropic), modelId }，官方预置与用户自定义走相同路径 |
| **Skill (技能)** | 可复用的 AI 创作能力单元，分轻量（prompt）和重量（代码插件）两层 |
| **Skill Runtime (技能运行时)** | 客户端内加载、校验、执行 Skill 的引擎 |
| **Skill Manifest (技能清单)** | 重量 Skill 的元数据文件，声明权限、参数、触发条件 |
| **Declarative Permission (声明式权限)** | Skill 通过 requires 字段声明对领域对象的访问范围，运行时沙箱执行 |
| **Distillation (蒸馏)** | 从用户 Canon/写作风格自动生成轻量 Skill 的过程 |
| **Market Intelligence (市场情报)** | 灵笔"懂市场"维度的能力：题材热度、读者偏好、竞品分析 |
| **Flywheel (飞轮)** | 两层正循环：Skill 生态飞轮 + 知识积累飞轮 |
| **Skill Store (技能商店)** | 客户端内浏览、搜索、安装、卸载 Skill 的界面 |
| **Slash Command (斜杠命令)** | 编辑器中输入 "/" 触发 Skill 的交互入口 |
| **GuidedFlow (引导流程)** | 数据驱动的轻量状态机，编排创作引导步骤的推进与完成判定；内容来自题材 Skill，执行复用 AIService |

## 服务边界 (Service Boundaries)

| 服务 | 职责 | 所属领域 |
|------|------|---------|
| **ProjectService** | 项目 CRUD | 项目管理 |
| **DocumentService** | 文档 CRUD + 文件读写 | 文档管理 |
| **AIService** | AI 对话路由 + 风格分析 + 续写 | AI 写作 |
| **AIProvider** | 具体模型提供商适配 (接口) | AI 基础设施 |
| **CanonService** | 正典条目 CRUD + 语义搜索 | 世界构建 |
| **CanonLinkingService** | 文档中自动检测 Canon 提及 | 世界构建 |
| **ExportService** | 文档导出 (MD/TXT/PDF) | 文档输出 |
| **FileService** | 底层文件读写 | 基础设施 |
| **SettingsService** | 用户设置持久化 | 基础设施 |
| **StorageService** | JSON 文件存储 (ZVec 降级) | 基础设施 |
| **SyncService** | 文件系统 ↔ 存储双向同步 | 基础设施 |
| **QuotaService** | AI 调用配额管理 | AI 基础设施 |
| **VersionHistoryService** | 文档版本快照 | 文档管理 |
| **ProjectTabController** | 多项目 Tab 管理 | UI 状态 |
| **SkillActionService** | Skill 注册/搜索/执行 | Skill 生态 |
| **SkillMarketplace** | Skill 浏览/安装/卸载/更新 | Skill 生态 |
| **IntentConfirmationService** | Skill 参数充分性评估 + 确认卡 | Skill 生态 |
| **ModelRegistry** | 模型元数据管理（能力/价格/上下文窗口） | AI 基础设施 |
| **GuidedFlowEngine** | 引导流程编排（步骤推进/完成判定/分支处理） | 创作引导 |