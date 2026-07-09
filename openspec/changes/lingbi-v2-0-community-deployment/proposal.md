# Proposal: 灵笔 v2.0 — 社区系统 + 一键部署 + 微服务完善

## Why

灵笔 v1.0 已完成 11 个微服务的架构设计和 130+ 技术方案调研，9/11 微服务已创建基础骨架。但当前存在以下问题：

- **启动复杂**：需要手动启动 11 个微服务 + 1 个 API Gateway + Flutter 客户端，无法一键运行
- **无 Docker 部署**：虽然有 Dockerfile，但缺少完整的 docker-compose 编排
- **无社区系统**：用户无法获取更新、分享技能、交流使用经验
- **微服务未完全实现**：canvas(Node.js) 和 settings(Node.js) 等微服务骨架不完整
- **无自动更新机制**：用户需要手动 git pull 才能更新

## What Changes

### 1. 微服务完善 (Completion)

- **Canvas Service** (Node.js): 完成故事画布 API——模板加载、节点 CRUD、布局算法
- **Settings Service** (Node.js): 完成设置管理 API——加密存储、配置验证、导入导出
- **AI Provider**: 完善 LiteLLM 集成、流式响应、模型动态注册
- **Document**: 完善文档 CRUD、全文搜索、Markdown 处理
- **Project**: 完善项目 CRUD、导入导出、元数据管理
- **其余微服务**: 完善业务逻辑、错误处理、健康检查

### 2. 一键启动系统 (One-Click Launcher)

- **Windows 一键启动器**: 双击运行，自动启动所有微服务 + API Gateway + Flutter 客户端
- **系统托盘图标**: 托盘菜单控制启动/停止/重启，显示运行状态
- **启动器 GUI**: 简洁的启动界面，显示各服务状态（绿色/红色指示器）
- **自动检测**: 检测端口冲突、环境依赖、自动安装缺失依赖

### 3. Docker 部署

- **完整 docker-compose.yml**: 11 个微服务 + API Gateway + 可选数据库
- **多阶段构建**: 优化镜像大小，Dart 服务使用 Dart 镜像，Node 服务使用 Node 镜像
- **一键部署**: `docker-compose up -d` 启动全部服务
- **环境配置**: 统一的 .env 文件管理所有配置

### 4. 社区系统 (Community)

- **更新检查器**: 启动时自动检测 GitHub 最新版本，提示更新
- **Skill 市场**: 内置 Skill 浏览/安装/管理界面
  - 从社区仓库浏览可用 Skill
  - 一键安装/卸载 Skill
  - Skill 版本管理
- **社区网站**: 基于 GitHub Pages 的社区站点
  - 项目文档
  - Skill 目录
  - 更新日志
  - 使用指南

### 5. 质量保证 (Quality)

- 每个微服务 ≥ 10 个单元测试
- 集成测试覆盖端到端流程
- 代码审查自动触发
- OpenAPI 文档自动生成

## Capabilities

### New Capabilities
- `one-click-launcher`: Windows 一键启动器 + 系统托盘
- `docker-compose-deployment`: 完整 Docker 编排部署
- `community-update-system`: 自动更新检查 + 版本管理
- `skill-marketplace`: Skill 市场浏览/安装/管理
- `community-website`: 基于 GitHub Pages 的社区站点

### Modified Capabilities
- `canvas-service`: 完成故事画布 API
- `settings-service`: 完成安全设置管理
- `ai-provider`: 完善 LiteLLM 集成
- `document-service`: 完善文档 CRUD
- `project-service`: 完善项目管理
- 所有微服务增加健康检查和错误处理

## Impact

### Affected Code
- `lingbi_server/` 下所有微服务需要完善业务逻辑
- `openspec/changes/lingbi-v1-0-microservices-api/` 的调研结论直接使用
- 新增 `launcher/` 目录放一键启动器
- 新增 `community/` 目录放社区网站和 Skill 市场
- 修改 `Dockerfile` 和 `docker-compose.yml`

### Breaking Changes
- 无 Breaking Changes（v1.0 微服务 API 保持不变）
- 新增 API 端点后向下兼容

## Timeline

- **Phase 1**: 一键启动器 + Docker 部署 (3 天)
- **Phase 2**: 微服务完善 (5 天)
- **Phase 3**: 社区系统 (3 天)
- **Phase 4**: 测试 + 验证 (2 天)