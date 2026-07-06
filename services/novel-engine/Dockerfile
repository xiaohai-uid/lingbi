# Novel Engine 微服务 Dockerfile — 多阶段构建
FROM dart:3.6-sdk AS builder

WORKDIR /app

# 复制依赖文件
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# 复制源码
COPY . .

# 编译为可执行文件
RUN dart compile exe main.dart -o bin/server

# 运行阶段
FROM dart:3.6-slim

WORKDIR /app

# 安装 curl 用于健康检查
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# 复制构建产物
COPY --from=builder /app/bin/server ./bin/server
COPY --from=builder /app/pubspec.yaml ./

# 暴露端口
EXPOSE 4001

# 健康检查
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:4001/health || exit 1

# 启动服务
CMD ["./bin/server"]
