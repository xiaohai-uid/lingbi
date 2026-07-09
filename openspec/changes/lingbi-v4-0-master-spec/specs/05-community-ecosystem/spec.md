# 社区生态 — 需求规格

> ID: CAP-COMMUNITY | 优先级: P1 | 依赖: CAP-MS (Skill Service :8091)

---

## 需求清单

### REQ-COMM-01: Skill 注册表
- **优先级**: P1
- **描述**: `community/skill-registry.json` 集中管理所有 Skill 元数据
- **验收标准**:
  - 注册表 JSON Schema 定义
  - 字段: name / version / description / author / entrypoint / dependencies
  - Skill 启用/禁用状态
  - 注册表校验 (schema validation)

### REQ-COMM-02: Skill 执行沙箱
- **优先级**: P2
- **描述**: Skill 在隔离环境中执行，不能访问用户文件系统以外的资源
- **验收标准**:
  - 文件系统访问限制在白名单目录
  - 网络访问限制（允许的域名白名单）
  - 执行超时控制 (默认 30 秒)
  - 内存限制 (默认 256MB)
  - 错误隔离 (Skill 崩溃不影响主进程)

### REQ-COMM-03: Novel-Architect Skill
- **优先级**: P1
- **描述**: 已实现的 16 步创作方法论 Skill，验证 Skill 系统可用
- **验收标准**:
  - Skill 可在灵笔中加载 (community/skill-registry.json 注册)
  - 16 步流程引导用户创作
  - 奇幻指南 (桑德森三定律) 可用
  - 悬疑指南 (Fair Play) 可用
  - 创作哲学 (constitution) 作为参考

### REQ-COMM-04: Skill 市场 UI
- **优先级**: P2
- **描述**: 灵笔内的 Skill 浏览/安装/卸载界面
- **验收标准**:
  - 已安装 Skill 列表 + 状态
  - 可用的社区 Skill 列表
  - 一键安装 (从注册表 URL)
  - 卸载确认 + 清理

### REQ-COMM-05: Docker Compose 部署
- **优先级**: P1
- **描述**: Docker Compose 一键启动所有微服务
- **验收标准**:
  - 12 个服务定义
  - 依赖顺序 (Gateway 最后启动)
  - healthcheck 每个服务
  - 日志卷挂载
  - .env 配置外部化 (API Keys 等)

### REQ-COMM-06: Launcher 桌面应用
- **优先级**: P2
- **描述**: 桌面启动器管理所有微服务生命周期
- **验收标准**:
  - 一键启动/停止所有服务
  - 服务状态实时显示 (绿色/黄色/红色)
  - 日志查看器
  - 系统托盘图标
  - 自启动选项