# 灵笔 × OpenWrite × DreamEngine 下一代架构圆桌会议

> 会议时间：2026-07-24
> 召集人：架构总召集人
> 仓库：`c:\codex\worktrees\lingbi-review-v1-mvr`
> 分支：`chore/ai-team-v1-mvr`
> HEAD commit：`f961960`

---

## 第一部分：证据清单

### 一、灵笔（Lingbi）本地仓库审计

| 检查项 | 状态 | 证据 |
|--------|------|------|
| Git 分支 | `chore/ai-team-v1-mvr` | `git branch` 输出 |
| 工作区 | 干净 | `nothing to commit, working tree clean` |
| HEAD | `f961960` feat: 技能市场完整实现 | `git log --oneline -1` |
| README | 存在，描述产品功能 | 根目录 README.md |
| CONTEXT.md | 存在，定义领域语言 | 5 个核心术语 + 12 个服务边界 |
| AGENTS.md | 存在，多 Agent 协作规范 | 含构建命令、架构、CI 门禁 |
| Flutter UI (lib/ui/) | IMPLEMENTED | 三栏布局、HomePage、ProjectPage、SettingsPage |
| UI V2 (lib/ui_v2/) | PARTIAL | FeatureFlag 控制，LingBiAppV3 存在 |
| AIService | IMPLEMENTED | 5 Provider + 自定义端点 + 流式/同步 |
| AI Provider 实现 | IMPLEMENTED | Free/SenseNova/DeepSeek/OpenAI/Claude |
| ModelRegistry | IMPLEMENTED | 4 平台静态配置，含模型列表 |
| ProjectService | IMPLEMENTED | 便携项目创建/打开，.lingbi/project.json |
| DocumentService | IMPLEMENTED | CRUD + .md 文件读写 + ZVec 元数据 |
| CanonService | IMPLEMENTED | 正典 CRUD + 语义搜索（ZVec） |
| CanonLinkingService | IMPLEMENTED | 文档中自动检测 Canon 提及 |
| StoryBeat/Storyboard | IMPLEMENTED | StoryBeatsRepository + JSON 存储 |
| VersionHistoryService | IMPLEMENTED | 版本快照 + 恢复 |
| ExportService | IMPLEMENTED | MD/TXT/PDF 导出 |
| SkillMarketplace | IMPLEMENTED | 17 技能 + 安装/卸载 + 本地/远程 |
| QuotaService | IMPLEMENTED | 每日配额管理 |
| SettingsService | IMPLEMENTED | 环境变量 + JSON 配置 |
| StorageService | IMPLEMENTED | JSON 文件存储（ZVec 降级） |
| SyncService | IMPLEMENTED | 文件系统 ↔ ZVec 双向同步 |
| ServiceLocator | IMPLEMENTED | 拓扑序初始化 + 降级模式 |
| 降级模式 (_LocalModeHome) | IMPLEMENTED | 纯 dart:io 文件操作 |
| Novel Engine 微服务 | PARTIAL | 3 层模型定义完整，main.dart 有递归 bug |
| Quality Review 微服务 | PARTIAL | 3 维审查管线（角色一致/爽点/格式） |
| Docker Compose | IMPLEMENTED | 15 个服务定义（含 LiteLLM） |
| LiteLLM 配置 | IMPLEMENTED | 4 模型路由 + 重试 + 超时 |
| 端到端测试 | IMPLEMENTED | 12 阶段全链路（真实 API） |
| 单元测试 | IMPLEMENTED | 7 个测试文件 |
| 写作锁 | UNKNOWN | 未发现实现 |
| 状态结算 | UNKNOWN | 未发现实现 |
| 承诺/剧情线/伏笔 | UNKNOWN | 未发现实现 |
| 世界线 | UNKNOWN | 未发现实现 |
| RAG/向量检索 | PARTIAL | ZVec 用于 Canon 搜索，非通用 RAG |
| 章节上下文包 | UNKNOWN | 仅简单 projectContext 字符串 |
| 模型路由（按任务分配） | UNKNOWN | 仅手动切换 Provider |
| 后台任务系统 | UNKNOWN | 未发现实现 |

### 二、OpenWrite（GitHub: LiPu-jpg/Openwrite）

