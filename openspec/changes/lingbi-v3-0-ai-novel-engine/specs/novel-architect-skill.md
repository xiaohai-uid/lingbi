# Novel-Architect Skill 整合 — Spec

## 目标

将 AI_NovelGenerator 的 `skill/novel-architect/` (55KB) 转化为灵笔的 Skill 系统可加载的社区 Skill。

## 来源分析

`F:\AI_NovelGenerator\skill\novel-architect\` 包含 4 个文件：

| 文件 | 大小 | 内容 |
|------|:----:|------|
| `SKILL.md` | 55KB | 完整小说创作 Skill：16 步流程、交互原则、背景任务管理 |
| `constitution.md` | 5.8KB | 创作哲学：故事优先、多维度角色、一致世界观、简洁语言、真实情感 |
| `fantasy.md` | 10KB | 奇幻类型写作指南：桑德森魔法定律、魔法系统设计、世界构建 |
| `mystery.md` | 10KB | 悬疑类型写作指南：Fair Play 原则、线索放置、误导设计 |

## 移植方案

### 结构

```
community/skills/novel-architect/
├── SKILL.md              # 主 Skill 定义（16 步流程）
├── constitution.md       # 创作哲学（不变）
├── fantasy.md            # 奇幻类型指南
├── mystery.md            # 悬疑类型指南
├── config.yaml           # Skill 配置
└── templates/
    ├── braindump.md      # 头脑风暴模板
    ├── character.md      # 角色表模板
    └── outline.md        # 章节大纲模板
```

### 适配修改

1. **输出路径**: `~/writing/novels/` → 灵笔项目内文档树
2. **文件格式**: Markdown 文件 → 灵笔 Document 模型
3. **交互方式**: 命令行对话 → 灵笔 AI Panel 内对话
4. **背景任务**: `delegate_task` → 灵笔微服务并行调用
5. **章节草稿**: 独立 Markdown → 灵笔编辑器内直接编辑

### 核心流程（16 步 → 灵笔适配）

| 步骤 | 原 Skill | 灵笔适配 |
|:----:|----------|----------|
| 1 | 收集项目基本信息 | AI Panel 对话表单 |
| 2 | 创建目录结构 | 自动创建项目文档树 |
| 3 | 交互式头脑风暴 | AI Panel 逐步提问 |
| 4 | 定义类型 | 从 Prompt 类型库选择 |
| 5 | 发现叙事声音 | AI 分析用户写作风格 |
| 6 | 构建角色 | Codex 角色条目自动生成 |
| 7 | 构建世界 | Codex 地点/传说条目 |
| 8 | 映射冲突 | 故事画布冲突节点 |
| 9 | 写梗概 | 文档 → 梗概文档 |
| 10 | 创建时间线 | 故事画布时间线 |
| 11 | 生成章节大纲 | 自动生成 Outline 文档 |
| 12 | 起草所有章节 | 逐章生成到编辑器 |
| 13 | 审查和润色 | 质量审查管线 |
| 14 | 章节审计 | 审查报告 |
| 15 | 最终连续性检查 | 全篇一致性检查 |
| 16 | 完成与呈现 | 生成完成报告 |

## 文件清单

| 文件 | 说明 |
|------|------|
| `community/skills/novel-architect/SKILL.md` | 主 Skill（从 55KB 精简适配） |
| `community/skills/novel-architect/constitution.md` | 创作哲学 |
| `community/skills/novel-architect/fantasy.md` | 奇幻类型指南 |
| `community/skills/novel-architect/mystery.md` | 悬疑类型指南 |
| `community/skills/novel-architect/config.yaml` | Skill 配置 |
| `community/skills/novel-architect/templates/` | 模板文件 |

## 验证

- Skill 注册到灵笔社区市场
- 启动后可在 AI Panel 选择 "Novel Architect" 模式
- 16 步流程可在灵笔 UI 中逐步完成