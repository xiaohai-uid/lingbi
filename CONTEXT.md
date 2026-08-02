# 灵笔 (LingBi)

Windows 桌面 AI 小说写作工具的领域语言。正典驱动、候选确认、多线叙事。

## Language

### 核心写作管线

**正典 (Canon)**:
一部小说的权威知识库，包含角色、地点、设定（含世界规则）、情节节点四种条目类型。所有 AI 生成必须以正典为事实依据。
_Avoid_: 设定集, 世界观数据库, 百科

**候选正文 (Candidate)**:
AI 生成但未经作者确认的文本。拥有完整生命周期：pending → reviewing → approved / revisionNeeded → adopted / rejected → archived。免费用户每次生成一个候选。
_Avoid_: 草稿, AI 输出, 生成结果

**抽卡模式 (Gacha)**:
付费会员功能。并发生成 N 个候选版本（温度微增以保证多样性），用户从中选最佳。本质是候选正文机制的多版本扩展。
_Avoid_: 多候选, 批量生成

**采纳 (Adopt)**:
将候选正文写入正式正文文件的动作。采纳后候选状态变为 adopted，内容成为小说正文的一部分。
_Avoid_: 确认, 接受, 应用

**发明 (Invention)**:
AI 在生成过程中创造的新设定（角色、地名、规则等）。是正典的候选入口——类比候选正文之于正式正文。用户可接受（纳入正典）或拒绝（永久黑名单，后续生成不得再使用）。
_Avoid_: 虚构内容, 幻觉, 新设定

**创作罗盘 (CreativeCompass)**:
作者意图 + 当前创作焦点的持久配置。注入 prompt 时永不截断，是生成上下文中优先级最高的部分。
_Avoid_: 写作指南, 创作方向

### 上下文工程

**上下文组装 (Context Assembly)**:
从各数据源（正典、伏笔、风格档案、RAG、叙事线约束、市场情报…）收集信息，组装为完整的 GenerationContext 的过程。由 ContextAssembler 执行。
_Avoid_: 上下文收集, prompt 拼装

**上下文编译 (Context Compilation)**:
对已收集的上下文条目进行优先级评分、token 预算分配和确定性裁剪的过程。由 ContextCompiler 执行，产出可解释的 CompiledContext（记录每条裁剪决策）。是 ContextAssembler 内部裁剪逻辑的升级替代。
_Avoid_: token 裁剪, 上下文压缩

**生成上下文 (GenerationContext)**:
送入 AI 的完整上下文包。包含作者意图、创作焦点、上文、大纲窗口、角色卡片、伏笔、风格约束、世界规则、叙事线配比、RAG 召回等。
_Avoid_: prompt, 上下文包

### 叙事结构

**叙事线 (Strand)**:
一条有名字和配比比例的故事线（如主线 0.5、感情线 0.3、世界观线 0.2）。StrandWeave 机制让 AI 生成时遵守配比约束，并标注段落归属。
_Avoid_: 故事线, 线索, 剧情线

**红线 (RedLine)**:
叙事线的硬约束规则。例如"连续 3 章不得无主线推进"。违反时拦截生成并提示用户。
_Avoid_: 底线, 限制规则

**平行世界 (Parallel World)**:
在剧情节点分叉出的平行故事分支。继承分叉点的角色/设定/伏笔状态快照，同一项目可存在多条并行分支，支持对比和合并。
_Avoid_: 分支剧情, IF 线, 平行线

### 风格与知识

**风格档案 (StyleProfile)**:
从作者作品中提取的文笔 DNA：句式、用词、节奏、修辞偏好、代表性文段。全局级资产，可跨项目引用。
_Avoid_: 风格模型, 写作风格, 文风

**风格提取 (Style Extraction)**:
从用户作品中提取 StyleProfile 的过程。由 StyleDistillationService 执行。输入是用户文本，输出是 StyleProfile。
_Avoid_: 风格蒸馏, 风格学习

**技能蒸馏 (Skill Distillation)**:
从正典 + 风格档案自动生成 SKILL.md 的过程。由 DistillationService 执行。实现"产品越用越懂用户"的知识积累飞轮。
_Avoid_: 蒸馏, 风格蒸馏

### 管线与编排

**写作管线 (Writing Pipeline)**:
主写作流程的完整状态机：idle → preflight → writing → reviewing → awaitingAdoption。由 NovelApplicationService 编排，是编辑器 UI 的唯一入口。使用 ContextAssembler。
_Avoid_: 写作流程, 生成管线

**写作循环 (Writing Loop)**:
轻量写作编排器，作为 AI 助手的回退路径（免费模型不支持工具调用时）和"续写下一章"功能。使用 ContextCompiler。由 NovelWritingLoop 实现。
_Avoid_: 续写器, 生成循环

## Onboarding 向导

**A 型步骤 (FreeTextStep)**:
向导中的自由文本输入步骤（主角描述、世界观、第一章目标）。不限字数，不可跳过。
_Avoid_: 填空题, 自由输入

**B 型步骤 (CardSelectStep)**:
向导中的预设卡片选择步骤（题材、字数目标、发布平台、创意方向）。题材为 6 热门卡片 + "更多"展开全部 14 项；其余全展示。支持"+ 自定义"与卡片共存。
_Avoid_: 下拉选择, 单选题

**快速选择屏 (QuickPickScreen)**:
向导第一屏，包含三个必选 B 型维度（题材 + 字数目标 + 发布平台）。目标：10 秒完成作品骨架。
_Avoid_: 基本信息页, 第一步

**深度填写屏 (DeepFillScreen)**:
向导第二屏，混合 A 型（主角、世界观、第一章目标）与 B 型（创意方向，可跳过默认"通用"）。返回第一屏需二次确认且清空全部数据。
_Avoid_: 详细信息页, 第二步

**第一章旅程 (FirstChapterJourney)**:
从向导点击"完成"到第一章被采纳的完整路径：导航到编辑器 → loading → 流式生成 → 候选操作栏 → 采纳固化。断链即 P0 事故。
_Avoid_: 生成流程, 新手引导流程

### 项目结构

**项目简报 (ProjectBrief)**:
项目创建时的持久契约：标题、类型、模板、目标平台、篇幅、受众、前提。一旦设定不可丢弃，只可修订。
_Avoid_: 项目配置, 创作计划

**章节状态快照 (ChapterStateSnapshot)**:
每章生成后自动回写的结构化状态：出场角色、情绪走向、未解伏笔、时间线位置、新发明、叙事线分布。供后续章节生成和监督 Agent 使用。
_Avoid_: 章节摘要, 章节记录
