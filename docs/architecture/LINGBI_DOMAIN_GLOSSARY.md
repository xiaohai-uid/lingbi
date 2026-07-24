# 灵笔领域术语表 (Lingbi Domain Glossary)

> 版本：1.0
> 日期：2026-07-24
> 来源：圆桌会议决议
> 规则：每个术语只有一个含义，禁止一词多义

---

## 核心概念

### Canon（正典）

**定义**：一部小说中已确认的世界观事实集合，包括角色、地点、世界规则和实体。

- 存储格式：Markdown + YAML frontmatter
- 存储位置：`{project}/canon/`
- 修改权限：仅作者通过采纳操作修改
- AI 权限：只读
- 不是：运行态、候选内容、向量索引

---

### Runtime State（运行态）

**定义**：随正文推进而自动更新的动态状态数据，包括角色当前状态、关系变化、资源账本。

- 存储格式：JSON
- 存储位置：`{project}/.lingbi/runtime/`
- 修改权限：Settler Agent 在采纳后自动更新
- 不是：正典（正典是静态确认事实，运行态是动态推导状态）

---

### Candidate（候选）

**定义**：AI 生成但尚未经作者采纳的输出内容。所有 AI 输出默认都是候选。

- 存储位置：`{project}/.lingbi/candidates/`
- 生命周期：生成 → 审稿 → 等待采纳 → 采纳/拒绝
- 采纳后：移入正文或正典
- 拒绝后：归档或删除
- 不是：正文、正典、运行态

---

### Manuscript（正文/手稿）

**定义**：小说的正式文本内容，即读者最终读到的文字。

- 存储格式：Markdown (.md)
- 存储位置：`{project}/` 根目录下的 .md 文件
- 修改方式：作者直接编辑 或 采纳 AI 候选
- 是唯一真源：其他层（索引、向量）从此派生
- 不是：大纲、正典、运行态

---

### Origin（起源/创作原点）

**定义**：一部小说的核心创意种子，包含题材、核心冲突、基调和卖点。

- 存储位置：`{project}/story/author_intent.md` 的前置部分
- 生命周期：创建后基本不变
- 用途：作为 Context Packet 层 1 的一部分
- 不是：大纲（大纲是结构化规划，Origin 是创意起点）

---

### Author Intent（作者意图）

**定义**：作者对整本书的长期创作承诺和核心方向，包括主题、情感基调、必须达成的结局方向。

- 存储位置：`{project}/story/author_intent.md`
- 生命周期：创建后极少修改
- 在 Context Packet 中：层 1，永不截断
- 来源：OpenWrite `src/story/author_intent.md`
- 不是：Current Focus（那是近期目标）

---

### Current Focus（当前焦点）

**定义**：近期写作的最高优先级约束和目标，可随篇章推进更新。

- 存储位置：`{project}/story/current_focus.md`
- 生命周期：每卷或每几章更新一次
- 在 Context Packet 中：层 2，永不截断
- 来源：OpenWrite `src/story/current_focus.md`
- 不是：Author Intent（那是长期不变的）

---

### Arc / Character Arc（角色弧光）

**定义**：一个角色从起点状态到终点状态的变化轨迹，包括内在信念、外在行为和关系的变化。

- 组成：起点(Lie) → 发展 → 转折 → 终点(Truth)
- 生命周期：创建 → 发展 → 转折 → 完成
- 可引用：Plotline、Promise
- 不是：CharacterState（那是某时刻的快照）

---

### Act（幕）

**定义**：卷内的叙事段落单元，通常对应三幕结构（建置/对抗/解决）中的一个阶段。

- 层级：Volume > Act > Chapter
- 用途：组织章节的叙事节奏
- 不是：Volume（卷是更大的物理分隔）

---

### Scene（场）

**定义**：章内一个连续的时空单元，有明确的开始和结束（时间跳跃或地点转换时分场）。

- 层级：Chapter > Scene
- 用途：写作时的最小叙事单元
- 不是：StoryBeat（节拍是场景内的情节动作）

---

### Chapter（章）

**定义**：小说的基本发布/阅读单元，对应一个 .md 文件。

- 存储：`{project}/第X章_标题.md`
- 层级：Act > Chapter > Scene
- 是写作流水线的操作对象
- 不是：Document（Document 是灵笔旧版通用文档概念）

---

### Story Beat（故事节拍）

**定义**：场景内的一个情节动作单元，描述"发生了什么"的最小粒度。

- 层级：Scene > StoryBeat
- 用途：故事画布中的编排单元
- 灵笔现状：已实现（StoryBeatsRepository）
- 不是：Scene（场是时空单元，节拍是动作单元）

---

### Promise（承诺）

**定义**：作者通过叙事向读者做出的显式或隐式承诺，如"主角会复仇""这个谜会解开"。

- 生命周期：创建 → 活跃 → 兑现/违背/过期
- 可引用：Plotline、CharacterArc
- 阻塞章节：到期未处理时审稿会标记为阻塞
- 不是：Foreshadowing（伏笔是手段，承诺是契约）

---

### Plotline（剧情线）

**定义**：一条连贯的剧情发展线，由多个章节中的事件串联而成。

- 生命周期：创建 → 活跃 → 高潮 → 收束
- 可引用：Promise、CharacterArc
- 阻塞章节：否（但审稿会警告未推进的剧情线）
- 不是：Promise（承诺是对读者的契约，剧情线是事件序列）

---

### Open Loop（开放回路）

