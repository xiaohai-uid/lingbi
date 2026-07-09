# 灵笔 v4.0 — 架构设计

> 设计文档 | 2026-07-18 | 整合 5 个历史变更的统一设计

---

## 1. 设计原则

1. **渐进式迁移** — 不破坏现有功能，每个 Phase 独立可交付
2. **数据不锁定** — 正文永远以纯 .md 文件存储，用户随时可迁移
3. **先本地，后分布式** — 本地 SQLite 起步，远期可扩展到 Qdrant/Neo4j
4. **测试驱动** — 每个抽象层先写测试，后实现
5. **向后兼容** — v0.5 Project 模型保留一个版本周期的兼容层
6. **可观测性** — 所有 LLM 调用和微服务 API 记录延迟、成功率和 Token 消耗

---

## 2. 领域模型设计

### 2.1 实体关系

```
World 1──N Work
World 1──N Canon
World 1──1 CharacterGraph
World 1──N Faction
World 1──N GlobalTimeline

Work 1──N Volume
Work 1──N Timeline (作品级时间线)
Work 1──N StyleTemplate

Volume 1──N Chapter
Volume 1──N Arc (故事弧)

Chapter 1──N Scene
Chapter 1──N Document
Chapter N──M Character (本章出场角色)

Scene 1──1 Document (正文)
Scene N──M Character
Scene N──M TimelineEvent

Canon (抽象父类):
  ├── Character 1──N Identity (身份)
  ├── Character N──M CharacterEdge (关系)
  ├── Location 1──N Scene
  ├── Lore 1──N Work
  └── WorldRule 1──N Work

TimelineEvent N──M Character
TimelineEvent N──M Location
Foreshadowing 1──1 TimelineEvent (埋设)
Foreshadowing 1──1 TimelineEvent (回收)
```

### 2.2 核心模型定义

```dart
// --- 顶层容器 ---
class World {
  String id;
  String name;
  String description;
  List<Work> works;
  List<CanonEntry> canon;
  List<Faction> factions;
  List<TimelineEvent> timeline;
  DateTime createdAt;
  DateTime updatedAt;
}

// --- 叙事作品 ---
class Work {
  String id;
  String worldId;
  String title;
  String author;
  String genre;          // fantasy / mystery / urban / wuxia
  String style;          // qidian / fanqie / custom
  WorkStatus status;     // draft / writing / completed / published
  int targetWordCount;
  List<Volume> volumes;
  List<Character> characters;
  Timeline timeline;
  List<StyleTemplate> styles;
}

// --- 卷/章/场景结构 ---
class Volume {
  String id;
  String workId;
  int index;
  String title;
  String synopsis;
  List<Chapter> chapters;
}

class Chapter {
  String id;
  String volumeId;
  int index;
  String title;
  List<Scene> scenes;
  List<String> characterIds;  // 本章出场角色
}

class Scene {
  String id;
  String chapterId;
  int index;
  String title;
  String documentId;    // 指向 .md 文件
  String synopsis;
  String pov;           // 视角角色
  SceneStatus status;   // outline / drafting / reviewing / done
}

// --- 知识体系 (Codex → Canon 重命名) ---
abstract class CanonEntry {
  String id;
  String worldId;
  String name;
  String description;
  CanonType type;       // character / location / lore / world_rule
  List<String> tags;
  Map<String, dynamic> customFields;
}

class Character extends CanonEntry {
  List<Identity> identities;     // 身份演变
  List<CharacterEdge> relations;  // 关系列表
  Map<String, int> weights;      // 权重缓存
  String appearance;              // 外貌
  String personality;             // 性格
  String background;              // 背景故事
  CharacterArchetype archetype;   // 原型
}

class Identity {
  String id;
  String name;           // "掌门" / "师妹" / "林长老"
  IdentitySource source; // system_detected / user_defined / llm_suggested
  bool isActive;
  DateTime periodStart;  // 身份起止时间
  DateTime? periodEnd;
  int baseWeight;        // 派生权重基数
}

// --- 关系图谱 ---
class CharacterEdge {
  String characterId1;
  String characterId2;
  RelationshipType type; // master_apprentice / enemy / lover / family / servant / ally
  int strength;          // 1-10
  RelationStage stage;   // suggested / confirmed / archived
  String description;
}

class CharacterNode {
  String characterId;
  String name;
  List<CharacterEdge> edges;
  int centrality;        // 图论中心度
}

// --- 时间线与伏笔 ---
class TimelineEvent {
  String id;
  String worldId;
  String workId;
  String title;
  String description;
  int sortOrder;         // 分数索引
  DateTime storyTime;    // 故事内时间
  List<String> characterIds;
  List<String> locationIds;
  EventType type;        // main_plot / sub_plot / background
  BranchMode branchMode; // none / optional / exclusive
}

class Foreshadowing {
  String id;
  String plantedEventId;   // 埋设事件
  String harvestedEventId; // 回收事件
  ForeshadowStatus status; // planted / growing / harvested / abandoned
  int subtlety;            // 隐蔽度 1-10
}
```

