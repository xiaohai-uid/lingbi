# 灵笔 V2：全面蒸馏 OpenWrite + 差异化超越

## Problem Statement

灵笔当前的 AI 交互范式是错误的——采用被动应答模式（用户问→AI答），而行业标杆 OpenWrite 采用 AI 主动引导模式。具体表现：

1. **自定义供应商支持不足**：中转站用户（自定义 API 端点）被拒之门外，Onboarding 只展示 5 个内置供应商，自定义入口藏在设置页深处
2. **题材模板形同虚设**：选择玄幻/仙侠/都市后只存为元数据标签，不触发任何 AI 引导流程，用户看到的仍是空白界面
3. **缺乏创作全流程引导**：没有世界观→角色→大纲→章节的结构化引导，没有反幻觉约束，没有一致性监督
4. **缺乏竞品已具备的核心能力**：伏笔管理、节奏控制、风格蒸馏、去AI味、六维审稿、RAG、扫榜、参考书管理等全部缺失

## Solution

以 OpenWrite 为功能基准全面蒸馏，同时保留灵笔 Skill 生态飞轮作为核心差异化。分三个优先级交付：

- **P0（可用基线）**：统一供应商 + AI 引导式创作 + 题材模板触发完整引导链 + 基础设施补全
- **P1（核心竞争力）**：反幻觉 + 监督智能体 + 伏笔 + 节奏 + 风格蒸馏 + 拆书 + AI搜索 + WebDAV + 扫榜 + 参考书 + RAG + 批量生成 + 公益模型
- **P2（差异化超越）**：六维审稿 + 变更传播 + 多模型路由 + 去AI味 + 一键成剧 + 平行世界 + 角色图谱 + 工作流审批 + 短篇支持

## User Stories

### P0：统一供应商（蒸馏 OpenWrite）

1. As a 中转站用户, I want 在 Onboarding 中直接添加自定义 API 端点（baseUrl + key）, so that 我不需要去设置页深处找入口就能开始使用
2. As a 用户, I want 所有供应商（内置/自定义）走完全相同的 UI 和代码路径, so that 我不需要理解"内置 vs 自定义"的区别
3. As a 用户, I want 添加供应商后自动从 /v1/models 拉取可用模型列表, so that 我不需要手动输入 modelId
4. As a 用户, I want 选择 OpenAI 兼容或 Anthropic 两种协议格式, so that 我的中转站无论哪种格式都能正常工作
5. As a 用户, I want 在 Onboarding 供应商选择步骤看到"添加自定义供应商"与预置供应商平级展示, so that 自定义是一等公民而非隐藏功能
6. As a 用户, I want 环境变量 API Key 优先级仍高于 UI 配置, so that 我的已有配置不被覆盖
7. As a 用户, I want 添加供应商时看到 OpenAI 和 Anthropic 两种格式的地址填写说明, so that 我不会填错格式

### P0：基础设施补全（蒸馏 OpenWrite）

8. As a 用户, I want 从思考模型切换到非思考模型时，旧推理内容不泄漏到新请求, so that 切换模型不会报错
9. As a 用户, I want AI 回复过程中点击停止后，未完成的工具调用不污染下次对话, so that 停止生成后状态正常
10. As a 用户, I want 一键导出 Word (.docx) 和 TXT 格式，兼容作家助手, so that 我能直接投稿到各平台
11. As a 用户, I want 发送前自动校验温度和最大 Token 参数合法性，越界即时提示, so that 不需要等服务器返回错误
12. As a 用户, I want 发送前自动清理异常字符，防止特殊字符导致请求被拒, so that 兼容性更好

### P0：AI 引导式创作

13. As a 新用户, I want 创建项目后 AI 主动发起结构化对话引导我构建世界观, so that 我不需要对着空白页面发呆
14. As a 新用户, I want 首次创建项目时进入全屏引导模式（世界观+核心角色）, so that 我有沉浸式的开书体验
15. As a 用户, I want 全屏引导完成后回到正常三栏布局，后续引导在 AI Panel 继续, so that 引导不打断我的正常创作
16. As a 用户, I want AI Panel 顶部显示引导进度条（世界观✓→角色✓→大纲●→章节○）, so that 我知道自己走到哪了
17. As a 用户, I want 随时跳出引导进入自由对话，引导状态暂停但不丢失, so that 我有自由度
18. As a 用户, I want 引导过程中 AI 的产出自动写入项目文件（世界观/角色/大纲）, so that 我不需要手动复制粘贴
19. As a 用户, I want AI 辅助判定每步是否完成（而非机械关键词匹配）, so that 体验不会退化为填表
20. As a 用户, I want 引导流程的步骤定义在 YAML/JSON 中而非硬编码, so that 社区可以贡献新的引导流程

