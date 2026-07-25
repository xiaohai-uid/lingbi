# 灵笔 Skill 生态执行方案

> 基于 ADR-0002 + 代码审计 + 产品愿景追问（2026-07-24）
> 目标：五批次全部做，分批集成验证，每批端到端测试通过后进下一批

---

## 批次总览

| 批次 | 内容 | 目标 | 预估文件数 |
|------|------|------|-----------|
| 1 | 基础体验修复 | 产品"能用" | 4-6 |
| 2 | Skill Runtime MVP | 飞轮传动轴 | 6-8 |
| 3 | Skill Store 打通 + 蒸馏 | 飞轮第一环闭环 | 4-6 |
| 4 | 市场情报 + 云同步 | "懂市场"维度 | 6-10 |
| 5 | 收费系统 | 第一笔收入 | 4-6 |

---

## 批次 1：基础体验修复

### 1.1 模型选择 UI 完善

**现状**：`lib/core/ai/model_registry.dart`（498行）已有完整的模型元数据（能力/价格/上下文窗口），但 `lib/ui_v2/pages/settings_page.dart` 中用户是否能看到具体模型 ID 并切换，未验证。

**任务**：
- 确认 settings_page.dart 是否已暴露 ModelRegistry 数据
- 如果未暴露：在设置页增加模型选择下拉，显示模型 ID + 价格 + 能力标签
- 在 `lib/ui_v2/components/model_status_bar.dart` 中显示当前激活模型

**验收**：用户能在设置页看到"当前模型: DeepSeek-Chat (¥1/百万token)"并切换到其他模型

**已确认**：运行时从 /v1/models 动态拉取。ModelRegistry 内置已知模型作为 fallback，运行时调用 /v1/models 补充。参考 CC Switch 的供应商管理方式（本地代理 + 多供应商面板 + 一键切换）。

---

### 1.2 思考过程折叠

**现状**：`lib/ui_v2/components/ai_assistant.dart` 未确认是否支持思考流式分离与折叠。

**任务**：
- 检查 ai_assistant.dart 的消息渲染逻辑
- 如果 AI 返回包含 `<think>` 标签或 reasoning 字段：提取为可折叠区块
- 默认折叠，点击展开

**验收**：AI 回复中思考过程默认折叠，不淹没正文

**已确认**：所有接入模型都是 OpenAI 兼容格式。思考内容模仿 DeepSeek 网页版效果——思考过程中流式展示，思考完成后自动折叠为可展开区块。不同 Provider 的思考格式需统一为 OpenAI 兼容的 reasoning 字段。

---

### 1.3 Skill 触发入口接线

**现状**：`lib/ui_v2/components/slash_command_menu.dart`（213行）已实现斜杠菜单 UI，`lib/services/skill_action_service.dart`（472行）已有执行引擎和 3 个内置技能。但未确认编辑器是否真的接了 "/" 触发。

**任务**：
- 在 `lib/ui_v2/pages/editor_page.dart` 中监听 "/" 输入
- 触发 SlashCommandMenu，传入 SkillActionService.registeredSkills
- 选择 Skill 后走 IntentConfirmationService 确认 → 执行 → 输出到候选区或编辑器

**验收**：编辑器中输入 "/" 弹出技能列表，选择"智能续写"后能生成内容

**已确认（代码审计）**：SlashCommandMenu 已在 editor_page.dart 中接线！
- 第 474-485 行：_showSlashMenu 状态 + Positioned 渲染 SlashCommandMenu
- 第 351-356 行：_onSlashDetected() 触发
- 第 647-649 行：AI 面板中有"选择技能 (/)" 按钮触发
- **缺口**：当前是通过按钮触发，不是在编辑器中输入 "/" 自动检测。需要增加编辑器输入监听，检测 "/" 自动弹出菜单。

---

### 1.4 AI 提问机制（通用对话场景）

**现状**：`lib/services/intention_confirmation_service.dart`（180行）已实现 Skill 参数驱动的确认卡。但这只覆盖"通过 Skill 触发"的场景。用户在 AI 面板直接输入模糊请求（如"帮我写一段"）时，AI 是否会先提问？

**任务**：
- 确认 AI 面板的对话流是否对模糊请求执行前置提问
- 如果没有：在 `lib/ui_v2/components/ai_assistant.dart` 中增加"意图不明时的确认卡"逻辑
- 规则：检测模糊关键词（"帮我写""续写""改一下"），先问"写什么？多长？什么风格？"