**定义**：叙事中已打开但尚未关闭的信息缺口，读者期待其关闭。

- 是 Promise 和 Mystery 的上位概念
- 生命周期：打开 → 活跃 → 关闭/过期
- 不是：具体的 Promise 或 Mystery（那些有更明确的语义）

---

### Foreshadowing（伏笔）

**定义**：为未来事件预先埋下的叙事线索，在触发时产生"原来如此"的效果。

- 生命周期：埋设 → 活跃 → 触发/过期
- 可引用：Promise、Plotline
- 阻塞章节：否（但审稿会警告过期伏笔）
- 不是：Promise（伏笔是叙事技巧，承诺是读者契约）

---

### Mystery（悬念）

**定义**：读者不知道答案但期待揭示的信息，如"谁是凶手""主角的身世"。

- 生命周期：创建 → 活跃 → 揭示/过期
- 可引用：Promise
- 阻塞章节：否
- 不是：Foreshadowing（悬念是信息缺口，伏笔是预设线索）

---

### Settlement（结算）

**定义**：章节采纳后，系统自动从正文中提取客观事实并更新运行态的过程。

- 触发：采纳后自动执行
- 执行者：Settler Agent
- 输出：角色状态更新、关系变化、资源变化、章节摘要
- 来源：OpenWrite 状态结算
- 不是：Adoption（采纳是作者确认，结算是系统处理）

---

### Adoption（采纳）

**定义**：作者明确确认将 AI 候选输出接受为正式内容的动作。

- 触发：作者点击"采纳"按钮
- 效果：候选从 candidates/ 移入正文或正典
- 后续：触发 Settlement
- 来源：OpenWrite 事务提交 + DreamEngine 作者采纳（UNVERIFIED）
- 不是：Settlement（采纳是人的决策，结算是机器处理）

---

### Worldline（世界线）

**定义**：从正史某章分叉出的候选未来叙事，用于探索"如果……会怎样"。

- 生命周期：分叉 → 活跃 → 采纳/过期/归档
- 隔离规则：不能修改正史正文和正典
- 合并方式：必须经过写作流水线（写→审→采纳→结算）
- 灵笔差异化能力：是
- 不是：Branch（Branch 是世界线的技术实现单元）

---

### Snapshot（快照）

**定义**：某一时刻的项目状态完整副本，用于回滚和比较。

- 触发：写作前自动创建、采纳前创建、用户手动创建
- 存储位置：`{project}/.lingbi/snapshots/`
- 用途：事务回滚、版本比较、世界线分叉基准
- 不是：VersionHistory（版本历史是文档级的，快照是项目级的）

---

### Context Packet（上下文包）

**定义**：写作前为 AI 组装的结构化输入，包含写作所需的全部相关信息。

- 组成：15 层信息（见架构文档）
- 总预算：默认 8000 token
- 来源：OpenWrite canonical packet
- 不是：简单的 prompt（Context Packet 是结构化的、有来源追踪的）

---

### Memory（记忆）

**定义**：跨章节保持的信息持久化机制的总称，包括正典事实、运行态、章节摘要和语义索引。

- 分类：正典记忆（确定性）、运行记忆（推导性）、语义记忆（概率性）
- 铁律：语义记忆（向量召回）不能作为正典事实
- 来源：OpenWrite 有界章节记忆
- 不是：RAG（RAG 是记忆的检索手段，不是记忆本身）

---

### Skill（技能）

**定义**：可安装、可卸载的 AI 能力扩展单元，通过声明式配置定义权限和行为。

- 存储：SKILL.md + 配置
- 权限：不能自行获得额外写文件或联网权限
- 输出：默认为候选
- 灵笔现状：已实现基础版（SkillMarketplace）
- 不是：Agent（Agent 有自主决策能力，Skill 是被动触发的）

---

### Action（动作）

**定义**：通过 Action Surface 执行的一个原子操作，如"写章""审稿""采纳""结算"。

- 特征：有明确输入/输出、有权限检查、可回滚
- 所有入口（UI、Agent、Skill）共用同一套 Action
- 来源：OpenWrite action surface
- 不是：Task（Task 是 Action 的执行容器，有状态和生命周期）

---

## 术语关系图

```
Author Intent ──约束──→ Current Focus
       │                      │
       └──────┬───────────────┘
              ▼
       Context Packet ←── Canon (正典)
              │          ←── Runtime State (运行态)
              │          ←── Memory (记忆)
              ▼
         Writing Pipeline
              │
    ┌─────────┼─────────┐
    ▼         ▼         ▼
 Planner   Writer   Reviewer
    │         │         │
    ▼         ▼         ▼
Candidate Candidate  ReviewReport
              │
              ▼
          Adoption ──→ Manuscript (正文)
              │
              ▼
          Settlement ──→ Runtime State
              │
              ▼
     Promise / Plotline / Foreshadowing 更新
```

---

## 禁止一词多义清单

| 术语 | 是 | 不是 |
|------|-----|------|
| Canon | 已确认的世界观事实 | 运行态、候选、代码中的 Codex |
| Document | 灵笔旧版通用文档概念 | 章节（新版用 Chapter） |
| StoryBeat | 场景内情节动作 | 章节、场景 |
| Candidate | AI 未采纳输出 | 正文、正典 |
| Settlement | 采纳后的事实提取 | 采纳本身 |
| Memory | 跨章节信息持久化 | 单纯的向量搜索 |
| Worldline | 候选未来叙事 | 正史分支 |
| Skill | 被动触发的能力扩展 | 自主 Agent |
