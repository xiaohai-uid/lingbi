# LingBi 全能力盘点与市场顶尖基准

> 日期：2026-07-27  
> 范围：Windows Flutter 当前分支 `verify/batch1-20260724`  
> 方法：静态代码与测试审计；竞品部分只采用官方网站、官方帮助文档和官方仓库/政策。未使用截图或 Computer Use。  
> 评分：功能深度 / 用户闭环 / 可靠性 / 可控性 / 差异化，每项 0–5。评分是本次审计判断，不是厂商自评。

## 1. 执行摘要

LingBi 不是一个“能力太少”的产品。代码中可辨识出 **31 类产品能力**，覆盖项目写作、模型接入、知识与连续性、审稿、市场情报、改编、Skills、同步和商业化。全量 `flutter test` 本次运行 **847 项全部通过**。然而，当前最大问题是能力没有形成统一闭环：许多模块各自存在 Service、Panel 和单元测试，却没有进入用户从“创建项目→规划→写作→审稿→采纳→发布”的主路径。

成熟度概览：

- 主路径可用：6 类；
- 部分接线：17 类；
- 只有 Service 或只有 UI：8 类；
- 达到商业级：0 类。

这并不否定现有工程量。相反，LingBi 已经拥有少见的候选稿安全采纳、变更传播、叙事线红线、反幻觉监督、中文网文市场情报等“好内核”。但如果模型选择显示与实际请求不一致、RAG/伏笔/关系/风格并未注入主生成管线、项目保存和恢复没有商业级保证，再多面板也无法兑现“顶尖”。

重新定位建议：

> **LingBi 是面向中文长篇网文职业作者与小型内容工作室的、本地优先、模型中立、可追溯的 AI 创作操作系统。**

它不服务“所有写作者的所有场景”。核心用户是在 Windows 上持续连载、需要管理长篇设定与剧情状态、希望使用自有模型/API，并且不能接受 AI 覆盖人工正文或忘记前文的作者。短故事、短剧改编、市场情报是专业扩展，不是首屏主定位。

## 2. 成熟度定义

| 等级 | 定义 |
|---|---|
| 只有 UI | 看得到入口或控件，但没有真实服务调用/数据结果 |
| 只有 Service | 有模型与业务代码，但当前 UI 主路径不可达 |
| 部分接线 | UI 调用了 Service，但输入、上下文、持久化、错误恢复或后续动作缺失 |
| 主路径可用 | 用户可以从入口得到结果并保存/继续，但尚未满足商业可靠性 |
| 商业级 | 有完整异常、恢复、性能、真实网络/模型、升级迁移、隐私与 Windows 发布验证 |

“测试通过”不自动等于商业级。UI 管线集成测试明确使用 Fake Pipeline（`test/ui_v2_pipeline_integration_test.dart:171-178`），而现有全链路测试主要验证服务组合（`test/e2e_workflow_test.dart:95`），没有替代真实 Windows 文件中断、真实模型、断网、升级、DPI 和安装包测试。

## 3. 完整能力地图与评分

### A. 创作工作台与基础工程