---

## 3. 存储层设计

### 3.1 Drift 表结构 (15 张表)

```
worlds          — World 实体
works           — Work 实体，worldId → worlds
volumes         — Volume 实体，workId → works
chapters        — Chapter 实体，volumeId → volumes
scenes          — Scene 实体，chapterId → chapters
canon_entries   — CanonEntry 父表 (多态)
characters      — Character 子表，canonId → canon_entries
locations       — Location 子表，canonId → canon_entries
lore_entries    — Lore 子表，canonId → canon_entries
world_rules     — WorldRule 子表，canonId → canon_entries
identities      — Identity 实体，characterId → characters
character_edges — CharacterEdge 实体
timeline_events — TimelineEvent 实体
foreshadowing   — Foreshadowing 实体
factions        — Faction 实体
```

### 3.2 存储策略矩阵

| 操作 | 引擎 | 说明 |
|------|------|------|
| 读取正文 | 文件系统 | 直接读 .md 文件 |
| 写入正文 | 文件系统 | 写 .md 文件 + 触发版本快照 |
| 元数据 CRUD | Drift | 强类型 SQLite 查询 |
| 全文搜索 | Drift FTS5 | SQLite 全文索引 |
| 语义搜索 | ZVec → Qdrant | 角色/场景相似度匹配 |
| 版本历史 | Git LFS | 正文版本快照 |
| 关系查询 | Drift JOIN | 当前数据量小，N+1 可接受 |
| 全局图谱 | Neo4j (远期) | 跨作品关系分析 |

### 3.3 数据迁移

```dart
// 迁移路径: v0.5 JSON → v4.0 Drift
// 1. Project → World("默认世界") + Work("未命名作品")
// 2. CodexEntry → 按 type 拆分为 Character / Location / Lore / WorldRule
// 3. 正文 .md 文件不动
// 4. ZVec 向量索引重建
abstract class DataMigrator {
  Future<MigrationResult> migrateV0_5ToV4_0();
  Future<void> rollback();
  Future<MigrationReport> dryRun();
}
```

---

## 4. AI 引擎设计

### 4.1 LLM 抽象层

```
LLMFactory (注册中心)
  ├─ OpenAICompatible (DeepSeek / OpenAI / 兼容 API)
  ├─ ClaudeClient (Anthropic)
  ├─ FreeProvider (内置公益模型)
  └─ CustomProvider (可注册)

Cross-Cutting:
  ├─ ThinkStreamFilter (思考标签过滤)
  ├─ RetryHandler (指数退避重试)
  ├─ SchemaProcessor (JSON Schema 提取/验证)
  └─ CostMonitor (Token 消耗追踪)
```

### 4.2 三层生成管线 (微服务形式)

