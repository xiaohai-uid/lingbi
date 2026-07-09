# 灵笔 v2.0 — 任务清单

---

## Phase 1: 一键启动器 + Docker 部署

### 1.1 创建 Windows 一键启动器
- [ ] 1.1.1 创建 launcher/ 目录和 pubspec.yaml
- [ ] 1.1.2 实现 service_manager.dart：进程启动/停止/健康检查
- [ ] 1.1.3 实现 launcher GUI：服务状态面板
- [ ] 1.1.4 实现系统托盘管理
- [ ] 1.1.5 实现日志查看器
- [ ] 1.1.6 实现环境自动检测（Dart/Node/端口）
- [ ] 1.1.7 编写启动器单元测试

### 1.2 Docker 部署完善
- [ ] 1.2.1 优化 Dockerfile（多阶段构建，减小镜像）
- [ ] 1.2.2 创建完整的 docker-compose.yml（12 个服务）
- [ ] 1.2.3 创建 .env.example（环境变量配置）
- [ ] 1.2.4 创建 Docker 网络和数据卷配置
- [ ] 1.2.5 Docker 构建测试

---

## Phase 2: 微服务完善

### 2.1 Canvas Service 完善
- [ ] 2.1.1 Canvas: 完成 index.js 路由（模板/节点/边/布局/导出）
- [ ] 2.1.2 Canvas: 完善 load-templates.js 模板加载逻辑
- [ ] 2.1.3 Canvas: 添加布局算法（力导向/树形/环形）
- [ ] 2.1.4 Canvas: 添加 Node.js 单元测试

### 2.2 Settings Service 完善
- [ ] 2.2.1 Settings: 完善 service.js 路由
- [ ] 2.2.2 Settings: 完善 storage.js 加密存储
- [ ] 2.2.3 Settings: 完善 crypto.js 加密解密
- [ ] 2.2.4 Settings: 添加 Node.js 单元测试

### 2.3 AI Provider 完善
- [ ] 2.3.1 AI: 完善 litellm_client.dart（流式/非流式）
- [ ] 2.3.2 AI: 完善 chat_service.dart（对话管理）
- [ ] 2.3.3 AI: 完善 model_config.dart（动态注册）
- [ ] 2.3.4 AI: 完善路由（chat/continue/embedding/style/novel）
- [ ] 2.3.5 AI: 添加 Dart 单元测试

### 2.4 Document Service 完善
- [ ] 2.4.1 Document: 完善 document.dart 模型
- [ ] 2.4.2 Document: 完善 database_service.dart（SQLite FTS）
- [ ] 2.4.3 Document: 完善路由（CRUD/搜索/大纲）
- [ ] 2.4.4 Document: 添加 Dart 单元测试

### 2.5 Project Service 完善
- [ ] 2.5.1 Project: 完善 project_service.dart（CRUD + 树形）
- [ ] 2.5.2 Project: 添加导入导出功能
- [ ] 2.5.3 Project: 添加 Dart 单元测试

### 2.6 其余微服务完善
- [ ] 2.6.1 Export: 完善导出服务（MD/TXT/PDF）
- [ ] 2.6.2 Version: 完善版本服务（快照/差异/恢复）
- [ ] 2.6.3 Quota: 完善配额服务（Token Bucket）
- [ ] 2.6.4 Storage: 完善向量存储
- [ ] 2.6.5 Sync: 完善 WebDAV 同步
- [ ] 2.6.6 Codex: 完善 CRUD + 语义搜索
- [ ] 2.6.7 所有微服务添加健康检查和错误处理

---

## Phase 3: 社区系统

### 3.1 更新检查器
- [ ] 3.1.1 实现 auto_updater.dart（GitHub API 版本检查）
- [ ] 3.1.2 实现版本比较逻辑（semver）
- [ ] 3.1.3 实现更新通知 UI
- [ ] 3.1.4 添加测试

### 3.2 Skill 市场
- [ ] 3.2.1 创建 community/skill-registry.json
- [ ] 3.2.2 实现 Skill 浏览器 UI（Flutter 面板）
- [ ] 3.2.3 实现 Skill 安装/卸载逻辑
- [ ] 3.2.4 实现 Skill 自动更新检查
- [ ] 3.2.5 添加测试

### 3.3 社区网站
- [ ] 3.3.1 创建 community/website/ 目录
- [ ] 3.3.2 创建首页 index.html
- [ ] 3.3.3 创建文档页面
- [ ] 3.3.4 创建 Skill 目录页面
- [ ] 3.3.5 创建更新日志页面
- [ ] 3.3.6 配置 GitHub Pages

---

## Phase 4: 测试 + 验证

### 4.1 集成测试
- [ ] 4.1.1 端到端测试：启动 → 连接 → 使用
- [ ] 4.1.2 Docker 构建测试
- [ ] 4.1.3 一键启动测试

### 4.2 代码质量
- [ ] 4.2.1 flutter analyze 0 错误验证
- [ ] 4.2.2 所有单元测试通过
- [ ] 4.2.3 代码审查

### 4.3 文档完善
- [ ] 4.3.1 更新 README.md
- [ ] 4.3.2 更新 CONTRIBUTING.md
- [ ] 4.3.3 创建 DEPLOY.md（部署指南）
- [ ] 4.3.4 创建 COMMUNITY.md（社区指南）