| 检查项 | 状态 | 证据 |
|--------|------|------|
| 项目入口 | IMPLEMENTED | CLI `openwrite` + Studio + Goethe + Dante |
| Goethe（规划 Agent） | IMPLEMENTED | 长会话规划，灵感→资产→handoff |
| Dante（写作 Agent） | IMPLEMENTED | ReAct 主 agent，写章/审查/结算 |
| 单一真源 (src/) | IMPLEMENTED | src/ 为确认版，data/ 为运行态 |
| author_intent.md | IMPLEMENTED | 整本书长期创作承诺 |
| current_focus.md | IMPLEMENTED | 近期最高优先级约束 |
| canonical packet | IMPLEMENTED | 章节上下文组装（大纲+角色+世界+伏笔+上章） |
| 有界章节记忆 | IMPLEMENTED | data/memory/chapters/ 摘要+观察+token |
| truth files | IMPLEMENTED | current_state.md, ledger.md, relationships.md |
| relationship ledger | IMPLEMENTED | relationships.md |
| foreshadowing DAG | IMPLEMENTED | data/foreshadowing/dag.yaml |
| 章节工作流 | IMPLEMENTED | wf_ch_*.yaml + book_state.yaml |
| 写作锁 | IMPLEMENTED | 跨进程作品锁 |
| 事务回滚 | IMPLEMENTED | 任一步失败恢复写前快照 |
| 状态结算 | IMPLEMENTED | 写章后提取事实→结算运行态 |
| 37 维审稿 | IMPLEMENTED | 读取意图/罗盘/大纲/角色/关系/风格 |
| 风格来源提取与合成 | IMPLEMENTED | sources/ → manifest.toml → composed.md |
| action surface 统一 | IMPLEMENTED | CLI/Studio/Goethe/Dante 共用 |
| Studio (Web UI) | IMPLEMENTED | 127.0.0.1 本地，版本冲突检查 |
| 旧稿导入 | IMPLEMENTED | TXT/Markdown 导入 |
| 整书导出 | IMPLEMENTED | Markdown/TXT |
| multi-write 子流程 | IMPLEMENTED | director/writer/reviewer 编排 |
| LICENSE | UNKNOWN | GitHub 404，未找到许可证文件 |
| 测试 | UNKNOWN | README 提及 test_outputs/，未见测试代码 |
| 版本号 | v5.8.0 | README 标注 |

### 三、DreamEngine / 幻海 Opus

| 检查项 | 状态 | 证据 |
|--------|------|------|
| http://111.170.163.42:4650/ | **实际为 OpenWrite 官网** | 页面标题"OpenWrite - 智能小说写作助手"，v1.2.6 |
| DreamEngine 公开搜索 | NOT_FOUND | 搜索"幻海Opus""DreamEngine 小说"无相关结果 |
| 起源碑 | UNVERIFIED | 无公开资料 |
| 命运线 | UNVERIFIED | 无公开资料 |
| 承诺台账 | UNVERIFIED | 无公开资料 |
| Scene Intelligence | UNVERIFIED | 无公开资料 |
| PreFlight | UNVERIFIED | 无公开资料 |
| 审核队列/采纳 | UNVERIFIED | 无公开资料 |
| 场景结算 | UNVERIFIED | 无公开资料 |
| RAG/语义记忆 | UNVERIFIED | 无公开资料 |
| Hangfire/SignalR | UNVERIFIED | 无公开资料 |
| 服务器状态 | 该 IP 运行的是 OpenWrite 官网 | HTTP 200，内容为 OpenWrite |

**关键结论**：用户提供的 `http://111.170.163.42:4650/` 地址实际托管的是 **OpenWrite v1.2.6 官方下载页面**（含 Windows x64 和 Android ARM64 下载链接，指向 gitee.com/ymhlw/openwrite）。DreamEngine/幻海Opus 在公开互联网上无法找到任何可验证信息。

---

## 第二部分：十三名成员独立陈述

### 成员 1：主席兼产品负责人

