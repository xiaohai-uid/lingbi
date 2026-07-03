# 灵笔领域语言 (Ubiquitous Language)

## 核心概念

| 术语 | 定义 |
|------|------|
| **Project (项目)** | 一部小说/作品的容器，包含文档、Codex 条目和设置 |
| **Document (文档)** | 项目中的一个章节/片段，以 .md 文件存储 |
| **CodexEntry (知识条目)** | 世界观元素：角色/地点/传说/情节节点 |
| **StoryBeat (故事节拍)** | 故事画布中的一个情节单元 |
| **AI Provider (AI 提供商)** | 提供 AI 能力的模型服务接口 |

## 服务边界 (Service Boundaries)

| 服务 | 职责 | 所属领域 |
|------|------|---------|
| **ProjectService** | 项目 CRUD | 项目管理 |
| **DocumentService** | 文档 CRUD + 文件读写 | 文档管理 |
| **AIService** | AI 对话路由 + 风格分析 + 续写 | AI 写作 |
| **AIProvider** | 具体模型提供商适配 (接口) | AI 基础设施 |
| **CodexService** | 世界观条目 CRUD + 语义搜索 | 世界构建 |
| **CodexLinkingService** | 文档中自动检测 Codex 提及 | 世界构建 |
| **ExportService** | 文档导出 (MD/TXT/PDF) | 文档输出 |
| **FileService** | 底层文件读写 | 基础设施 |
| **SettingsService** | 用户设置持久化 | 基础设施 |
| **StorageService** | JSON 文件存储 (ZVec 降级) | 基础设施 |
| **SyncService** | 文件系统 ↔ 存储双向同步 | 基础设施 |
| **QuotaService** | AI 调用配额管理 | AI 基础设施 |
| **VersionHistoryService** | 文档版本快照 | 文档管理 |
| **ProjectTabController** | 多项目 Tab 管理 | UI 状态 |