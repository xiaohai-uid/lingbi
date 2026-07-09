# 灵笔 v3.0 — AI Novel Engine

> OpenSpec Change Proposal | 将灵笔从"写作工具"升级为"AI 小说创作平台"

---

## 1. 问题陈述

### 1.1 现状

灵笔 v2.0.0 已具备完整的写作工具功能：WYSIWYG 编辑器、项目/文档管理、AI 对话、版本历史、导出导入、Codex 世界构建、故事画布。但 AI 能力停留在"对话式辅助"层面：

- **AI Provider** 接口简单，缺少统一错误处理、流式过滤、重试机制
- **写作辅助** 仅支持续写/分析，没有完整的"创意→大纲→正文"生成管线
- **Prompt 管理** 硬编码在代码中，无法按类型/风格切换
- **质量保障** 无自动审查机制，生成内容质量不可控
- **世界构建** 仅有基础的 Codex 条目，缺少关系图谱和事件追踪

### 1.2 机遇

`F:\AI_NovelGenerator` 项目（半成品）中已验证了以下能力：

| 模块 | 行数 | 成熟度 |
|------|:----:|:------:|
| LLM 抽象层 (`base_client.py`) | 11KB | 生产级：ThinkStreamFilter、错误层次、Schema 处理 |
| 三层生成管线 (`expand_idea_service.py`) | 44KB | 已验证：梗概→细纲→正文全链路 |
| 质量审查 (`review_pipeline.py`) | 7KB | 可运行：角色一致性+爽点密度+格式审查 |
| Prompt 工程 (`prompt_default.yaml`) | 8.9KB | 起点爆款优化版 Prompt |
| Novel Architect Skill (`SKILL.md`) | 55KB | 完整小说创作方法论 |

---

## 2. 目标

### 2.1 一句话目标

> 为灵笔注入商业级 AI 小说生成能力，让用户从"手动写作"变为"AI 辅助创作"。

### 2.2 成功指标

| 指标 | 当前 | 目标 |
|------|:----:|:----:|
| AI 生成连贯章节的成功率 | 无管线 | ≥80%（Layer 3） |
| 从创意到第一章的时间 | 手动编写 | ≤5 分钟 |
| 角色一致性违规率 | 无检测 | ≤2 次/万字 |
| Provider 切换响应时间 | ~500ms | ≤200ms |
| 测试覆盖率（AI 模块） | ~20% | ≥80% |

---

## 3. 架构设计

### 3.1 系统架构（v2.0 → v3.0）

