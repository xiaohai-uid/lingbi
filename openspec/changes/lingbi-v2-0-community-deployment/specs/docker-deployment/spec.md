## ADDED Requirements

### Requirement: 完整 Docker Compose 编排
The system SHALL provide a complete docker-compose.yml that orchestrates all 12 services (API Gateway + 11 microservices).

#### Scenario: 用户执行 docker-compose up -d
- **WHEN** 用户在项目根目录执行 `docker-compose up -d`
- **THEN** 12 个服务容器依次启动
- **AND** 所有服务在 `lingbi_network` 内网互通
- **AND** API Gateway (:8080) 是唯一对外暴露端口

#### Scenario: 各服务正常启动
- **WHEN** 用户执行 `docker-compose ps`
- **THEN** 所有 12 个服务状态为 "Up"
- **AND** 每个服务健康检查通过

### Requirement: 多阶段 Dockerfile
The system SHALL use multi-stage Docker builds to minimize final image size.

#### Scenario: Dart 服务构建
- **WHEN** 执行 Docker 构建 Dart 微服务
- **THEN** 第一阶段编译 Dart 代码为 AOT 二进制
- **AND** 第二阶段仅复制二进制到 slim 镜像
- **AND** 最终镜像包含健康检查指令

### Requirement: 环境变量配置
The system SHALL support environment variable configuration through a .env file.

#### Scenario: 用户配置环境变量
- **WHEN** 用户编辑 `.env` 文件
- **THEN** 可配置端口映射、API Keys、数据目录
- **AND** 配置生效无需修改 docker-compose.yml

### Requirement: 数据持久化
The system SHALL persist all user data across container restarts using Docker volumes.

#### Scenario: Docker 数据卷挂载
- **WHEN** 用户停止并重启容器
- **THEN** 所有数据持久化保留
- **AND** 数据卷 `lingbi_data` 存储在宿主机

### Requirement: 健康检查
The system SHALL implement Docker health checks for each service container.

#### Scenario: Docker 健康检查
- **WHEN** 每个服务启动后
- **THEN** Docker 自动执行 `/health` 端点健康检查
- **AND** 不健康的服务自动重启