**灵笔三大优势：**
1. **真正的桌面优先体验**：Flutter Windows 原生应用，不依赖浏览器或服务器。证据：`lib/main.dart` 降级模式可纯本地写作。
2. **多 Provider AI 接入已就绪**：5 个内置 Provider + 自定义 OpenAI-compatible 端点。证据：`ai_service.dart` L90-97 `registerCustomProvider`。
3. **便携项目格式已落地**：`.lingbi/project.json` + 纯 .md 文件，不依赖 SaaS。证据：e2e 测试阶段 1 和 11。

**灵笔五大结构性缺陷：**
1. **无长篇连续性机制**：没有章节上下文包、有界记忆、状态结算。AI 只看一个 `projectContext` 字符串。
2. **无写作流水线**：AI 续写是一次性调用，没有规划→写作→审稿→采纳→结算闭环。
3. **无剧情追踪**：没有承诺、伏笔、剧情线、角色弧光任何概念。
4. **微服务架构与本地优先矛盾**：docker-compose 定义 15 个服务，但桌面端完全不用它们。
5. **无作者控制权分层**：AI 输出直接追加到正文，没有候选/采纳机制。

**OpenWrite 最值得吸收的五项：**
1. 单一真源 (src/ vs data/) 分离
2. canonical packet 章节上下文组装
3. 写作锁 + 事务回滚
4. 状态结算（写后提取事实→更新运行态）
5. author_intent + current_focus 创作罗盘

**DreamEngine 最值得吸收的五项：**
无法评估。公开信息为零。标记为 UNVERIFIED。

**不适合当前灵笔的：**
- 15 微服务 Docker 部署（个人开发者维护成本过高）
- 多 Agent 数量膨胀（12+ 角色）
- 需要服务器才能使用的功能

**世界线之前必须完成：**
- 唯一真源契约
- 章节上下文包
- 写作流水线（写→审→采纳→结算）
- 候选/正史隔离

**可延后：**
- 云端协作
- 多人编辑
- 移动端

---

### 成员 2：灵笔现状审计员

**审计方法**：逐文件阅读 `lib/`、`services/`、`test/`、`docker-compose.yml`。

**关键发现：**

1. **README 与代码基本一致**：README 描述的功能（编辑器、AI 助手、正典、故事画布、导出）在代码中均有实现。
2. **Novel Engine 有代码缺陷**：`services/novel-engine/main.dart` 第 7 行 `serve` 函数递归调用自身，永远不会正常启动。
3. **微服务从未被桌面端调用**：`lib/` 中没有任何 HTTP 客户端调用 `localhost:8080-8093`。Docker 架构是独立存在的。
4. **Quality Review 只有 3 维**（角色一致性 0.4 + 爽点密度 0.35 + 格式 0.25），远非 OpenWrite 的 37 维。
5. **测试覆盖真实**：e2e 测试 387 行，覆盖 12 个阶段，使用真实 SenseNova API。
6. **ZVec 在 Windows 降级为 JSON**：`StorageService` 是实际持久化层。
7. **Canon 搜索是关键词匹配**，不是真正的向量语义搜索（ZVec 降级后）。

**状态标记汇总：**
- IMPLEMENTED：UI 编辑、AI 对话、正典 CRUD、版本历史、导出、技能市场、配额
- PARTIAL：Novel Engine（模型完整但入口有 bug）、Quality Review（3 维）、UI V2
- DOC_ONLY：微服务协作（docker-compose 定义但桌面端不用）
- UNKNOWN/缺失：写作锁、状态结算、承诺/伏笔、世界线、RAG、后台任务、模型路由

---

### 成员 3：OpenWrite 架构研究员

**核心架构提炼：**

OpenWrite 的内核是 **"一本小说 = 一条长期生产线"**，而非"一次 prompt = 一段文本"。

**可迁移设计（按优先级）：**

1. **src/ vs data/ 分离**：确认版真源（人可编辑）vs 运行态（机器维护）。灵笔当前 `.md` 文件既是真源也是唯一存储，缺少运行态层。
2. **canonical packet**：每章写作前组装完整上下文（大纲窗口+角色+世界规则+伏笔+上章正文+truth files+风格）。灵笔只有一个 `projectContext` 字符串。
3. **有界章节记忆**：每章写完后提取摘要+客观观察+token 用量，下一章只注入相关有界摘要。防止整本正文塞回模型。
4. **写作锁 + 事务回滚**：跨进程锁覆盖上下文读取→模型调用→最终提交。任一步失败恢复写前快照。
5. **创作罗盘**：author_intent（长期不变）+ current_focus（近期可调）作为最高优先级控制面。

