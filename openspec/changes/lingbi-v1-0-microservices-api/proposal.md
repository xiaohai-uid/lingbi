# Proposal: 灵笔 v1.0 — 微服务 API 化 + 第三方模型生态

## Why

灵笔当前 v0.4.0 是一个单进程 Flutter Desktop 应用，所有业务逻辑（AI 调用、文档管理、知识图谱、导出）都运行在同一个进程内，耦合严重。这导致：
- 模型扩展困难：每次接入新模型都要改客户端代码
- 无后端化能力：无法做远程 AI 代理、多端同步、Web 版
- 调试困难：所有模块跑在同一个进程，出错难以隔离

**现在** 需要重构为微服务架构，每个核心模块封装成独立 API，同时建立完整的第三方模型生态。

## What Changes

### 架构层
- **从单进程 → 微服务集群**：11 个核心模块各自拆成独立 API 服务
- **客户端 → API Gateway**：Flutter 应用通过统一的 API Gateway 访问所有服务
- **本地存储 → 可选后端**：保留 ZVec 本地存储（离线模式），同时支持远程后端

### 第三方模型生态
- **通用 OpenAI 兼容适配器**：一次配置，支持所有 `/v1/chat/completions` 模型
- **国内大模型 SDK 封装**：通义千问 / 智谱 GLM / 百川 / 月之暗面 / 火山引擎 / 商汤等
- **配置文件驱动**：用户在设置页可添加任意自定义模型，无需改代码

### 四层分解架构
```
大阶段 1: AI 生态服务 ──→ 大阶段 2: 核心业务服务
├── 模型接入层           ├── 项目管理层
├── 配额管理层           ├── 文档管理层
└── 向量索引层           ├── Codex 管理层
                        ├── 导出管理层
                        └── 版本管理层
```

## Capabilities

### New Capabilities
- `microservice-architecture`: 微服务集群架构设计、API Gateway、服务注册发现
- `third-party-model-ecosystem`: 第三方模型接入、OpenAI 兼容适配器、国内大模型封装
- `config-driven-providers`: 配置文件驱动的 Provider 动态注册机制
- `api-gateway`: 统一 API 网关，路由所有客户端请求到对应微服务
- `service-mesh-pattern`: 服务间通信、熔断降级、健康检查

### Modified Capabilities
- `ai-provider-registry`: AI 模型注册与路由机制（现有架构升级）
- `codex-service`: Codex 服务从内嵌式改为独立 API
- `document-service`: 文档服务 API 化
- `project-service`: 项目服务 API 化
- `export-service`: 导出服务 API 化
- `version-history-service`: 版本历史服务 API 化
- `settings-service`: 设置服务 API 化 + 配置加密
- `quota-service`: 配额管理服务 API 化
- `storage-service`: 存储层抽象（本地/远程可选）
- `sync-service`: 文件同步服务 API 化

## Impact

### Affected Code
- `lib/services/` 下所有 Service 需要重写为 API 服务
- `lib/core/ai/` 下的 Provider 架构需要通用化
- `lib/core/di/service_locator.dart` 需要改为 API Gateway 调用
- `lib/ui/` 所有 UI 组件需要从本地调用改为 API 调用

### Affected APIs
- 新增 11 个微服务 API 端点（每个模块独立 HTTP API）
- 新增 API Gateway 统一入口
- 新增模型配置 API

### Affected Dependencies
- 新增 `http` / `dio` 用于 API 调用
- 新增 `shelf` / `dart_frog` / `fiber` 用于构建 API 服务（后端）
- 新增 `encrypt` 用于配置加密存储
- 可能引入 `grpc` 用于服务间通信

### Breaking Changes
- **BREAKING**: API Key 存储方式从 JSON 明文改为加密存储
- **BREAKING**: 所有 Service 接口从同步改为异步 API 调用
- **BREAKING**: `ServiceLocator` 单例模式改为 API 客户端池