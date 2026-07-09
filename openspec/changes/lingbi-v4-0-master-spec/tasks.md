# 灵笔 v4.0 Master Spec — 实施任务清单

> 46 个任务 | 6 个 Phase | 预估 19 周 | 2026-07-18

---

## Phase 1: 世界模型 + 存储迁移 (P0, 5 周)

**依赖:** 无 | **影响:** 全部 Service 层

### Task 1.1: World 领域模型实现 (1 周)
- **Files**: 10+ 新建模型文件
- [x] **1.1.1** 实现 World / Work / Volume / Chapter / Scene 模型类
- [x] **1.1.2** 实现 Canon 父类 + Character / Location / Lore / WorldRule 子类
- [x] **1.1.3** 实现 Identity / CharacterEdge / TimelineEvent / Foreshadowing / Faction 模型
- [x] **1.1.4** 实现 NovelStructure 层级 (SynopsisAndCharacters / VolumeOutline / 等)
- [x] **1.1.5** 实现 JSON 序列化/反序列化
- [x] **1.1.6** 编写模型测试 (20+ 测试用例)

### Task 1.2: Drift 存储层 (1.5 周)
- **Files**: 5+ 新建 + build.yaml + pubspec.yaml 修改
- [x] **1.2.1** 配置 pubspec.yaml + build.yaml + build_runner
- [x] **1.2.2** 定义 16 张 Drift 表结构 (含 Factions + Foreshadowings)
- [x] **1.2.3** 实现 Database 类 + 连接管理
- [x] **1.2.4** 实现 WorldRepository / WorkRepository
- [x] **1.2.5** 实现 CharacterRepository / SceneRepository / TimelineRepository
- [x] **1.2.6** 实现 VectorService 抽象 + ZVecVectorService
- [x] **1.2.7** 实现 FileService 适配新路径
- [ ] **1.2.8** 编写 Repository 测试 (20+ 测试用例)

### Task 1.3: 数据迁移 (1 周)
- **Files**: 2+ 新建
- [x] **1.3.1** 实现 DataMigrator (Project → World + Work, CodexEntry → Canon)
- [x] **1.3.2** 实现 dryRun() 预览模式
- [x] **1.3.3** 实现 rollback() 回滚
- [ ] **1.3.4** 编写迁移测试 (10+ 测试用例)
- [ ] **1.3.5** 迁移验证: 现有数据完全恢复

### Task 1.4: Service 层适配 (1 周)
- **Files**: 17+ 修改文件
- [x] **1.4.1** WorldService / WorkService 替代 ProjectService (World 模型已提取)
- [x] **1.4.2** CanonService 替代 CodexService (@Deprecated 标注完成)
- [x] **1.4.3** CharacterGraphService 适配新存储
- [x] **1.4.4** FactionService / TimelineService 适配新存储
- [x] **1.4.5** SyncService 适配 Drift + 文件混合
- [x] **1.4.6** 兼容层: 旧 ProjectService / CodexService @Deprecated 标注
- [x] **1.4.7** Repository TODO 修复 (getCharactersForScene / _midpoint 等)

### Task 1.5: UI 适配 (0.5 周)
- **Files**: 8+ 修改
- [ ] **1.5.1** Sidebar 适配 World → Work 层次
- [ ] **1.5.2** ProjectPage 适配 Volume/Chapter/Scene 树
- [ ] **1.5.3** CodexPage 适配 Canon 分类视图
- [ ] **1.5.4** SettingsPage 添加 World 管理

> ⏳ UI 适配尚未开始，需另行执行

---

## Phase 2: AI 引擎微服务化 (P0, 4 周)

**依赖:** Phase 1 完成

### Task 2.1: LLM 抽象层完善 (0.5 周)
- **Files**: 6 修改
- [ ] **2.1.1** 审查现有 `lib/core/ai/` 代码完整性
- [ ] **2.1.2** 补全 ThinkStreamFilter / RetryHandler / SchemaProcessor 测试
- [ ] **2.1.3** 确认 LLMFactory 注册所有 Provider
- [ ] **2.1.4** 确认旧 AIProvider 接口已标记 @Deprecated
- [ ] **2.1.5** `flutter analyze` 0 error + 测试通过

### Task 2.2: Novel Engine 微服务 (1.5 周)
- **Files**: 10+ 新建
- [ ] **2.2.1** 创建 dart_frog 微服务项目 `services/novel-engine/`
- [ ] **2.2.2** 创建 Layer1Generator / Layer2Generator / Layer3Generator 服务端实现
- [ ] **2.2.3** 创建 SSE 流式响应端点
- [ ] **2.2.4** 创建缓存层 (30 分钟 TTL)
- [ ] **2.2.5** 实现 Fallback Chain: Layer3 → Layer2Compact → Layer1Only → DirectLLM
- [ ] **2.2.6** 编写服务端测试 (20+ 测试用例)
- [ ] **2.2.7** 健康检查端点 + Dockerfile

