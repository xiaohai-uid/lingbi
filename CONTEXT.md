# 灵笔 v4.0 领域语言 (Ubiquitous Language)

> 2026-07-10 更新: 加入 v5.0 愿景方向

## 核心愿景

灵笔的目标是成为**中文最好的 AI 原生长篇网文创作引擎**，对标 NovelAI 但超越它。
核心差异化：长篇稳定性（500万字不崩人设）、分步确认式生成、网文专项优化。

## 核心概念

| 术语 | 定义 |
|------|------|
| **World (世界)** | 顶层容器，一个 World 可包含多个 Work（叙事作品）|
| **Work (作品)** | 一部小说/作品，包含 Volumes（卷）|
| **Volume (卷)** | 作品的分卷，包含 Chapters（章）|
| **Chapter (章)** | 卷下的章节，包含 Scenes（场景）|
| **Scene (场景)** | 最小叙事单元，关联一个 .md 正文文件 |
| **Document (文档)** | 正文文件，以 .md 格式存储在 `documents/` 目录下 |
| **CanonEntry (正典条目)** | 世界观元素：角色/地点/传说/规则 |
| **Character (角色)** | 含身份演变、关系图谱、权重 |
| **Identity (身份)** | 角色在不同时期的称谓/身份 |
| **TimelineEvent (时间线事件)** | 故事时间线上的事件节点 |
| **Foreshadowing (伏笔)** | 埋设与回收的伏笔关系 |
| **Faction (势力)** | 组织/门派/国家等团体 |

## AI 体系

| 术语 | 定义 |
|------|------|
| **LLMFactory (LLM 工厂)** | AI Provider 注册中心 |
| **Layer1/2/3 Generator** | 三层生成管线：梗概→细纲→正文 |
| **ReviewPipeline (审查管线)** | 质量审查：角色一致性/爽点密度/格式 |
| **PromptService** | Prompt 模板引擎 |
| **ButterflyAnalyzer** | 蝴蝶效应分析器 |

## 存储架构

| 层 | 技术 | 用途 |
|----|------|------|
| **World 元数据** | JSON (world.json) | World 的 id/name/description/genres |
| **结构化数据** | Drift (SQLite) | Works/Volumes/Chapters/Scenes/Characters 等 |
| **正文内容** | .md 文件 | 场景正文 |
| **设置** | JSON (settings.json) | 主题/AI Provider/API Keys |

## 服务边界

| 服务 | 职责 |
|------|------|
| **WorldService** | World/Work/Volume/Chapter/Scene CRUD |
| **CanonService** | Character/Location/Lore/WorldRule CRUD |
| **DocumentService** | .md 文件读写 + 字数统计 |
| **AIService** | AI 对话路由 + 风格分析 + 续写 + 三层生成 |
| **SettingsService** | 用户设置持久化 |
| **QuotaService** | AI 调用配额管理 |
| **ExportService** | 文档导出 (MD/TXT/PDF/EPUB) |
| **VersionHistoryService** | 文档版本快照 |
| **TimelineService** | 时间线事件管理 |
| **FactionService** | 势力管理 |
| **CharacterGraphService** | 角色关系图谱 |
| **ButterflyAnalyzer** | 蝴蝶效应分析 |