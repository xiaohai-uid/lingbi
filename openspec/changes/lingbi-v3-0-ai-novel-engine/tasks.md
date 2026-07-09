# 灵笔 v3.0 — AI Novel Engine

> 实施任务清单 | 46 文件 | 6 Phase | 预计 18-27 天

---

## Phase 3.1: LLM Provider 抽象层重构 (P0, 3-5 天)

**依赖:** 无
**文件:** 6 新建 + 6 修改 = 12 文件
**测试:** 15+ 测试用例

### Task 3.1.1: 数据模型和错误层次 (0.5 天)

**Files:**
- Create: `lib/core/ai/llm_models.dart`
- Create: `lib/core/ai/llm_errors.dart`

- [ ] **Step 1: 定义 LLMRequest / LLMResponse 模型**
  ```dart
  class LLMRequest { ... }
  class LLMResponse { ... }
  class TokenUsage { ... }
  ```
- [ ] **Step 2: 定义错误层次**
  ```dart
  sealed class LLMException implements Exception { ... }
  class LLMAuthException extends LLMException { ... }
  class LLMRateLimitException extends LLMException { ... }
  class LLMTimeoutException extends LLMException { ... }
  class LLMResponseException extends LLMException { ... }
  ```
- [ ] **Step 3: 编写测试**
  - 测试模型序列化/反序列化
  - 测试错误构造和类型判断
  - 预期: 5+ 测试通过

### Task 3.1.2: 抽象基类 BaseLLMClient (0.5 天)

**Files:**
- Create: `lib/core/ai/base_client.dart`
- Create: `lib/core/ai/think_stream_filter.dart`

- [ ] **Step 1: 定义 BaseLLMClient 抽象类**
  ```dart
  abstract class BaseLLMClient {
    String get providerName;
    Future<String> generateText(LLMRequest request);
    Stream<String> streamText(LLMRequest request);
    Future<T> generateStructured<T>(LLMRequest request, T Function(Map<String, dynamic>) fromJson);
  }
  ```
- [ ] **Step 2: 移植 ThinkStreamFilter**
  - 从 AI_NovelGenerator `base_client.py` 移植 `_ThinkStreamFilter`
  - 支持跨 chunk 的 `<think>...</think>` 过滤
  - 支持 ````json...``` 代码块提取
- [ ] **Step 3: 编写测试**
  - ThinkStreamFilter 单元测试（空输入、单 chunk、跨 chunk、嵌套标签）
  - 预期: 5+ 测试通过

### Task 3.1.3: 重试处理器 (0.5 天)

**Files:**
- Create: `lib/core/ai/retry_handler.dart`

- [ ] **Step 1: 实现指数退避重试**
  ```dart
  class RetryHandler {
    final int maxRetries;
    final Duration baseDelay;
    final double backoffFactor;
    final Set<Type> retryableErrors;
    
    Future<T> execute<T>(Future<T> Function() fn) async { ... }
  }
  ```
- [ ] **Step 2: 编写测试**
  - 测试重试次数
  - 测试退避延迟
  - 测试不可恢复错误直接抛出
  - 预期: 3+ 测试通过

### Task 3.1.4: Schema 处理器 (0.5 天)

**Files:**
- Create: `lib/core/ai/schema_processor.dart`

- [ ] **Step 1: 实现 JSON Schema 提取和验证**
  ```dart
  class SchemaProcessor {
    T extractFromResponse<T>(String response, T Function(Map<String, dynamic>) fromJson);
    Map<String, dynamic>? extractJsonBlock(String text);  // 提取 ```json 块
    bool validateAgainstSchema(Map<String, dynamic> data, Map<String, dynamic> schema);
  }
  ```
- [ ] **Step 2: 编写测试**
  - 测试 JSON 代码块提取
  - 测试 Schema 验证
  - 预期: 3+ 测试通过

### Task 3.1.5: 工厂模式 (0.5 天)

**Files:**
- Create: `lib/core/ai/llm_factory.dart`

- [ ] **Step 1: 实现可注册工厂**
  ```dart
  class LLMFactory {
    static final Map<String, BaseLLMClient Function()> _registry = {};
    static void register(String name, BaseLLMClient Function() factory) { ... }
    static BaseLLMClient create(String name) { ... }
    static List<String> availableProviders() { ... }
  }
  ```
- [ ] **Step 2: 注册内置 Provider**
  - 注册 free_provider
  - 注册 openai_provider
  - 注册 claude_provider
  - 注册 deepseek_provider
- [ ] **Step 3: 编写测试**
  - 测试注册/创建
  - 测试未注册 Provider 错误
  - 预期: 3+ 测试通过

### Task 3.1.6: 现有 Provider 适配 (1 天)

**Files:**
- Modify: `lib/core/ai/free_provider.dart`
- Modify: `lib/core/ai/deepseek_provider.dart`
- Modify: `lib/core/ai/openai_provider.dart`
- Modify: `lib/core/ai/claude_provider.dart`
- Modify: `lib/services/ai_service.dart`
- Modify: `lib/core/ai/ai_provider.dart` (旧接口标记为 @Deprecated)

- [ ] **Step 1: 修改每个 Provider 实现 BaseLLMClient**
  - 保留旧接口方法，委托给新接口
  - 添加 @Deprecated 注解
- [ ] **Step 2: 修改 AIService 使用 LLMFactory**
  - 从工厂创建客户端
  - 支持运行时切换 Provider
- [ ] **Step 3: 运行 `flutter analyze`**
  - 预期: 0 error, 0 warning

---

## Phase 3.2: 三层生成管线 (P0, 5-7 天)

**依赖:** Phase 3.1
**文件:** 12 新建 + 3 修改 = 15 文件
**测试:** 20+ 测试用例

### Task 3.2.1: 数据模型 (0.5 天)

**Files:**
- Create: `lingbi_server/microservices/novel-engine/lib/structure_models.dart`

- [ ] **Step 1: 定义三层结构模型**
  ```dart
  class SynopsisAndCharacters { ... }
  class CharacterProfile { ... }
  class VolumeOutline { ... }
  class ChapterOutline { ... }
  class SceneOutline { ... }
  class LayeredNovelStructure { ... }
  class SceneGenerationContext { ... }
  ```
- [ ] **Step 2: 编写序列化/反序列化测试**
  - 预期: 5+ 测试通过

### Task 3.2.2: Layer 1 生成器 (1 天)

**Files:**
- Create: `lingbi_server/microservices/novel-engine/lib/layer1_generator.dart`

- [ ] **Step 1: 实现 Layer1Generator**
  - 接收用户创意 + 类型 + 风格参数
  - 调用 LLM.generateStructured<SynopsisAndCharacters>()
  - 验证输出结构完整性
  - 缓存结果（30 分钟 TTL）
- [ ] **Step 2: 编写测试**
  - 测试正常生成路径
  - 测试 LLM 失败时的重试
  - 测试输出验证
  - 预期: 5+ 测试通过

### Task 3.2.3: Layer 2 生成器 (1 天)

**Files:**
- Create: `lingbi_server/microservices/novel-engine/lib/layer2_generator.dart`

- [ ] **Step 1: 实现 Layer2Generator**
  - 接收 Layer1 输出 + 卷数/章数参数
  - 调用 LLM.generateStructured<LayeredNovelStructure>()
  - 验证章节数/场景数约束
  - 缓存结果
- [ ] **Step 2: 实现降级策略**
  - 三层 → 二层（compact）→ 一层（直接生成）
- [ ] **Step 3: 编写测试**
  - 测试正常生成路径
  - 测试降级路径
  - 预期: 5+ 测试通过

### Task 3.2.4: Layer 3 生成器 (1.5 天)

**Files:**
- Create: `lingbi_server/microservices/novel-engine/lib/layer3_generator.dart`

- [ ] **Step 1: 实现 Layer3Generator**
  - 接收场景上下文
  - 调用 LLM.streamText() 流式生成
  - 逐 chunk 推送到 SSE
  - 场景完成后可选触发质量审查
- [ ] **Step 2: 实现 SSE 流式响应**
  ```
  event: chunk
  data: {"text": "章节内容...", "sceneComplete": false}
  
  event: complete
  data: {"text": "...", "sceneComplete": true, "wordCount": 1234}
  ```
- [ ] **Step 3: 编写测试**
  - 测试流式生成
  - 测试 SSE 格式
  - 测试中断恢复
  - 预期: 5+ 测试通过

### Task 3.2.5: 微服务入口和路由 (1 天)

**Files:**
- Create: `lingbi_server/microservices/novel-engine/main.dart`
- Create: `lingbi_server/microservices/novel-engine/pubspec.yaml`
- Create: `lingbi_server/microservices/novel-engine/routes/health.dart`
- Create: `lingbi_server/microservices/novel-engine/routes/generate_layer1.dart`
- Create: `lingbi_server/microservices/novel-engine/routes/generate_layer2.dart`
- Create: `lingbi_server/microservices/novel-engine/routes/generate_layer3.dart`

- [ ] **Step 1: 创建 dart_frog 微服务**
  - `dart_frog create novel-engine`
  - 配置 pubspec.yaml 依赖
- [ ] **Step 2: 实现路由**
  - `/health` → 健康检查
  - `/generate-layer1` → POST
  - `/generate-layer2` → POST
  - `/generate-layer3` → GET (SSE)
- [ ] **Step 3: 编写路由测试**
  - 预期: 5+ 测试通过

### Task 3.2.6: 集成到现有架构 (1 天)

**Files:**
- Modify: `docker-compose.yml`
- Modify: `lingbi_server/_middleware.dart`
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1: 更新 docker-compose.yml**
  - 添加 novel-engine 服务定义
  - 配置端口 :8092
  - 添加 healthcheck
- [ ] **Step 2: 更新 API Gateway 路由**
  - 在 _middleware.dart 中添加 `/api/v1/novel/*` → :8092
- [ ] **Step 3: 更新 Flutter AIService**
  - 添加 generateNovel() 方法
  - 添加 streamNovelScene() 方法（SSE）

---

## Phase 3.3: Prompt 工程 + 类型库 (P1, 2-3 天)

**依赖:** 无
**文件:** 4 新建
**测试:** 5+ 测试用例

### Task 3.3.1: YAML Prompt 模板库 (1 天)

**Files:**
- Create: `assets/prompts/novel/prompts.yaml`

- [ ] **Step 1: 从 AI_NovelGenerator 移植 Prompt 模板**
  - 起点爆款风格（冲突前置、金手指、期待感）
  - 番茄爽文风格（快节奏、高密度爽点）
  - 展开创意 (expand_idea) 模板
  - 风格分析模板
  - 小说拆解模板
- [ ] **Step 2: 编写 PromptService**
  - 加载 YAML 文件
  - 根据类型/风格渲染 Prompt
  - 支持变量替换 {{idea}}, {{genre}}, {{numChapters}}

### Task 3.3.2: 类型化写作指南 (1 天)

**Files:**
- Create: `assets/prompts/novel/genres/fantasy.yaml`
- Create: `assets/prompts/novel/genres/mystery.yaml`
- Create: `assets/prompts/novel/genres/urban.yaml`

- [ ] **Step 1: 从 novel-architect/fantasy.md 移植奇幻指南**
  - 桑德森三定律
  - 魔法系统设计模板
  - 世界构建检查清单
- [ ] **Step 2: 从 novel-architect/mystery.md 移植悬疑指南**
  - Fair Play 原则
  - 线索放置模式
  - 误导设计
- [ ] **Step 3: 创建都市类型指南**
  - 现代都市设定模板
  - 行业背景研究

---

## Phase 3.4: 质量审查管线 (P1, 3-4 天)

**依赖:** Phase 3.1
**文件:** 5 新建
**测试:** 15+ 测试用例

### Task 3.4.1: 角色一致性检测 (1 天)

**Files:**
- Create: `lib/services/quality/character_consistency.dart`
- Create: `lib/services/quality/review_models.dart`

- [ ] **Step 1: 从 AI_NovelGenerator 移植 CharacterConsistency**
  - 定义 CharacterConsistencyResult
  - 实现性格/动机/对话风格一致性检测
  - 实现偏差评分 (0-100)
- [ ] **Step 2: 编写测试**
  - 预期: 5+ 测试通过

### Task 3.4.2: 爽点密度分析 (1 天)

**Files:**
- Create: `lib/services/quality/hook_density.dart`

- [ ] **Step 1: 从 AI_NovelGenerator 移植 HookDensity**
  - 定义 HookEvent 类型（打脸/反转/升级/获得/装逼/复仇/保护/揭秘）
  - 实现密度计算（点数/1000字）
  - 平台要求判断（番茄 ≥2.0）
- [ ] **Step 2: 编写测试**
  - 预期: 5+ 测试通过

### Task 3.4.3: 格式审查和综合报告 (1 天)

**Files:**
- Create: `lib/services/quality/format_review.dart`
- Create: `lib/services/quality/review_pipeline.dart`

- [ ] **Step 1: 实现格式审查**
  - 段落长度检查
  - 对话/叙述比例
  - 禁止内容检查
- [ ] **Step 2: 实现 ReviewPipeline 编排**
  - 并行执行三个审查模块
  - 综合评分 (0-10)
  - 重写决策
- [ ] **Step 3: 编写测试**
  - 预期: 5+ 测试通过

---

## Phase 3.5: 世界构建增强 (P2, 3-5 天)

**依赖:** 现有 Codex 系统
**文件:** 4 新建 + 2 修改
**测试:** 15+ 测试用例

**详细 Spec:** `specs/worldbuilding-enhancement.md`

### Task 3.5.1: 角色关系图谱 (1 天)

**Files:**
- Create: `lib/core/models/character_edge.dart`
- Create: `lib/services/character_graph_service.dart`

- [ ] **Step 1: 实现角色关系模型和服务**
  - 关系类型枚举（师徒/敌对/恋人/家族/主仆/盟友）
  - 关系强度 (1-10)
  - 关系图谱 CRUD
- [ ] **Step 2: 编写测试**（5+）

### Task 3.5.2: 势力管理 (1 天)

**Files:**
- Create: `lib/core/models/faction.dart`
- Create: `lib/services/faction_service.dart`

- [ ] **Step 1: 实现势力模型和服务**
  - 势力类型（宗门/国家/家族/组织）
  - 成员管理
  - 势力关系（盟友/敌对）
- [ ] **Step 2: 编写测试**（5+）

### Task 3.5.3: 时间线和伏笔追踪 (1-2 天)

**Files:**
- Create: `lib/core/models/timeline_event.dart`
- Create: `lib/core/models/foreshadowing.dart`
- Create: `lib/services/timeline_service.dart`
- Create: `lib/services/foreshadowing_service.dart`

- [ ] **Step 1: 实现时间线事件和服务**
- [ ] **Step 2: 实现伏笔追踪**
- [ ] **Step 3: 编写测试**（5+）

### Task 3.5.4: UI 集成 (0.5 天)

- [ ] **Step 1: 修改 CodexPage 添加关系图谱入口**
- [ ] **Step 2: 修改故事画布集成时间线**

---

## Phase 3.6: Novel-Architect Skill 整合 (P2, 2-3 天)

**依赖:** 无
**文件:** 4 新建
**验证:** Skill 注册到社区市场

**详细 Spec:** `specs/novel-architect-skill.md`

### Task 3.6.1: 移植核心 Skill (1 天)

**Files:**
- Create: `community/skills/novel-architect/SKILL.md`
- Create: `community/skills/novel-architect/constitution.md`

- [ ] **Step 1: 从 55KB 精简适配 SKILL.md**
  - 保留 16 步流程
  - 适配灵笔输出路径和文档格式
  - 精简背景任务管理部分
- [ ] **Step 2: 移植 constitution.md**

### Task 3.6.2: 移植类型指南 (1 天)

**Files:**
- Create: `community/skills/novel-architect/fantasy.md`
- Create: `community/skills/novel-architect/mystery.md`

- [ ] **Step 1: 移植 fantasy.md**（10KB）
- [ ] **Step 2: 移植 mystery.md**（10KB）

### Task 3.6.3: 注册到社区市场 (0.5 天)

- [ ] **Step 1: 更新 `community/skill-registry.json`**
- [ ] **Step 2: 验证 Skill 可在灵笔中加载**

---

## 最终验证

- [ ] **Step 1: `flutter analyze` — 0 error**
- [ ] **Step 2: `flutter test` — 全部通过**
- [ ] **Step 3: 微服务测试 — 全部通过**
- [ ] **Step 4: Docker Compose 集成测试**
- [ ] **Step 5: 版本号更新至 v3.0.0**