**不适合灵笔的部分：**
- CLI-first 交互（灵笔是 GUI 桌面端）
- Python 生态（灵笔是 Dart/Flutter）
- 单模型环境变量配置（灵笔需要多 Provider 切换）
- 无 GUI 编辑器（灵笔有 Quill WYSIWYG）

**许可证风险：**
GitHub LICENSE 文件返回 404。**不得建议直接复制 OpenWrite 代码**。只能吸收设计思想并重新实现。

---

### 成员 4：DreamEngine 产品研究员

**研究结论：无法完成。**

- 用户提供的地址 `http://111.170.163.42:4650/` 实际是 OpenWrite 官网
- 搜索"DreamEngine""幻海Opus""起源碑""命运线""承诺台账""Scene Intelligence"均无相关结果
- 未找到任何公开域名、产品页面、使用文档或代码仓库

**所有 DreamEngine 相关功能标记为：`PUBLIC_DESCRIPTION_ONLY` 或 `UNVERIFIED`**

建议：如果用户有 DreamEngine 的内部文档或截图，可在后续补充。当前无法进行证据化比较。

---

### 成员 5：长篇小说总编辑

**核心关切：灵笔当前无法稳定写到 50 章以上。**

原因：
1. AI 续写只看当前文本 + 一个 projectContext 字符串，30 章后必然丢失前文信息
2. 没有角色状态追踪，角色会"复活"或性格突变
3. 没有承诺/伏笔管理，读者期待会被遗忘
4. 没有剧情线账本，支线会无限膨胀或消失

**必须吸收的能力：**
- 有界章节记忆（OpenWrite）：每章结算，下一章只注入相关摘要
- 角色状态追踪（OpenWrite truth files）：current_state.md
- 承诺/伏笔生命周期：创建→活跃→到期→兑现/过期
- 创作罗盘：防止 AI 在 50 章后偏离核心主题

**反对：**
- 反对只关注生成速度
- 反对没有审稿就直接保存
- 反对 AI 自动修改角色设定

---

### 成员 6：叙事系统设计师

**当前灵笔的叙事层级：只有 Project → Document（扁平）。**

需要设计：
```
Project (书)
├── Volume (卷)
│   ├── Act (幕)
│   │   ├── Chapter (章)
│   │   │   └── Scene (场)
│   │   └── ...
│   └── ...
└── 全局结构
    ├── Outline (大纲)
    ├── Plotline (剧情线)
    ├── Promise (承诺)
    ├── Foreshadowing (伏笔)
    └── CharacterArc (角色弧光)
```

**防止概念重叠的关键裁决：**
- StoryBeat 保留为"场景内的节拍单元"，不升级为章节
- Canon 保留为"世界观静态条目"，不包含动态状态
- 动态状态归入 Runtime State（truth files 等价物）

---

### 成员 7：世界线与互动叙事设计师

**世界线是灵笔的差异化能力，但必须在正史机制健全后才能做。**

设计原则：
1. 世界线 = 候选未来，不是正史
2. 生成世界线不能修改正文
3. 选择世界线不能自动修改正史
4. 只有显式写作+采纳才能推进正史
5. 分支有过期机制，防止无限膨胀

**前置依赖：**
- 候选/正史隔离机制
- 采纳工作流
- 快照系统
- 正典版本控制

---

### 成员 8：上下文与记忆工程师

**当前灵笔的上下文 = 一个字符串。这是最大的技术债。**

Chapter Context Packet 设计（按优先级排序）：

| 层 | 内容 | 最大 token | 来源 |
|----|------|-----------|------|
| 1 | 作者意图 (author_intent) | 500 | 正典 |
| 2 | 当前焦点 (current_focus) | 300 | 正典 |
| 3 | 当前卷/幕摘要 | 400 | 大纲 |
| 4 | 章纲 | 300 | 大纲 |
| 5 | 上一章正文或摘要 | 2000 | 记忆 |
| 6 | 相关角色卡 | 800 | 正典 |
| 7 | 相关世界规则 | 500 | 正典 |
| 8 | 角色当前状态 | 400 | 运行态 |
| 9 | 关系变化 | 300 | 运行态 |
| 10 | 有效承诺 | 300 | 运行态 |
| 11 | 活跃剧情线 | 300 | 运行态 |
| 12 | 即将到期伏笔 | 200 | 运行态 |
| 13 | 风格规则 | 400 | 正典 |
| 14 | 用户临时指令 | 200 | 会话 |
| 15 | 禁止泄露内容 | 100 | 正典 |
| **总计** | | **~7000** | |

