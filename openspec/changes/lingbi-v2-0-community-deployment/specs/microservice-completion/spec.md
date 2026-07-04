## MODIFIED Requirements

### Requirement: Canvas Service 完善
The Canvas Service SHALL provide complete CRUD APIs for story canvas templates, nodes, edges, layout algorithms, and export.
**FROM:** Basic Node.js skeleton with template files only
**TO:** Full REST API with node/edge CRUD, layout algorithms, and export

#### Scenario: Canvas CRUD API
- **WHEN** 用户请求 POST /canvas/nodes
- **THEN** 创建新画布节点
- **AND** 返回节点 ID 和位置信息
- **WHEN** 用户请求 POST /canvas/edges
- **THEN** 创建节点间连线
- **AND** 验证连接合法性

#### Scenario: 画布模板加载
- **WHEN** 用户请求 GET /canvas/templates
- **THEN** 返回可用模板列表（mind-map, story-flow）
- **WHEN** 用户请求 GET /canvas/templates/story-flow
- **THEN** 返回 story-flow 模板的完整 JSON 定义

#### Scenario: 布局算法
- **WHEN** 用户请求 POST /canvas/layout with type="force-directed"
- **THEN** 应用力导向布局算法
- **AND** 返回更新后的节点位置

### Requirement: Settings Service 完善
The Settings Service SHALL provide encrypted storage, configuration validation, and import/export capabilities.
**FROM:** Basic Node.js skeleton with JSON storage
**TO:** Full REST API with AES-256 encryption, validation, and import/export

#### Scenario: 设置加密存储
- **WHEN** 用户请求 POST /settings/encrypt with api_key
- **THEN** 使用 AES-256 加密存储
- **AND** 返回加密成功状态
- **WHEN** 用户请求 POST /settings/decrypt with key name
- **THEN** 返回解密后的原始值

#### Scenario: 设置导入导出
- **WHEN** 用户请求 GET /settings/export
- **THEN** 返回所有设置的 JSON 导出
- **AND** 敏感字段已加密
- **WHEN** 用户请求 POST /settings/import with JSON body
- **THEN** 导入设置值
- **AND** 验证每个值合法性

### Requirement: AI Provider 完善
The AI Provider Service SHALL support streaming responses, dynamic model registration, and comprehensive error handling.
**FROM:** Basic Dart skeleton with LiteLLM client
**TO:** Full streaming SSE support, dynamic model registry, and error handling

#### Scenario: 流式聊天
- **WHEN** 用户请求 POST /ai/chat with SSE
- **THEN** 返回 Server-Sent Events 流式响应
- **AND** 每个 chunk 包含部分响应内容
- **AND** 最后发送 [DONE] 标记

#### Scenario: 模型动态注册
- **WHEN** 用户请求 POST /ai/models with 模型配置
- **THEN** 注册新模型到可用模型列表
- **AND** 返回模型 ID
- **WHEN** 用户请求 GET /ai/models
- **THEN** 返回所有已注册模型列表

### Requirement: Document Service 完善
The Document Service SHALL provide full-text search, document statistics, and outline extraction.
**FROM:** Basic CRUD skeleton
**TO:** SQLite FTS full-text search + outline extraction + document statistics

#### Scenario: 文档全文搜索
- **WHEN** 用户请求 GET /document/search?q=关键词
- **THEN** 使用 SQLite FTS 全文搜索
- **AND** 返回匹配的文档列表（含相关性分数）

#### Scenario: 文档 CRUD
- **WHEN** 用户请求 POST /document with 文档内容
- **THEN** 创建新文档并返回 ID
- **AND** 自动生成大纲
- **AND** 计算文档统计（字数/段落数）

### Requirement: Project Service 完善
The Project Service SHALL support tree-structured project management and Markdown import/export.
**FROM:** Basic CRUD skeleton
**TO:** Tree structure management + Markdown import/export

#### Scenario: 项目树形结构
- **WHEN** 用户请求 GET /project/:id/tree
- **THEN** 返回项目的文档树
- **WHEN** 用户请求 POST /project with 项目名称
- **THEN** 创建新项目
- **AND** 初始化树形文档结构

#### Scenario: 项目导入导出
- **WHEN** 用户请求 POST /project/import with Markdown 文件
- **THEN** 导入 Markdown 目录结构为项目
- **AND** 自动创建对应的文档树