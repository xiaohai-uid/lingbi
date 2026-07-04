# Lingbi v1.0 微服务架构 — 设计文档

## 一、总体架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter Client (灵笔)                          │
│                             (UI Layer)                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │  编辑器   │ │ 项目管理  │ │ Codex    │ │ AI 面板  │ │ 设置面板  │ │
│  └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘ │
└────────┼────────────┼────────────┼────────────┼────────────┼──────┘
         │            │            │            │            │
         └────────────┼────────────┼────────────┼────────────┘
                      │            │            │
         ┌────────────┴────────────┴────────────┐
         │       API Gateway (本地 HTTP)         │
         │   localhost:8080/                    │
         │   路由分发 + 认证 + 限流              │
         └────────────┬────────────┬────────────┘
                      │            │
         ┌────────────┴────────────┴────────────┐
         │         Microservices Cluster         │
         │   (本地多进程 / 可选远程部署)          │
         ├──────────────────────────────────────┤
         │ /ai          : AI 模型接入 + 路由    │
         │ /project     : 项目 CRUD + 元数据    │
         │ /document    : 文档 CRUD + 同步      │
         │ /codex       : Codex CRUD + 语义搜索 │
         │ /export      : 多格式导出            │
         │ /version     : 版本历史              │
         │ /settings    : 用户配置              │
         │ /quota       : 配额管理              │
         │ /storage     : 存储抽象层            │
         │ /sync        : 文件同步              │
         │ /canvas      : 故事画布              │
         └──────────────────────────────────────┘
```

## 二、四层分解架构

### 大阶段 1: AI 生态服务 (Phase 1)
```
├── 模型接入层 (Provider Layer)
│   ├── 内置 Provider 改造 (Free/DeepSeek/OpenAI/Claude)
│   ├── 通用 OpenAI 兼容适配器 (Ollama/vLLM/LM Studio/本地)
│   ├── 国内大模型 SDK 封装 (通义/智谱/百川/月暗面/火山/商汤)
│   ├── 配置文件驱动注册机制
│   └── Provider 工厂模式
│
├── 配额管理层 (Quota Layer)
│   ├── 配额规则引擎
│   ├── 使用量统计
│   ├── 限流策略
│   └── 配额重置逻辑
│
└── 向量索引层 (Vector Layer)
    ├── Embedding 抽象层
    ├── 多模型 Embedding 支持
    ├── 向量索引管理
    └── 语义搜索 API
```

### 大阶段 2: 核心业务服务 (Phase 2)
```
├── 项目管理层
│   ├── 项目 CRUD API
│   ├── 项目导入导出 API
│   └── 项目元数据 API
│
├── 文档管理层
│   ├── 文档 CRUD API
│   ├── Markdown 处理 API
│   ├── 文件同步 API
│   └── 文档搜索 API
│
├── Codex 管理层
│   ├── Codex CRUD API
│   ├── 关系图谱 API
│   ├── 语义搜索 API
│   └── Codex 关联检测 API
│
├── 导出管理层
│   ├── Markdown 导出 API
│   ├── PDF 导出 API
│   ├── EPUB 导出 API
│   └── DOCX 导出 API
│
└── 版本管理层
    ├── 版本快照 API
    ├── 版本差异 API
    ├── 版本恢复 API
    └── 版本清理 API
```

## 三、微服务 API 设计

### 3.1 AI 服务 API

```http
# 获取可用模型列表
GET /ai/models

# 添加自定义模型
POST /ai/models
{
  "id": "ollama-local",
  "name": "Ollama 本地模型",
  "type": "openai_compatible",
  "baseUrl": "http://localhost:11434/v1",
  "apiKey": "",
  "model": "qwen2.5:7b",
  "enabled": true
}

# 删除模型
DELETE /ai/models/{id}

# 设置当前活跃模型
PUT /ai/active/{id}

# 聊天（流式）
POST /ai/chat
{
  "message": "用户消息",
  "context": "项目上下文",
  "temperature": 0.7,
  "maxTokens": 2048
}
# 返回 Server-Sent Events 流

