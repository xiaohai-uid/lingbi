# ADR-0003: 引导产出物存储 — 项目级结构化文件 + Canon 索引

## 状态

已接受 (2026-07-25)

## 背景

引导式 AI 产生的结构化数据（世界观/角色/大纲）需要决定存储形态。

## 决策

照搬 OpenWrite 做法：项目级结构化文件制。

1. **引导产出写入项目目录**：`project_meta/worldbuilding.json`、`project_meta/characters.json`、`project_meta/outline.json` 等，支持任意嵌套层级结构
2. **Canon 作为轻量索引**：创建摘要级 CanonEntry（标题 + 简述 + 指向文件路径），供语义搜索和 AI 上下文注入使用
3. **世界宪法**：不可变硬规则（物理法则/力量上限）与可编辑百科分离，照搬 OpenWrite 的 Hard Invariants + Soft Guidance 分层
4. **AI 上下文注入时按需加载**：不一次性灌入全部结构化数据，根据当前创作阶段选择性注入

## 后果

- 正面：层级结构不丢失；Git 可追踪；一键成剧可直接消费；与 OpenWrite 行为一致
- 负面：需设计 project_meta 的 schema 版本管理；Canon 索引与源文件需保持同步
