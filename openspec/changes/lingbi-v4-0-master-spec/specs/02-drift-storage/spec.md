# Drift 存储层 — 需求规格

> ID: CAP-STORAGE | 优先级: P0 | 依赖: CAP-WORLD

---

## 需求清单

### REQ-STORE-01: Drift 集成
- **优先级**: P0
- **描述**: 集成 Drift (SQLite) 作为结构化数据存储引擎
- **验收标准**:
  - `drift` + `sqlite3_flutter_libs` 依赖配置
  - `build.yaml` 配置 drift_dev 代码生成
  - `build_runner` 可正常运行生成代码
  - 数据库文件存储在 `Documents/灵笔/data/` 目录

### REQ-STORE-02: 15 张表结构
- **优先级**: P0
- **描述**: 按设计文档定义 15 张 Drift 表
- **验收标准**:
  - worlds / works / volumes / chapters / scenes 表
  - canon_entries (父表) + characters / locations / lore_entries / world_rules (子表)
  - identities / character_edges / timeline_events / foreshadowing / factions 表
  - 所有表含 id (TEXT PK), createdAt, updatedAt
  - 外键约束指向父表

### REQ-STORE-03: Repository 层
- **优先级**: P0
- **描述**: 为每个核心实体创建 Repository 封装 Drift 查询
- **验收标准**:
  - `WorldRepository` — World CRUD + Work 关联查询
  - `CharacterRepository` — Character CRUD + Identity 关联
  - `SceneRepository` — Scene CRUD + 文档关联
  - `TimelineRepository` — 时间线事件 CRUD + 排序
  - 所有 Repository 可 mock（抽象接口）

### REQ-STORE-04: 数据迁移
- **优先级**: P1
- **描述**: v0.5 JSON 存储 → v4.0 Drift 数据迁移
- **验收标准**:
  - `DataMigrator` 类实现迁移逻辑
  - dryRun() 预览迁移影响
  - migrate() 执行迁移，失败回滚
  - Project → World("默认世界") + Work("未命名作品")
  - CodexEntry → 按 type 拆分为对应子表
  - ZVec 向量索引重建

### REQ-STORE-05: .md 文件共存
- **优先级**: P0
- **描述**: 正文内容继续以纯 .md 文件存储
- **验收标准**:
  - Scene.documentId 指向 .md 文件路径
  - 文件读写由 FileService 处理
  - 用户可随时用任意编辑器打开 .md 文件
  - 文件改名/移动时同步更新 Drift 索引

### REQ-STORE-06: ZVec 共存 + 远期 Qdrant
- **优先级**: P1
- **描述**: ZVec 继续用于本地向量搜索，远期支持 Qdrant
- **验收标准**:
  - `VectorService` 抽象接口
  - ZVecVectorService 实现（本地）
  - QdrantVectorService 远期实现（通过 REST API）
  - 运行时可通过配置切换向量后端