| # | 能力 | 当前证据与成熟度 | 五维评分 | 市场位置 | 顶尖目标与可验证验收 |
|---:|---|---|---|---|---|
| 1 | 项目与本地文档 | `ProjectService` 支持 portable project、扫描磁盘和 CRUD（`lib/services/project_service.dart:19-114`）；`DocumentService` 支持创建、保存、删除、重命名（`lib/services/document_service.dart:21-87`）。**主路径可用** | 3/3/3/3/3 | 接近 OpenWrite，本地工程明显落后 Scrivener | 项目事务、回收站、自动备份、升级迁移、损坏修复；1000 章项目冷启动 <3 秒，强杀后已确认内容零丢失，另一台 Windows 可完整恢复 |
| 2 | 长文编辑器 | Quill 编辑、Slash 检测和 30 秒防抖保存已接入（`lib/ui_v2/pages/editor_page.dart:80-105`、`:208-233`）。退出仅 fire-and-forget，错误被吞。**部分接线** | 3/3/2/3/2 | 明显落后 Scrivener/LivingWriter | 输入日志或 WAL、保存状态可见、恢复草稿、章节拆分重排、目标统计；强杀 1000 次不丢超过最后一次可见已保存点 |
| 3 | 大纲、节拍与故事画布 | StoryBeat 仓库和 Storyboard 页面存在（`lib/core/database/story_beats_repository.dart:13-31`、`lib/ui_v2/pages/storyboard_page.dart:136`），但不是项目创建/生成的必经上下文。**部分接线** | 2/2/2/3/2 | 落后 Novelcrafter Plan Matrix、Scrivener Corkboard、Sudowrite Canvas | 场景/POV/地点/子情节矩阵，卡片拖动重排正文并更新生成上下文；100 章筛选、重排和冲突检查可复现 |
| 4 | 候选稿、安全采纳与冲突保护 | 候选稿落盘、拒绝、采纳；采纳前校验源版本、创建快照和写锁（`lib/modules/pipeline/candidate_service.dart:109-248`、`lib/modules/pipeline/novel_application_service.dart:469-545`）。**主路径可用** | 4/3/3/4/5 | 架构接近标杆，具备领先潜力 | 持久化多分支时间线、局部 diff/采纳、崩溃安全原子替换。当前先删目标再 rename（`:513-518`）并非严格原子；注入每个故障点后正文必须仍为旧版或完整新版 |
| 5 | 版本、快照、恢复 | 版本保存/读取/恢复可用（`lib/services/version_history_service.dart:44-125`），候选管线另有 snapshots；缺统一恢复中心和 diff。**部分接线** | 3/2/2/3/2 | 落后 Scrivener Snapshots、NovelAI branching timeline | 自动版本、人工命名、逐段 diff、候选分支、回收站、项目灾难恢复统一；任意历史节点一键预览和无损恢复 |
| 6 | 导入、导出与出版编译 | Markdown/TXT/PDF/“Word”及项目目录导出（`lib/services/export_service.dart:13-88`）。“Word”实际是 HTML 写入文件（`:43-49`、`:117-142`），不是标准 DOCX。**部分接线** | 3/2/2/2/1 | 明显落后 Scrivener、Novelcrafter、LivingWriter | 真 DOCX/EPUB/PDF/纯文本、样式模板、全项目包（正文+Canon+设置+历史+Skills）；Word/EPUB 通过格式校验并可在主流工具无警告打开 |

### B. AI 生成、模型与上下文

