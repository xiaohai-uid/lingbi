# 灵笔 v4.0 — 微服务架构设计

> 2026-07-09 | 基于 v4.0 Ubiquitous Language + Go + Rust 混合架构

---

## 1. 架构总览

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Desktop                           │
│                    (纯展示层 + gRPC 客户端)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │Dashboard │ │Workspace │ │  Editor  │ │ Settings │  ...        │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘            │
│       └────────────┴──────┬──────┴────────────┘                  │
│                    ┌──────┴──────┐                               │
│                    │  gRPC Client │                               │
│                    └──────┬──────┘                               │
└───────────────────────────┼──────────────────────────────────────┘
                            │ (gRPC over HTTP/2, :50051)
┌───────────────────────────┼──────────────────────────────────────┐
│                    ┌──────┴──────┐                                │
│                    │  API Gateway │  (Go)                         │
│                    │  :8080      │  auth · rate-limit · routing  │
│                    └──────┬──────┘                                │
│         ┌─────────────────┼────────────────────┐                  │
│         ▼                 ▼                    ▼                  │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐            │
│  │   Go     │    │     Go       │    │     Go       │            │
│  │ CRUD     │    │   CRUD       │    │   CRUD       │            │
│  │ Services │    │   Services   │    │   Services   │            │
│  ├──────────┤    ├──────────────┤    ├──────────────┤            │
│  │ Project  │    │  Document    │    │  Settings    │            │
│  │ Service  │    │  Service     │    │  Service     │            │
│  │ :8082    │    │  :8083       │    │  :8087       │            │
│  ├──────────┤    ├──────────────┤    ├──────────────┤            │
│  │ Timeline │    │  Export      │    │  Quota       │            │
│  │ Service  │    │  Service     │    │  Service     │            │
│  │ :8094    │    │  :8085       │    │  :8088       │            │
│  ├──────────┤    ├──────────────┤    ├──────────────┤            │
│  │ Faction  │    │  Sync        │    │  Version     │            │
│  │ Service  │    │  Service     │    │  History     │            │
│  │ :8095    │    │  :8090       │    │  :8086       │            │
│  └──────────┘    └──────────────┘    └──────────────┘            │
│         │                 │                    │                  │
│         ▼                 ▼                    ▼                  │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │                    PostgreSQL + Redis                      │    │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                    │
│         ┌─────────────────┼────────────────────┐                  │
│         ▼                 ▼                    ▼                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │    Rust      │  │    Rust      │  │    Rust      │            │
│  │  AI/推理     │  │  AI/推理     │  │  AI/推理     │            │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤            │
│  │ AI Provider  │  │ Novel Engine │  │ Quality      │            │
│  │ :8081        │  │ :8092        │  │ Review       │            │
│  ├──────────────┤  ├──────────────┤  │ :8093        │            │
│  │ Canon Service│  │ Butterfly    │  ├──────────────┤            │
│  │ :8084        │  │ Analyzer     │  │ Canvas       │            │
│  └──────────────┘  │ :8096        │  │ Service      │            │
│                    └──────────────┘  │ :8091        │            │
│                                      └──────────────┘            │
│         │                 │                    │                  │
│         ▼                 ▼                    ▼                  │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │          Qdrant (向量搜索) + LiteLLM (AI Gateway)          │    │
│  └──────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

## 2. 语言归属决策

### Go 微服务（CRUD + 编排型）

| 服务 | 理由 |
|------|------|
| **API Gateway** | 高并发路由、认证、限流 — Go 的 goroutine 模型天然适合 |
| **Project Service** | 大量 CRUD + 树形结构操作 — Go 标准库 + sqlx 高效 |
| **Document Service** | .md 文件读写 + 全文搜索 — Go 的 FTS 生态成熟 |
| **Settings Service** | 简单 KV 操作 — Go + Redis 最为轻量 |
| **Export Service** | PDF/EPUB 导出 — Go 的 PDF 库（unidoc/gofpdf）成熟 |
| **Quota Service** | Token Bucket 算法 — Go 并发安全实现简单 |
| **Sync Service** | WebDAV 同步 + 文件监控 — Go 的 fsnotify + webdav 库 |
| **Version History** | 快照 + 差异比较 — Go 的 diff 算法实现 |
| **Timeline Service** | 时间线事件管理 CRUD |
| **Faction Service** | 势力管理 CRUD |

### Rust 微服务（AI + 推理密集型）