### Task 2.3: Quality Review 微服务 (1 周)
- **Files**: 10+ 新建
- [ ] **2.3.1** 创建 dart_frog 微服务项目 `services/quality-review/`
- [ ] **2.3.2** 从现有 `review_pipeline.dart` (11KB) 拆分出 5 子模块
- [ ] **2.3.3** CharacterConsistency 审查
- [ ] **2.3.4** HookDensity 审查
- [ ] **2.3.5** FormatReview 审查
- [ ] **2.3.6** ReviewPipeline 编排 + 综合评分
- [ ] **2.3.7** 编写服务端测试 (15+ 测试用例)

### Task 2.4: Prompt 工程体系 (0.5 周)
- **Files**: 8+ 新建
- [ ] **2.4.1** 创建 `assets/prompts/novel/prompts.yaml` (20+ 模板)
- [ ] **2.4.2** 创建类型指南: fantasy / mystery / urban / wuxia
- [ ] **2.4.3** 创建风格模板: qidian / fanqie
- [ ] **2.4.4** 实现 PromptService (YAML 加载 + 变量替换)
- [ ] **2.4.5** 编写 PromptService 测试

### Task 2.5: Flutter 客户端适配 (0.5 周)
- **Files**: 5 修改
- [ ] **2.5.1** AIService 添加 generateNovel() / streamNovelScene() 方法
- [ ] **2.5.2** AI Panel 添加生成管线 UI
- [ ] **2.5.3** AI Panel 添加质量审查结果展示
- [ ] **2.5.4** API Gateway 路由配置

---

## Phase 3: 身份识别 + 上下文注入 (P1, 3 周)

**依赖:** Phase 1 完成

### Task 3.1: 身份识别引擎 (1 周)
- **Files**: 6+ 新建
- [ ] **3.1.1** 实现称呼规则库 (RuleMatcher)
- [ ] **3.1.2** 实现 IdentityDetector (规则匹配 + LLM 兜底)
- [ ] **3.1.3** 实现 DetectorCache (key=场景ID)
- [ ] **3.1.4** 实现渐进式学习 (用户确认 → 规则库)
- [ ] **3.1.5** 编写测试 (10+ 测试用例)

### Task 3.2: 上下文注入引擎 (1 周)
- **Files**: 4+ 新建
- [ ] **3.2.1** 实现 ContextResolver (权重排序 + 角色/地点/规则关联)
- [ ] **3.2.2** 实现 ContextInjector (分层组装 + ~1500 tokens 预算)
- [ ] **3.2.3** 实现 LRU 缓存
- [ ] **3.2.4** 实现 Token 计数器
- [ ] **3.2.5** 编写测试 (10+ 测试用例)

### Task 3.3: 身份管理 UI (1 周)
- **Files**: 5+ 新建
- [ ] **3.3.1** 角色面板 (身份列表 + 权重展示)
- [ ] **3.3.2** 通知气泡 (新身份检测提示)
- [ ] **3.3.3** 确认/拒绝/修改交互
- [ ] **3.3.4** 集成到 CodexPage
- [ ] **3.3.5** 集成到 NovelService 生成管线

---

## Phase 4: 社区生态 + Launcher (P1, 3 周)

**依赖:** Phase 1 + Phase 2 完成

### Task 4.1: API Gateway + 微服务基础设施 (1 周)
- **Files**: 15+ 新建
- [ ] **4.1.1** 创建 `lingbi_server/` gateway 项目 (dart_frog)
- [ ] **4.1.2** 实现 12 个微服务路由挂载
- [ ] **4.1.3** 实现速率限制中间件
- [ ] **4.1.4** 实现请求日志 + CORS
- [ ] **4.1.5** 实现健康检查聚合
- [ ] **4.1.6** 创建 docker-compose.yml (12 服务)
- [ ] **4.1.7** 创建各服务 Dockerfile
- [ ] **4.1.8** 编写集成测试

### Task 4.2: Skill 系统 (1 周)
- **Files**: 8+ 新建
- [ ] **4.2.1** 实现 Skill 注册表 (skill-registry.json)
- [ ] **4.2.2** 创建 Skill Service 微服务 (:8091)
- [ ] **4.2.3** 实现 Skill 执行沙箱
- [ ] **4.2.4** Novel-Architect Skill 注册 + 验证
- [ ] **4.2.5** 实现 Skill 市场 UI
- [ ] **4.2.6** 编写测试 (10+ 测试用例)

### Task 4.3: Launcher (1 周)
- **Files**: 5+ 新建
- [ ] **4.3.1** 实现 Launcher 核心 (startAll/stopAll/restart)
- [ ] **4.3.2** 实现实时状态监控流
- [ ] **4.3.3** 实现 GUI 启动器 (Flutter 窗口)
- [ ] **4.3.4** 实现系统托盘
- [ ] **4.3.5** 实现日志查看器
- [ ] **4.3.6** 实现 Windows 系统自启 (无 .bat 脚本)