裁剪规则：超出预算时，按层号从低优先级开始截断。

---

### 成员 9：Agent 编排工程师

**当前灵笔没有 Agent 概念。AIService 是一个简单的路由。**

建议保留的 Agent 角色（合并后）：

| 角色 | 职责 | 默认模型 |
|------|------|---------|
| Planner | 规划章纲、卷纲、结构 | 强模型 |
| Writer | 执行正文写作 | 便宜模型 |
| Reviewer | 审稿（连续性+风格+结构） | 强模型 |
| Settler | 状态结算（提取事实→更新运行态） | 便宜模型 |

**不需要的角色：**
- 独立的 Context Engineer（由流水线自动组装）
- 独立的 Reviser（合并到 Writer）
- 独立的 Observer（合并到 Settler）
- 独立的 Continuity Checker（合并到 Reviewer）
- 独立的 Style Checker（合并到 Reviewer）
- 独立的 Researcher（由 Skill 系统处理）
- 独立的 Worldline Simulator（延后）

**4 个角色足够。不超过 5 个。**

---

### 成员 10：桌面产品与 UX 设计师

**灵笔的桌面编辑体验是核心资产，不能丢。**

必须保留：
- Flutter Quill WYSIWYG 编辑器
- 三栏布局（sidebar + editor + AI panel）
- 多项目 Tab
- 深色模式
- 本地文件直接编辑

需要新增的 UX：
- 写作任务面板（显示当前流水线状态）
- 流式预览（AI 写作时实时显示）
- 审核队列（待采纳的 AI 输出列表）
- 采纳/拒绝按钮（diff 视图）
- 正典保护提示（AI 试图修改正典时弹窗确认）

**普通作者不需要知道底层文件结构。**

---

### 成员 11：可靠性与数据工程师

**当前灵笔的数据可靠性：基本可用但脆弱。**

已有：
- 版本快照（VersionHistoryService）
- 降级模式（ServiceLocator.failed()）
- 原子写（SkillMarketplace._writeSkillFile）

缺失：
- 写作锁（两个操作同时修改同一文档）
- 事务提交（AI 续写一半断电）
- 索引重建（ZVec/JSON 损坏后）
- 后台任务恢复（关闭窗口后任务丢失）

**设计建议：**
- 写作锁：文件级 `.lock` + 进程内 mutex
- 事务：写前快照 → 执行 → 成功则提交，失败则回滚
- 任务日志：JSON 文件记录任务状态，重启后可恢复
- 不需要 Hangfire，本地 Isolate + Timer 足够

---

### 成员 12：模型路由与成本工程师

**当前灵笔：用户手动切换 Provider，没有按任务分配。**

设计：

| 任务 | 模型等级 | 示例 |
|------|---------|------|
| 架构规划、关键剧情决策 | T1 强模型 | Claude Sonnet 4, GPT-4o |
| 审稿、最终裁决 | T1 强模型 | 同上 |
| 信息提取、初稿执行 | T2 便宜模型 | DeepSeek Chat, GPT-4o-mini |
| 格式转换、批量任务 | T2 便宜模型 | 同上 |
| 状态结算、摘要 | T3 最便宜 | SenseNova Flash Lite |

**失败降级**：T1 失败 → 重试 → 降级到 T2 → 提示用户
**配额**：按 token 计量，不按次数

---

### 成员 13：反方审查员

**攻击清单：**