```
v2.0 架构（当前）:

┌─────────────────────────────────────────────┐
│              Flutter 客户端                    │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ Sidebar │ │  Editor   │ │  AI Panel    │  │
│  │ (项目树) │ │ (Quill)   │ │ (简单对话)   │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │      Services (简单 Provider 调用)      │  │
│  └────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────┘
                      │ HTTP
┌─────────────────────▼───────────────────────┐
│          API Gateway :8080                    │
│  ┌───┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐      │
│  │AI │ │Pj │ │Doc│ │Cx│ │Ex│ │Vr│ │...│      │
│  │8081│ │8082│ │8083│ │..│ │..│ │..│ │  │      │
│  └───┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘      │
└─────────────────────────────────────────────┘


v3.0 架构（目标）:

┌─────────────────────────────────────────────────────┐
│              Flutter 客户端（增强）                    │
│  ┌─────────┐ ┌──────────┐ ┌──────────────────────┐  │
│  │ Sidebar │ │  Editor   │ │  AI Panel v2         │  │
│  │ (项目树) │ │ (Quill)   │ │  ├─ 对话 (续写/分析) │  │
│  └─────────┘ └──────────┘ │  ├─ 生成管线          │  │
│  ┌────────────────────────┴──┤  ├─ 质量审查面板     │  │
│  │   LLM Client Layer        │  └─ Prompt 选择器   │  │
│  │   (BaseLLMClient)         │                     │  │
│  │   ├─ OpenAICompatible     │                     │  │
│  │   ├─ ClaudeClient         │                     │  │
│  │   └─ GeminiClient         │                     │  │
│  └────────────────────────┬──┘                     │
└───────────────────────────┬─────────────────────────┘
                            │ HTTP / SSE
┌───────────────────────────▼─────────────────────────┐
│          API Gateway :8080                            │
│  ┌───┐ ┌──┐ ┌──┐ ┌───┐ ┌───┐ ┌──┐ ┌───┐ ┌───┐    │
│  │AI │ │Pj │ │Doc│ │ NE │ │ QR │ │Cx │ │.. │ │Sync│   │
│  │8081│ │8082│ │8083│ │8092│ │8093│ │.. │ │   │ │   │   │
│  └───┘ └──┘ └──┘ └───┘ └───┘ └──┘ └───┘ └───┘    │
│                                  │       │           │
│  ┌───────────────────────────────▼───────▼───────┐   │
│  │           Novel Engine (新增)                   │   │
│  │  Layer1 → Layer2 → Layer3 → Review              │   │
│  └───────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 3.2 微服务新增

| 服务 | 端口 | 语言 | 职责 |
|------|:----:|:----:|------|
| `novel-engine` | 8092 | Dart | 三层生成管线编排 |
| `quality-review` | 8093 | Dart | 质量审查（未来独立服务） |

### 3.3 Flutter 客户端新增/修改

| 模块 | 类型 | 说明 |
|------|:----:|------|
| `lib/core/ai/base_client.dart` | **新建** | LLM 抽象基类 |
| `lib/core/ai/llm_factory.dart` | **新建** | 工厂模式 |
| `lib/core/ai/llm_errors.dart` | **新建** | 错误层次 |
| `lib/core/ai/llm_models.dart` | **新建** | 请求/响应模型 |
| `lib/core/ai/retry_handler.dart` | **新建** | 指数退避重试 |
| `lib/core/ai/schema_processor.dart` | **新建** | 结构化输出处理 |
| `lib/core/ai/think_stream_filter.dart` | **新建** | 思考标签过滤 |
| 现有 4 个 Provider | **修改** | 适配新 BaseLLMClient 接口 |
| `lib/services/ai_service.dart` | **修改** | 简化，委托给工厂 |
| `lib/services/prompt_service.dart` | **新建** | Prompt 管理 |
| `lib/services/quality/` | **新建** | 质量审查模块 |
| `lib/ui/pages/prompt_editor_page.dart` | **新建** | Prompt 编辑器 |
| `lib/ui/layout/ai_panel/` | **修改** | 新增生成管线面板 |

---

## 4. 阶段规划

### Phase 3.1: LLM Provider 抽象层重构 (P0)

**依赖:** 无（可独立开发）
**预计:** 3-5 天
**测试:** 15+ 测试用例

将灵笔的 AI Provider 从简单的接口实现升级为完整的 LLM 抽象层：

```
现状                    → 目标
─────────────────────────────────────
AIProvider (interface)  → BaseLLMClient (abstract class)
  generate(prompt)        generateText(LLMRequest)
  streamGenerate(prompt)  streamText(LLMRequest) [SSE]
                          generateStructured<T>(req, parser)
                          
                          ThinkStreamFilter (推理标签过滤)
                          LLMFactory (插件式注册)
                          RetryHandler (指数退避)
                          SchemaProcessor (结构化输出)
```

**关键接口设计:**

```dart
// 抽象基类
abstract class BaseLLMClient {
  String get providerName;
  
  Future<String> generateText(LLMRequest request);
  Stream<String> streamText(LLMRequest request);
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  );
}

// 请求/响应模型
class LLMRequest {
  final List<Map<String, String>> messages;
  final String? systemPrompt;
  final double? temperature;
  final int? maxTokens;
  final Map<String, dynamic>? responseSchema;  // JSON Schema
  // ...
}

class LLMResponse {
  final String content;
  final TokenUsage? usage;
  final String? finishReason;
  final Duration latency;
}

// 错误层次
sealed class LLMException implements Exception {
  final String message;
  final String provider;
}
class LLMAuthException extends LLMException { ... }
class LLMRateLimitException extends LLMException { ... }
class LLMTimeoutException extends LLMException { ... }
class LLMResponseException extends LLMException { ... }
```

**ThinkStreamFilter 移植:**

```dart
/// 流式文本过滤器，跨 chunk 移除 <think>...</think> 内容
class ThinkStreamFilter {
  String _buffer = '';
  bool _insideThink = false;
  
  String feed(String chunk) { ... }
  String finish() { ... }
}
```

### Phase 3.2: 三层生成管线 (P0)

**依赖:** Phase 3.1（LLM 抽象层需就绪）
**预计:** 5-7 天
**测试:** 20+ 测试用例

**三层架构:**

```
用户创意 (100-500 字)
    │
    ▼
