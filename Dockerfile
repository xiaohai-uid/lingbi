FROM cirrusci/flutter:3.38.0 AS builder

LABEL description="Lingbi - AI Novel Writing Desktop App Development Environment"
LABEL maintainer="Lingbi Team"

WORKDIR /app

# 先复制 pubspec 以利用 Docker 缓存
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 复制源码
COPY . .

# 代码检查
RUN flutter analyze lib/

# 运行测试
RUN flutter test

# 构建阶段
FROM builder AS release
RUN flutter build windows --release

# 开发阶段 - 默认容器保留为开发环境
FROM builder AS dev
CMD ["flutter", "test"]