| # | 能力 | 当前证据与成熟度 | 五维评分 | 市场位置 | 顶尖目标与可验证验收 |
|---:|---|---|---|---|---|
| 7 | 多 Provider、自定义 API 与模型发现 | EndpointConfig、OpenAI-compatible/Anthropic 协议、模型发现和安全 Key 存储均已存在（`lib/core/ai/provider_factory.dart:36-57`、`lib/services/settings_service.dart:258-284`、`:517-535`）。**部分接线** | 4/2/2/4/4 | 设计接近 Novelcrafter，运行一致性落后 | 加 OpenRouter/Ollama/LM Studio 明确向导；UI 选中模型必须与请求 payload、日志快照一致；切换、失败回滚、重启恢复做真实端点契约测试 |
| 8 | 运行时模型切换 | `setSelectedModelId` 只保存 ID（`lib/services/settings_service.dart:250-255` 附近的模型映射），`AIService` 实际只按 Endpoint 创建 provider（`lib/services/ai_service.dart:52-69`）。多个 Service 在 DI 时捕获当时的 provider（`lib/core/di/service_locator.dart:231-285`）。**虚假完成/部分接线** | 2/1/1/2/1 | 明显落后 Novelcrafter | 单一 `ModelRuntime`，每次任务解析 provider+model 快照；切换后所有工具下一请求立即使用新模型，旧流不中断，0 次 UI/请求不一致 |
| 9 | 任务级模型路由 | 规划/写作/审稿三个 RouteSlot 有配置解析和成本提示（`lib/services/model_router_service.dart:115-225`），但主 AI/管线没有消费 router。**只有 Service + UI** | 3/1/2/3/4 | 概念先进，交付落后 | 路由实际进入每个任务；支持默认、超时、限流、费用上限和 fallback 记录；故障矩阵下任务结果能说明使用了哪个模型、为何降级 |
| 10 | AI 对话、续写、润色与 Slash Skills | AIService 流式对话/续写，编辑器内置智能续写、润色、去 AI 味（`lib/services/ai_service.dart:114-216`、`lib/services/skill_action_service.dart:301-464`）。**主路径可用** | 3/3/2/3/2 | 落后 Sudowrite/NovelAI 的生成质量与控制 | 场景目标→2–4 候选→风格/视角/长度控制→局部 diff→采纳；建立中文题材 Eval 集，盲评胜率和拒绝率均有门槛 |
| 11 | 上下文编译与可解释注入 | ContextAssembler 有预算和多段上下文（`lib/modules/pipeline/context_assembler.dart:115-248`），ProjectDataSource 读取当前/前章、角色和世界规则（`lib/modules/pipeline/project_data_source.dart:144-278`）。但摘要只是“标题+字数”，运行态/关系/伏笔、strand、RAG 返回空（`:253-264`、`:296-299`）。**部分接线** | 3/2/2/3/4 | 明显落后 Novelcrafter/NovelAI | 上下文检查器显示来源、时点、token、裁剪理由；自动实体链接和 progression；固定任务中关键事实召回率 ≥95%，过期状态误注入 <1% |
| 12 | 创作罗盘与作者意图 | AuthorIntent、CurrentFocus 和持久化 Store 存在（`lib/modules/pipeline/creative_compass.dart:14-252`），没有主 UI 闭环。**只有 Service** | 3/1/2/4/4 | 有差异化概念 | 在场景/章节级展示“本次想实现什么”，生成和审稿都引用它；用户可锁定不可更改项，验收为锁定约束违反率 <2% |
| 13 | 生成流水线与章节结算 | prepare→context→candidate→review→adopt→settlement 状态机、BookState 和未结算阻断已实现（`lib/modules/pipeline/novel_application_service.dart:195-260`、`:304-423`、`:557-706`）。**部分接线** | 4/3/3/4/5 | 架构领先潜力 | 将审稿、Canon/状态变更建议、用户确认和恢复做成可见工作流；每阶段可重入、可取消、可恢复，故障注入后状态机无死锁 |

### C. 世界观、连续性与知识

| # | 能力 | 当前证据与成熟度 | 五维评分 | 市场位置 | 顶尖目标与可验证验收 |
|---:|---|---|---|---|---|
| 14 | Canon 人物/地点/设定/情节点 | 四类 Canon CRUD、搜索和语义搜索已有 UI（`lib/services/canon_service.dart:54-170`、`lib/ui_v2/pages/canon_page.dart:59-457`）。**主路径可用** | 3/3/3/3/3 | 接近基础 Story Bible，落后 Novelcrafter Codex/Campfire | 自动正文提及链接、别名、来源、有效时间、章节 progression、双向引用；实体链接 F1 ≥0.9，状态冲突有证据链 |
| 15 | 人物关系图 | CRUD、AI 从章节提取关系、合并和力导向布局（`lib/services/character_relation_graph_service.dart:235-452`），有 Panel。**部分接线** | 4/3/3/4/4 | 接近 Campfire 的关系可视化 | 关系强度、方向、时间版本、正文证据、冲突检测并注入场景；每条自动关系必须可追溯到文本且可撤销 |
| 16 | 伏笔生命周期 | 建立/解决/逾期检测/上下文文本已有（`lib/services/foreshadowing_service.dart:133-294`），Panel 可 CRUD；主生成数据源仍返回空伏笔。**部分接线** | 4/3/3/4/5 | 功能有领先潜力 | 正文自动发现、人工确认、计划回收窗口、逾期与误回收报警、生成约束；标注数据集召回率 ≥85%，用户确认后零静默改写 |
| 17 | 多叙事线与红线 | 叙事线比例、红线、自动标注、分布和生成前 gate（`lib/services/strand_weave_service.dart:39-355`），有完整 Panel，但管线 `getStrandConstraints` 为空。**部分接线** | 4/3/3/4/5 | 同类少见，已具差异化 | 与大纲矩阵和生成管线统一；跨 20 章监控偏离并解释，红线违反必须在采纳前阻断或要求确认 |
| 18 | 反幻觉与一致性监督 | 约束前言、AI 输出新发明识别、章节快照、监督报告（`lib/services/anti_hallucination_service.dart:139-409`），有 Panel，尚未成为采纳 gate。**部分接线** | 4/2/2/4/5 | 已具领先潜力 | 生成前/后双 gate，区分“新创意”与“冲突”，给 Canon/章节证据；高风险冲突召回 ≥95%，误报 <10% |
| 19 | 向量知识库/RAG | 增量索引、批量索引、余弦搜索和 RAG 文本构建（`lib/services/vector_knowledge_service.dart:129-350`）。Windows ZVec 被明确降级，原生加载永远返回空，vectorSearch 退化普通查询（`lib/core/database/zvec_service.dart:46-110`）；管线 RAG 返回空。**虚假完成/部分接线** | 3/2/1/3/3 | 明显落后 Novelcrafter 上下文体系 | Windows 可工作的本地向量库/可选远程 embeddings，增量失效、来源定位、上下文预算；10 万段 p95 检索 <300ms，Recall@5 达目标，关闭联网可运行 |
| 20 | 参考书采集与四维分析 | URL/file/manual、断点式抓取和风格/人物/情节/氛围分析（`lib/services/reference_book_service.dart:196-511`）。默认抓取器及版权/robots/解析稳定性不足，结果未进入主上下文。**部分接线** | 4/2/2/3/4 | 独特但风险高 | 只处理用户授权来源；文件导入优先，引用段落可追溯，风格只抽象不复现原文；每条洞察含来源位置，失败可续跑 |
| 21 | 风格蒸馏与绑定 | 从样本提取词汇、节奏、修辞等 StyleProfile，可保存、绑定、编辑、生成约束（`lib/services/style_distillation_service.dart:49-233`）。主 pipeline 的 `_styleCache` 未加载（`lib/modules/pipeline/project_data_source.dart:114-119`）。**部分接线** | 4/3/2/4/4 | 接近 Sudowrite 风格承诺，未闭环 | 绑定后实际注入，显示约束和强度；跨题材盲评确认“像作者但非复制”，相似片段检测避免复现参考文本 |