**验收**：用户输入"帮我续写"时，AI 先问续写方向和长度，而非直接生成

**已确认**：模仿 OpenWrite 的混合策略——先固定化提问（客户端规则引擎，检测关键词触发确认卡），超出规则边界时由 AI 模型自身判断是否需要追问。两层组合：规则层在前，AI 层在后。

---

## 批次 2：Skill Runtime MVP（飞轮传动轴）

### 2.1 Skill 包格式标准

**任务**：定义 .skill 包结构

```
my-skill/
├── SKILL.md           # 必须有，YAML frontmatter + Markdown 指令
├── manifest.yaml      # 重量 Skill 必须有，声明权限和参数
├── scripts/           # 可选，重量 Skill 的可执行代码
│   └── main.dart
├── references/        # 可选，参考文档
└── assets/            # 可选，图片/字体等资源
```

manifest.yaml 格式：
```yaml
id: my-skill
name: 我的技能
version: 1.0.0
author: community
type: lightweight  # lightweight | heavyweight | builtin
category: writing
requires:
  - canon.read
  - document.read
parameters:
  - name: length
    label: 续写长度
    type: select
    default: '300'
    options: ['100', '300', '500', '1000']
input_scope: selection_or_document  # selection | full_document | selection_or_document | none
output_mode: candidate  # candidate | analysis
mutation_policy: insert_at_cursor  # insert_at_cursor | replace_selection | append_to_end | read_only
```

**涉及文件**：
- 新建 `lib/services/skill/skill_manifest.dart` — 解析 manifest.yaml
- 新建 `lib/services/skill/skill_package.dart` — .skill 包的解压和校验

**验收**：给定一个 .skill 包，能解析出 manifest 并验证结构完整性

---

### 2.2 声明式权限系统

**任务**：
- 定义权限枚举：`canon.read`, `canon.write`, `document.read`, `document.write`, `storybeat.read`, `storybeat.write`
- 实现权限校验器：执行 Skill 前检查 manifest 声明 vs 实际调用
- 轻量 Skill 默认只有 read 权限；重量 Skill 按 manifest 声明

**涉及文件**：
- 新建 `lib/services/skill/skill_permission.dart` — 权限枚举 + 校验逻辑
- 修改 `lib/services/skill_action_service.dart` — execute 前加权限检查

**验收**：一个声明了 `canon.read` 的 Skill 尝试写入 Canon 时被拒绝

---

### 2.3 动态 Skill 加载器

**任务**：这是打通 SkillActionService ↔ SkillMarketplace 的关键。

- 扫描 SkillMarketplace 的安装目录（`{用户文档}/lingbi_skills/`）
- 对每个已安装的 Skill：
  - 读取 SKILL.md，解析 YAML frontmatter
  - 如果有 manifest.yaml：解析为重量 Skill
  - 如果只有 SKILL.md：构建为轻量 Skill
  - 注册到 SkillActionService
- 应用启动时自动扫描 + 加载
- Skill 安装/卸载后实时刷新

**涉及文件**：
- 新建 `lib/services/skill/skill_loader.dart` — 动态加载器
- 修改 `lib/services/skill_action_service.dart` — 支持动态注册轻量 Skill
- 修改 `lib/core/di/service_locator.dart` — 启动时调用 SkillLoader

**轻量 Skill 的执行方式**：
- 从 SKILL.md 提取 prompt 模板
- 用 frontmatter 中的 parameters 构造 SkillParameter 列表
- 构建一个 DynamicPromptSkill : SkillAction，buildPrompt 时把模板 + 用户参数 + 上下文拼装

**验收**：在 Skill Store 安装一个社区 Skill（如"伏笔管理器"），斜杠命令中能看到并执行它

**已确认**：使用 Anthropic 标准 SKILL.md 格式（name + description frontmatter + Markdown 正文）。灵笔在运行时解析 Markdown 正文提取 prompt 模板，参数从正文的步骤段落中提取。不扩展 frontmatter。

---

### 2.4 Skill 执行沙箱（重量 Skill）

**任务**：
- 重量 Skill 的 scripts/ 目录里的代码如何执行？
- 选项 A：Dart isolate（安全但受限，不能直接调 Flutter API）
- 选项 B：嵌入 Dart eval/解释器（如 dart_eval 包）
- 选项 C：重量 Skill 只支持声明式 API 调用（不执行任意代码，而是通过 manifest 声明的"动作"映射到内置 API）

