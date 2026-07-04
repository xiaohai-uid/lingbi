# Lingbi v1.0 微服务架构 — 主 Spec 文档

## 概述

本文档整合了 11 个核心微服务的深度技术调研结果，每个微服务至少调研了 10 个不同的技术解决方案。基于调研结论，给出最终推荐的技术栈和实施路径。

---

## 微服务调研汇总

### 1. AI Provider 微服务

**调研方案数**: 10
**推荐方案**: **LiteLLM AI Gateway** + Ollama（本地模型）

**核心理由**:
- 支持 100+ LLM 提供商
- 统一 OpenAI 格式 API
- 开箱即用的成本跟踪、负载均衡、日志记录
- 支持流式响应（SSE）和异步调用
- 国内大模型接入（DashScope 等）

**备选方案**: Dify + Portkey Gateway

**实施优先级**: Phase 1 (最高优先级)

---

### 2. Codex Service 微服务

**调研方案数**: 20
**推荐方案**: **Qdrant**（向量）+ **Neo4j**（图谱）+ BM25 混合搜索

**核心理由**:
- Qdrant 提供高性能向量搜索（Rust 实现）
- Neo4j 提供专业的图数据库能力
- BM25 + 向量混合搜索提供最高的召回率和精确度
- SQLite vectors 作为本地备选

**备选方案**: Chroma + 纯关系型数据库

**实施优先级**: Phase 2 (中优先级)

---

### 3. Document Service 微服务

**调研方案数**: 20
**推荐方案**: **SQLite FTS** + Git + markdown_it

**核心理由**:
- SQLite FTS 提供零配置的全文搜索
- Git 提供成熟的版本控制和历史记录
- markdown_it 提供快速、可扩展的 Markdown 解析
- Git diff + LZO 压缩实现高效版本存储

**备选方案**: Meilisearch + 纯文件存储

**实施优先级**: Phase 1 (高优先级)

---

### 4. Project Service 微服务

**调研方案数**: 10
**推荐方案**: JSON + SQLite + 树形结构

**核心理由**:
- 树形结构直观表示项目层级
- JSON 存储项目元数据，易于调试
- SQLite 存储文档关联和索引
- Markdown 目录导入导出 + Pandoc 多格式转换

**备选方案**: 纯关系型数据库 + 扁平结构

**实施优先级**: Phase 1 (高优先级)

---

### 5. Export Service 微服务

**调研方案数**: 20
**推荐方案**: Flutter 原生 + WeasyPrint + Pandoc

**核心理由**:
- Flutter 原生导出（PNG/SVG）适合简单场景
- WeasyPrint 支持现代 CSS，输出质量高
- Pandoc 支持 100+ 格式，适合批量导出

**备选方案**: Puppeteer + docx.js

**实施优先级**: Phase 2 (中优先级)

---

### 6. Version History Service 微服务

**调研方案数**: 10
**推荐方案**: SQLite 快照 + LZO 压缩 + Git diff

**核心理由**:
- SQLite 提供零依赖的存储能力，事务保证数据一致性
- LZO 提供高速压缩，适合实时版本存储
- Git diff 算法提供精确的版本差异计算

**备选方案**: 纯 SQLite 快照 + LZ4 压缩

**实施优先级**: Phase 2 (中优先级)

---

### 7. Settings Service 微服务

**调研方案数**: 10
**推荐方案**: flutter_secure_storage + JSON

**核心理由**:
- flutter_secure_storage 提供平台原生安全存储
- JSON 格式简单易用，易于调试和版本控制
- 配置模板和重置功能提升用户体验

**备选方案**: pointycastle + YAML

**实施优先级**: Phase 1 (高优先级)

---

### 8. Quota Service 微服务

**调研方案数**: 10
**推荐方案**: Token Bucket + SQLite 计数器

**核心理由**:
- Token Bucket 算法成熟、易于实现
- SQLite 提供零依赖的持久化存储
- 配额可视化和告警提升用户体验

**备选方案**: 滑动窗口计数器 + Redis + Lua 脚本

**实施优先级**: Phase 2 (中优先级)

---

### 9. Storage Service 微服务

**调研方案数**: 20
**推荐方案**: SQLite + vectors + LanceDB

**核心理由**:
- SQLite 提供零依赖的通用存储能力
- SQLite vectors 扩展提供轻量级向量搜索
- LanceDB 作为高性能备选
- 混合存储架构适合复杂场景

**备选方案**: Qdrant + 纯文件存储