### D. 审稿、修订与质量控制

| # | 能力 | 当前证据与成熟度 | 五维评分 | 市场位置 | 顶尖目标与可验证验收 |
|---:|---|---|---|---|---|
| 22 | 六维审稿 | 一致性、节奏、人物等维度评分与修复建议（`lib/services/six_dimension_review_service.dart:191-240`），Panel 可运行。**部分接线** | 3/3/2/3/3 | 落后 Sudowrite Feedback、LivingWriter Analysis | 章节/整书 developmental、line、dialogue、copy、自定义；问题绑定证据与影响范围，支持对话、diff 预览、选择应用；人工标注集准确率与有用率达门槛 |
| 23 | 变更传播 | 根据设定变更检索受影响位置、生成修复建议、批量应用（`lib/services/change_propagation_service.dart:152-280`）。当前依赖尚不可靠的 vector 服务，主流程未触发。**部分接线** | 4/2/2/3/5 | 概念上领先同类 | 修改 Canon 时自动生成 impact plan；逐项 diff、依赖顺序、原文已变更冲突、撤销；100 章基准项目中遗漏率 <5%，绝不静默批改 |
| 24 | 去 AI 味 | 规则命中、段落/章节改写和选择应用（`lib/services/de_ai_flavor_service.dart:122-240`），Panel 可用。**主路径可用** | 3/3/3/4/4 | 中文差异化，质量未验证 | 从“去 AI 味”改为可解释文风诊断；保留事实、视角、声音，逐段 diff；人工盲评自然度提升且事实漂移 <1% |
| 25 | 意图澄清 | 本地规则检测模糊短指令并给 quick options（`lib/services/clarity_check_service.dart:27-75`），编辑器/助手有交互。**主路径可用** | 2/3/4/3/3 | 体验层面接近标杆 | 按任务风险决定是否追问，记住用户偏好，避免每次打断；清晰任务误拦截 <3%，模糊高风险请求追问召回 ≥90% |
| 26 | 工作流审批 | 对章节/大纲/角色/世界观进行提交、批准、拒绝、带反馈重生和 pipeline gate（`lib/services/workflow_approval_service.dart:189-435`），但未成为生成/写入的统一 gate。**部分接线** | 4/2/3/4/4 | 适合工作室协作，单人产品中偏重 | 单人用“确认采纳”，团队版再做角色权限/评论；所有 AI 写入正式资产必须可预览、批准、审计和撤销 |