Layer 1: 梗概·人设生成器
    ├─ 输入: 创意 + 类型 + 风格
    ├─ 调用: generateStructured<SynopsisAndCharacters>()
    ├─ 输出: 故事梗概(500-1000字) + 核心人设(3-8个)
    └─ 重试: 3 次指数退避
    │
    ▼
Layer 2: 卷·章细纲生成器
    ├─ 输入: Layer 1 输出 + 卷数/章数
    ├─ 调用: generateStructured<LayeredNovelStructure>()
    ├─ 输出: 分卷结构 + 每卷章节细纲 + 每章3-5场景
    └─ 降级: → expand_idea_v2 (单层生成)
    │
    ▼
Layer 3: 逐场景正文生成器
    ├─ 输入: Layer 2 输出 + 场景编号
    ├─ 调用: streamText() [SSE]
    ├─ 输出: 流式场景正文 (500-2000字/场景)
    └─ 并行: 同卷内场景可并行生成
```

**微服务 API:**

```
POST /api/v1/novel/generate-layer1
  Request:  { userIdea, genre, style, numCharacters }
  Response: { synopsis, characters[], setting, themes[] }

POST /api/v1/novel/generate-layer2
  Request:  { layer1, numVolumes, chaptersPerVolume }
  Response: { volumes: [{ title, summary, chapters: [{ title, summary, scenes: [{ ... }] }] }] }

GET /api/v1/novel/generate-layer3?volume=0&chapter=0&scene=0
  Response: SSE stream
  event: chunk     data: {"text": "...", "sceneComplete": false}
  event: complete  data: {"text": "全文", "sceneComplete": true, "wordCount": 1234}
```

**降级策略:**

```dart
Future<NovelOutput> generateWithFallback(LLMService service, String idea) async {
  try {
    return await generateLayer3(service, idea);  // 三层
  } on OutOfTokensException {
    return await generateLayer2Compact(service, idea);  // 降级为二层
  } on TimeoutException {
    return await generateLayer1Only(service, idea);  // 降级为一层
  }
}
```

### Phase 3.3: 网文 Prompt 工程 + 类型库 (P1)

**依赖:** 无（可独立开发）
**预计:** 2-3 天

从 `prompt_default.yaml` 移植起点爆款 Prompt 模板：

```yaml
# assets/prompts/novel/prompts.yaml
prompts:
  expand_idea:
    qidian_bestseller:
      name: "起点爆款"
      description: "起点中文网万订爆款风格 - 爽感优先"
      system_prompt: |
        你是一名资深网文编辑，精通起点中文网文的爆款创作逻辑。
        【创作理念】起点爆款网文的核心是"爽感"...
      constraints:
        min_chars: 3000
        max_chars: 30000
        rules:
          - "冲突前置：开篇3-5%篇幅内必须出现强力冲突"
          - "金手指设计：主角必须有独特优势"
          - "期待感：每个章节结尾留下钩子"
          - "打脸爽感：主角反击反派的场景要有张力"
    
    fanqie_passion:
      name: "番茄爽文"
      description: "番茄小说快节奏爽文 - 每500字一个爽点"
      # ...
```

类型化写作指南从 `skill/novel-architect/` 迁移：

```yaml
# assets/prompts/novel/genres/fantasy.yaml
fantasy_worldbuilding:
  sanderson_laws:
    first: "读者对魔法的享受程度与对它的理解程度成正比"
    second: "限制比能力更有趣"
    third: "在添加新内容之前，先拓展已有的"
  magic_system_design:
    - energy_source: "魔法来源？有限还是无限？"
    - rules_of_use: "谁能使用？需要什么条件？"
    - costs: "使用魔法的代价是什么？"
    - limits: "明确什么是做不到的"
```

### Phase 3.4: 质量审查管线 (P1)

**依赖:** Phase 3.1（LLM 抽象层）
**预计:** 3-4 天
**测试:** 15+ 测试用例

```dart
// 角色一致性
class CharacterConsistencyResult {
  bool isConsistent;
  int deviationScore;           // 0-100
  String reason;
  List<CharacterIssue> issues;
}

// 爽点密度
class HookDensityResult {
  List<HookEvent> hookEvents;
  double density;               // 爽点数/1000字
  double targetDensity;         // 番茄: ≥2.0/1000字
  bool meetsRequirement;
}

