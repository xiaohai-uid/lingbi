# 灵笔下一代架构 (Lingbi Next Architecture)

> 版本：1.0
> 日期：2026-07-24
> 来源：灵笔 × OpenWrite × DreamEngine 圆桌会议决议
> 状态：设计阶段，未实施

---

## 1. 产品定位

**灵笔 = 长篇小说创作工作台 (Long-form Novel Writing Workbench)**

- 面向个人小说作者的 Windows 桌面应用
- 核心能力：AI 辅助长篇写作 + 本地优先 + 世界线选择（未来）
- 不是：通用内容平台、SaaS 服务、团队协作工具

---

## 2. 核心原则

| # | 原则 | 来源 |
|---|------|------|
| 1 | 灵笔是唯一主项目 | 用户约束 |
| 2 | 正典只有一个正式来源（Markdown） | OpenWrite src/ 思想 |
| 3 | AI 输出默认是候选 | OpenWrite 事务回滚思想 |
| 4 | 采纳与结算分开 | OpenWrite 状态结算 |
| 5 | 向量库不是事实来源 | 可靠性要求 |
| 6 | 世界线不得污染正史 | 灵笔差异化设计 |
| 7 | 强模型只用于高价值决策 | 用户预算约束 |
| 8 | 便宜模型负责可验证执行 | 用户预算约束 |
| 9 | 本地模式必须始终可用 | 用户离线需求 |
| 10 | 不进行没有回滚方案的大重构 | 个人开发者约束 |
| 11 | 不为了多 Agent 而增加 Agent | 反方审查 |
| 12 | 不为了微服务而增加微服务 | 反方审查 |
| 13 | 不复制许可证不明确的代码 | OpenWrite LICENSE 404 |
| 14 | 每项架构能力必须有测试方法 | CI 门禁 |
| 15 | 每项建议必须说明来自哪个项目 | 证据化要求 |

---

## 3. 领域模型

```
Project (书)
├── Manuscript (正文)
│   ├── Volume (卷)
│   │   ├── Act (幕)
│   │   │   ├── Chapter (章)
│   │   │   │   └── Scene (场)
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── Canon (正典)
│   ├── Character (角色)
│   ├── Location (地点)
│   ├── Rule (世界规则)
│   └── Entity (实体)
├── Outline (大纲)
│   ├── Synopsis (总纲)
│   ├── VolumeOutline (卷纲)
│   └── ChapterOutline (章纲)
├── Narrative Tracking (叙事追踪)
│   ├── Promise (承诺)
│   ├── Plotline (剧情线)
│   ├── Foreshadowing (伏笔)
│   ├── Mystery (悬念)
│   └── CharacterArc (角色弧光)
├── Runtime State (运行态)
│   ├── CharacterState (角色当前状态)
│   ├── RelationshipLedger (关系账本)
│   ├── ResourceLedger (资源账本)
│   └── ChapterMemory (章节记忆)
├── Worldline (世界线) [Phase 6]
│   ├── DivergencePoint (分叉点)
│   ├── CandidateBranch (候选分支)
│   └── BranchSnapshot (分支快照)
└── Style (风格)
    ├── StyleRules (风格规则)
    └── StyleSources (风格来源)
```

---

## 4. 数据分层

```
┌─────────────────────────────────────────────────┐
│  Layer 1: Markdown Canon (正文 + 正典真源)       │
│  格式: .md + YAML frontmatter                   │
│  位置: {project_dir}/                           │
│  权限: 作者可编辑, AI 只读(除非采纳)            │
├─────────────────────────────────────────────────┤
│  Layer 2: JSON Runtime State (运行态)           │
│  格式: .json                                    │
│  位置: {project_dir}/.lingbi/runtime/           │
│  权限: 系统自动维护, 作者可查看                  │
├─────────────────────────────────────────────────┤
│  Layer 3: SQLite Index (索引)                   │
│  格式: .db                                      │
│  位置: {project_dir}/.lingbi/index.db           │
│  权限: 可重建, 非真源                           │
├─────────────────────────────────────────────────┤
│  Layer 4: Vector Index (向量索引)               │
│  格式: ZVec 或 JSON 降级                        │
│  位置: {project_dir}/.lingbi/vectors/           │
│  权限: 辅助搜索, 非事实来源                     │
├─────────────────────────────────────────────────┤
│  Layer 5: Snapshots (快照)                      │
│  格式: .json + .md 副本                         │
│  位置: {project_dir}/.lingbi/snapshots/         │
│  权限: 系统自动, 用于回滚                       │
├─────────────────────────────────────────────────┤
│  Layer 6: Task Journal (任务日志)               │
│  格式: .json                                    │
│  位置: {project_dir}/.lingbi/tasks/             │
│  权限: 系统维护, 用于恢复                       │
└─────────────────────────────────────────────────┘
```

