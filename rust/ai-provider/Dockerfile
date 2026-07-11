# Rust 微服务通用多阶段构建 Dockerfile
# 使用方式: docker build -f Dockerfile -t lingbi/<service-name> .

# ---- 构建阶段 ----
FROM rust:1.85-slim-bookworm AS builder

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN cargo install cargo-chef --locked

WORKDIR /app

# 缓存依赖
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
RUN cargo chef prepare 2>/dev/null || true
COPY . .
RUN cargo build --release --bin $(basename $(pwd))

# ---- 运行阶段 ----
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/$(basename $(pwd)) /app/server

EXPOSE ${PORT:-8080}

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

CMD ["./server"]