---

## Phase 5: 世界构建增强 (P2, 2 周)

**依赖:** Phase 1 完成

### Task 5.1: UI 集成已有代码 (0.5 周)
- **Files**: 6 修改
- [ ] **5.1.1** 角色关系图谱可视化 (Codex 页面)
- [ ] **5.1.2** 势力视图 UI
- [ ] **5.1.3** 时间线可视化 (故事画布集成)
- [ ] **5.1.4** 关系图谱导出为图片

### Task 5.2: 蝴蝶效应引擎 (1 周)
- **Files**: 5+ 新建
- [ ] **5.2.1** 实现 ButterflyAnalyzer
- [ ] **5.2.2** 实现费用预估 + 用户确认 UI
- [ ] **5.2.3** 实现结果展示 (角色列表 + 权重变化)
- [ ] **5.2.4** 实现结果手动编辑
- [ ] **5.2.5** 编写测试 (10+ 测试用例)

### Task 5.3: 导入导出增强 (0.5 周)
- **Files**: 4+ 新建
- [ ] **5.3.1** DOCX 原生导出 (Dart Open XML)
- [ ] **5.3.2** EPUB 原生导出
- [ ] **5.3.3** Markdown/JSON 导入
- [ ] **5.3.4** Pandoc 可选集成 (PDF/HTML)
- [ ] **5.3.5** 导出设置 UI

---

## Phase 6: 商业化 + 发布 (P2, 2 周)

**依赖:** Phase 1-5 完成

### Task 6.1: 配额 + 会员系统 (0.5 周)
- **Files**: 4 修改
- [ ] **6.1.1** 实现 QuotaService 微服务 (:8088)
- [ ] **6.1.2** 实现会员状态管理
- [ ] **6.1.3** 实现爱发电捐赠集成
- [ ] **6.1.4** UI: 配额展示 + 升级提示

### Task 6.2: 代码清理与安全扫描 (0.5 周)
- **Files**: 全项目扫描
- [ ] **6.2.1** 修复 claude_provider.jpg → claude_provider.dart
- [ ] **6.2.2** 清理废弃 tasks.md 文件
- [ ] **6.2.3** 更新 pubspec.yaml 版本号 → 0.6.0
- [ ] **6.2.4** git secrets 扫描 (API Keys / tokens)
- [ ] **6.2.5** .env.example 清理敏感信息
- [ ] **6.2.6** 依赖审计

### Task 6.3: GitHub 开源发布 (0.5 周)
- **Files**: 10+ 新建/修改
- [ ] **6.3.1** 更新 README.md + 截图
- [ ] **6.3.2** 更新 CONTRIBUTING.md + SECURITY.md
- [ ] **6.3.3** 创建 GitHub Actions CI (.github/)
- [ ] **6.3.4** 创建 Issue/PR 模板
- [ ] **6.3.5** 创建 GitHub Releases 配置

### Task 6.4: Windows 打包 (0.5 周)
- **Files**: 3 修改
- [ ] **6.4.1** MSIX 配置 (msix_config)
- [ ] **6.4.2** 应用图标 + 名称
- [ ] **6.4.3** 安装包构建验证
- [ ] **6.4.4** Docker Hub 镜像构建配置

---

## 最终验证

- [ ] **V1**: `flutter analyze` — 0 error, 0 warning
- [ ] **V2**: `flutter test` — 全部通过
- [ ] **V3**: 微服务健康检查 — 全部 green
- [ ] **V4**: Docker Compose up — 所有服务正常
- [ ] **V5**: E2E 测试 — 新建 World → 写作 → 导出完整流程

---

## 依赖图

```
Phase 1 ────→ Phase 2 ────→ Phase 4 ────→ Phase 6
  │                                        ↑
  └──→ Phase 3 ──────────────→ Phase 5 ────┘

Phase 1: 存储层 (所有 Phase 的基础)
Phase 2: AI 引擎微服务化 (依赖 Phase 1 存储)
Phase 3: 身份识别 + 上下文注入 (依赖 Phase 1 领域模型)
Phase 4: 社区 + Launcher (依赖 Phase 1 存储 + Phase 2 AI)
Phase 5: 世界构建增强 (依赖 Phase 1 领域模型)
Phase 6: 商业化 (依赖全部 Phase)
```

---

## 任务统计

| Phase | 子任务数 | 预估工期 | 并行度 |
|:-----:|:--------:|:--------:|:------:|
| 1 | 29 | 5 周 | 低 (串行依赖) |
| 2 | 22 | 4 周 | 中 (LLM + Prompt 可并行) |
| 3 | 14 | 3 周 | 中 (引擎 + UI 可并行) |
| 4 | 20 | 3 周 | 高 (Gateway + Skill + Launcher 可并行) |
| 5 | 14 | 2 周 | 高 (各增强可并行) |
| 6 | 14 | 2 周 | 高 (安全 + 打包 + GitHub 可并行) |
| **总计** | **113** | **19 周** | |