**便携项目目录结构（兼容现有格式）：**

```
我的小说/
├── .lingbi/
│   ├── project.json          # 项目元数据（已有）
│   ├── runtime/
│   │   ├── character_state.json
│   │   ├── relationships.json
│   │   ├── promises.json
│   │   ├── plotlines.json
│   │   ├── foreshadowing.json
│   │   └── chapter_memory/
│   │       ├── ch_001.json
│   │       └── ch_002.json
│   ├── candidates/           # AI 候选输出
│   │   └── ch_003_draft.md
│   ├── snapshots/
│   ├── tasks/
│   ├── index.db
│   └── vectors/
├── 第一章.md                 # 正文真源
├── 第二章.md
├── canon/
│   ├── characters/
│   │   └── 林远舟.md
│   ├── locations/
│   └── rules.md
├── outline/
│   ├── synopsis.md
│   └── chapters/
│       └── ch_003.md
├── style/
│   ├── rules.md
│   └── sources/
└── story/
    ├── author_intent.md      # 创作罗盘：长期意图
    └── current_focus.md      # 创作罗盘：当前焦点
```

---

## 5. 状态机

### 写作流水线状态机

```
                    ┌──────────────────────────────────────┐
                    │                                      │
                    ▼                                      │
IDLE → PREFLIGHT → WRITING → REVIEWING → AWAITING_ADOPTION │
                                              │            │
                                         ┌────┴────┐       │
                                         ▼         ▼       │
                                      ADOPTED   REJECTED ──┘
                                         │
                                         ▼
                                      SETTLING → SETTLED → IDLE
                                         
任何阶段失败 → ROLLBACK → IDLE
```

### 状态说明

| 状态 | 含义 | 触发 |
|------|------|------|
| IDLE | 空闲，等待用户指令 | 初始/完成/回滚后 |
| PREFLIGHT | 预检：组装 Context Packet，验证前置条件 | 用户请求写作 |
| WRITING | AI 正在生成候选正文 | 预检通过 |
| REVIEWING | 审稿 Agent 评估候选 | 写作完成 |
| AWAITING_ADOPTION | 等待作者采纳/拒绝 | 审稿完成 |
| ADOPTED | 作者已采纳，候选成为正文 | 作者确认 |
| REJECTED | 作者拒绝，候选归档 | 作者拒绝 |
| SETTLING | 提取事实，更新运行态 | 采纳后自动 |
| SETTLED | 结算完成，运行态已更新 | 结算成功 |
| ROLLBACK | 回滚到写前快照 | 任何阶段失败 |

---

## 6. Action Surface

**所有入口（UI、AI Agent、Skill、CLI）共用同一个 Action Surface。**

```dart
abstract class NovelActionSurface {
  // 写作
  Future<Result<CandidateChapter>> writeChapter(WriteRequest req);
  Future<Result<ReviewReport>> reviewChapter(String chapterId);
  Future<Result<void>> adoptCandidate(String candidateId);
  Future<Result<void>> rejectCandidate(String candidateId);
  Future<Result<SettlementReport>> settleChapter(String chapterId);
  
  // 正典
  Future<Result<CanonEntry>> createCanon(CanonEntry entry);
  Future<Result<CanonEntry>> updateCanon(String id, CanonEntry entry);
  
  // 大纲
  Future<Result<ChapterOutline>> planChapter(PlanRequest req);
  
  // 叙事追踪
  Future<Result<Promise>> createPromise(Promise p);
  Future<Result<void>> resolvePromise(String id, Resolution r);
  Future<Result<Plotline>> createPlotline(Plotline p);
  Future<Result<Foreshadowing>> plantForeshadowing(Foreshadowing f);
  
  // 世界线 [Phase 6]
  Future<Result<WorldlineBranch>> createBranch(DivergencePoint dp);
  Future<Result<void>> adoptBranch(String branchId);
  
  // 上下文
  Future<ContextPacket> assembleContext(String chapterId);
  
  // 记忆
  Future<ChapterMemory> getChapterMemory(String chapterId);
}
```

**权限规则：**
- AI Agent 只能写入 `candidates/` 目录
- 只有 `adoptCandidate` 才能将候选移入正文
- 只有 `settleChapter` 才能更新运行态
- 正典修改必须经过作者确认

---

## 7. Agent 权限