# 风格分析
POST /ai/style/analyze
{ "text": "待分析文本" }

# 小说拆解
POST /ai/novel/analyze
{ "text": "小说文本" }

# 智能续写
POST /ai/continue
{ "text": "前文内容" }

# Embedding
POST /ai/embedding
{ "text": "待向量化文本" }
```

### 3.2 模型配置格式

```json
{
  "id": "model-uuid",
  "name": "模型名称",
  "type": "openai_compatible|deepseek|claude|openai|free|qwen|zhipu|baidu|baichuan|yi|volcengine|sensetime",
  "baseUrl": "API Base URL（仅 openai_compatible 需要）",
  "apiKey": "API Key（可选）",
  "model": "模型名称",
  "description": "描述",
  "enabled": true,
  "config": {
    "temperature": 0.7,
    "maxTokens": 2048,
    "topP": 1.0,
    "frequencyPenalty": 0.0,
    "presencePenalty": 0.0
  }
}
```

### 3.3 API Gateway 路由

```
/api/v1/
├── /ai/...        → :8081 (AI 服务)
├── /project/...   → :8082 (项目服务)
├── /document/...  → :8083 (文档服务)
├── /codex/...     → :8084 (Codex 服务)
├── /export/...    → :8085 (导出服务)
├── /version/...   → :8086 (版本服务)
├── /settings/...  → :8087 (设置服务)
├── /quota/...     → :8088 (配额服务)
├── /storage/...   → :8089 (存储服务)
├── /sync/...      → :8090 (同步服务)
├── /canvas/...    → :8091 (画布服务)
```

### 3.4 服务间通信

```
AI 服务 ←→ 配额服务 (调用前检查)
AI 服务 ←→ 向量索引 (生成 embedding)
Codex 服务 ←→ AI 服务 (语义搜索)
文档服务 ←→ 同步服务 (文件同步)
文档服务 ←→ 版本服务 (自动快照)
```

## 四、技术选型

| 层次 | 技术 | 说明 |
|------|------|------|
| **API 框架** | `dart_frog` / `fiber` | Dart 原生，与 Flutter 共享代码 |
| **客户端** | `dio` | HTTP 客户端，支持拦截器/超时/重试 |
| **数据库** | `sqflite` + `sqlite3` | 本地 SQLite，支持向量索引 |
| **加密存储** | `pointycastle` + `encrypt` | API Key 加密存储 |
| **服务注册** | 本地注册表 + 健康检查 | 简单场景，无需 etcd/consul |
| **限流** | Token Bucket | 内置配额系统 |
| **日志** | `logger` + 结构化 JSON | 便于排查问题 |

## 五、数据流

```
用户输入
  ↓
Flutter Client (UI)
  ↓
API Gateway (:8080)
  ↓ 路由分发
对应微服务 (:8081~8091)
  ↓
Service 层处理
  ↓
Repository 层 (ZVec / SQLite / 文件)
  ↓
响应 → API Gateway → Flutter Client
```

## 六、关键决策

### 6.1 为什么选择 Dart 后端而不是 Python/Node

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Dart (dart_frog)** | 共享类型定义、零心智负担、启动快 | 生态较小 |
| Python (FastAPI) | 生态丰富、AI 库支持好 | 需独立进程、类型不共享 |
| Node.js | 生态成熟、API 框架多 | 需独立进程、类型不共享 |

**决策**：选择 Dart，理由：与 Flutter 共享模型定义，减少跨进程数据序列化成本。

### 6.2 微服务部署策略

| 场景 | 方案 |
|------|------|
| **个人用户** | 所有服务跑在 `localhost` 不同端口，API Gateway 统一管理 |
| **团队协作** | 远程部署后端，客户端只保留 UI |
| **企业私有** | 完全本地部署，数据库可选远程 |

### 6.3 存储方案

| 需求 | 方案 |
|------|------|
| **本地优先** | SQLite + ZVec，数据在用户机器 |
| **可选同步** | 通过 Sync 服务，支持 WebDAV / S3 / 自建后端 |
| **离线可用** | 所有 Service 降级到本地 SQLite |