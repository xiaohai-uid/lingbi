# 灵笔 v3.0 AI Novel Engine — 架构设计

> 设计文档 | 2026-07-05

---

## 1. 设计原则

1. **渐进式迁移** — 不破坏现有功能，每个 Phase 独立可交付
2. **概念移植** — 从 AI_NovelGenerator 移植设计思想而非代码（Python → Dart）
3. **测试驱动** — 每个抽象层先写测试，后实现
4. **向后兼容** — 旧 AIProvider 接口保留一个版本周期
5. **可观测性** — 所有 LLM 调用记录 Token 消耗、延迟、成功率

---

## 2. 核心模块设计

### 2.1 LLM 抽象层 (Phase 3.1)

```
┌─────────────────────────────────────────────────────┐
│                   LLMFactory                         │
│  ├─ registerProvider(type, clientClass)              │
│  └─ create(providerName) → BaseLLMClient             │
├─────────────────────────────────────────────────────┤
│  BaseLLMClient (abstract)                            │
│  ├─ generateText(LLMRequest) → Future<String>        │
│  ├─ streamText(LLMRequest) → Stream<String>          │
│  └─ generateStructured(LLMRequest, parser) → Future<T>│
├──────────┬──────────┬──────────┬────────────────────┤
│ OpenAI   │ Claude   │ Gemini   │ 自定义 Provider    │
│ Compat.  │ Client   │ Client   │ (可注册扩展)        │
├──────────┴──────────┴──────────┴────────────────────┤
│  Cross-Cutting: ThinkStreamFilter · RetryHandler    │
│                 SchemaProcessor · CostMonitor        │
└─────────────────────────────────────────────────────┘
```

### 2.2 三层生成管线 (Phase 3.2)

```
┌─────────────────────────────────────────────────────┐
│              Novel Engine (:8092)                     │
│                                                       │
│  POST /api/v1/novel/generate-layer1                   │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Layer1Generator                                 │ │
│  │  1. 验证输入 (创意非空, 类型合法)                 │ │
│  │  2. 调用 LLM.generateStructured<Synopsis>()      │ │
│  │  3. 验证输出结构                                  │ │
│  │  4. 缓存结果 (30分钟 TTL)                        │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  POST /api/v1/novel/generate-layer2                   │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Layer2Generator                                 │ │
│  │  1. 加载 Layer1 缓存                             │ │
│  │  2. 调用 LLM.generateStructured<Volumes>()       │ │
│  │  3. 验证章节数/场景数约束                         │ │
│  │  4. 缓存结果                                      │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  GET /api/v1/novel/generate-layer3 (SSE)              │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Layer3Generator                                 │ │
│  │  1. 加载 Layer2 缓存                             │ │
│  │  2. 调用 LLM.streamText() (流式)                 │ │
│  │  3. 逐 chunk 推送到 SSE                          │ │
│  │  4. 场景完成后触发质量审查 (Phase 3.4)           │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  Fallback Chain:                                      │
│  Layer3 → Layer2Compact → Layer1Only → DirectLLM     │
└─────────────────────────────────────────────────────┘
```

### 2.3 Prompt 管理体系 (Phase 3.3)

```
assets/prompts/
├── novel/
│   ├── prompts.yaml          # 主配置：Prompt 模板库
│   ├── genres/
│   │   ├── fantasy.yaml      # 奇幻类型写作指南
│   │   ├── mystery.yaml      # 悬疑类型写作指南
│   │   ├── urban.yaml        # 都市类型写作指南
│   │   └── wuxia.yaml        # 武侠类型写作指南
│   └── styles/
│       ├── qidian.yaml       # 起点爆款风格
│       └── fanqie.yaml       # 番茄爽文风格
└── skills/
    └── novel-architect/      # Phase 3.6
```

### 2.4 质量审查管线 (Phase 3.4)

```
单场景正文
    │
    ▼
┌─────────────────────────────────┐
│  ReviewPipeline                  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ CharacterConsistency      │  │  ← 角色行为是否符合人设
│  │ - deviationScore (0-100)  │  │
│  │ - specificIssues[]        │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ HookDensity                │  │  ← 爽点分布是否达标
│  │ - density (点/1000字)      │  │
│  │ - meetsRequirement         │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ FormatReview               │  │  ← 格式是否符合规范
│  │ - paragraphLength         │  │
│  │ - dialogueRatio            │  │
│  │ - prohibitedContent        │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 综合评分 + 重写决策       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
    │
    ▼
ReviewReport { overallScore, needsRewrite, suggestions }
```

---

## 3. 数据流

### 完整创作流程

```
用户输入创意 (100 字)
    │
    ▼
[Flutter] AI Panel v2 → POST /novel/generate-layer1
    │
    ▼
[novel-engine] Layer1Generator → LLM.generateStructured<Synopsis>()
    │
    ▼ 返回: 梗概 + 人设
    │
[Flutter] 用户审查 Layer1 结果 → 确认/修改
    │
    ▼
[Flutter] → POST /novel/generate-layer2
    │
    ▼
[novel-engine] Layer2Generator → LLM.generateStructured<Volumes>()
    │
    ▼ 返回: 分卷 + 章节细纲
    │
[Flutter] 用户审查 Layer2 结果 → 确认/修改
    │
    ▼
[Flutter] → GET /novel/generate-layer3 (SSE)
    │
    ▼
[novel-engine] Layer3Generator → LLM.streamText()
    │
    ▼ 流式返回: 场景正文 chunks
    │
[Flutter] 实时渲染编辑器内容
    │
    ▼
[novel-engine] → ReviewPipeline (Phase 3.4)
    │
    ▼ 返回: ReviewReport
    │
[Flutter] 展示审查结果 → 用户决定是否重写
```

---

## 4. 测试策略

| 层级 | 测试类型 | 工具 | 覆盖 |
|------|----------|:----:|:----:|
| LLM 抽象层 | 单元测试 | flutter_test | 每个 Provider 的 mock 测试 |
| ThinkStreamFilter | 单元测试 | flutter_test | 跨 chunk、边界案例 |
| 重试机制 | 单元测试 | flutter_test | 各种错误的重试行为 |
| 三层生成管线 | 集成测试 | flutter_test | 各层生成 + 降级路径 |
| Prompt 服务 | 单元测试 | flutter_test | 模板加载 + 渲染 |
| 质量审查 | 单元测试 | flutter_test | 各审查模块 + 综合报告 |
| 微服务 | API 测试 | dart test | 每个路由的请求/响应 |
| 全链路 | 集成测试 | integration_test | 创意→生成→审查全流程 |

---

## 5. 性能目标

| 操作 | 目标延迟 | 说明 |
|------|:--------:|------|
| Layer 1 生成 | ≤15s | 非流式，需等待完整输出 |
| Layer 2 生成 | ≤20s | 非流式，输出较大 |
| Layer 3 首字 | ≤3s | 流式，首字后持续输出 |
| 质量审查 | ≤5s | 三个审查模块并行 |
| Provider 切换 | ≤100ms | 工厂模式，无重连开销 |
| Prompt 加载 | ≤50ms | YAML 解析 + 缓存 |