```
POST /api/v1/novel/generate-layer1
  Layer1Generator
  1. 验证输入 (创意非空, 类型合法)
  2. 调用 LLM.generateStructured<Synopsis>()
  3. 验证输出结构
  4. 缓存结果 (30 分钟 TTL)

POST /api/v1/novel/generate-layer2
  Layer2Generator
  1. 加载 Layer1 缓存
  2. 调用 LLM.generateStructured<LayeredNovelStructure>()
  3. 验证章节数/场景数约束
  4. 缓存结果

GET /api/v1/novel/generate-layer3 (SSE)
  Layer3Generator
  1. 加载 Layer2 缓存
  2. 调用 LLM.streamText() 流式生成
  3. 逐 chunk 推送到 SSE
  4. 场景完成后触发质量审查

Fallback: Layer3 → Layer2Compact → Layer1Only → DirectLLM
```

### 4.3 质量审查管线

```
ReviewPipeline
  ├─ CharacterConsistency (角色一致性) — 性格/动机/对话风格
  ├─ HookDensity (爽点密度) — 打脸/反转/升级/获得/装逼
  ├─ FormatReview (格式审查) — 段落/对话比/禁止内容
  └─ ReviewReport (综合报告) — 评分 0-10 + 重写建议
```

### 4.4 Prompt 工程体系

```
assets/prompts/
├── novel/
│   ├── prompts.yaml          # 主配置：20+ Prompt 模板
│   ├── genres/
│   │   ├── fantasy.yaml      # 奇幻 (桑德森三定律)
│   │   ├── mystery.yaml      # 悬疑 (Fair Play)
│   │   ├── urban.yaml        # 都市
│   │   └── wuxia.yaml        # 武侠
│   └── styles/
│       ├── qidian.yaml       # 起点爆款 (冲突前置)
│       └── fanqie.yaml       # 番茄爽文 (快节奏)
└── skills/
    └── novel-architect/      # 16 步创作方法论
```

---

## 5. 微服务架构

### 5.1 服务定义

| 端口 | 服务 | 技术栈 | 优先级 |
|:----:|------|--------|:------:|
| 8081 | AI Provider | LiteLLM Gateway + Dart | P0 |
| 8082 | Project Service | Shelf + Drift | P0 |
| 8083 | Document Service | Shelf + Drift + FTS5 | P0 |
| 8084 | Codex Service | Shelf + Drift + ZVec | P1 |
| 8085 | Export Service | Shelf + pdf/epub libs | P1 |
| 8086 | Version History | Shelf + Git LFS | P1 |
| 8088 | Quota Service | Shelf + Drift | P1 |
| 8089 | Sync Service | Shelf + Drift | P1 |
| 8090 | Canvas Service | Shelf + Drift | P1 |
| 8091 | Skill Service | Shelf + Drift | P2 |
| 8092 | Novel Engine | Shelf + LLM | P0 |
| 8093 | Quality Review | Shelf + LLM | P1 |

### 5.2 API Gateway

```dart
// dart_frog _middleware.dart
Router()
  .mount('/api/v1/ai/', proxy('http://localhost:8081'))
  .mount('/api/v1/projects/', proxy('http://localhost:8082'))
  .mount('/api/v1/documents/', proxy('http://localhost:8083'))
  .mount('/api/v1/codex/', proxy('http://localhost:8084'))
  .mount('/api/v1/export/', proxy('http://localhost:8085'))
  .mount('/api/v1/version-history/', proxy('http://localhost:8086'))
  .mount('/api/v1/quota/', proxy('http://localhost:8088'))
  .mount('/api/v1/sync/', proxy('http://localhost:8089'))
  .mount('/api/v1/canvas/', proxy('http://localhost:8090'))
  .mount('/api/v1/skills/', proxy('http://localhost:8091'))
  .mount('/api/v1/novel/', proxy('http://localhost:8092'))
  .mount('/api/v1/quality/', proxy('http://localhost:8093'));
```

### 5.3 Docker Compose

```yaml
version: '3.8'
services:
  api-gateway:
    build: ./lingbi_server
    ports: ["8080:8080"]
  ai-provider:
    build: ./services/ai-provider
    ports: ["8081:8080"]
  novel-engine:
    build: ./services/novel-engine
    ports: ["8092:8080"]
  # ... 其余微服务
  lite-llm:
    image: ghcr.io/berriai/litellm:main
    ports: ["4000:4000"]
    volumes: ["./litellm_config.yaml:/app/config.yaml"]
```

