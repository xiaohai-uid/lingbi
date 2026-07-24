# 灵笔部署指南 (Deployment Guide)

## 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | 3.38+ | 客户端构建 |
| Dart SDK | 3.7+ | 微服务构建 (随 Flutter 附带) |
| Docker | 24+ | 容器运行 |
| Docker Compose | v2+ | 服务编排 |
| Node.js | 18+ | Canvas / Settings 微服务 |

---

## 一、本地开发模式

### 1. 克隆与安装

```bash
git clone https://github.com/YOUR_USERNAME/lingbi.git
cd lingbi

# 客户端依赖
flutter pub get

# 服务端依赖
cd lingbi_server && dart pub get && cd ..

# 复制环境变量
cp .env.example .env
# 编辑 .env 填入 AI API Keys
```

### 2. 启动微服务

```bash
# 方式 A：使用启动器 (推荐)
cd launcher
flutter pub get
flutter run -d windows

# 方式 B：手动逐个启动
cd lingbi_server
dart run bin/server.dart --port 8080   # API Gateway

# 各微服务 (每个终端一个)
cd lingbi_server/microservices/canon    && dart run bin/server.dart --port 8084
cd lingbi_server/microservices/settings && npm start  # :8087
cd lingbi_server/microservices/canvas   && npm start  # :8091
# ... 其余微服务类似
```

### 3. 启动客户端

```bash
flutter run -d windows
```

---

## 二、Docker Compose 一键部署

### 1. 准备环境变量

```bash
cp .env.example .env
# 编辑 .env，至少填入：
# - LITELLM_MASTER_KEY
# - SENSENOVA_API_KEY / DEEPSEEK_API_KEY / OPENAI_API_KEY (按需)
```

### 2. 构建并启动

```bash
# 构建全部镜像
docker-compose build

# 后台启动全部服务
docker-compose up -d
```

### 3. 查看状态

```bash
docker-compose ps
```

期望输出：所有 15 个服务显示 `Up` + `healthy`。

```
NAME              STATUS
api-gateway       Up (healthy)
ai-provider       Up (healthy)
project           Up (healthy)
document          Up (healthy)
canon             Up (healthy)
export            Up (healthy)
version           Up (healthy)
settings          Up (healthy)
quota             Up (healthy)
storage           Up (healthy)
sync              Up (healthy)
canvas            Up (healthy)
novel-engine      Up (healthy)
quality-review    Up (healthy)
litellm           Up (healthy)
```

### 4. 验证健康检查

```bash
# API Gateway
curl http://localhost:8080/health

# 各微服务
curl http://localhost:8081/health  # AI Provider
curl http://localhost:8084/health  # Canon
curl http://localhost:8087/health  # Settings
curl http://localhost:8091/health  # Canvas
```

每个 `/health` 端点返回：

```json
{"status": "ok", "service": "<服务名>"}
```

### 5. 停止服务

```bash
docker-compose down           # 停止并移除容器
docker-compose down -v        # 同时移除数据卷 (⚠️ 会清除数据)
```

---

## 三、服务端口总览

| 服务 | 端口 | 运行时 | 路由前缀 |
|------|------|--------|---------|
| API Gateway | 8080 | Dart Frog | `/api/v1/*` |
| AI Provider | 8081 | Dart Frog | `/api/v1/ai` |
| Project | 8082 | Dart Frog | `/api/v1/project` |
| Document | 8083 | Dart Frog | `/api/v1/document` |
| Canon | 8084 | Dart Frog | `/api/v1/canon` |
| Export | 8085 | Dart Frog | `/api/v1/export` |
| Version | 8086 | Dart Frog | `/api/v1/version` |
| Settings | 8087 | Node.js | `/api/v1/settings` |
| Quota | 8088 | Dart Frog | `/api/v1/quota` |
| Storage | 8089 | Dart Frog | `/api/v1/storage` |
| Sync | 8090 | Dart Frog | `/api/v1/sync` |
| Canvas | 8091 | Node.js | `/api/v1/canvas` |
| Novel Engine | 8092 | — | — |
| Quality Review | 8093 | — | — |
| LiteLLM | 4000 | Python | — |

---

## 四、常见问题排查

### 服务启动失败

```bash
# 查看服务日志
docker-compose logs <service-name>

# 检查端口占用
netstat -ano | findstr :8080
```

### 健康检查一直 unhealthy

1. 确认容器内 curl 已安装
2. 检查服务日志：`docker-compose logs <service>`
3. 确认端口未被其他进程占用

### Node.js 微服务 (Settings/Canvas) 构建失败

```bash
# 进入目录安装依赖
cd lingbi_server/microservices/settings && npm install
cd lingbi_server/microservices/canvas && npm install
```

### LiteLLM 连接失败

- 检查 `LITELLM_MASTER_KEY` 是否设置
- 确认 `litellm_config.yaml` 存在且配置正确
- 查看日志：`docker-compose logs litellm`

---

## 五、生产部署建议

- 修改 `LITELLM_MASTER_KEY` 为强随机字符串
- 使用反向代理 (Nginx/Caddy) 暴露 API Gateway :8080
- 配置 HTTPS 证书
- 定期备份 `lingbi_data` 数据卷
- 设置日志轮转防止磁盘溢出