// 综合审查
class ReviewReport {
  double overallScore;           // 0-10
  EditorFeedback? editorFeedback;
  CharacterConsistencyResult? consistency;
  HookDensityResult? hookDensity;
  FormatReviewResult? format;
  bool needsRewrite;
  String rewriteReason;
  List<String> suggestions;
}

// 审查管线编排
class ReviewPipeline {
  Future<ReviewReport> review(String text, {String platform = 'qidian'}) async {
    final tasks = <Future>[
      _checkCharacterConsistency(text),
      _calculateHookDensity(text, platform),
      _checkFormat(text),
    ];
    await Future.wait(tasks);
    return _aggregate(tasks);
  }
}
```

### Phase 3.5: 世界构建增强 (P2)

**依赖:** 现有 Codex 系统
**预计:** 3-5 天

```dart
// 角色关系图谱
class CharacterGraph {
  List<CharacterNode> nodes;
  List<CharacterEdge> edges;  // 师徒/敌对/恋人/家族
}

// 伏笔追踪
class ForeshadowingTracker {
  List<ForeshadowingEvent> planted;
  List<ForeshadowingEvent> payoffs;  // 已回收的伏笔
  Map<String, double> densityByChapter;
}
```

### Phase 3.6: Novel-Architect Skill 整合 (P2)

**依赖:** 无
**预计:** 2-3 天

将 55KB 的 `novel-architect/SKILL.md` 转化为灵笔 Skill 系统可加载的格式。

---

## 5. 风险分析

| 风险 | 概率 | 影响 | 缓解措施 |
|------|:----:|:----:|----------|
| AI_NovelGenerator 的 Python 逻辑难以直接移植到 Dart | 中 | 高 | 概念移植而非代码移植；先验证核心模式 |
| LLM 结构化输出在 Dart 生态中支持有限 | 中 | 中 | 使用 JSON Schema + 自定义验证，不依赖 SDK |
| 三层生成管线可能超时（长文本） | 高 | 中 | SSE 流式输出 + 超时重试 + 降级策略 |
| ThinkStreamFilter 可能误过滤正常内容 | 低 | 中 | 单元测试覆盖边界案例；可配置开关 |
| Prompt 模板可能过时（网文风向变化） | 中 | 低 | YAML 外部化，用户可自行编辑更新 |

---

## 6. 迁移策略

### 向后兼容

- Phase 3.1 重构期间保留旧 `AIProvider` 接口，新增 `BaseLLMClient` 并行存在
- 所有 Provider 逐步迁移，每个 Provider 迁移后运行完整测试套件
- Phase 3.2 的 novel-engine 独立部署，不影响现有微服务

### 回滚策略

- Phase 3.1: 将 `ai_service.dart` 回退到旧版本即可
- Phase 3.2: `docker-compose.yml` 移除 novel-engine 服务
- YAML Prompt 文件: 删除或覆盖即可

---

## 7. 依赖关系图

```
Phase 3.1 (LLM 抽象层) ───────────────┐
      │                                │
      ▼                                ▼
Phase 3.2 (三层生成管线) ◄─── Phase 3.4 (质量审查)
      │                                │
      ▼                                ▼
Phase 3.3 (Prompt 工程)         Phase 3.5 (世界构建)
      │
      ▼
Phase 3.6 (Novel-Architect Skill)
```

**关键路径:** Phase 3.1 → Phase 3.2 → (并行) Phase 3.3/3.4 → Phase 3.5/3.6

---

## 8. 文件变更总览

| 阶段 | 新建 | 修改 | 小计 |
|:----:|:----:|:----:|:----:|
| 3.1 | 6 | 6 | 12 |
| 3.2 | 12 | 3 | 15 |
| 3.3 | 4 | 0 | 4 |
| 3.4 | 5 | 0 | 5 |
| 3.5 | 4 | 2 | 6 |
| 3.6 | 4 | 0 | 4 |
| **合计** | **35** | **11** | **46** |

---

## 9. 参考

- AI_NovelGenerator: `F:\AI_NovelGenerator`
- 灵笔设计文档: `docs/superpowers/specs/2026-07-05-integration-test-design.md`
- 灵笔验证报告: `docs/VERIFICATION_REPORT.md`
- 灵感笔记: `projects/lingbi-v3-0-ai-novel-engine-blueprint-2026-07-05.md` (Obsidian)