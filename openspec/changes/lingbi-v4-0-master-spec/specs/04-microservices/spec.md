# 微服务架构 — 需求规格

> ID: CAP-MS | 优先级: P0 | 依赖: CAP-STORAGE, CAP-AI

---

## 需求清单

### REQ-MS-01: API Gateway
- **优先级**: P0
- **描述**: dart_frog API Gateway 统一路由分发，端口 8080
- **验收标准**:
  - 12 个微服务的路由挂载
  - 速率限制 (默认 100 req/min 每服务)
  - 请求日志 (方法/路径/耗时/状态码)
  - CORS 支持（本地开发）
  - 健康检查聚合: GET /health → 所有服务状态

### REQ-MS-02: AI Provider 微服务 (:8081)
- **优先级**: P0
- **描述**: LiteLLM Gateway 统一 LLM 提供商接入
- **验收标准**:
  - 支持 100+ LLM Provider
  - 统一 OpenAI 格式 API
  - 流式响应 (SSE)
  - 成本跟踪 + Token 日志
  - 本地 Ollama 模型支持（可选）

### REQ-MS-03: Project 微服务 (:8082)
- **优先级**: P0
- **描述**: Project/Work CRUD + 树形结构管理
- **验收标准**:
  - WorkCRUD + Volume/Chapter/Scene 层级管理
  - 树形结构查询 (GET /api/v1/projects/:id/tree)
  - Markdown 目录导入/导出
  - 搜索 (按标题/描述)

### REQ-MS-04: Document 微服务 (:8083)
- **优先级**: P0
- **描述**: 文档管理 + 全文搜索
- **验收标准**:
  - .md 文件读写
  - Drift FTS5 全文搜索
  - 字数统计
  - 文档快照 (配合 Version History)

### REQ-MS-05: Codex 微服务 (:8084)
- **优先级**: P1
- **描述**: Canon 条目 CRUD + 语义搜索 + 图谱查询
- **验收标准**:
  - Character / Location / Lore / WorldRule CRUD
  - ZVec 语义搜索
  - 角色关系图谱查询
  - 知识图谱可视化数据接口

### REQ-MS-06: Export 微服务 (:8085)
- **优先级**: P1
- **描述**: 多格式导出
- **验收标准**:
  - Markdown / TXT / JSON 原生导出
  - DOCX / EPUB 原生导出 (Dart)
  - PDF 导出 (Pandoc 可选)
  - 批量导出 (整部作品)

### REQ-MS-07: Version History (:8086)
- **优先级**: P1
- **描述**: 文档版本历史管理
- **验收标准**:
  - Git LFS 存储版本快照
  - 版本对比 (diff)
  - 版本回滚
  - 自动快照 (每 5 分钟 + 手动保存)

### REQ-MS-08: Quota (:8088)
- **优先级**: P1
- **描述**: AI 调用配额管理
- **验收标准**:
  - 每日配额 (免费 100 次/天)
  - 会员无限制
  - 配额耗尽时优雅降级提示

### REQ-MS-09: Sync (:8089)
- **优先级**: P1
- **描述**: 文件系统 ↔ Drift 双向同步
- **验收标准**:
  - .md 文件变更自动同步到 Drift 索引
  - Drift 元数据变更同步到文件系统
  - 冲突检测 + 解决策略

### REQ-MS-10: Canvas (:8090)
- **优先级**: P1
- **描述**: 故事画布服务
- **验收标准**:
  - StoryBeat CRUD
  - 画布节点布局持久化
  - 画布导出为图片

### REQ-MS-11: Skill (:8091)
- **优先级**: P2
- **描述**: Skill 注册/发现/执行服务
- **验收标准**:
  - Skill 注册 (name / version / entrypoint)
  - Skill 列表查询
  - Skill 执行隔离沙箱
  - Skill 卸载

### REQ-MS-12: Novel Engine (:8092)
- **优先级**: P0
- **描述**: 三层生成管线微服务（见 CAP-AI REQ-AI-02）

### REQ-MS-13: Quality Review (:8093)
- **优先级**: P1
- **描述**: 质量审查微服务（见 CAP-AI REQ-AI-04）