**实施优先级**: Phase 3 (低优先级)

---

### 10. Sync Service 微服务

**调研方案数**: 10
**推荐方案**: Rclone + WebDAV + 冲突保留策略

**核心理由**:
- Rclone 支持 70+ 云存储，提供 bisync 双向同步
- WebDAV 标准化协议，几乎所有云存储都支持
- 冲突保留策略避免数据丢失
- 离线优先设计提升用户体验

**备选方案**: Syncthing + Git 集成

**实施优先级**: Phase 3 (低优先级)

---

### 11. Canvas Service 微服务

**调研方案数**: 20
**推荐方案**: vyuh_node_flow + D3.js via WebView

**核心理由**:
- vyuh_node_flow 提供高性能渲染（目标 60fps）
- D3.js 提供强大的布局算法（力导向、树、环形等）
- 内置 LOD 和迷你地图，支持大图形虚拟渲染
- 模板系统和搜索定位提升创作效率

**备选方案**: flutter_flow_chart + Cytoscape.js

**实施优先级**: Phase 3 (低优先级)

---

## 最终推荐技术栈

| 层次 | 推荐技术 |
|------|----------|
| **AI Provider** | LiteLLM AI Gateway + Ollama（本地模型） |
| **Codex Service** | Qdrant（向量）+ Neo4j（图谱）+ BM25 混合搜索 |
| **Document Svc** | SQLite FTS + Git + markdown_it |
| **Project Svc** | JSON + SQLite + 树形结构 |
| **Export Svc** | Flutter 原生 + WeasyPrint + Pandoc |
| **Version Svc** | SQLite 快照 + LZO 压缩 + Git diff |
| **Settings Svc** | flutter_secure_storage + JSON 加密 |
| **Quota Svc** | Token Bucket + SQLite 计数器 |
| **Storage Svc** | SQLite + vectors + LanceDB |
| **Sync Svc** | Rclone + WebDAV + 冲突保留 |
| **Canvas Svc** | vyuh_node_flow + D3.js via WebView |
| **API Gateway** | dart_frog（Dart 原生） |
| **数据库** | SQLite（本地）+ Qdrant（向量） |
| **HTTP 客户端** | Dio（Flutter 客户端） |

---

## 实施路径

### Phase 1 (高优先级) - 核心功能
- AI Provider 微服务（第三方模型接入）
- Document Service（文档管理）
- Project Service（项目管理）
- Settings Service（配置管理）

### Phase 2 (中优先级) - 增强功能
- Codex Service（知识图谱）
- Export Service（多格式导出）
- Version History（版本历史）
- Quota Service（配额管理）

### Phase 3 (低优先级) - 高级功能
- Storage Service（存储抽象）
- Sync Service（文件同步）
- Canvas Service（故事画布）

---

## 架构决策记录 (ADR)

### ADR-001: 选择 Dart 作为后端 API 框架

**问题**: 微服务后端选择哪种技术栈？

**选项**:
- Dart (dart_frog)
- Python (FastAPI)
- Node.js (Express)

**决策**: 选择 Dart (dart_frog)

**理由**:
- 与 Flutter 共享模型定义，减少跨进程数据序列化成本
- 统一技术栈，降低维护成本
- 启动速度快，适合微服务场景

---

### ADR-002: 选择 LiteLLM 作为 AI Provider 网关

**问题**: 第三方模型接入选择哪种方案？

**选项**:
- LiteLLM
- LangChain
- 自研网关

**决策**: 选择 LiteLLM

**理由**:
- 支持 100+ LLM 提供商
- 开箱即用的成本跟踪、负载均衡
- 国内大模型支持好
- 社区活跃

---

### ADR-003: 选择 SQLite 作为核心存储

**问题**: 本地数据存储选择哪种方案？

**选项**:
- SQLite
- MongoDB
- 纯文件存储

**决策**: 选择 SQLite

**理由**:
- 零依赖，嵌入式
- 事务保证数据一致性
- 成熟的生态
- 适合本地优先场景

---

## 下一步

1. **开始实施 Phase 1**: 从 AI Provider 微服务开始
2. **编写详细任务清单**: 将调研结论转化为可执行任务
3. **启动子代理开发**: 按 TDD 方法并行开发各微服务
4. **代码审查**: 完成后进行自动代码审查
5. **验证完成**: 验证所有微服务正常工作

---

*调研完成时间: 2025-06-30*
*调研方案总数: 130+*