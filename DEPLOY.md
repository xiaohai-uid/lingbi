# 灵笔 v4.0 — 部署指南

> 更新时间: 2026-07-09
> 网络状态: ⚠️ 离线（需联网下载依赖后部署）

---

## 前置条件

- Docker 26+（已安装 v29.5.3 ✅）
- Go 1.24+（已安装 v1.25.0 ✅）
- Rust 1.85+（已安装 v1.96.0 ✅）
- protoc（已安装 v35.1 ✅）
- protoc-gen-go + protoc-gen-go-grpc（❌ 需 `go install`）
- Dart protoc plugin（❌ 需 `pub global activate protoc_plugin`）

## 一键部署（网络恢复后）

```bash
# 1. 安装 Protobuf 编译器插件
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
dart pub global activate protoc_plugin

# 2. 编译 Protobuf
make proto

# 3. 编译 Go 微服务（测试依赖）
cd go/api-gateway && go mod tidy && go build ./cmd/server
cd go/project-service && go mod tidy && go build ./cmd/server
cd go/settings-service && go mod tidy && go build ./cmd/server
cd go/quota-service && go mod tidy && go build ./cmd/server
cd go/document-service && go mod tidy && go build ./cmd/server
cd go/export-service && go mod tidy && go build ./cmd/server
cd go/sync-service && go mod tidy && go build ./cmd/server
cd go/version-history && go mod tidy && go build ./cmd/server
cd go/timeline-service && go mod tidy && go build ./cmd/server
cd go/faction-service && go mod tidy && go build ./cmd/server

# 4. 编译 Rust 微服务
cd rust/ai-provider && cargo build
cd rust/novel-engine && cargo build
cd rust/quality-review && cargo build
cd rust/canon-service && cargo build
cd rust/butterfly-analyzer && cargo build
cd rust/canvas-service && cargo build
cd rust/storage-service && cargo build

# 5. Docker 全栈构建
make build-docker
make up

# 6. 运行集成测试
make test-integration

# 7. Flutter 前端
bash scripts/migrate-flutter.sh
cd lingbi  # 主 Flutter 项目
make proto-dart
flutter pub get
flutter test
flutter build windows --release
```

## 快速启动（已有镜像）

```bash
# 如果 Docker 镜像已构建
docker compose up -d
bash scripts/run-integration-tests.sh
```

## 服务端⼝一览

```
:8080  API Gateway       :8081  AI Provider
:8082  Project Service   :8083  Document Service
:8084  Canon Service     :8085  Export Service
:8086  Version History   :8087  Settings Service
:8088  Quota Service     :8089  Storage Service
:8090  Sync Service      :8091  Canvas Service
:8092  Novel Engine      :8093  Quality Review
:8094  Timeline Service  :8095  Faction Service
:8096  Butterfly Analyzer
:4000  LiteLLM
:5432  PostgreSQL
:6379  Redis
:6333  Qdrant
```

## 集成测试

```bash
# Docker 部署后运行
bash scripts/run-integration-tests.sh
# 预期: 35-40 个测试全部通过（绿色 ✅）

# Flutter 集成测试
flutter test test/integration_test/full_stack_test.dart
```

## 常见问题

### Q: `go mod tidy` 失败
A: 需要网络连接。检查 `https://proxy.golang.org` 是否可达。

### Q: `cargo build` 失败
A: 需要 crates.io 网络。确保 `~/.cargo/config.toml` 中镜像配置正确。

### Q: Docker 构建失败
A: 检查 Docker Desktop 是否运行。首次构建需拉取基础镜像：
- Go: `golang:1.24-alpine`
- Rust: `rust:1.85-slim-bookworm`
- 第三方: `postgres:16-alpine`, `redis:7-alpine`, `qdrant/qdrant:v1.12`

### Q: Flutter gRPC 代码未生成
A: 运行 `make proto-dart` 后，在 `lib/grpc/generated/` 目录下应有 `.pb.dart` 和 `.pbserver.dart` 文件。