1. **15 微服务是过度设计**：docker-compose 定义 15 个服务，但桌面端一个都不用。这是"为了微服务而微服务"。个人开发者维护 15 个 Docker 容器是不现实的。
2. **Novel Engine 从未真正运行**：main.dart 有递归 bug，这个服务从未成功启动过。
3. **多 Agent 膨胀风险**：有人提议 12 个 Agent 角色，这是伪需求。4 个足够。
4. **RAG 不能代替正典**：向量召回是概率性的，正典事实必须是确定性的。
5. **AI 自动修改设定是危险的**：必须有候选→采纳机制。
6. **OpenWrite 许可证不明**：不能复制代码，只能吸收思想。
7. **一次性大重构会杀死项目**：必须增量迁移。
8. **只有 UI 没有后台流程**：当前 AI 续写没有审稿、没有结算、没有锁。
9. **DreamEngine 信息为零**：不能基于不存在的信息做架构决策。

---

## 第三部分：十个专题辩论

### 专题一：灵笔到底是什么产品

**辩论：**
- 主席：灵笔的核心用户是个人小说作者，不是团队，不是平台。
- 总编辑：必须是"长篇小说生产系统"，不能只是编辑器。
- UX 设计师：但不能让普通作者面对"生产系统"的复杂度。
- 反方：不要做"小说操作系统"，那是过度设计。

**裁决：灵笔 = 长篇小说创作工作台（Long-form Novel Writing Workbench）**

辅助能力：AI 写作助手、世界线创作工具（未来）。
不是：通用内容平台、小说操作系统、项目管理平台。

---

### 专题二：唯一真源

**裁决：**
- **Markdown 文件是正文唯一真源**（.md 文件在磁盘上）
- **JSON 保存结构化运行态**（角色状态、承诺、伏笔、剧情线）
- **SQLite 只保存索引和检索数据**（可重建）
- **向量库不是事实来源**（只用于相似度搜索辅助）
- **正典条目用 Markdown + YAML frontmatter**（人可读可编辑）

冲突检测：文件 mtime + 内容 hash。用户手工编辑后触发 sync。

---

### 专题三：写作主流水线

**比较：**
- 方案 A（直接生成）：当前灵笔。快但不可控。
- 方案 B（规划→写作→审稿→保存）：基本闭环。
- 方案 C（Preflight→写作→审稿→采纳→结算）：OpenWrite 模式。
- 方案 D（规划→多分支推演→选择→写作→审稿→采纳→结算）：世界线模式。

**裁决：采用方案 C 为基础，方案 D 为世界线扩展。**

正式状态机：
```
IDLE → PREFLIGHT → WRITING → REVIEWING → AWAITING_ADOPTION → ADOPTED → SETTLING → SETTLED
                                         → REJECTED → (回到 WRITING 或 IDLE)
任何阶段失败 → ROLLBACK → IDLE
```

---

### 专题四：承诺、剧情线、伏笔的边界

| 概念 | 定义 | 生命周期 | 可引用 | 阻塞章节 |
|------|------|---------|--------|---------|
| Promise | 作者对读者的显式承诺（如"主角会复仇"） | 创建→活跃→兑现/违背 | 剧情线、角色弧 | 是（到期未处理） |
| Plotline | 一条连贯的剧情发展线 | 创建→活跃→高潮→收束 | 承诺、角色弧 | 否 |
| Foreshadowing | 为未来事件埋下的线索 | 埋设→活跃→触发/过期 | 承诺、剧情线 | 否（但审稿警告） |
| Mystery | 读者不知道但角色可能知道的信息 | 创建→活跃→揭示 | 承诺 | 否 |
| CharacterArc | 角色从 A 状态到 B 状态的变化轨迹 | 起点→发展→转折→终点 | 剧情线、承诺 | 否 |

---

### 专题五：章节上下文（Chapter Context Packet）

见成员 8 陈述。补充裁剪规则：
- 总预算默认 8000 token（可由用户调整）
- 超出时按优先级从 15→1 逆序截断
- 层 1-2（作者意图+焦点）永不截断
- 每类信息标注数据来源（正典/运行态/记忆/会话）

---

### 专题六：记忆与 RAG

**分类：**
| 类型 | 存储 | 可修改 | 用于 |
|------|------|--------|------|
| 正典事实 | Markdown | 仅作者采纳 | 上下文包层 6-7 |
| 运行事实 | JSON | 结算自动更新 | 上下文包层 8-12 |
| 章节摘要 | JSON | 结算自动生成 | 上下文包层 5 |
| 风格资料 | Markdown | 作者管理 | 上下文包层 13 |
| 语义记忆 | 向量索引 | 自动 | RAG 辅助召回 |
| 用户偏好 | JSON | 用户设置 | 全局 |

