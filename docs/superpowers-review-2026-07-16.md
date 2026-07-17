# 灵笔 / Lingbi 全面代码审查报告（Superpowers 工作流）

> 审查方法：遵循 Superpowers 工作流的 `requesting-code-review`（派发代码审查子代理）、`receiving-code-review`（逐项技术核验）、`verification-before-completion`（所有结论均基于实际命令输出/源码）三个核心 skill。
> 审查范围：D:\lingbi-repair（Flutter 3.27.1 / Dart 3.6.0，AI 小说写作工具 "灵笔/Lingbi"）
> 基线 commit：6545407（fix: Dart+Rust 修复 + 334 测试全绿）
> 审查时间：2026-07-16
> 派发 3 个并行审查子代理：UI/Flutter（Galileo）、后端/服务（Kant）、测试与构建（Nash）

## 0. 验证基线（verification-before-completion 证据）
- `flutter analyze`：**250 条问题 = 17 error / 22 warning / 211 info（exit 1，不通过）**
- `flutter test`：**+369 通过 / -30 失败（31s）**。30 个失败全部是集成测试（需要本机运行的微服务：Canvas :8091、Project/Auth :8080、AI Provider、Quota、Settings 等），属环境依赖，**非代码缺陷**。已读 `test/integration_test/health_check_test.dart`、`test/integration/full_stack_test.dart` 确认。
- 当前工作树为**未提交**状态：`git status` 显示 8 个已修改页面 + 3 个未跟踪新组件（wg_nav/wg_popover/wg_sidebar）+ 3 个文档。

## 1. 总体结论
**工作树当前无法编译（17 个分析错误），不具备可发布状态。**
- 功能实现的"骨架"是好的：设计令牌系统、暗色模式、组件抽取、后端真实评分/知识图谱持久化都被审查子代理确认存在且质量不错。
- 但今天未提交的 UI 改造**引入 17 个编译错误**，且交接文档 `docs/handoff-2026-07-16.md` 声称"flutter analyze 0 errors、build 成功、334 测试全绿"——与现状矛盾（验证纪律问题）。
- **不可直接合并/发布**，需先修复 Critical，重新 `flutter analyze` → 0 error 并 `flutter build windows --release` 验证。

子代理各自结论：UI"With fixes"；后端"With fixes"；测试构建"Broken"。

## 2. Critical（必须修复）— 全部为工作树 17 个编译错误
### C1. `WgSidebar` 重名导致 12/17 错误（已在源码核验）
- `lib/ui/theme/wg_components.dart:1180` 旧泛型 `WgSidebar({required this.child})` 是**死代码**（全仓无外部调用）。
- `lib/ui/components/wg_sidebar.dart:15` 新导航 `WgSidebar({this.items})`。
- 两个同名类使 6 个页面 ambiguous_import：`canon_page.dart:39`、`settings_page.dart:80`、`story_canvas_page.dart:49`、`wg_dashboard_page.dart:81`、`wg_editor_page.dart:60`、`wg_workspace_page.dart:68`。
- 修复：删除 `wg_components.dart:1178-1191` 的旧 `WgSidebar`，并给 `wg_editor_page.dart`、`wg_workspace_page.dart` 加 `import 'package:lingbi/ui/components/wg_sidebar.dart';`。一次清除 12 个错误。

### C2. `wg_sidebar.dart:99` Undefined name 'context'
- `_userFooter()` 用了 `WgTokens.borderFor(context)`，但方法无 `BuildContext` 参数。
- 修复：`Widget _userFooter(BuildContext context) => ...`，调用处传 `context`。

### C3. `wg_popover.dart:192` undefined_method openFirstWorkspace
- `WgSearchPanel` 调用 `openFirstWorkspace(context)`（定义在 `wg_nav.dart:64`），但 `wg_popover.dart` 未 import。
- 修复：加 `import 'package:lingbi/ui/components/wg_nav.dart';`

### C4. `canon_page.dart:132` named parameter 'margin' isn't defined
- `TextStyle(... margin: EdgeInsets.only(...))` — `TextStyle` 无 margin。
- 修复：用 `Padding` 包裹 `Text`，从 style 去掉 margin。

### C5. `wg_editor_page.dart:248` 'QuillEditorConfigurations' isn't a class
- `flutter_quill: ^11.0.0`（已解析 11.5.0）v11 API 为 `QuillEditor.basic(config: QuillEditorConfig(...))`，非 `configurations:`。
- 修复：`config: const quill.QuillEditorConfig(placeholder: '开始写作...', padding: EdgeInsets.all(24))`。

