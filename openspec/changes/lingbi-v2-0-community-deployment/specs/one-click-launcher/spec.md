## ADDED Requirements

### Requirement: Windows 一键启动器
The system SHALL provide a Windows one-click launcher that can start all microservices and the Flutter client with a single double-click.

#### Scenario: 用户双击启动器图标
- **WHEN** 用户双击 lingbi-launcher.exe
- **THEN** 启动器 GUI 显示服务状态面板
- **AND** 环境自动检测运行（Dart/Node/端口可用性）
- **AND** 缺失依赖自动安装

#### Scenario: 用户点击"启动全部"
- **WHEN** 用户点击"启动全部"按钮
- **THEN** 启动器按顺序启动所有微服务
- **AND** 每个服务健康检查通过后标记为 🟢
- **AND** 所有服务就绪后自动启动 Flutter 客户端

#### Scenario: 用户最小化到托盘
- **WHEN** 用户关闭启动器窗口
- **THEN** 启动器最小化到系统托盘
- **AND** 托盘图标显示运行状态

### Requirement: 系统托盘管理
The system SHALL manage a system tray icon for the launcher providing quick access to common operations.

#### Scenario: 右键菜单操作
- **WHEN** 用户右键点击托盘图标
- **THEN** 显示菜单：显示/隐藏、启动/停止、退出
- **AND** 点击"退出"时确认是否同时停止所有服务

#### Scenario: 服务异常通知
- **WHEN** 某个微服务意外退出
- **THEN** 托盘图标闪烁提示
- **AND** 状态面板显示该服务为错误状态

### Requirement: 日志查看器
The system SHALL provide a real-time log viewer for each running microservice.

#### Scenario: 用户查看服务日志
- **WHEN** 用户在状态面板点击某服务的"日志"按钮
- **THEN** 打开日志查看器
- **AND** 实时显示该服务的 stdout/stderr
- **AND** 支持日志搜索和过滤

### Requirement: 启动模式切换
The system SHALL support switching between local process mode and Docker mode.

#### Scenario: 用户切换启动模式
- **WHEN** 用户选择"Docker 模式"
- **THEN** 启动器使用 docker-compose 启动所有服务
- **AND** 状态面板通过 Docker API 检查服务状态

### Requirement: 开机自启
The system SHALL support registering the launcher as a Windows startup item.

#### Scenario: 用户启用开机自启
- **WHEN** 用户开启"开机自动启动"
- **THEN** 启动器注册为 Windows 开机启动项
- **AND** 下次开机时自动启动并恢复上次状态