**铁律：向量召回结果只作为参考，不作为正典事实。正典事实必须来自 Markdown 真源文件。**

---

### 专题七：世界线

**设计：**
- **Divergence Point**：从正史某章分叉
- **Candidate Worldline**：候选未来，独立沙箱
- **Canon Snapshot**：分叉时冻结正典快照
- **Branch Comparison**：并排比较候选与正史
- **Branch Selection**：作者选择采纳哪个候选
- **Branch Merge**：将候选内容合并回正史（需显式写作+采纳）
- **Branch Expiration**：超过 N 天未操作的分支自动归档
- **Branch Adoption**：只有显式采纳才能推进正史

**铁律：**
```
生成世界线不能修改正文。
选择世界线不能修改正史。
只有显式写作和采纳动作才能推进正史。
```

---

### 专题八：Agent 与模型路由

**最终保留 4 个角色：**

| 角色 | 输入 | 输出 | 可读 | 可写 | 禁止 | 模型 | 失败降级 |
|------|------|------|------|------|------|------|---------|
| Planner | 意图+焦点+大纲 | 章纲/卷纲 | 正典+运行态 | 候选大纲 | 写正文 | T1 | 提示用户 |
| Writer | Context Packet | 候选正文 | 全部 | 候选区 | 写正典 | T2 | 重试→T1 |
| Reviewer | 候选正文+正典 | 审稿报告 | 全部 | 审稿记录 | 修改正文 | T1 | 降级 T2 |
| Settler | 已采纳正文 | 运行态更新 | 正文+运行态 | 运行态 | 写正典 | T3 | 重试 |

---

### 专题九：桌面端与后台任务

**裁决：**
- Flutter 继续作为主界面 ✓
- 后台任务使用 Dart Isolate（不需要独立服务）
- 不需要 Hangfire 等价（本地单用户，Timer + Isolate 足够）
- 流式输出通过 StreamController 恢复
- 关闭窗口后：当前任务保存检查点，下次启动恢复
- 任务可中止（取消 token）
- 同一本书用文件锁防并发
- **不需要 15 个微服务。模块化单体足够。**

---

### 专题十：技能系统

**升级方向：每个 Skill 声明权限和能力。**

```yaml
id: smart-continuation
name: 智能续写
version: 2.0.0
applies_to: [chapter, scene]
triggers: [user_request, pipeline_step]
required_context: [context_packet, style_rules]
allowed_actions: [generate_candidate]
read_permissions: [canon, runtime_state, memory]
write_permissions: [candidate_zone]
preferred_model_tier: T2
output_schema: candidate_chapter
validation: min_length_100
```

**铁律：技能不得自行获得额外写文件或联网权限。所有写操作必须经过 Action Surface。**

---

## 第四部分：交叉质询

### 反方审查员质询主席：
"你说灵笔是'长篇小说创作工作台'，但当前连基本的章节层级都没有。Project → Document 是扁平的。你确定不是先做编辑器再做系统？"

**主席回应**：是的，Phase 1 先统一数据契约，不急于加层级。但定位必须是工作台，不能永远只是编辑器。

### 反方审查员质询 Agent 工程师：
"你说 4 个 Agent 足够，但 OpenWrite 有 director/writer/reviewer 子流程。你怎么处理 multi-write？"

**Agent 工程师回应**：multi-write 是 Writer 内部的子步骤编排，不是独立 Agent。Writer 可以内部调用 draft→refine→finalize，但对外仍是一个 Writer 角色。

### 总编辑质询上下文工程师：
"8000 token 预算够吗？写到 100 章时相关角色可能有 20 个。"

**上下文工程师回应**：不够时按相关性排序，只注入本章相关角色（通过大纲和上章提及计算）。不是所有角色都注入。

### UX 设计师质询可靠性工程师：
"文件锁会不会让普通作者困惑？"

**可靠性工程师回应**：锁是内部的，用户看不到。只在极端情况（崩溃恢复）才提示。

---

## 第五部分：少数意见

