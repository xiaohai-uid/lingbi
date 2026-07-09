## ADDED Requirements

### Requirement: 单元测试覆盖
The system SHALL have comprehensive unit test coverage for all microservices with at least 10 test cases per service.

#### Scenario: 每个微服务 ≥10 个测试
- **WHEN** 运行该服务的测试套件
- **THEN** 至少包含 10 个独立的测试用例
- **AND** 覆盖正常流程、边界条件、错误处理

#### Scenario: 测试全部通过
- **WHEN** 执行所有服务的测试
- **THEN** 所有测试通过（0 失败、0 跳过）

### Requirement: 代码静态分析
The codebase SHALL pass static analysis with zero errors.

#### Scenario: flutter analyze 通过
- **WHEN** 执行 `flutter analyze`
- **THEN** lib/ 目录 0 编译错误
- **AND** 0 警告

### Requirement: Docker 构建验证
All Docker images SHALL build successfully and pass health checks.

#### Scenario: Docker 镜像构建
- **WHEN** 执行 `docker-compose build`
- **THEN** 所有服务镜像构建成功
- **AND** 所有健康检查通过

### Requirement: 一键启动验证
The one-click launcher SHALL start all services within 30 seconds on Windows 10/11.

#### Scenario: Windows 一键启动
- **WHEN** 双击启动器
- **THEN** 所有服务在 30 秒内启动完成
- **AND** Flutter 客户端自动打开
- **AND** 功能正常可用