### P0：题材模板触发引导链

21. As a 用户, I want 选择"玄幻"题材后触发完整的玄幻开书引导链, so that 题材选择不是摆设
22. As a 用户, I want 玄幻引导包含修炼体系/宗门/地理/种族等专属问题, so that AI 真的懂这个题材
23. As a 用户, I want 预装官方题材 Skill（玄幻/仙侠/都市/悬疑/言情/科幻/历史）, so that 开箱体验 = OpenWrite
24. As a 用户, I want 不安装任何第三方 Skill 也能获得完整引导体验, so that 我不需要额外操作
25. As a Skill 创作者, I want 题材引导知识以 Skill 形式承载并可替换, so that 社区可以贡献更好的题材引导

### P0：项目级结构化存储

26. As a 用户, I want 世界观/角色/大纲以结构化 JSON 存储在项目目录, so that 层级结构不丢失且可被 Git 追踪
27. As a 用户, I want Canon 自动创建索引条目指向结构化文件, so that 语义搜索和 AI 上下文注入仍然可用
28. As a 用户, I want 世界宪法分为不可变硬规则和可编辑百科, so that 核心设定不会被 AI 随意篡改

### P0：通用基础

29. As a 用户, I want 三级分层架构（总纲→章纲→正文）贯穿所有生成, so that 结构清晰可控
30. As a 用户, I want 生成门禁——通过 N 道检查才允许输出, so that 低质量内容不会直接呈现
31. As a 用户, I want 术语表功能——自定义术语及其释义，AI 生成时遵守, so that 专有名词不会被篡改

### P1：反幻觉三定律 + 监督智能体

32. As a 用户, I want AI 生成时遵守"大纲即法律"——不得偏离已确认大纲, so that 剧情不会跑偏
33. As a 用户, I want AI 生成时遵守"设定即物理"——不得违反世界观硬规则, so that 力量体系不会崩坏
34. As a 用户, I want AI 发明新设定时明确标识为"发明", so that 我能决定是否接受
35. As a 用户, I want 每章生成后自动回写结构化状态快照（出场角色/情绪/未解伏笔/时间线）, so that 下一章不靠模型记忆
36. As a 用户, I want 独立监督 Agent 在生成后检查人设/背景是否漂移, so that 角色不会 OOC
37. As a 用户, I want 监督 Agent 发现问题时给出具体修改建议而非笼统警告, so that 我能快速修正

### P1：伏笔全生命周期管理

38. As a 用户, I want 创建伏笔时记录埋设章节/预期回收章节/关联角色, so that 伏笔有完整元数据
39. As a 用户, I want 伏笔逾期未回收时收到提醒, so that 我不会忘记填坑
40. As a 用户, I want AI 生成时自动注入当前活跃伏笔列表, so that AI 不会遗忘或矛盾

### P1：Strand Weave 节奏控制

41. As a 用户, I want 设定主线/感情/世界观的配比（如60/20/20）, so that 节奏可控
42. As a 用户, I want AI 生成时遵守配比约束并标注当前段落属于哪条线, so that 不会偏废
43. As a 用户, I want 设置红线约束（如"连续3章不得无主线推进"）, so that 有底线保障

### P1：风格蒸馏引擎

44. As a 用户, I want 从已有作品中提取文笔 DNA（句式/用词/节奏/修辞偏好）, so that AI 续写能保持我的风格
45. As a 用户, I want 风格档案作为可复用资产跨项目使用, so that 换书也能保持风格一致
46. As a 用户, I want 风格蒸馏结果可编辑微调, so that 我能修正 AI 的误判

### P1：拆书知识库 + 参考书管理

47. As a 用户, I want 导入一本作品后 AI 自动分析其结构/节奏/人设/爽点, so that 我能学习借鉴
48. As a 用户, I want 拆书结果回灌到生成上下文, so that AI 写出来的东西有"读过好书"的质感
49. As a 用户, I want 用我自己的 API Key 调用 LLM 完成拆书分析, so that 不需要灵笔服务端
50. As a 用户, I want 通过 URL 导入/在线搜索小说站导入参考书, so that 我能快速建立对标库
51. As a 用户, I want 大篇幅参考书支持断点续爬, so that 网络中断不用从头来
52. As a 用户, I want 参考书深度分析（风格/人物/情节/氛围四层）, so that 我能精准学习对标的优点

### P1：AI 网页搜索（蒸馏 OpenWrite）