### E. 专业扩展与生态

| # | 能力 | 当前证据与成熟度 | 五维评分 | 市场位置 | 顶尖目标与可验证验收 |
|---:|---|---|---|---|---|
| 27 | 中文题材引导流程 | Long/Short Flow、7 个题材 Skill 与状态持久化（`lib/services/guided_flow_engine.dart:41-503`、`lib/core/di/service_locator.dart:200-226`）。欢迎页题材卡只回调无参数（`lib/ui_v2/pages/welcome_page.dart:136-155`），创建弹窗再次要求选题材且字段未回写项目存储（`lib/ui_v2/components/app_scaffold.dart:114-230`）。**虚假完成/部分接线** | 4/1/2/3/5 | 内核领先潜力，体验落后 OpenWrite | 点击题材即形成 ProjectBrief，问题结果写入可见资产，随时跳过/返回；创建完成率 ≥85%，首次候选 P50 ≤8 分钟 |
| 28 | Skills、市场与蒸馏 | 动态 Prompt Skill、权限沙箱、安装/卸载、热加载、从项目蒸馏 SKILL.md（`lib/services/skill/skill_executor.dart:44-175`、`lib/services/skill_marketplace.dart:118-265`、`lib/services/skill/distillation_service.dart:64-269`）。权限不是 OS 沙箱，市场可信链不足。**部分接线** | 4/2/2/4/5 | 接近 Sudowrite Plugins，开放性有优势 | 签名、来源、版本、权限说明、审核、回滚、离线包；恶意 Skill 安全测试不能越权读写/联网，运行记录可审计 |
| 29 | 中文网文市场情报 | 远端趋势快照、缓存、AI 分析、写作上下文已有（`lib/services/market_intel_service.dart:112-168`、`:309-420`）。DI 使用默认空 `apiUrl`，Toolbox 又未传项目 genre/platform（`lib/ui_v2/components/toolbox_page.dart:88-92`）。**虚假完成/只有 UI+Service** | 3/1/1/2/5 | 调研样本中无直接同类，差异化最大 | 合法数据连接器；每条结论显示平台、时间、样本量、来源和置信度；无数据时绝不让 AI 伪造。离线缓存可追溯，数据新鲜度 SLA 明确 |
| 30 | 短故事、短剧改编和平行世界 | 短故事情绪曲线/反转/打磨（`lib/services/short_story_service.dart:282-433`）；短剧含角色卡、镜头、场景和输出格式（`lib/services/drama_conversion_service.dart:352-443`）；平行分支、diff、合并状态和戏剧版生成（`lib/services/parallel_world_service.dart:234-488`）。均有 Panel。**部分接线** | 4/2/2/4/5 | 组合少见，但主用户价值未验证 | P2 专业扩展；从已完成小说资产一键派生、保持角色一致、分支可回溯。用真实工作室任务验证节省时间 ≥40%，否则不占主导航 |
| 31 | 联网搜索、同步、商业授权与公益额度 | SearXNG/AnySearch/custom 搜索 Service 可用（`lib/services/web_search_service.dart:174-225`），但 AI 助手搜索/Canon 页签仍硬编码（`lib/ui_v2/components/ai_assistant.dart:623-666`）。WebDAV 有上传下载和冲突模型（`lib/services/sync/webdav_service.dart:103-238`、`lib/services/sync/sync_manager.dart:138-298`）。License 只校验格式并由调用方传过期时间，无服务端签名（`lib/services/license_service.dart:127-145`）；遥测默认开启（`lib/services/sync/sync_manager.dart:74-87`）。**虚假完成/部分接线** | 3/1/1/2/3 | 明显落后商业发行标准 | 搜索结果有来源引用；同步覆盖项目所有资产并有三方冲突 UI；离线签名许可证/服务端权益校验；遥测默认关闭；隐私、退款、导出、升级和订阅到期策略通过发布审计 |

## 4. 市场标杆（只使用第一方材料）