---

## 6. 身份识别 + 上下文注入

### 6.1 身份识别管线

```
原始文本
  │
  ▼
RuleMatcher (规则引擎)
  ├─ 称呼匹配: "掌门" / "师妹" / "林长老"
  └─ 模式匹配: "姓+职务" / "辈分+称呼"
  │
  ▼ (规则匹配不到时)
LLMDetector (LLM 兜底)
  └─ 调用 BaseLLMClient 分析上下文
  │
  ▼
DetectorCache
  └─ key = "章节ID", ttl = 场景编辑周期
  │
  ▼
用户确认 UI
  └─ 角色面板 → 确认/拒绝/修改 → 渐进式学习
```

### 6.2 上下文注入引擎

```
ContextResolver
  ├─ 按权重排序: baseWeight + tempWeight + identityWeight
  ├─ 活跃身份过滤: 当前场景出场角色
  ├─ 地点/规则/时间线关联
  └─ LRU 缓存: key = 章节ID, 失效 = 用户编辑

ContextInjector
  ├─ 分层组装: 核心(500) + 活跃(500) + 参考(300) + 规则(200)
  ├─ Token 预算: ~1500 tokens 上限
  └─ 注入格式: markdown blockquote
```

---

## 7. 社区 + 生态系统

### 7.1 Skill 系统

```
community/
├── skill-registry.json     # 注册表
├── skills/                  # Skill 仓库
│   ├── novel-architect/     # 已安装
│   └── ...                  # 社区贡献
└── website/                 # Skill 市场前端
    ├── index.html
    ├── changelog/
    └── skills/
```

### 7.2 Launcher

```dart
// 功能
class Launcher {
  Future<void> startAll();      // 一键启动所有微服务
  Future<void> stopAll();       // 一键停止
  Future<void> restart(String serviceName);
  Stream<ServiceStatus> watch(); // 实时状态流
  Future<HealthReport> healthCheck();
}
```

### 7.3 Docker 部署

```
灵笔/
├── docker-compose.yml        # 全服务编排
├── Dockerfile                # Flutter 构建
├── docker/
│   ├── api-gateway/          # 网关 Dockerfile
│   ├── ai-provider/          # AI 服务 Dockerfile
│   └── ...                   # 各服务 Dockerfile
└── scripts/
    ├── start.ps1             # Windows 启动
    └── start.sh              # Linux/macOS 启动
```

---

## 8. 商业化

### 8.1 配额系统

```dart
class QuotaService {
  int dailyLimit;              // 默认 100 次/天
  bool isPremium;              // 会员无限
  Future<bool> checkQuota(String userId);
  Future<QuotaUsage> getUsage(String userId);
  Future<void> consume(String userId);
}
```

### 8.2 发布计划

```
GitHub 开源:
  - MIT License
  - README + CONTRIBUTING + SECURITY
  - GitHub Actions CI
  - Docker Hub 镜像

商业化:
  - 爱发电捐赠
  - 会员: 无限 API + 优先更新
  - 企业版: 私有部署 + 技术支持
```

---

## 9. 决策记录

| 决策 | 选择 | 理由 | 替代方案 |
|------|------|------|---------|
| **存储层** | Drift + .md 混合 | 强类型查询 + 数据不锁定 | 纯 SQLite / MongoDB |
| **向量搜索** | ZVec 起步 → Qdrant 远期 | 本地零配置 → 分布式扩展 | Chroma / Pinecone |
| **关系图谱** | Drift JOIN → Neo4j 远期 | 当前数据量小，渐进 | Neo4j 直接上 |
| **AI 网关** | LiteLLM | 100+ Provider 支持 | Dify / Portkey |
| **微服务框架** | dart_frog (Shelf) | Dart 原生，与 Flutter 共享类型 | Python FastAPI / Go |
| **身份识别** | 规则引擎 + LLM 兜底 | 低成本 + 高准确率 | 纯 LLM / 纯规则 |
| **版本控制** | Git LFS | 成熟、零开发量 | 自建版本库 |
| **部署** | Docker Compose | 开发者友好 | Kubernetes |