53. As a 用户, I want AI 在对话中主动联网搜索素材与资料, so that 写历史/科幻等需要考据的题材时不用自己切浏览器
54. As a 用户, I want 搜索结果自动注入当前对话上下文, so that AI 基于搜索结果继续创作
55. As a 用户, I want 配置搜索服务（如 AnySearch/SearXNG/自建）, so that 我有选择权

### P1：WebDAV 云同步（蒸馏 OpenWrite）

56. As a 用户, I want 项目/Skill/对话记录通过 WebDAV 同步到云端, so that 多台设备间无缝切换
57. As a 用户, I want 配置任意 WebDAV 服务器（坚果云/Nextcloud/自建）, so that 数据主权在我手里
58. As a 用户, I want 同步冲突时有明确的解决策略（时间戳优先/手动选择）, so that 不会丢数据

### P1：扫榜（市场趋势分析）

59. As a 用户, I want 导入/爬取起点/番茄/晋江等平台的榜单数据, so that 我知道当前什么题材火
60. As a 用户, I want AI 分析榜单趋势（题材/标签/开头模式/爽点密度）, so that 我开书时有数据支撑
61. As a 用户, I want 扫榜结果可保存为市场情报资产，后续创作时引用, so that 分析不是一次性的

### P1：向量知识库 (RAG)

62. As a 用户, I want 项目内所有设定/章节/参考书自动向量化, so that AI 生成时能语义检索相关内容
63. As a 用户, I want 生成前自动召回与当前章节语义相关的段落/设定/伏笔, so that 上下文不遗漏
64. As a 用户, I want 向量库支持重建（设定变更后重新索引）, so that 检索结果始终准确

### P1：批量生成 + 任务队列

65. As a 用户, I want 批量生成多章（如一次生成5章草稿）, so that 我不需要逐章点击
66. As a 用户, I want 后台异步任务队列，支持取消/重试/查看进度, so that 批量操作不阻塞 UI
67. As a 用户, I want 批量生成时每章仍遵守反幻觉约束和状态回写, so that 质量不因批量而下降

### P1：套餐/公益模型（蒸馏 OpenWrite）

68. As a 新用户, I want 有免费公益模型可供体验（能力偏低但零门槛）, so that 我没有 API Key 也能试用
69. As a 用户, I want 公益模型有明确的配额限制和性能提示, so that 我知道它的局限性

### P2：六维审稿

70. As a 用户, I want 生成后从爽点/一致性/节奏/OOC/连续性/追读力六个维度自动审稿, so that 质量有多角度保障
71. As a 用户, I want 审稿结果以评分+具体问题列表呈现, so that 我知道哪里需要改

### P2：变更传播

72. As a 用户, I want 修改设定后自动识别受影响章节, so that 我不需要逐章排查
73. As a 用户, I want 对受影响章节提供逐章修复建议, so that 修改成本可控

### P2：多模型路由

74. As a 用户, I want 为规划/正文/审阅分别指定不同模型, so that 我可以用便宜模型规划、贵模型写正文
75. As a 用户, I want 多模型路由基于已统一化的 EndpointConfig, so that 每个路由槽位都能选任何供应商

### P2：去AI味引擎

76. As a 用户, I want 检测生成文本中的 AI 写作痕迹（如"值得注意的是"/"不禁"等）, so that 文本更自然
77. As a 用户, I want 分场景改写去AI味（保持原意）, so that 不会被读者看出是 AI 写的

### P2：一键成剧（重量 Skill，超出 OpenWrite）

78. As a 小说作者, I want 一键将小说拆解为角色提示词卡+分镜脚本+场景描述, so that 我能快速产出漫剧/短剧资产
79. As a 漫剧工作者, I want 导入剧本后获得角色一致性描述+镜头语言标注, so that 生图时角色不变脸
80. As a 游戏开发者, I want 从小说提取角色/场景/剧情分支资产, so that 我能快速搭建游戏叙事
81. As a 用户, I want 一键成剧支持预设风格（国漫/日漫/写实/3D）+ 自定义补充, so that 输出贴合我的目标平台
82. As a 用户, I want 一键成剧作为重量 Skill 走 Skill Runtime, so that 社区可以扩展新的输出格式

### P2：平行世界（超出 OpenWrite，源自红果短剧）

83. As a 用户, I want 在某个剧情节点创建分支，生成多条平行故事线, so that 我能探索不同走向
84. As a 用户, I want 每条分支继承分叉点的完整上下文（角色/设定/伏笔状态）, so that 分支不会丢失前文
85. As a 用户, I want 基于已有 IP 资产生成不同版本的剧本/提示词（成剧下游）, so that 一个 IP 能产出多种形态

### P2：角色关系图谱可视化

