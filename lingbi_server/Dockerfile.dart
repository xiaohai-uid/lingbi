# =============================================================================
# 通用 Dart 微服务 Dockerfile（参数化）
#
# 支持两种构建方式（按审计结论区分）：
#   - dart_frog：ai_provider / project / document / canon / export /
#                version / storage / sync  （routes/ + dart_frog 依赖）
#   - shelf    ：quota                       （shelf_router 依赖）
#
# 构建参数（通过 docker-compose build.args 注入）：
#   SERVICE   - 微服务子目录名，如 ai_provider
#   FRAMEWORK - dart_frog（默认）或 shelf
#   ENTRY     - shelf 模式入口文件路径，如 main.dart（dart_frog 模式忽略）
#   PORT      - 监听端口，用于 EXPOSE 与 HEALTHCHECK
#
# 构建上下文为 lingbi_server/ 根目录，微服务位于 microservices/$SERVICE/
# =============================================================================

# ---- Builder 阶段 ----
FROM dart:3.6-sdk AS builder

# dart_frog_cli 仅 dart_frog 项目需要，统一安装（幂等，命中缓存）
RUN dart pub global activate dart_frog_cli ^1.1.0
ENV PATH="$PATH:/root/.pub-cache/bin"

ARG SERVICE
ARG FRAMEWORK=dart_frog
ARG ENTRY=main.dart

WORKDIR /app

# 先复制依赖清单以利用 Docker 层缓存（仅 pubspec.yaml；pubspec.lock 由 pub get 生成）
COPY microservices/$SERVICE/pubspec.yaml ./microservices/$SERVICE/

WORKDIR /app/microservices/$SERVICE
RUN dart pub get

# 复制微服务全部源码
WORKDIR /app
COPY microservices/$SERVICE/ ./microservices/$SERVICE/

WORKDIR /app/microservices/$SERVICE

# 根据框架选择构建方式：
#   dart_frog -> dart_frog build 生成 build/bin/server.dart，再 AOT 编译为单文件二进制
#   shelf     -> 直接 dart compile exe <ENTRY>
RUN if [ "$FRAMEWORK" = "dart_frog" ]; then \
      dart_frog build \
        && cd build && dart pub get \
        && dart compile exe bin/server.dart -o /app/bin/server; \
    else \
      dart compile exe "$ENTRY" -o /app/bin/server; \
    fi

# ---- Runtime 阶段 ----
FROM dart:3.6-slim

# 安装 curl 用于健康检查
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app/bin /app/data && \
    chown -R appuser:appuser /app

WORKDIR /app

USER appuser

# 复制 AOT 编译产物
COPY --from=builder /app/bin/server ./bin/server

ARG PORT=8080
ENV PORT=$PORT

EXPOSE $PORT

# 健康检查（端口由 ARG PORT 注入；shell 形式可展开 $PORT）
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f "http://localhost:${PORT}/health" || exit 1

CMD ["./bin/server"]
