# Prompt 模板目录

此目录存放 LLM Prompt 模板文件。
v3.2 阶段模板仍硬编码在 Dart 代码中，v3.3 迁移到 YAML 文件。

## 规划中的模板文件
- generate_outline.yaml      # 梗概→卷章细纲
- stream_scene.yaml          # 场景细纲→正文流式生成
- character_check.yaml       # 角色一致性检测
- expand_idea.yaml           # 创意拓展

## 模板格式（规划）

```yaml
id: generate_outline
name: 生成细纲
description: 从故事梗概生成卷章细纲
system_prompt: |
  你是一个专业的网文大纲生成器...
constraints:
  min_chars: 500
  max_chars: 30000
```