**涉及文件**：
- 新建 `lib/services/skill/skill_executor.dart` — 执行引擎
- 新建 `lib/services/skill/skill_api.dart` — 暴露给 Skill 的灵笔 API（canon.read/write 等）

**已确认**：声明式 API。重量 Skill 不执行任意代码，而是通过 manifest.yaml 声明动作（如 canon.write、document.write），映射到灵笔内置 API 调用。

---

### 2.5 端到端验证

**任务**：
- 编写测试：安装轻量 Skill → 斜杠触发 → 权限校验 → 执行 → 输出
- 编写测试：重量 Skill 声明 canon.write → 执行写入 → Canon 条目创建成功
- 编写测试：重量 Skill 未声明 canon.write → 执行被拒绝

**涉及文件**：
- 新建 `test/skill_runtime_test.dart`

---

## 批次 3：Skill Store 打通 + 蒸馏

### 3.1 Skill Store 与 Runtime 联动

**现状**：`lib/ui_v2/pages/skill_market_page.dart`（805行）已完整。`lib/services/skill_marketplace.dart`（285行）已完整。但安装后不会触发 Runtime 重新加载。

**任务**：
- install/uninstall 成功后通知 SkillLoader 刷新
- Skill Store 页面显示"已安装且可用"状态
- 斜杠命令列表实时反映已安装的 Skill

**涉及文件**：
- 修改 `lib/services/skill_marketplace.dart` — 安装后发出通知
- 修改 `lib/services/skill/skill_loader.dart` — 监听安装事件并刷新

**验收**：在 Skill Store 点击安装 → 斜杠命令中立即出现该 Skill

---

### 3.2 蒸馏即创作

**任务**：用户从自己的 Canon + 写作风格自动生成一个轻量 Skill。

流程：
1. 用户在 Skill Store 点击"从我的作品蒸馏 Skill"
2. 选择源材料：Canon 条目（角色/设定）+ 文档样本（前 3 章）
3. AI 分析：提取风格特征（句长/用词频率/修辞偏好）+ 世界观要素
4. 生成 SKILL.md：包含风格 prompt + 参数（题材/基调/视角）
5. 保存到用户本地 Skill 目录，自动注册

**涉及文件**：
- 新建 `lib/services/skill/distillation_service.dart` — 蒸馏逻辑
- 修改 `lib/ui_v2/pages/skill_market_page.dart` — 增加"蒸馏"入口
- 复用 `lib/services/ai_service.dart` — 风格分析 prompt

**验收**：用户选 3 章文档 → 生成一个"我的风格 Skill" → 斜杠命令可用

**已确认**：两者合一。蒸馏出的 Skill 同时包含风格 prompt（句式/用词频率/修辞偏好）和 Canon 引用（角色/设定/世界观要素）。

---

### 3.3 端到端验证

**任务**：
- 测试：蒸馏 → 安装 → 斜杠触发 → 生成的文本风格与源材料一致
- 测试：Skill Store 安装 → 卸载 → 斜杠列表正确更新

---

## 批次 4：市场情报 + 云同步

### 4.1 市场情报 — 用户输入（A）

**任务**：
- 项目创建时增加"目标平台/题材/读者画像"字段
- 这些信息注入 AI 上下文，影响生成建议

**涉及文件**：
- 修改 `lib/core/models/project.dart` — 增加 targetPlatform/genre/audience 字段
- 修改 `lib/ui_v2/pages/welcome_page.dart` 或新建项目时增加配置
- 修改 `lib/modules/pipeline/context_assembler.dart` — 注入市场上下文

---

### 4.2 市场情报 — 平台数据爬取（B）

**任务**：
- 新建微服务或本地模块：爬取起点/番茄/七猫榜单数据
- 定期更新（每日/每周）
- 在写作面板显示"当前热门题材""同类型平均章长"等

**涉及文件**：
- 新建 `lingbi_server/microservices/market-intel/` — 爬取微服务
- 新建 `lib/services/market_intel_service.dart` — 客户端消费
- 新建 `lib/ui_v2/components/market_panel.dart` — 市场情报面板

**已确认**：平台默认爬取公开榜单（标题/标签/热度）。用户可接入自己的 API，通过调用平台的爬虫工具爬取所需信息。