| 服务 | 理由 |
|------|------|
| **AI Provider** | LLM 调用的流式处理 + 并发请求 — Rust 的 async + tokio 极致性能 |
| **Novel Engine** | 三层生成管线（结构化输出 + 流式）— 类型安全处理复杂 Prompt 模板 |
| **Quality Review** | 角色一致性/爽点密度分析 — 需要高效文本处理 + LLM 批处理 |
| **Canon Service** | 向量搜索 + 图结构（角色关系）— Rust 的 Qdrant/Neo4j 客户端性能 |
| **Butterfly Analyzer** | 蝴蝶效应分析 — 图遍历 + 状态模拟，Rust 的安全并发模型 |
| **Canvas Service** | 场景关系图 — 图计算密集 |

## 3. 微服务端口分配

```
Port  Service           Language  Tech Stack
────  ────────────────  ────────  ─────────────────────────────────
:50051  gRPC Internal   —         (服务间通讯用，非外部暴露)
:8080   API Gateway     Go        gin + gRPC-gateway + JWT + Redis
:8081   AI Provider     Rust      axum + tokio + reqwest + LiteLLM
:8082   Project         Go        gin + sqlx + PostgreSQL
:8083   Document        Go        gin + sqlx + FTS
:8084   Canon           Rust      axum + qdrant-client + neo4j
:8085   Export          Go        gin + gofpdf + pandoc
:8086   Version History Go        gin + sqlx + LZO
:8087   Settings        Go        gin + go-redis
:8088   Quota           Go        gin + go-redis (Token Bucket)
:8089   Storage         Rust      axum + qdrant-client + lance
:8090   Sync            Go        gin + webdav + fsnotify
:8091   Canvas          Rust      axum + petgraph + serde
:8092   Novel Engine    Rust      axum + tokio + tera (templates)
:8093   Quality Review  Rust      axum + tokio + reqwest
:8094   Timeline        Go        gin + sqlx + PostgreSQL
:8095   Faction         Go        gin + sqlx + PostgreSQL
:8096   Butterfly       Rust      axum + petgraph + tokio
```

## 4. 数据流

### 4.1 写作流程

```
用户输入创意
  │
  ▼
Flutter (gRPC: NovelEngine.GenerateLayer1)
  │
  ▼
API Gateway (Go) → 路由 → Novel Engine (Rust)
  │
  ▼
Novel Engine: Layer1 (梗概) → LLM (via AI Provider)
  │
  ▼
Novel Engine: Layer2 (细纲) → LLM (via AI Provider)
  │
  ▼
Novel Engine: Layer3 (正文流式) → LLM (via AI Provider)
  │
  ▼
Project Service (Go) → PostgreSQL 存储
  │
  ▼
Document Service (Go) → .md 文件写入
  │
  ▼
返回 Flutter → UI 渲染
```

### 4.2 AI 调用流

```
Flutter → gRPC → API Gateway → AI Provider (Rust)
  │
  ▼
AI Provider: 路由到 OpenAI/Claude/DeepSeek/Ollama
  │
  ▼
流式响应 ← AI Provider 解析 + 过滤 (ThinkStreamFilter)
  │
  ▼
Flutter 流式渲染
```

## 5. gRPC 服务定义

### 5.1 核心服务

