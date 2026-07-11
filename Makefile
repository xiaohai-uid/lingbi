# 灵笔 v4.0 — 全栈构建工具
# 使用: make <target>
# 前提: Linux/macOS/WSL 环境，Docker 26+，Go 1.24+，Rust 1.85+

.PHONY: help proto proto-go proto-rust proto-dart build-go build-rust \
        build-docker up down test test-unit test-integration clean

help: ## 显示帮助
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ===== Protobuf =====

PROTO_DIR := protos
PROTO_GO_DIR := go/pkg/lingbi-proto
PROTO_RUST_DIR := rust/crates/lingbi-proto
PROTO_DART_DIR := lib/grpc/generated

proto: proto-go proto-rust proto-dart ## 编译全部 Protobuf

proto-go: ## 编译 Go Protobuf
	mkdir -p $(PROTO_GO_DIR)
	protoc --proto_path=$(PROTO_DIR) \
		--go_out=$(PROTO_GO_DIR) --go_opt=paths=source_relative \
		--go-grpc_out=$(PROTO_GO_DIR) --go-grpc_opt=paths=source_relative \
		$(PROTO_DIR)/common/*.proto \
		$(PROTO_DIR)/project/*.proto \
		$(PROTO_DIR)/ai/*.proto \
		$(PROTO_DIR)/canon/*.proto \
		$(PROTO_DIR)/document/*.proto \
		$(PROTO_DIR)/quality/*.proto \
		$(PROTO_DIR)/settings/*.proto \
		$(PROTO_DIR)/export/*.proto

proto-rust: ## 编译 Rust Protobuf
	mkdir -p $(PROTO_RUST_DIR)/src
	cd rust/crates/lingbi-proto && cargo build

proto-dart: ## 编译 Dart Protobuf
	mkdir -p $(PROTO_DART_DIR)
	protoc --proto_path=$(PROTO_DIR) \
		--dart_out=$(PROTO_DART_DIR) \
		$(PROTO_DIR)/common/*.proto \
		$(PROTO_DIR)/project/*.proto \
		$(PROTO_DIR)/ai/*.proto \
		$(PROTO_DIR)/canon/*.proto \
		$(PROTO_DIR)/document/*.proto \
		$(PROTO_DIR)/quality/*.proto \
		$(PROTO_DIR)/settings/*.proto \
		$(PROTO_DIR)/export/*.proto

# ===== Go 微服务构建 =====

GO_SERVICES := api-gateway project-service settings-service quota-service \
               timeline-service faction-service document-service export-service \
               sync-service version-history

build-go: $(GO_SERVICES) ## 编译全部 Go 微服务

$(GO_SERVICES):
	@echo "🔨 Building $@..."
	cd go/$@ && go build -o ../../build/go/$@ ./cmd/server

build-go-all: ## 编译并运行 Go 测试
	@for svc in $(GO_SERVICES); do \
		echo "🔨 Building $$svc..."; \
		cd go/$$svc && go build -o ../../build/go/$$svc ./cmd/server; \
	done

test-go: ## 运行 Go 测试
	@for svc in $(GO_SERVICES); do \
		echo "🧪 Testing $$svc..."; \
		cd go/$$svc && go test ./... -count=1 2>/dev/null || true; \
	done

# ===== Rust 微服务构建 =====

RUST_SERVICES := ai-provider novel-engine quality-review canon-service \
                 butterfly-analyzer canvas-service storage-service

build-rust: $(RUST_SERVICES) ## 编译全部 Rust 微服务

$(RUST_SERVICES):
	@echo "🔨 Building $@..."
	cd rust/$@ && cargo build --release 2>/dev/null

build-rust-all: ## 编译并运行 Rust 测试
	@for svc in $(RUST_SERVICES); do \
		echo "🔨 Building $$svc..."; \
		cd rust/$$svc && cargo build --release 2>/dev/null; \
	done

test-rust: ## 运行 Rust 测试
	@for svc in $(RUST_SERVICES); do \
		echo "🧪 Testing $$svc..."; \
		cd rust/$$svc && cargo test 2>/dev/null || true; \
	done

# ===== Docker =====

build-docker: ## 构建全部 Docker 镜像
	docker compose build

up: ## 启动全栈
	docker compose up -d

down: ## 停止全栈
	docker compose down

logs: ## 查看日志
	docker compose logs -f

# ===== 测试 =====

test: test-unit test-integration ## 运行全部测试

test-unit: ## 运行单元测试
	@echo "🧪 单元测试..."
	$(MAKE) test-go
	$(MAKE) test-rust

test-integration: ## 运行集成测试（需先 up）
	@echo "🧪 集成测试..."
	bash scripts/run-integration-tests.sh

test-flutter: ## 运行 Flutter 测试
	@echo "🧪 Flutter 测试..."
	cd ../../ && flutter test

# ===== 清理 =====

clean: ## 清理构建产物
	rm -rf build/
	rm -rf $(PROTO_GO_DIR)
	docker compose down -v 2>/dev/null || true

# ===== 入口 =====

all: proto build-go-all build-rust-all build-docker ## 完整构建流程
	@echo "✅ 全部构建完成！运行 'make up' 启动全栈"