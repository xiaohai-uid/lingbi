---
name: skill-creator
description: 创建新的技能(Skill)、修改和改进现有技能。触发词：创建技能、写个技能、做个助手、帮我做一个XX、我想让AI学会XX、把流程变成技能。
category: meta
---

# 技能创建助手

## Skill 目录结构

```
skill-name/
├── SKILL.md          (必需 — 技能主文件)
├── scripts/          (可选 — 可执行脚本)
├── references/       (可选 — 按需读取的参考文档)
└── assets/           (可选 — 输出模板)
```

## 三级加载机制

1. **元数据**（name + description）— 始终在系统提示中，用于匹配触发
2. **SKILL.md 正文** — skill_lookup 后加载（≤500 行）
3. **配套资源** — file_read 按需读取

## 创建流程

Step 1: 了解需求
- 用 question 工具询问用户：任务目标 / 触发条件 / 输出格式 / 约束规则
- 最多问 3-5 个问题

Step 2: 规划结构
- 决定需要哪些文件（SKILL.md 必须，其余按需）
- 确定 references/ 中放什么参考文档

Step 3: 编写 SKILL.md
- name：英文小写 + 连字符（如 `webnovel-writing`）
- description：贪婪覆盖触发词（越宽越好，确保 AI 能匹配到）
- 正文：清晰的工作流步骤，每步说明用什么工具、产出什么

Step 4: 自我验证
- 检查触发词是否覆盖用户常见表达
- 检查流程步骤是否完整（无遗漏环节）
- 检查资源引用路径是否正确
- 检查边缘场景（空输入 / 超长输入 / 错误路径）

Step 5: 保存
- file_write 写入 SKILL.md
- 如有 references，file_write 写入对应文件
- 用 question 确认用户是否满意

## 修改技能

1. skill_lookup 读取现有 Skill 内容
2. 了解用户想修改什么
3. 修改后用 file_write 覆盖
4. 内置技能修改时自动克隆为用户副本（不覆盖内置）

## SKILL.md 格式规范

```markdown
---
name: skill-name-here
description: 触发词描述，越宽越好。当用户说XX、YY、ZZ时自动触发。
category: writing | editing | analysis | meta
---

# 技能标题

## 工作流程

Step 1: ...
Step 2: ...

## 重要规则

- ...
```

## 重要规则

- name 必须英文小写 + 连字符
- description 必须包含所有可能的触发表达
- 正文不超过 500 行（超过的拆到 references/）
- 不要在 SKILL.md 中硬编码用户数据
- 创建完成后告知用户如何触发该技能