没有一个产品在所有维度顶尖。正确策略不是“复制某一个”，而是为 LingBi 的目标用户选择组合标杆。

### Sudowrite：生成、改写与审稿闭环

官方首页列出 Story Bible 从想法到大纲、章节 beats 与成稿，Write/Rewrite/Expand/Describe/Canvas 等能力；Feedback 支持章节、场景或整书的 developmental、line、dialogue、copy、自定义反馈，并能讨论和修订；Plugins 支持无代码与多阶段工具。证据：[Sudowrite 官网](https://www.sudowrite.com/)、[Feedback](https://www.sudowrite.com/features/feedback)、[Plugins](https://www.sudowrite.com/features/plugins)。

LingBi 对标重点：生成不能止于聊天文本；审稿必须完成“问题→正文证据→影响→修复候选→diff→确认应用”。

### Novelcrafter：Codex、规划、上下文与模型自由

Codex 支持正文提及自动检测/链接、人物与地点 progression、富文本属性和 Smart Highlighting；Plan Matrix 按场景、POV、地点、标签/子情节追踪；官方模型管理覆盖 Claude、Groq、LM Studio、Ollama、OpenAI、OpenAI-compatible、OpenRouter；导出支持 DOCX、Markdown 和包含 Codex/Chat/Snippet 的项目数据。证据：[Codex](https://www.novelcrafter.com/features/codex)、[Plan Matrix](https://www.novelcrafter.com/help/docs/plan/planning-with-the-matrix)、[Chat](https://www.novelcrafter.com/help/docs/chat/uses-for-chat)、[Model Management](https://www.novelcrafter.com/help/docs/models/model-management)、[Export](https://www.novelcrafter.com/help/docs/export/novel)、[Privacy](https://www.novelcrafter.com/privacy-policy)。

LingBi 对标重点：这是最重要的系统标杆。Canon 必须升级为可链接、可随剧情变化、可解释注入的 Codex。

### NovelAI：可控续写、上下文预算、分支历史与隐私

Editor 为输入和生成保留 branching timeline；Lorebook 按激活词把人物/地点/物件/阵营注入上下文；Advanced Settings 分别控制 Memory、Author's Note、Lorebook、Story 的 token、插入位置、裁剪、bias 和 stop；FAQ 说明模型切换、加密故事和保留 retry history 的导出。证据：[Editor](https://docs.novelai.net/en/text/editor/)、[Lorebook](https://docs.novelai.net/en/text/lorebook/)、[Advanced Settings](https://docs.novelai.net/en/text/editor/advancedsettings/)、[Models](https://docs.novelai.net/en/text/models/)、[FAQ](https://docs.novelai.net/en/faq/)、[Terms](https://novelai.net/terms)。

LingBi 对标重点：把现有候选稿升级为可恢复分支；高级用户可以看见并控制上下文，但默认界面仍要简单。

### Scrivener：Windows 本地工程、恢复与编译

Binder、Corkboard、Outliner、Research、Templates、Snapshots/Compare、自动保存与备份、Compile 是长篇写作工程标杆。证据：[Scrivener Windows Features](https://www.literatureandlatte.com/scrivener/features?os=Windows)。

LingBi 对标重点：AI 不可用时仍是一款可信的 Windows 长篇写作器；保存、版本、恢复、编译是底座，不是附加功能。

### Campfire：结构化世界观

官方写作页展示 Manuscript、Index Cards、正文元素标签，以及 cultures、species、settings、languages、Interactive Maps、Characters、Relationship Web、Timeline、Calendar 等互联模块。证据：[Campfire Write](https://www.campfirewriting.com/write)、[Campfire Features](https://www.campfirewriting.com/features)。

LingBi 对标重点：人物/地点/世界观不能只是几篇 Markdown，而要形成有关系、时间和正文引用的实体图谱。

### LivingWriter：一体化编辑体验与整稿分析

官方列出 AI Outlines、Element Generation、Rewrite、Manuscript Chat、Summarize、整章/整书 Analysis、拖放章节、Boards、Research Board、协作评论、Cloud Sync 与出版导出。证据：[LivingWriter 官网](https://livingwriter.com/)。

LingBi 对标重点：18 个工具需要在编辑器、概览和 Canon 的合适时机出现，而不是永久平铺在孤立工具箱。

### 中文/本地优先样本

本轮检查了[阅文作家专区/作家助手](https://write.qq.com/)和[番茄作家专区](https://fanqienovel.com/writer/zone/)。官方公开页可确认它们强在投稿/发布、平台规则、活动、福利和创作课程，但公开资料不足以对其编辑器内部 AI 深度作可靠评分，因此不编造对比。OpenWrite 继续作为已完成本地静态分析的中文 Windows 体验样本，而不伪称其公开官方能力文档。

## 5. 已领先、接近标杆、明显落后、虚假完成

### 已有领先潜力

- 候选稿不直接覆盖正文、采纳前源版本冲突检测；
- 伏笔生命周期、叙事线比例和红线约束；
- Canon 变更传播到章节的影响计划；
- 反幻觉监督与章节结算建议；
- 中文网文市场情报（前提是数据真实、可追溯）；
- Skills 蒸馏与权限声明的开放架构。

这些能力多数是“架构领先潜力”，还不能称市场领先产品，因为缺主流程、真实数据和商业可靠性验证。

### 接近标杆

- 本地项目/文档工作区；
- Canon 基础 CRUD；
- 多 Provider 和自定义兼容端点；
- 风格画像、人物关系、去 AI 味；
- 候选生成和用户采纳模式。

### 明显落后

- 创建项目和首次成果引导；
- 场景级规划矩阵、正文双向链接、剧情时点状态；
- 整书审稿和可操作修订闭环；
- Windows 原子保存、备份、恢复、标准 DOCX/EPUB 编译；
- 云同步冲突解决、隐私政策、授权/支付、遥测同意；
- 真实模型切换一致性和本地模型向导。

### 虚假完成（必须优先纠正宣传与 UI）

1. 题材卡看似选择题材，实际只触发无参数创建回调；
2. 模型选择器显示所选模型，运行 provider 未必应用该 model ID；
3. 模型路由面板存在，但生成任务没有读取路由；
4. RAG 面板存在，主 ContextDataSource 的 RAG/strand 返回空；
5. AI 助手显示联网搜索/Canon 页签，内容仍为硬编码；
6. 市场面板存在，但默认没有数据 API，且项目题材/平台没有传入；
7. “Word 导出”本质是 HTML，不是标准 DOCX；
8. 许可证“激活”没有签名或服务器真实性校验；
9. 同步声明有 merge，但当前冲突模型主要作 keepLocal/keepRemote 决策，缺用户可控三方合并；
10. Windows ZVec 名称仍在，但原生向量能力明确未启用。

## 6. 重新定义护城河

单个功能很容易被复制。LingBi 应把五个已有内核组合成难复制的系统：

1. **中文网文结构知识**：题材 Skills、平台节奏、人物/爽点/伏笔/叙事线；
2. **时点化 Story Graph**：Canon 实体、关系、progression、章节证据；
3. **可解释 Context Compiler**：每次 AI 读了什么、为什么、多少 token、哪些被裁剪；
4. **安全生成事务**：候选分支、审稿 gate、diff、确认采纳、快照、结算和变更传播；
5. **模型中立与本地优先**：自有 Key、本地模型、完整导出、AI 断网仍可工作。

组合后的核心承诺：

> **LingBi 不只帮你“写一段”，而是让 AI 在可见、可控、可恢复的前提下理解并维护一部长篇中文网文。**

市场情报作为第六层差异化：它必须是有来源、时效、样本量与置信度的数据产品，不能是 Prompt 让模型猜趋势。

## 7. 分阶段路线

### P0：可信写作闭环（先让核心承诺成立）

- ProjectBrief、题材直达、项目事务与迁移；
- `ModelRuntime`，修复真实模型切换和 stale provider；
- 项目概览、可见 Story Assets、三问引导；
- FirstChapterWorkflow：上下文预览→多候选→diff→采纳→版本；
- 原子保存、自动备份、恢复中心、标准项目包；
- 遥测默认关闭、数据请求预览、错误和离线状态。

退出条件：首次成果 P50 ≤8 分钟；UI/请求模型不一致为 0；强杀/断电测试零丢失已确认内容；项目可跨 Windows 设备恢复。

### P1：长篇智能护城河

- Story Graph：正文自动链接、别名、progression、关系和时间；
- Context Inspector：来源、token、裁剪、时点；
- 真正接入伏笔、strand、风格、RAG、关系和状态；
- 整书审稿、反幻觉 gate、变更传播与选择性修复；
- 规划矩阵、场景卡和章节重排；
- Skills 签名、权限、版本、审核和回滚。

退出条件：关键事实召回 ≥95%；高风险冲突召回 ≥95%；变更传播遗漏 <5%；所有 AI 正式写入都有证据、diff、确认和撤销。

### P2：职业网文增长层

- 合法的起点/番茄等市场数据连接器与置信度；
- 参考书授权导入和可追溯分析；
- 短故事和短剧改编工作流；
- 平行世界/分支实验；
- 任务级多模型路由、成本预算和 fallback；
- WebDAV 完整资产同步与三方冲突界面。

退出条件：用真实作者/工作室任务验证节省时间、采纳率、留存和付费意愿；没有数据证明价值的扩展不进入一级导航。

### P3：商业规模化

- 团队权限、评论、审批与协作；
- 签名许可证、支付/订阅、退款和权益；
- 崩溃、性能、升级遥测（明确 opt-in）；
- Windows 安装/升级/DPI/键盘/无障碍/安全发布矩阵；
- 明确内容权属、不用于训练、数据删除与导出政策。

## 8. 产品级总验收门槛

1. 所有可点击控件都有真实结果、加载、错误、空状态和键盘焦点；
2. 所有 AI 输出标记 provider/model/prompt 版本/上下文来源；
3. 所有 AI 对正式正文和 Story Assets 的修改都先候选、再 diff、再确认；
4. 所有自动分析结论可追溯到正文/Canon/外部来源；
5. 断网、限流、API Key 失效、磁盘满、文件被外部修改、应用强杀均有恢复路径；
6. 1000 章/300 万字项目的启动、检索、保存、导出达到明确定量预算；
7. 125%/150%/200% DPI、键盘、屏幕阅读器基础路径可用；
8. 完整项目导出不依赖订阅，订阅到期后本地正文永远可读写；
9. 遥测默认关闭，启用前说明字段、目的、保存周期和撤回方法；
10. 真实作者盲测：核心生成质量与 Sudowrite/NovelAI 对比，规划/连续性与 Novelcrafter 对比，工程可靠性与 Scrivener 对比，结果达到预先定义的非劣门槛。

## 9. 五个最意外的发现

1. **LingBi 真正有价值的不是 18 个 Panel，而是一条已经存在但未被产品化的安全生成事务。**候选、源版本冲突、快照、写锁、结算都已出现。
2. **模型切换问题比 UI bug 更严重。**它会同时污染风格、审稿、RAG、短剧等所有在 DI 时捕获旧 provider 的模块，导致用户无法相信结果来自所选模型。
3. **连续性能力“看起来很多、实际注入很少”。**伏笔、关系、叙事线、RAG、运行状态各有 Service，但 ProjectDataSource 对多个字段直接返回空。
4. **市场情报是最有可能形成中国市场独特护城河的功能，也是当前最接近空壳的功能。**默认无数据源且 UI 缺项目上下文；如果做真，竞品公开资料中没有直接等价项。
5. **847 项测试全绿仍掩盖商业风险。**大量测试使用 mock/fake，无法证明真实模型、真实 Windows 文件系统中断、同步冲突、安装升级和标准格式导出。

## 10. 最终判断

此前“8 分钟从题材到第一章”的定位不是错误，但它只描述了获客入口，没有覆盖 LingBi 的全部能力。修正后应采用两层表达：

- 对新用户：**8 分钟开始写第一章。**
- 对职业用户：**在数百万字连载中，让 AI 始终理解、尊重并可追溯地维护你的故事。**

不要把“市面上各种能力都达到顶尖”解释为每个功能都在 P0 同时做到 5 分。那会再次制造大量孤立面板。真正可执行的顶尖策略是：P0 先做到最可信的 Windows 写作闭环；P1 把 Story Graph + Context Compiler + 安全生成事务做成绝对强项；P2 再用真实市场数据和改编工作流扩张。只有形成可重复测量的用户结果，才算“顶尖”，而不是类和页面的数量。
