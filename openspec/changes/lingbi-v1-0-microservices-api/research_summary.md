# 灵笔微服务调研报告汇总

## 概述

针对灵笔 v1.0 微服务架构的 11 个核心模块，进行了深度技术调研。每个模块至少调研了 10 个不同的技术解决方案，覆盖方案名称、链接、优缺点、适配度评分，并最终给出推荐方案。

---

## 调研清单

| 序号 | 微服务 | 调研方案数 | 推荐方案 |
|------|--------|------------|----------|
| 1 | AI Provider | 10 | LiteLLM AI Gateway |
| 2 | Codex Service | 20 | Qdrant + Neo4j + BM25混合搜索 |
| 3 | Document Service | 20 | SQLite FTS + Git + markdown_it |
| 4 | Project Service | 10 | JSON + SQLite + 树形结构 |
| 5 | Export Service | 20 | Flutter原生 + WeasyPrint + Pandoc |
| 6 | Version History | 10 | SQLite快照 + LZO压缩 + Git diff |
| 7 | Settings Service | 10 | flutter_secure_storage + JSON |
| 8 | Quota Service | 10 | Token Bucket + SQLite计数器 |
| 9 | Storage Service | 20 | SQLite + vectors + LanceDB |
| 10 | Sync Service | 10 | Rclone + WebDAV + 冲突保留策略 |
| 11 | Canvas Service | 20 | vyuh_node_flow + D3.js |

---

## 各模块详细调研

> 详细调研报告已单独保存，见下方各模块文件。

---

## 整体架构决策建议

### 推荐技术栈

| 层次 | 推荐技术 |
|------|----------|
| **AI Provider** | LiteLLM AI Gateway + Ollama（本地模型） |
| **向量数据库** | Qdrant（远程）+ SQLite vectors（本地） |
| **图数据库** | Neo4j Community（可选） |
| **文档存储** | SQLite FTS + JSON |
| **版本控制** | SQLite快照 + LZO压缩 |
| **配置加密** | flutter_secure_storage |
| **配额管理** | Token Bucket + SQLite |
| **文件同步** | Rclone + WebDAV |
| **画布** | vyuh_node_flow（Flutter）+ D3.js（WebView） |

### 实施优先级

**Phase 1（高优先级）**：
- AI Provider 微服务（第三方模型接入）
- Document Service（文档管理）
- Project Service（项目管理）
- Settings Service（配置管理）

**Phase 2（中优先级）**：
- Codex Service（知识图谱）
- Export Service（多格式导出）
- Version History（版本历史）
- Quota Service（配额管理）

**Phase 3（低优先级）**：
- Storage Service（存储抽象）
- Sync Service（文件同步）
- Canvas Service（故事画布）