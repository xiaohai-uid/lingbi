# World 领域模型 — 需求规格

> ID: CAP-WORLD | 优先级: P0 | 依赖: 无

---

## 需求清单

### REQ-WORLD-01: World 顶层容器
- **优先级**: P0
- **描述**: 新增 World 实体作为顶级容器，替代 Project 成为系统根实体。一个 World 可包含多个 Work（叙事作品）。
- **验收标准**:
  - World CRUD (创建/读取/更新/删除)
  - World 包含 metadata (name, description, createdAt, updatedAt)
  - World 可关联多个 Work
  - 现有 Project 自动迁移为默认 World 下的一个 Work

#### Scenario: 用户创建世界
- **Given**: 用户首次启动灵笔
- **When**: 用户点击"新建世界"
- **Then**: 系统创建 World 实体，自动创建默认 Work "未命名作品"，进入编辑器

### REQ-WORLD-02: Work 升级
- **优先级**: P0
- **描述**: Project 重命名为 Work，新增 Volume → Chapter → Scene 层级结构
- **验收标准**:
  - Work 包含 Volume 列表
  - Volume 包含 Chapter 列表
  - Chapter 包含 Scene 列表
  - Scene 关联一个 .md 文档
  - 支持拖拽重排 Volume/Chapter/Scene

### REQ-WORLD-03: Codex → Canon 重命名
- **优先级**: P1
- **描述**: CodexEntry 体系重构为 Canon（知识体系），拆分为四个具体子类
- **验收标准**:
  - Character / Location / Lore / WorldRule 四个具体类继承 CanonEntry
  - 每个子类有专属字段
  - 现有 CodexEntry 数据自动迁移到对应子类
  - 搜索接口兼容旧数据

### REQ-WORLD-04: 角色身份演变
- **优先级**: P1
- **描述**: Character 支持多身份（Identity），身份随时间线演变
- **验收标准**:
  - Character.identities 列表
  - Identity 包含名称/来源/活跃状态/起止时间/权重
  - 系统可从行文自动检测身份
  - 用户可手动添加/编辑/确认身份

### REQ-WORLD-05: 兼容层
- **优先级**: P0
- **描述**: 保留 v0.5 Project 接口一个版本周期
- **验收标准**:
  - 旧 ProjectService 方法可用（内部委托给 WorldService）
  - 旧 CodexService 方法可用（内部委托给 CanonService）
  - @Deprecated 注解标注旧接口
  - flutter analyze 0 error