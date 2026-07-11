# 灵笔 v4.0 — Flutter 前端重构指南

## 目标

将 Flutter 从"含业务逻辑的全栈应用"重构为"纯展示层 + gRPC 客户端"

## 删除

以下目录/文件可全部删除，业务逻辑已迁移到 Go/Rust 微服务：

```
lib/services/           # 全部删除 — 业务逻辑已迁移到微服务
  ai_service.dart
  butterfly_analyzer.dart
  canon_service.dart
  character_graph_service.dart
  codex_linking_service.dart
  codex_service.dart
  context/              # 上下文注入 → 由后端管理
  document_service.dart
  export_service.dart
  faction_service.dart
  identity/             # 身份检测 → 后端 AI 分析
  interfaces/           # 接口定义 → Protobuf 生成
  novel/                # 三层生成 → Rust Novel Engine
  project_service.dart
  prompt_service.dart
  quality/              # 质量审查 → Rust Quality Review
  quota_service.dart
  settings_service.dart
  storage_service.dart
  timeline_service.dart
  version_history_service.dart
  world_service.dart

lib/core/database/      # 删除 — 数据持久化移到 PostgreSQL
  zvec_service.dart
  collections.dart
  story_beats_repository.dart

lib/core/di/            # 删除 — ServiceLocator 不再需要
  service_locator.dart

lib/core/file_system/   # 删除 — 文件操作移到 Document Service
  file_service.dart
  sync_service.dart

lib/data/               # 删除 — 数据层移到微服务
  database/
  migration/
  repositories/
```

## 保留

```
lib/                    # 纯 UI 展示层
  main.dart             # 入口，初始化 gRPC 客户端
  core/
    ai/                 # 保留 LLM 类型定义
    errors/             # 保留错误类型（AppError 等）
    lifecycle/          # 保留生命周期管理
    models/             # 保留数据模型（但数据来源改为 gRPC）
  ui/                   # 保留全部 UI 组件
    layout/
    pages/
    theme/
    components/
    widgets/
  utils/                # 保留工具函数
```

## 新增

```
lib/grpc/               # gRPC 客户端层（新增）
  generated/            # protoc 生成的 Dart 代码
  client.dart           # gRPC 客户端工厂
  project_client.dart   # ProjectService 客户端封装
  document_client.dart  # DocumentService 客户端封装
  ai_client.dart        # AIProviderService 客户端封装
  canon_client.dart     # CanonService 客户端封装
  settings_client.dart  # SettingsService 客户端封装
```

## 依赖变更

```yaml
# pubspec.yaml — 删除
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0
  drift_dev: ^2.20.0
  build_runner: ^2.4.0
  path_provider: ^2.1.0  # 文件操作移到后端
  file_picker: ^8.0.0    # 文件操作移到后端

# pubspec.yaml — 新增
  grpc: ^4.0.0
  protobuf: ^3.0.0
  fixnum: ^2.0.0
```

## 状态管理迁移

| 当前 | 迁移后 |
|------|--------|
| `ServiceLocator.instance.worldService.getWorks()` | `ProjectClient().listWorks(worldId)` |
| `ServiceLocator.instance.aiService.chat()` | `AIClient().streamText(request)` |
| `ServiceLocator.instance.documentService.save()` | `DocumentClient().saveDocument(request)` |
| `ServiceLocator.instance.settingsService.get()` | `SettingsClient().getSetting(key)` |

## 数据流变化

```
当前:  Widget → Service → ServiceLocator → Drift/ZVec
v4.0:  Widget → State → gRPC Client → API Gateway → 微服务 → PostgreSQL/Qdrant
```