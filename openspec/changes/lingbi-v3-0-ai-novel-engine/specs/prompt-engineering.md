# 网文 Prompt 工程 + 类型库 — Spec

## 目标

建立灵笔的 Prompt 管理体系，从 AI_NovelGenerator 的 `prompt_definitions/prompt_default.yaml` 和 `skill/novel-architect/` 中提取网文创作最佳实践。

## Prompt 管理方式

- YAML 文件存储 Prompt 模板（灵笔编辑器内可编辑）
- 按类型分类：起点爆款、番茄爽文、传统文学
- 按体裁细分：玄幻、仙侠、都市、悬疑、言情

## 核心 Prompt 模板

### 1. 创意展开 (expand_idea)
从 AI_NovelGenerator 的 `prompt_default.yaml` 移植，优化为中文网文风格：
- 冲突前置（开篇 3-5% 内出现强力冲突）
- 金手指设计（主角独特优势）
- 期待感（每章结尾留钩子）
- 成长路径（清晰升级路线）
- 打脸爽感（反派反击场景）
- 代入感强（主角视角为主）
- 节奏明快（情节推进快）

### 2. 风格分析
- 分析用户现有文本的风格特征
- 识别：叙事节奏、对话密度、描写风格、情绪曲线

### 3. 小说拆解
- 分析名著的章节结构
- 提取：钩子位置、高潮分布、人物弧线

### 4. 类型化写作指南

从 `skill/novel-architect/` 迁移：

| 类型 | 来源 | 核心原则 |
|------|------|----------|
| 奇幻 | `fantasy.md` | 桑德森魔法定律、硬/软魔法系统、世界构建 |
| 悬疑 | `mystery.md` | Fair Play 原则、线索放置、误导设计 |
| 起点爆款 | `prompt_default.yaml` | 爽感引擎、金手指、升级打脸 |

## 文件清单

| 文件 | 说明 |
|------|------|
| `assets/prompts/novel/prompts.yaml` | Prompt 模板库 |
| `assets/prompts/novel/genres/fantasy.yaml` | 奇幻类型指南 |
| `assets/prompts/novel/genres/mystery.yaml` | 悬疑类型指南 |
| `assets/prompts/novel/genres/urban.yaml` | 都市类型指南 |
| `lib/services/prompt_service.dart` | Prompt 加载/管理服务 |
| `lib/ui/pages/prompt_editor_page.dart` | Prompt 编辑器 UI |