## 3. Important（应当修复）
### 前端（UI 子代理）
- I-UI1. **搜索/通知弹层选中后不关闭（UX bug）**：4 个页面传 `onClose: () {}`（如 `settings_page.dart:89`），`OverlayEntry` 永不移除，弹层浮在导航之上。需让 `WgPopover.contentBuilder` 收到 `close` 回调。
- I-UI2. **硬编码颜色**：多处 `Color(0x1AE8A838)` 等应改用 `WgTokens.accentSoft/accent/surfaceStrong`，违背令牌一致性目标。
- I-UI3. 死代码：`wg_editor_page.dart:72` 未用的 `_rail(bool d)`。
- I-UI4. 潜在竞争：`_onSettingsChanged` 中 `setState` 无 `mounted` 守卫。
- I-UI5. 3 个新组件零 widget 测试。

### 后端（后端子代理，均已在源码核验）
- I-BE1. **Claude 流式返回原始 SSE 字节**：`claude_provider.dart:111-112` 直接 yield 解码后的原始 HTTP body；`deepseek_provider.dart:102-108` 正确解析 `data:` 行。Claude 生成的章节会把协议文本直接显示给用户。修复：复用 DeepSeek 的 SSE 解析。
- I-BE2. **流式错误被吞成文本**：`deepseek_provider.dart:114`、`claude_provider.dart:115` yield 错误文本，调用方无法区分失败与正文。修复：抛 `LLMResponseException`。
- I-BE3. **默认 provider 为 'free' 空操作**：`layer1/2/3_generator.dart`、`review_pipeline.dart`、`ai_service.dart` 默认走 `FreeProvider` 占位串，未配置真实 provider 时静默"假成功"。修复：未配置时抛 `LLMConfigurationException`。
- I-BE4. **配额/会员仅客户端、可绕过**：`quota_service.dart:8 _dailyLimit=100`、`quota_service.dart:45` 仅校验 `token.length < 16` 并写本地 `.lingbi_member` 文件，重启即清零。修复：用量入库、会员令牌签名校验。

### 测试与构建（测试子代理）
- I-T1. **集成测试零 CI 覆盖**：`ci.yml` 用非递归 glob `test/*_test.dart`，`test/integration_test/`、`test/integration/` 从不运行；e2e 仅 curl `/health`。30 个 Dart 集成用例在 CI 中完全不跑。
- I-T2. **`flutter test` 对贡献者非密封**：默认跑必失败 30 个，养成忽视失败的习惯。建议用 `bool.fromEnvironment('RUN_INTEGRATION')` 门控。
- I-T3. `test/ai_generation_test.dart` 是弱测试：只跑 `FreeProvider` 占位串，断言 `contains('配置 API Key')`，给"AI 生成"假信心。
- I-T4. 新组件无 widget 测试（同 I-UI5）。
- I-T5. `ci.yml` 锁 3.27、`release.yml` 锁 3.38.0，版本不一致。

## 4. Minor（锦上添花）
- M1. 211 条 info 级 lint 可 `dart fix --apply lib/`（在绿色已提交基线做，勿在破损 WIP 上做）。
- M2. 22 条 warning 指向半完成重构：`unused_field`/`unused_import`/`unused_element`。
- M3. `wg_nav.dart` 与 6 个页面循环依赖（Dart 容忍，但脆弱）。
- M4. 后端小问题：死代码 `ThinkStreamFilter`（base_client.dart）、并行两套已 `@Deprecated` 的 provider 系统、`generateStructured` 失败回退会崩、`BaseLLMClient.embed()` 返回零向量、Go 服务 `CORS *` 与原始错误外泄、`CharacterGraphService` 孤儿实例、`rust/ai-provider` schema 解析失败传 null。

## 5. 强项（被三个子代理一致确认）
- 真实设计令牌系统（`WgTokens` + `*For(context)` 亮度助手），暗色模式真正落地、6 页一致。
- 组件抽取合理：导航/搜索/通知从 5 页重复代码收敛到 `wg_nav/wg_popover/wg_sidebar`。
- 页面比交接文档描述的更完整（workspace 多 tab、story_canvas 交互图、settings 完整 AI 配置 UI）。
- 后端 provider 抽象干净（`BaseLLMClient` + `LLMFactory` + 密封异常层级）、重试真实接线、质量评分为真实启发式、知识图谱持久化存在（drift DAO 测试证明）、Rust ai-provider 生产级、Go 服务稳健、无硬编码密钥。
- 单元测试核心质量高（quality_service / knowledge_graph 用真实 DB 跑行为，非 mock）。

## 6. 修复优先级建议
1. 应用 C1–C5（17 错误）→ `flutter analyze` 必须 0 error，再 `flutter build windows --release`。
2. 修 I-BE1/I-BE2/I-BE3（流式正确性，最高杠杆，影响真实用户输出）。
3. 修弹层关闭 UX（I-UI1）。
4. 门控集成测试（I-T1/I-T2）+ 补新组件 widget 测试（I-UI5）。
5. 统一令牌使用（I-UI2）、清理死代码与告警（M1/M2）。
6. 更正 `docs/handoff-2026-07-16.md` 的"构建验证"声明以反映真实状态。