**开源爬虫工具调研结果**（作为内置候选）：
1. MediaCrawler (GitHub 43k+ stars) — 多平台爬虫，支持小红书/抖音/B站/微博/知乎等
2. Crawl4AI (LLM 友好型爬虫) — 专为 LLM 优化的网页爬取器
3. FictionDown (Golang) — 网络小说爬取，支持多站点多线程校对
4. novel-crawler-cli (Node.js + Puppeteer) — 支持起点 VIP 登录爬取
5. EasySpider — 可视化无代码爬虫，可自定义采集任务

**推荐方案**：内置 MediaCrawler 或 Crawl4AI 作为默认爬虫引擎，用户可在设置中配置自定义爬虫 API 地址。

---

### 4.3 市场情报 — 用户群体聚合（C）

**任务**：
- 匿名收集用户题材分布、完读率等聚合数据
- 需要用户明确授权（opt-in）
- 数据存储在 lingbi_server

**涉及文件**：
- 新建 `lingbi_server/microservices/analytics/` — 聚合服务
- 修改 `lib/services/settings_service.dart` — 增加"匿名贡献数据"开关

**已确认**：默认开启，只传匿名统计。需在隐私政策中明确告知用户，并提供关闭选项。

---

### 4.4 云同步

**任务**：
- WebDAV 同步：项目文件 + Skill 配置 + 对话记录
- 参考 OpenWrite 的实现方式

**涉及文件**：
- 新建 `lib/services/sync/webdav_service.dart`
- 新建 `lib/services/sync/sync_manager.dart`
- 修改设置页增加 WebDAV 配置

---

## 批次 5：收费系统

### 5.1 Pro 订阅层（C 优先）

**任务**：
- 免费层：本地编辑 + 自带 API Key + 基础 Skill
- Pro 层：云同步 + 高级导出（Word/PDF 模板）+ 批量操作 + 官方模型套餐

**涉及文件**：
- 新建 `lib/services/subscription_service.dart`
- 新建 `lib/services/license_service.dart` — 许可证验证
- 修改相关功能页增加 Pro 门禁

---

### 5.2 模型套餐代理（A）

**任务**：
- lingbi_server 代理模型调用，加价转售
- 用户充值 → 套餐 → 调用走服务端

**涉及文件**：
- 新建 `lingbi_server/microservices/billing/`
- 新建 `lingbi_server/microservices/proxy-gateway/`
- 修改客户端 AI Provider 增加"灵笔套餐"选项

---

## 确认结果汇总

| 编号 | 问题 | 确认答案 |
|------|------|---------|
| Q1 | 模型列表来源 | 运行时从 /v1/models 动态拉取，ModelRegistry 内置作为 fallback。参考 CC Switch 供应商管理方式 |
| Q2 | AI 思考内容格式 | 所有 Provider 都是 OpenAI 兼容格式。模仿 DeepSeek 网页版——思考流式展示后自动折叠。统一为 reasoning 字段 |
| Q3 | SlashCommandMenu 接线状态 | 已接线！但通过按钮触发，缺编辑器输入“/”自动检测。需补输入监听 |
| Q4 | AI 提问机制 | 混合策略：客户端规则引擎先固定化提问（检测关键词），超出边界由 AI 模型自身判断。模仿 OpenWrite |
| Q5 | 轻量 Skill 格式 | Anthropic 标准 SKILL.md（name + description frontmatter + Markdown 正文）。不扩展 frontmatter |
| Q6 | 重量 Skill 执行 | 声明式 API。manifest.yaml 声明动作，映射到灵笔内置 API，不执行任意代码 |
| Q7 | 蒸馏 Skill 内容 | 两者合一：风格 prompt（句式/用词/修辞）+ Canon 引用（角色/设定/世界观） |
| Q8 | 平台数据爬取 | 默认爬取公开榜单。用户可接入自己的 API 调用爬虫工具。候选内置爬虫：MediaCrawler(43k stars)、Crawl4AI、FictionDown、EasySpider |
| Q9 | 用户数据聚合 | 默认开启，只传匿名统计。隐私政策明确告知，提供关闭选项 |

---

## 依赖关系图

```
批次1（基础体验）─无依赖─→ 可独立完成
  │
  ├─→ 批次2（Skill Runtime）依赖批次1的 Skill 触发入口接线
  │     │
  │     └─→ 批次3（Store打通+蒸馏）依赖批次2的动态加载器
  │           │
  │           └─→ 批次4（市场情报+云同步）依赖批次3的生态闭环
  │                 │
  │                 └─→ 批次5（收费）依赖批次4的 Pro 功能差异化
  │
  └─→ 批次4.1（市场情报-用户输入A）可与批次2并行
```