86. As a 用户, I want 看到角色之间的力导向关系图（拖拽/缩放/高亮）, so that 复杂人物关系一目了然
87. As a 用户, I want 关系图随剧情推进自动更新（新增角色/关系变化）, so that 图谱始终反映当前状态
88. As a 用户, I want 点击角色节点跳转到角色详情, so that 快速查阅

### P2：工作流审批

89. As a 用户, I want 蓝图/卷/章节有审批流（草稿→待审→通过/拒绝）, so that 生成内容不会未经确认就定稿
90. As a 用户, I want 拒绝时附带修改意见，AI 据此重新生成, so that 迭代有方向

### P2：短篇写作支持

91. As a 短篇作者, I want 有专门的短篇引导流程（情绪设计/反转构思/精修出稿）, so that 不需要走长篇的世界观→大纲流程
92. As a 短篇作者, I want 短篇拆文（故事核/结构分析/情感线/反转设计/共鸣分析）, so that 我能学习优秀短篇
93. As a 短篇作者, I want 短篇扫榜（知乎盐言/番茄短篇风口数据）, so that 我知道短篇市场要什么

## Implementation Decisions

### 架构决策（来自 ADR-0001 ~ 0005）

- **引导式 AI = 三层混合架构**：编排层（GuidedFlowEngine，数据驱动状态机）+ 内容层（题材 Skill）+ 执行层（AIService.chat()）
- **供应商统一化**：取消内置/自定义区分，所有供应商 = EndpointConfig { id, name, baseUrl, apiKey, protocol(openai|anthropic), modelId }；AIProviderFactory 不再 switch(name)
- **双协议**：OpenAI 兼容（/v1/chat/completions）+ Anthropic（/v1/messages）
- **模型自动发现**：从 /v1/models 拉取
- **产出物存储**：项目级结构化文件（project_meta/*.json）+ Canon 轻量索引
- **世界宪法**：Hard Invariants（不可变）+ Soft Guidance（可编辑）分层
- **UI 混合模式**：首次创建→全屏引导（世界观+角色）→后续→AI Panel
- **内容层 = Skill 生态**：预装官方题材 Skill，社区可替换
- **一键成剧 = 重量 Skill**：走 Skill Runtime
- **平行世界 = 双定位**：小说分支 + 成剧下游
- **联网功能分阶段**：当前 local-first（用户 API + 爬虫工具），后期付费功能上服务器

### 模块变更

- **AIService 重构**：去掉 5 个硬编码 Provider 实例，改为 EndpointConfig 列表 + 统一 Provider 工厂；新增思考模型推理内容管理、停止生成状态保护、参数即时校验、异常字符过滤
- **GuidedFlowEngine（新建）**：步骤定义加载（YAML/JSON）、状态推进、完成判定（AI 辅助）、暂停/恢复、产出物写入触发；支持长篇/短篇两种流程模板
- **ProjectMetaRepository（新建）**：project_meta/ 目录下结构化文件的 CRUD + schema 版本管理 + Canon 索引同步
- **Skill Runtime 扩展**：新增 `type: guided_flow` Skill 类型，支持多轮有状态对话
- **ContextAssembler 扩展**：新增世界宪法/伏笔/节奏配比/风格档案/状态快照等数据源；集成 RAG 语义召回
- **NovelApplicationService 扩展**：集成反幻觉约束注入、监督 Agent 调用、生成门禁、批量生成编排
- **OnboardingWizard 重构**：供应商选择改为统一列表 + "添加自定义"平级入口 + 地址格式指引
- **AIPanel 扩展**：顶部引导进度条 + 引导/自由对话模式切换
- **WebSearchService（新建）**：AI 网页搜索能力，可配置搜索后端（AnySearch/SearXNG/自建），结果注入对话上下文
- **SyncService 扩展**：新增 WebDAV 协议支持，项目/Skill/对话记录云同步，冲突解决策略
- **ExportService 扩展**：新增 Word (.docx) 导出，兼容作家助手格式
- **ReferenceBookService（新建）**：参考书管理（URL导入/在线搜索/断点续爬）+ 四层深度分析（风格/人物/情节/氛围）
- **VectorKnowledgeService（新建）**：项目内向量化 + 语义检索 + 索引重建，基于本地嵌入模型或用户 API
- **TaskQueueService（新建）**：后台异步任务队列（批量生成/重建索引/参考书分析），支持取消/重试/进度查询
- **MarketIntelService 扩展**：扫榜能力（榜单爬取 + AI 趋势分析 + 情报资产保存）
- **CharacterGraphService（新建）**：角色关系图谱数据维护 + 自动更新（从章节状态回写中提取）
- **WorkflowApprovalService（新建）**：蓝图/卷/章节审批流（草稿→待审→通过/拒绝）+ 拒绝意见回注

### 数据模型变更

- **EndpointConfig**：{ id, name, baseUrl, apiKey, protocol, modelId, authStrategy?, isReasoningModel? }
- **GuidedFlowDefinition**：{ id, genre, type(long|short), steps: [{ id, name, prompt, constraints, completionCriteria, outputs }] }
- **ProjectMeta**：worldbuilding.json / characters.json / outline.json / foreshadowing.json / style_profile.json / chapter_states/ / market_intel/ / references/
- **WorldConstitution**：{ hardInvariants: [], softGuidance: [] }
- **ChapterStateSnapshot**：{ chapterId, activeCharacters, emotionArc, unresolvedForeshadowing, timeline, strandDistribution }
- **ForeshadowingEntry**：{ id, description, plantedChapter, expectedPayoffChapter, status, relatedCharacters }
- **StrandWeaveConfig**：{ strands: [{ name, ratio }], redLines: [] }
- **StyleProfile**：{ sentencePatterns, vocabulary, rhythm, rhetoricPreferences, samples }
- **ReferenceBook**：{ id, title, source(url/file), crawlProgress, analysis: { style, characters, plot, atmosphere } }
- **VectorIndex**：{ projectId, entries: [{ id, type, content, embedding }], lastRebuiltAt }
- **TaskQueueItem**：{ id, type, status(pending/running/done/failed/cancelled), progress, retryCount, result }
- **MarketIntelAsset**：{ id, platform, crawledAt, trends: [{ genre, tags, heatScore, patterns }] }
- **CharacterRelation**：{ fromId, toId, relationType, description, sinceChapter }
- **ApprovalRecord**：{ targetId, targetType(blueprint/volume/chapter), status(draft/pending/approved/rejected), feedback }

## Testing Decisions

### 测试原则

- 只测外部行为，不测实现细节
- 通过接缝（interface）mock 依赖，不在单元测试中启动真实 LLM 调用
- 集成测试可使用 mock AIProvider 返回预设响应

### 测试接缝

| 接缝 | 测试内容 |
|------|----------|
| AIProvider 接口 | 统一供应商创建、双协议请求格式、模型发现、连接测试、推理内容过滤 |
| ContextDataSource 接口 | 上下文组装优先级、token 预算裁剪、按需加载、RAG 召回 |
| SkillApi 接口 | 权限守卫、沙箱执行、读写 Canon/Document |
| NovelApplicationService | 写作流水线编排、反幻觉约束注入、生成门禁、批量生成 |
| GuidedFlowEngine（新） | 步骤推进、完成判定、暂停恢复、产出物写入触发、长篇/短篇模板 |
| ProjectMetaRepository（新） | 结构化文件 CRUD、Canon 索引同步、schema 版本迁移 |

### 已有测试先例

- `test/pipeline_integration_test.dart`：流水线集成测试模式
- `test/skill_runtime_e2e_test.dart`：Skill 执行端到端测试模式
- `test/model_registry_test.dart`：模型注册/发现测试模式
- `test/onboarding_state_test.dart`：Onboarding 状态机测试模式

## Out of Scope

- **AI 生图/生视频**：灵笔只输出结构化提示词/脚本，不集成生图模型
- **服务端部署**：当前阶段 local-first，服务端是后期商业化方向
- **移动端/Web 端应用**：仅 Flutter Desktop（Windows 优先）；WebDAV 仅为数据同步，非多平台应用
- **多人协作**：不在本次范围
- **付费/订阅系统**：后期商业化阶段
- **Skill Store 后端**：复用 GitHub 基础设施，不自建服务端

## Further Notes

- 本 spec 共 93 个 User Stories，覆盖 P0（31个）/ P1（38个）/ P2（24个）全部功能
- 建议 `/to-tickets` 时按优先级分批，P0 为第一批 tracer bullet
- OpenWrite 功能蒸馏基准：所有 OpenWrite 已有的能力，灵笔必须达到同等完备度
- 预装题材 Skill 的质量直接决定开箱体验，必须达到 OpenWrite 内置引导的水平
- 平行世界 MVP 建议先做"小说分支"，"成剧下游"依赖一键成剧 Skill 完成后再接入
- ADR 文档：docs/adr/0001~0005 记录了所有架构决策的完整背景和取舍
- 功能来源标注：一键成剧/平行世界为超出 OpenWrite 的差异化新增（分别源自 AI漫剧行业需求和红果短剧），其余均为蒸馏自 OpenWrite 或同类竞品