1. **成员 7（世界线设计师）**：认为世界线应该在 Phase 3 就开始原型验证，而非 Phase 6。理由：世界线需要候选/正史隔离，这个机制越早建立越好。
   - **驳回理由**：没有写作流水线就没有"候选"概念，隔离机制无从谈起。

2. **成员 12（成本工程师）**：认为应该保留 LiteLLM 作为可选的模型路由层。
   - **部分采纳**：LiteLLM 保留为 Docker 部署的可选项，但桌面端不依赖它。

3. **成员 3（OpenWrite 研究员）**：认为应该直接采用 OpenWrite 的 src/data 目录结构。
   - **部分采纳**：吸收分离思想，但目录结构适配灵笔的便携项目格式。

---

## 第六部分：最终投票

| 决议 | 赞成 | 反对 | 弃权 |
|------|------|------|------|
| 灵笔定位为长篇小说创作工作台 | 12 | 0 | 1 |
| 采用模块化单体，暂停微服务 | 11 | 1 | 1 |
| Markdown 为正文唯一真源 | 13 | 0 | 0 |
| AI 输出默认为候选 | 13 | 0 | 0 |
| 4 个 Agent 角色 | 10 | 2 | 1 |
| 世界线放 Phase 6 | 9 | 3 | 1 |
| 不复制 OpenWrite 代码 | 13 | 0 | 0 |
| DreamEngine 信息不足，不做架构依赖 | 13 | 0 | 0 |

---

## 第七部分：决议

1. **灵笔继续作为唯一主项目**，定位为"长篇小说创作工作台"。
2. **采用模块化单体架构**，现有微服务代码保留为参考但不作为运行依赖。
3. **Markdown 是正文唯一真源**，JSON 是运行态，SQLite 是索引，向量库是辅助。
4. **AI 输出默认是候选**，必须经过采纳才能成为正史。
5. **采纳与结算分开**：采纳是作者确认，结算是系统提取事实更新运行态。
6. **世界线不得污染正史**，只有显式写作+采纳才能推进正史。
7. **强模型只用于高价值决策**（规划、审稿、裁决），便宜模型负责执行。
8. **本地模式必须始终可用**，不依赖任何服务器。
9. **不进行没有回滚方案的大重构**。
10. **不复制许可证不明确的代码**（OpenWrite LICENSE 404）。
11. **4 个 Agent 角色**：Planner、Writer、Reviewer、Settler。
12. **DreamEngine 相关信息全部标记为 UNVERIFIED**，不作为架构依据。

---

## 评分矩阵

| 维度 | 灵笔 | OpenWrite | DreamEngine |
|------|-----:|----------:|------------:|
| 桌面写作体验 | 4 | 2 | UNVERIFIED |
| 本地优先 | 4 | 4 | UNVERIFIED |
| 长篇连续性 | 1 | 4 | UNVERIFIED |
| 唯一真源 | 2 | 5 | UNVERIFIED |
| 上下文治理 | 1 | 5 | UNVERIFIED |
| 状态结算 | 0 | 4 | UNVERIFIED |
| 审稿闭环 | 1 | 4 | UNVERIFIED |
| 作者控制权 | 2 | 4 | UNVERIFIED |
| 世界线 | 0 | 0 | UNVERIFIED |
| RAG 与记忆 | 1 | 3 | UNVERIFIED |
| 模型路由 | 2 | 2 | UNVERIFIED |
| 技能扩展 | 3 | 1 | UNVERIFIED |
| 任务恢复 | 1 | 3 | UNVERIFIED |
| 数据可迁移性 | 4 | 4 | UNVERIFIED |
| 个人开发可维护性 | 3 | 4 | UNVERIFIED |
| 产品成熟度 | 2 | 4 | UNVERIFIED |

**评分证据：**
- 灵笔桌面写作体验 4 分：有 Quill WYSIWYG + 三栏布局 + 多 Tab + 深色模式，但无流式预览和审核队列
- 灵笔长篇连续性 1 分：只有简单 projectContext 字符串，无有界记忆
- OpenWrite 唯一真源 5 分：src/ vs data/ 严格分离，有 sync 命令，有版本冲突检查
- OpenWrite 上下文治理 5 分：canonical packet 有明确组成和组装代码
- DreamEngine 全部 UNVERIFIED：公开互联网无任何可验证信息