```protobuf
// Project Service
service ProjectService {
  rpc CreateWorld (CreateWorldRequest) returns (World);
  rpc GetWorld (GetWorldRequest) returns (World);
  rpc ListWorlds (ListWorldsRequest) returns (ListWorldsResponse);
  rpc UpdateWorld (UpdateWorldRequest) returns (World);
  rpc DeleteWorld (DeleteWorldRequest) returns (Empty);
  rpc CreateWork (CreateWorkRequest) returns (Work);
  rpc GetWork (GetWorkRequest) returns (Work);
  rpc ListWorks (ListWorksRequest) returns (ListWorksResponse);
  rpc UpdateWork (UpdateWorkRequest) returns (Work);
  rpc CreateVolume (CreateVolumeRequest) returns (Volume);
  rpc CreateChapter (CreateChapterRequest) returns (Chapter);
  rpc CreateScene (CreateSceneRequest) returns (Scene);
  rpc GetTree (GetTreeRequest) returns (WorldTree);
}

// Document Service
service DocumentService {
  rpc GetDocument (GetDocumentRequest) returns (Document);
  rpc SaveDocument (SaveDocumentRequest) returns (Document);
  rpc GetWordCount (GetWordCountRequest) returns (WordCount);
  rpc SearchDocuments (SearchDocumentsRequest) returns (SearchDocumentsResponse);
}

// AI Provider Service
service AIProviderService {
  rpc GenerateText (GenerateTextRequest) returns (GenerateTextResponse);
  rpc StreamText (StreamTextRequest) returns (stream StreamChunk);
  rpc GenerateStructured (GenerateStructuredRequest) returns (GenerateStructuredResponse);
  rpc Embed (EmbedRequest) returns (EmbedResponse);
}

// Novel Engine Service
service NovelEngineService {
  rpc GenerateLayer1 (GenerateLayer1Request) returns (SynopsisAndCharacters);
  rpc GenerateLayer2 (GenerateLayer2Request) returns (ChapterOutline);
  rpc StreamLayer3 (StreamLayer3Request) returns (stream StreamChunk);
  rpc GenerateChapter (GenerateChapterRequest) returns (stream StreamChunk);
  rpc ContinueWriting (ContinueWritingRequest) returns (stream StreamChunk);
}

// Canon Service
service CanonService {
  rpc CreateCharacter (CreateCharacterRequest) returns (Character);
  rpc GetCharacter (GetCharacterRequest) returns (Character);
  rpc ListCharacters (ListCharactersRequest) returns (ListCharactersResponse);
  rpc CreateLocation (CreateLocationRequest) returns (Location);
  rpc GetRelations (GetRelationsRequest) returns (CharacterGraph);
  rpc SearchCanon (SearchCanonRequest) returns (SearchCanonResponse);
}

// Quality Review Service
service QualityReviewService {
  rpc ReviewChapter (ReviewChapterRequest) returns (ReviewReport);
  rpc CheckCharacterConsistency (CheckCharacterConsistencyRequest) returns (ConsistencyReport);
  rpc AnalyzeHooks (AnalyzeHooksRequest) returns (HookAnalysis);
  rpc FullReview (FullReviewRequest) returns (FullReviewReport);
}

// Settings Service
service SettingsService {
  rpc GetSetting (GetSettingRequest) returns (Setting);
  rpc SetSetting (SetSettingRequest) returns (Setting);
  rpc GetAllSettings (GetAllSettingsRequest) returns (SettingsMap);
  rpc ResetSettings (ResetSettingsRequest) returns (Empty);
}
```

### 5.2 数据模型 (Protobuf)

```protobuf
message World {
  string id = 1;
  string name = 2;
  string description = 3;
  repeated string genres = 4;
  int64 created_at = 5;
  int64 updated_at = 6;
}

message Work {
  string id = 1;
  string world_id = 2;
  string title = 3;
  string description = 4;
  int32 volume_count = 5;
  int64 created_at = 6;
  int64 updated_at = 7;
}

message Volume {
  string id = 1;
  string work_id = 2;
  string title = 3;
  string summary = 4;
  int32 chapter_count = 5;
  int32 order = 6;
}

message Chapter {
  string id = 1;
  string volume_id = 2;
  string title = 3;
  string summary = 4;
  int32 scene_count = 5;
  int32 order = 6;
}

message Scene {
  string id = 1;
  string chapter_id = 2;
  string title = 3;
  string summary = 4;
  string document_id = 5;
  int32 order = 6;
}

message Character {
  string id = 1;
  string world_id = 2;
  string name = 3;
  string description = 4;
  repeated Identity identities = 5;
  CharacterArc arc = 6;
  int32 weight = 7;
}

message Identity {
  string id = 1;
  string character_id = 2;
  string name = 3;
  string period = 4;
  string description = 5;
}

message CharacterEdge {
  string source_id = 1;
  string target_id = 2;
  RelationshipType type = 3;
  int32 strength = 4;
  string description = 5;
}

message TimelineEvent {
  string id = 1;
  string world_id = 2;
  string title = 3;
  string description = 4;
  int64 story_time = 5;
  repeated string involved_character_ids = 6;
}
```

## 6. 目录结构

