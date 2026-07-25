# ADR-0002: Skill 生态架构 — 分层运行时 + 声明式权限

## 状态

已决定（2026-07-24 产品愿景审计会议）

## 背景

灵笔的核心竞争壁垒是 Skill 生态的网络效应（飞轮第一层）。市面上已有大量 AI 写作工具（如 OpenWrite），纯功能无法形成护城河。Skill 生态需要同时满足：

- 低门槛创作（普通用户也能贡献）
- 高能力上限（专业开发者可写代码插件）
- 安全可控（第三方 Skill 不能无限制访问用户数据）
- 本地优先（不依赖云端执行）

## 决定

### 1. Skill 分层

| 层级 | 载体 | 能力 | 创作门槛 |
|------|------|------|---------|
| 轻量 Skill | SKILL.md（结构化 prompt） | 注入 AI 上下文，无文件写入 | 写 Markdown |
| 重量 Skill | Dart/脚本代码 + manifest.yaml | 可读写 Document/Canon/StoryBeat | 编程 |
| 内置 Skill | 编译进客户端的 Dart 类 | 完全权限 | 官方开发 |
| 类型 Skill | 按体裁分（小说/剧本/短篇） | 继承对应层级能力 | 混合 |
| 细分类型 Skill | 按题材分（修仙/都市/悬疑） | 继承对应层级能力 | 混合 |

### 2. 声明式权限

重量 Skill 必须在 manifest.yaml 中声明所需权限：

```yaml
requires:
  - canon.read
  - canon.write
  - document.read
  - document.write
  - storybeat.read
```

运行时按声明权限沙箱执行。轻量 Skill 默认只有 read 权限。

### 3. 分发机制

复用 GitHub 基础设施（仓库 + Releases + Raw URL），不自建服务端。

### 4. 冷启动策略

三轨并行：
- A：官方批量生产（现有 17 个 Skill）
- B：蒸馏即创作（用户 Canon/风格自动生成轻量 Skill）
- D：跨平台迁移（适配 Claude/GPTs 社区已有写作 prompt）

### 5. 关键实现断裂点

当前 `SkillActionService`（执行引擎）与 `SkillMarketplace`（商店）未打通。安装的 SKILL.md 不会被 Runtime 加载执行。需要：
- Skill 包格式标准（.skill = zip: SKILL.md + manifest.yaml + 可选 scripts/）
- 动态加载器（从本地安装目录解析并注册到 SkillActionService）
- 权限校验层（执行前检查 manifest 声明 vs 实际调用）

## 替代方案（已否决）

1. **纯 prompt 模板**：壁垒太低，任何人可复制，飞轮无法形成网络效应。
2. **纯代码插件**（VS Code Extension 模式）：创作者门槛过高，飞轮转不起来。
3. **自建 Skill 服务端**：Bootstrap 阶段成本过高，GitHub 方案够用。
4. **自由访问所有数据**（无权限系统）：用户信任崩塌，商业化不可行。

## 后果

- 正面：兼顾低门槛与高能力，安全可控，分发零成本
- 负面：需要实现动态加载 + 权限沙箱（额外工程量）；GitHub 分发体验不如自建服务端
- 风险：如果蒸馏功能做不好，B 路径失效，冷启动只靠 A+D 供给不足
