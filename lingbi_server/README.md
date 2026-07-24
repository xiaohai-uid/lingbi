# lingbi_server

> 灵笔微服务后端 — API Gateway + 11 微服务

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

## 架构

API Gateway (`:8080`) 统一接收请求并代理到各微服务：

| 路由前缀 | 微服务 | 端口 | 运行时 |
|----------|--------|------|--------|
| `/api/v1/ai` | AI Provider | 8081 | Dart |
| `/api/v1/project` | Project | 8082 | Dart |
| `/api/v1/document` | Document | 8083 | Dart |
| `/api/v1/canon` | Canon | 8084 | Dart |
| `/api/v1/export` | Export | 8085 | Dart |
| `/api/v1/version` | Version | 8086 | Dart |
| `/api/v1/settings` | Settings | 8087 | Node.js |
| `/api/v1/quota` | Quota | 8088 | Dart |
| `/api/v1/storage` | Storage | 8089 | Dart |
| `/api/v1/sync` | Sync | 8090 | Dart |
| `/api/v1/canvas` | Canvas | 8091 | Node.js |

## 快速开始

```bash
# 安装依赖
dart pub get

# 启动 API Gateway
dart run bin/server.dart --port 8080

# 启动单个微服务
cd microservices/<name>
dart pub get
dart run bin/server.dart --port <PORT>
```

## Docker 部署

详见根目录 [DEPLOY.md](../DEPLOY.md)。

```bash
docker-compose up -d
docker-compose ps   # 确认全部 healthy
```

## 测试

```bash
# 集成测试
dart test

# 微服务独立测试
cd microservices/<name> && dart test
```

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT