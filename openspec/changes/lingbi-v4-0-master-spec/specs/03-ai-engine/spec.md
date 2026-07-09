# AI 引擎 — 需求规格

> ID: CAP-AI | 优先级: P0 | 依赖: 无

---

## 需求清单

### REQ-AI-01: LLM 抽象层
- **优先级**: P0
- **描述**: 基于现有 `lib/core/ai/` 代码，标准化为 LLMFactory + BaseLLMClient 体系
- **验收标准**:
  - LLMFactory: register() / create() / availableProviders()
  - BaseLLMClient: generateText() / streamText() / generateStructured()
  - ThinkStreamFilter: 过滤 `a` 标签
  - RetryHandler: 指数退避 + 可重试错误类型配置
  - SchemaProcessor: JSON 代码块提取 + 验证
  - 所有 Provider 实现 BaseLLMClient (OpenAI / Claude / DeepSeek / Free)

#### Scenario: 切换 Provider
- **Given**: 用户正在使用 DeepSeek 写作
- **When**: 用户在设置中切换到 Claude
- **Then**: LLMFactory.create("claude") 返回 ClaudeClient 实例，后续所有 AI 调用走 Claude

### REQ-AI-02: 三层生成管线 (微服务化)
- **优先级**: P0
- **描述**: 将现有 `lib/services/novel/` 的三层生成器迁移到独立微服务 `novel-engine:8092`
- **验收标准**:
  - Layer1 (梗概): POST → 创意 + 类型 → SynopsisAndCharacters
  - Layer2 (细纲): POST → Layer1 输出 → LayeredNovelStructure
  - Layer3 (正文): GET SSE → Layer2 输出 → 流式章节生成
  - Fallback Chain: Layer3 → Layer2Compact → Layer1Only → DirectLLM
  - 缓存: Layer1/Layer2 结果缓存 30 分钟 TTL
  - 健康检查: GET /health

### REQ-AI-03: Prompt 工程体系
- **优先级**: P1
- **描述**: 从硬编码 Prompt 迁移到 YAML 模板库
- **验收标准**:
  - `assets/prompts/novel/prompts.yaml` 包含 20+ Prompt 模板
  - 类型指南: fantasy / mystery / urban / wuxia
  - 风格模板: qidian / fanqie / custom
  - PromptService: 加载 YAML → 变量替换 → 渲染
  - 支持 `{{idea}} {{genre}} {{numChapters}}` 等变量

### REQ-AI-04: 质量审查管线 (微服务化)
- **优先级**: P1
- **描述**: 迁移现有 `lib/services/quality/review_pipeline.dart` (11KB) 到微服务并拆分子模块
- **验收标准**:
  - `quality-review:8093` 微服务
  - 三个独立审查模块: character_consistency / hook_density / format_review
  - ReviewPipeline 并行编排 + 综合评分
  - 11KB 单体文件拆为 5 个文件
  - POST /api/v1/quality/review → 审查报告

### REQ-AI-05: 上下文注入
- **优先级**: P1
- **描述**: ContextResolver + ContextInjector 分层注入项目上下文到 LLM
- **验收标准**:
  - 按权重排序角色/身份/地点/规则
  - 分层组装: 核心(500) + 活跃(500) + 参考(300) + 规则(200) tokens
  - LRU 缓存: key=章节ID, 失效=用户编辑
  - Token 预算控制 ~1500 tokens