| 角色 | 输入 | 输出 | 可读 | 可写 | 禁止 | 模型等级 | 失败降级 |
|------|------|------|------|------|------|---------|---------|
| Planner | 意图+焦点+大纲+运行态 | 候选章纲/卷纲 | 全部 | candidates/ | 写正文、写正典 | T1 | 提示用户 |
| Writer | Context Packet | 候选正文 | 全部 | candidates/ | 写正典、修改运行态 | T2 | 重试→T1 |
| Reviewer | 候选正文+正典+运行态 | 审稿报告 | 全部 | reviews/ | 修改正文、修改正典 | T1 | 降级 T2 |
| Settler | 已采纳正文+当前运行态 | 运行态更新 | 正文+运行态 | runtime/ | 写正典、写正文 | T3 | 重试 |

---

## 8. 上下文包 (Context Packet)

```dart
class ContextPacket {
  final String authorIntent;        // 层1: 500 token, 永不截断
  final String currentFocus;        // 层2: 300 token, 永不截断
  final String volumeActSummary;    // 层3: 400 token
  final String chapterOutline;      // 层4: 300 token
  final String previousChapter;     // 层5: 2000 token (正文或摘要)
  final List<CharacterCard> characters; // 层6: 800 token
  final String worldRules;          // 层7: 500 token
  final String characterStates;     // 层8: 400 token
  final String relationshipChanges; // 层9: 300 token
  final List<Promise> activePromises; // 层10: 300 token
  final List<Plotline> activePlotlines; // 层11: 300 token
  final List<Foreshadowing> dueForeshadowing; // 层12: 200 token
  final String styleRules;          // 层13: 400 token
  final String userInstruction;     // 层14: 200 token
  final String spoilerBlacklist;    // 层15: 100 token
  final int tokenBudget;            // 总预算: 默认 8000
  final Map<String, String> sourceTracking; // 数据来源追踪
}
```

**裁剪规则：**
- 超出预算时从层 15 → 层 3 逆序截断
- 层 1-2 永不截断
- 角色卡按本章相关性排序，只取 top-N
- 上一章超过 2000 token 时自动切换为摘要

---

## 9. 世界线模型 [Phase 6]

```dart
class WorldlineBranch {
  final String id;
  final String divergenceChapterId;  // 分叉点
  final DateTime createdAt;
  final DateTime? expiresAt;         // 过期时间
  final BranchStatus status;         // active/adopted/expired/archived
  final String canonSnapshotId;      // 分叉时的正典快照
  final List<String> candidateChapters; // 分支内的候选章节
  final String? comparisonSummary;   // 与正史的比较摘要
}

enum BranchStatus { active, adopted, expired, archived }
```

**铁律：**
1. 生成世界线 → 只写入 `candidates/worldlines/{branch_id}/`
2. 选择世界线 → 只标记 status，不修改正史
3. 合并世界线 → 触发写作流水线（写→审→采纳→结算）
4. 分支过期 → 默认 30 天，可配置

---

## 10. 记忆系统