```
D:/lingbi-repair/
├── ARCHITECTURE.md          # 本文档
├── API_CONTRACTS.md         # 完整 API 契约
├── docker-compose.yml       # 全栈编排
├── protos/                  # gRPC Protobuf 定义
│   ├── common/
│   │   └── common.proto
│   ├── project/
│   │   └── project.proto
│   ├── document/
│   │   └── document.proto
│   ├── ai/
│   │   ├── ai_provider.proto
│   │   └── novel_engine.proto
│   ├── canon/
│   │   └── canon.proto
│   ├── quality/
│   │   └── quality.proto
│   ├── settings/
│   │   └── settings.proto
│   └── export/
│       └── export.proto
├── go/                      # Go 微服务
│   ├── api-gateway/
│   ├── project-service/
│   ├── document-service/
│   ├── settings-service/
│   ├── export-service/
│   ├── quota-service/
│   ├── sync-service/
│   ├── version-history/
│   ├── timeline-service/
│   ├── faction-service/
│   └── pkg/                 # 共享 Go 库
│       ├── auth/
│       ├── middleware/
│       └── models/
├── rust/                    # Rust 微服务
│   ├── ai-provider/
│   ├── novel-engine/
│   ├── quality-review/
│   ├── canon-service/
│   ├── butterfly-analyzer/
│   ├── canvas-service/
│   ├── storage-service/
│   └── crates/              # 共享 Rust crate
│       ├── lingbi-proto/    # 自动生成的 Protobuf 类型
│       └── lingbi-common/   # 共享工具
├── lib/                     # Flutter 前端 (保留)
│   ├── grpc/                # gRPC 客户端 (新)
│   ├── ui/                  # 纯展示层 (重构)
│   └── ...                  # 移除所有业务逻辑
└── test/                    # 集成测试
    ├── integration/
    └── fixtures/
```

## 7. 数据库设计

### PostgreSQL (Go 微服务)

```
worlds
  id UUID PK
  name VARCHAR(255)
  description TEXT
  genres TEXT[]
  created_at TIMESTAMPTZ
  updated_at TIMESTAMPTZ

works
  id UUID PK
  world_id UUID FK → worlds
  title VARCHAR(255)
  description TEXT
  volume_count INT DEFAULT 0
  created_at TIMESTAMPTZ
  updated_at TIMESTAMPTZ

volumes
  id UUID PK
  work_id UUID FK → works
  title VARCHAR(255)
  summary TEXT
  chapter_count INT DEFAULT 0
  sort_order INT

chapters
  id UUID PK
  volume_id UUID FK → volumes
  title VARCHAR(255)
  summary TEXT
  scene_count INT DEFAULT 0
  sort_order INT

scenes
  id UUID PK
  chapter_id UUID FK → chapters
  title VARCHAR(255)
  summary TEXT
  document_id UUID
  sort_order INT

documents
  id UUID PK
  scene_id UUID FK → scenes
  content TEXT
  word_count INT DEFAULT 0
  created_at TIMESTAMPTZ
  updated_at TIMESTAMPTZ

settings
  key VARCHAR(255) PK
  value JSONB
  updated_at TIMESTAMPTZ

quota_records
  id UUID PK
  user_id VARCHAR(255)
  model VARCHAR(255)
  tokens_used INT
  reset_at TIMESTAMPTZ

events (timeline)
  id UUID PK
  world_id UUID FK → worlds
  title VARCHAR(255)
  description TEXT
  story_time BIGINT
  character_ids UUID[]
  created_at TIMESTAMPTZ

factions
  id UUID PK
  world_id UUID FK → worlds
  name VARCHAR(255)
  description TEXT
  member_ids UUID[]
  leader_id UUID
```

### Qdrant (Rust 微服务) — 向量搜索

```
Collection: canon_embeddings
  - 向量维度: 1536 (OpenAI ada-002)
  - payload: { id, type, name, text, world_id }

Collection: document_embeddings
  - 向量维度: 1536
  - payload: { id, scene_id, chunk, chapter_id }
```

## 8. 渐进式迁移路线

```
Phase 1  (当前) 架构设计 + Protobuf + 基础设施
Phase 2  (3天)  Go 核心: API Gateway + Project Service + PostgreSQL
Phase 3  (3天)  Rust 核心: AI Provider + Novel Engine
Phase 4  (2天)  Flutter gRPC 客户端 + 移除旧业务逻辑
Phase 5  (2天)  剩余 Go 服务: Document/Settings/Export/Quota/Sync/Version
Phase 6  (2天)  剩余 Rust 服务: Canon/Quality/Butterfly/Canvas
Phase 7  (2天)  集成测试 + 性能压测 + 发布
```

> 总预估: 14 天
> 当前: Phase 1 开始