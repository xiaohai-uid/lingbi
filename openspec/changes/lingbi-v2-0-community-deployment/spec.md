# 灵笔 v2.0 — 社区系统 + 一键部署 + 微服务完善

## 概述

本文档定义灵笔 v2.0 的完整规格，涵盖微服务完善、一键启动系统、Docker 部署和社区系统四大模块。基于 v1.0 的 130+ 调研结论，将 11 个微服务从骨架完善为生产级服务。

---

## 1. 微服务完善 (Microservice Completion)

### 1.1 Canvas Service

**状态**: 骨架 (Node.js)
**完善内容**:

| API 端点 | 方法 | 说明 |
|----------|------|------|
| `/canvas/templates` | GET | 获取画布模板列表 (mind-map, story-flow) |
| `/canvas/templates/:id` | GET | 获取指定模板详情 |
| `/canvas/nodes` | POST | 创建节点 |
| `/canvas/nodes/:id` | PUT/DELETE | 更新/删除节点 |
| `/canvas/edges` | POST | 创建连线 |
| `/canvas/edges/:id` | PUT/DELETE | 更新/删除连线 |
| `/canvas/layout` | POST | 应用布局算法 (force-directed/tree/radial) |
| `/canvas/export` | POST | 导出画布为图片/JSON |
| `/canvas/health` | GET | 健康检查 |

### 1.2 Settings Service

**状态**: 骨架 (Node.js)
**完善内容**:

| API 端点 | 方法 | 说明 |
|----------|------|------|
| `/settings` | GET | 获取所有设置 |
| `/settings/:key` | GET/PUT | 获取/更新单个设置 |
| `/settings/encrypt` | POST | 加密存储敏感数据 |
| `/settings/decrypt` | POST | 解密读取敏感数据 |
| `/settings/export` | GET | 导出设置 (JSON) |
| `/settings/import` | POST | 导入设置 (JSON) |
| `/settings/reset` | POST | 重置为默认设置 |
| `/settings/validate` | POST | 验证设置值 |
| `/settings/health` | GET | 健康检查 |

### 1.3 AI Provider Service

**状态**: 部分实现 (Dart, 36 行 main)
**完善内容**:
- 完整 LiteLLM 客户端实现
- 模型动态注册/注销
- 流式响应 (SSE) 支持
- 非流式响应支持
- 模型列表 API
- 模型配置持久化
- 错误处理 + 重试机制
- 超时控制

### 1.4 Document Service

**状态**: 部分实现 (Dart, 20 行 main)
**完善内容**:
- 完整文档 CRUD
- SQLite FTS 全文搜索
- Markdown 解析 (markdown_it)
- 文档大纲提取
- 文档统计 (字数/段落)
- 批量操作支持

### 1.5 Project Service

**状态**: 部分实现 (Dart, 17 行 main)
**完善内容**:
- 完整项目 CRUD
- 项目导入/导出 (Markdown 目录)
- 树形结构管理
- 项目统计
- 元数据管理

### 1.6 其余微服务

- **Export**: 完善 Markdown/TXT/PDF 导出
- **Version History**: 完善快照/差异/恢复
- **Quota**: 完善 Token Bucket 限流
- **Storage**: 完善向量存储
- **Sync**: 完善 WebDAV 同步
- **Codex**: 完善 CRUD + 语义搜索

---

## 2. 一键启动系统 (One-Click Launcher)

### 2.1 架构

```
launcher/
├── main.dart            # Flutter 启动器 GUI
├── service_manager.dart  # 服务生命周期管理
├── docker_manager.dart   # Docker 模式管理
├── tray_manager.dart     # 系统托盘管理
├── auto_updater.dart     # 自动更新检查
└── assets/
    └── icon.ico          # 托盘图标
```

### 2.2 功能规格

**启动模式**:
- **本地模式 (默认)**: 自动启动所有微服务进程 + API Gateway + Flutter 客户端
- **Docker 模式**: 使用 docker-compose 启动所有服务
- **混合模式**: 本地运行 Flutter 客户端，远程连接已有后端

**GUI 界面**:
- 服务列表显示 11 个微服务 + API Gateway 状态
- 每个服务显示：名称、端口、状态指示灯 (绿/黄/红)
- 操作按钮：启动全部/停止全部/重启单个
- 日志查看器：实时显示服务日志
- 设置面板：配置端口、Docker 路径、开机自启

**系统托盘**:
- 右键菜单：显示/隐藏、启动/停止、退出
- 左键点击：切换显示/隐藏
- 状态提示：Service Running / Stopped

**自动检测**:
- 端口冲突检测
- 环境依赖检测 (Dart/Node/Docker)
- 自动 `pub get` / `npm install`
- 首次启动引导

---

## 3. Docker 部署

### 3.1 服务映射

| 服务 | 内部端口 | 外部端口 | 基础镜像 |
|------|---------|---------|---------|
| api-gateway | 8080 | 8080 | dart:3.6-slim |
| ai-provider | 8081 | 8081 | dart:3.6-slim |
| project | 8082 | 8082 | dart:3.6-slim |
| document | 8083 | 8083 | dart:3.6-slim |
| codex | 8084 | 8084 | dart:3.6-slim |
| export | 8085 | 8085 | dart:3.6-slim |
| version | 8086 | 8086 | dart:3.6-slim |
| settings | 8087 | 8087 | node:20-alpine |
| quota | 8088 | 8088 | dart:3.6-slim |
| storage | 8089 | 8089 | dart:3.6-slim |
| sync | 8090 | 8090 | dart:3.6-slim |
| canvas | 8091 | 8091 | node:20-alpine |

### 3.2 网络

- 所有服务在 `lingbi_network` 内网
- 外部只暴露 API Gateway (8080)
- 微服务间通过服务名通信

---

## 4. 社区系统 (Community)

### 4.1 更新检查器

- 启动时异步检查 GitHub Releases
- 比较本地版本 vs 远程版本
- 新版本可用时显示通知
- 点击跳转到下载页面

### 4.2 Skill 市场

**架构**:
```
community/
├── website/              # 社区网站 (GitHub Pages)
│   ├── index.html
│   ├── skills/           # Skill 目录
│   ├── docs/             # 文档
│   └── blog/             # 更新日志
└── skill-registry.json   # 官方 Skill 注册表
```

**Skill 市场功能**:
- 内置 Skill 浏览器面板
- 从社区注册表获取 Skill 列表
- 一键安装/卸载 Skill
- Skill 自动更新检查
- 本地 Skill 管理

### 4.3 社区网站

基于 GitHub Pages 的静态站点：
- 首页：项目介绍 + 快速开始
- 文档：用户指南 + API 文档
- Skills：Skill 目录 + 安装指南
- 更新日志：版本历史 + 发布说明
- 贡献指南：如何参与

---

## 5. 质量要求

- 每个微服务 ≥ 10 个单元测试
- `flutter analyze` 0 错误
- 所有测试通过
- Docker 构建通过
- 一键启动测试通过 (Windows 10/11)
- API 兼容性验证