| 记忆类型 | 存储位置 | 更新方式 | 用于 |
|---------|---------|---------|------|
| 正典事实 | canon/*.md | 作者采纳 | Context Packet 层 6-7 |
| 运行事实 | runtime/*.json | Settler 自动 | Context Packet 层 8-12 |
| 章节摘要 | runtime/chapter_memory/ | Settler 自动 | Context Packet 层 5 |
| 风格资料 | style/ | 作者管理 | Context Packet 层 13 |
| 语义索引 | vectors/ | 自动 | RAG 辅助召回 |
| 用户偏好 | .lingbi/settings.json | 用户设置 | 全局配置 |

**RAG 使用规则：**
- 向量召回只作为"可能相关"的提示
- 召回结果必须与正典真源交叉验证
- 召回结果不能直接写入 Context Packet 的正典层
- 召回结果标注来源为 `[RAG_SUGGESTION]`

---

## 11. 任务系统

```dart
class WritingTask {
  final String id;
  final TaskType type;          // write/review/settle/plan
  final TaskStatus status;      // pending/running/paused/completed/failed/cancelled
  final String chapterId;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? checkpoint;     // 中断点（用于恢复）
  final int retryCount;
  final String? error;
}
```

**设计决策：**
- 使用 Dart Isolate 执行后台任务（不需要独立服务）
- 任务日志写入 `.lingbi/tasks/` 目录
- 关闭窗口时：保存 checkpoint，下次启动恢复
- 同一本书同一时间只允许一个写作任务（文件锁）
- 任务可取消（CancellationToken）
- 失败最多重试 2 次

---

## 12. 模型路由

```dart
enum ModelTier { t1_strong, t2_standard, t3_economy }

class ModelRouter {
  ModelTier resolveTier(ActionType action) {
    switch (action) {
      case ActionType.plan:
      case ActionType.review:
      case ActionType.finalDecision:
        return ModelTier.t1_strong;
      case ActionType.write:
      case ActionType.extract:
      case ActionType.format:
        return ModelTier.t2_standard;
      case ActionType.settle:
      case ActionType.summarize:
      case ActionType.batchTask:
        return ModelTier.t3_economy;
    }
  }
}
```

**降级策略：**
- T1 失败 → 重试 1 次 → 降级 T2 → 提示用户
- T2 失败 → 重试 2 次 → 提示用户
- T3 失败 → 重试 3 次 → 跳过（标记待处理）

**成本统计：**
- 每次调用记录 token 用量（input + output）
- 按项目/章节/任务类型汇总
- 在设置页显示日/周/月成本估算

---

## 13. 技能系统

```yaml
# Skill 声明格式
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
validation:
  min_length: 100
  max_length: 10000
  must_contain_chapter_title: true
```

**权限铁律：**
- 技能不能自行获得额外写文件权限
- 技能不能自行联网
- 所有写操作必须经过 Action Surface
- 技能输出默认为候选

---

## 14. 可靠性

| 机制 | 实现方式 | 来源 |
|------|---------|------|
| 写作锁 | 文件级 `.lock` + 进程内 Mutex | OpenWrite 跨进程锁 |
| 事务提交 | 写前快照 → 执行 → 成功提交/失败回滚 | OpenWrite 事务回滚 |
| 版本快照 | VersionHistoryService（已有） | 灵笔现有 |
| 索引重建 | SQLite 可从 Markdown 真源重建 | 新设计 |
| 任务恢复 | Task Journal + checkpoint | 新设计 |
| 降级模式 | ServiceLocator.failed()（已有） | 灵笔现有 |
| 崩溃恢复 | 启动时检查 .lock 和 tasks/，提示恢复 | 新设计 |

---

## 15. 数据迁移

**原则：旧项目必须能直接打开。**

迁移策略：
1. 检测 `.lingbi/project.json` 版本号
2. 无 `runtime/` 目录 → 创建空运行态（不影响现有 .md 文件）
3. 无 `canon/` 目录 → 从 ZVec/JSON 中的 CanonEntry 导出为 .md
4. 无 `story/` 目录 → 创建空 author_intent.md 和 current_focus.md
5. 现有 .md 文件保持原位不动
6. 迁移是单向的（旧→新），不修改旧格式文件内容

**兼容保证：**
- 旧版灵笔打开新项目：忽略 `.lingbi/runtime/` 等新目录
- 新版灵笔打开旧项目：自动补充缺失目录，不修改现有文件

---

## 16. 安全边界

| 边界 | 规则 |
|------|------|
| AI → 正典 | 禁止直接写入，必须经过采纳 |
| AI → 正文 | 只能写入 candidates/，采纳后移入 |
| AI → 运行态 | 只有 Settler 在采纳后可更新 |
| Skill → 文件系统 | 只能写入 candidates/，不能写正典 |
| Skill → 网络 | 禁止自行联网 |
| 世界线 → 正史 | 禁止直接修改，必须经过写作流水线 |
| 向量库 → 正典 | 向量召回不能作为正典事实来源 |

---

## 17. 架构总览

```
Lingbi Desktop Experience (Flutter)
        ↓
Novel Action Surface (统一入口)
        ↓
Novel Application Service (模块化单体)
        ├─ ProjectModule
        ├─ CanonModule
        ├─ OutlineModule
        ├─ WritingPipelineModule
        ├─ ReviewModule
        ├─ AdoptionModule
        ├─ SettlementModule
        ├─ PromiseLedgerModule
        ├─ PlotlineLedgerModule
        ├─ CharacterArcModule
        ├─ ForeshadowingModule
        ├─ WorldlineModule [Phase 6]
        ├─ MemoryModule (RAG)
        ├─ SkillModule
        └─ ModelRouterModule
        ↓
Local Persistence
        ├─ Markdown Canon (正文+正典真源)
        ├─ JSON Runtime State (运行态)
        ├─ SQLite Index (可重建索引)
        ├─ Vector Index (辅助搜索)
        ├─ Snapshots (回滚用)
        └─ Task Journal (任务恢复)
```

**关键裁决：**
1. 采用模块化单体 ✓
2. 现有微服务保留为参考代码，不作为运行依赖 ✓
3. LiteLLM 保留为 Docker 可选部署，桌面端不依赖 ✓
4. 便携项目格式向后兼容 ✓
5. 旧数据通过版本检测自动迁移 ✓
