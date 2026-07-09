## Why

灵笔当前（v0.4.0）是一个"AI 小说写作助手"，以 **Project（项目）** 为顶级实体，面向单个网文作品的创作。但用户真实需求远大于此：

> 「他笔下从来不是一本小说，而是一个世界」

现有的 Project → Document 扁平结构无法承载：
- **一个世界观产出多部作品**（网文 + 剧本 + 游戏脚本）
- **角色身份随剧情演变**（师妹→道侣→掌门）
- **事件蝴蝶效应对角色权重的影响**
- **世界线分支**（游戏编剧场景）
- **按角色权重分层注入 LLM 上下文**（控制 token 成本）

## What Changes

- **领域模型重构**：新增 World 顶级实体，替代 Project 成为核心容器。Project 降级为 Work（一部叙事作品）
- **存储层迁移**：从 JSON 文件存储迁移到 Drift (SQLite) + .md 文件混合架构
- **身份识别系统**：系统自动从行文中识别角色身份，用户只需确认/修改
- **权重系统**：角色权重根据身份权重派生 + 临时权重 + 特殊说明动态计算
- **上下文注入引擎**：按权重分层自动组装 LLM Prompt（~1500 tokens 上限）
- **蝴蝶效应引擎**：手动分析事件对角色权重的影响，费用透明
- **时间线增强**：分数索引排序 + 故事内时间 + 可选分支模式
- **导入导出体系**：Dart 原生导出（Markdown/TXT/DOCX/EPUB/JSON）+ Pandoc 高级导出（PDF/HTML）

## Capabilities

### New Capabilities
- `world-model`: World / Work / Volume / Chapter / Scene / Document 层级领域模型
- `drift-storage`: Drift (SQLite) 表结构定义 + Repository 层 + 数据迁移
- `identity-detection`: 系统自动从行文识别角色身份，LLM 兜底 + 渐进式学习
- `weight-system`: baseWeight 派生值 + tempWeight + WeightSpec 特殊说明
- `context-injection`: 分层上下文组装 + LRU 缓存 + Token 预算控制
- `butterfly-effect`: 手动分析事件影响 + 费用预估 + 结果可视化
- `timeline-enhancement`: 分数索引 + 故事内时间 + 分支模式
- `import-export`: Dart 原生导出 + Pandoc 高级导出

### Modified Capabilities
- `codex-entry`: → 拆分为独立类（Character / Location / Lore / WorldRule），命名为 Canon
- `character-model`: 新增 identities / baseWeight / tempWeight / weightSpecs / relations
- `relationship-model`: 新增 RelationStage 阶段演进（LLM 建议→用户确认）
- `timeline-service`: 升级为一级实体，新增分支 / 蝴蝶效应 / 故事内时间
- `novel-service`: ContextResolver 集成，注入策略改为分层上下文
- `prompt-service`: 新增分层 Prompt 组装 + Token 预算控制

## Impact

- **新依赖**：`drift` + `sqlite3_flutter_libs` + `build_runner` + `uuid`
- **受影响模块**：17 个 Service 需改从 Drift 读数据；Codex→Canon 重命名
- **数据迁移**：Project → World("默认世界") + Work("未命名作品")；CodexEntry → 对应表
- **ZVec 共存**：ZVec 继续存语义索引，Drift 存结构化数据
- **无需迁移现有 .md 文件**：正文文件不动，只变元数据存储
- **Pandoc**：可选依赖，仅用于 PDF 高级导出。DOCX/EPUB 用 Dart 原生生成