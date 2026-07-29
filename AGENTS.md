# 灵笔 AGENTS.md

## 项目概述
灵笔（LingBi）是 Windows 桌面小说创作工具，Flutter Desktop 实现。
核心卖点：世界观（Canon）驱动的 AI 辅助创作，候选正文机制，7 种题材专属技能。

## 构建与验证
```powershell
# 构建
flutter pub get --enforce-lockfile
flutter run -d windows

# 验证（每次代码变更后必须运行）
flutter analyze lib/
flutter test --exclude-tags network
flutter build windows --release
```

## 架构约束
- 6 层分层：shared → domain → modules → services → ui → workflows
- 上层只能依赖下层，不可反向依赖
- UI 不得绕过 NovelApplicationService 直接操作管线
- AI 生成内容必须经过候选正文机制（candidate_store），不得直接落盘
- service_locator.dart 是唯一的 DI 注册点

## AI Provider 架构
- 7 个供应商：OpenAI / Anthropic / DeepSeek / SenseNova / Claude / OpenAI-Compatible / Free
- 所有供应商继承 AIProvider 基类（shared/ai/ai_provider.dart）
- 运行时模型选择通过 RuntimeModelSelection 管理
- 新增供应商必须：继承基类 → 注册到 ProviderFactory → 更新 ModelRegistry

## 代码规范
- Dart >=3.6，使用 ES module 风格 import
- 每个服务必须有对应的接口（services/interfaces/）
- 错误处理使用 Result 模式（shared/errors/result.dart），不抛异常
- 文件命名：snake_case
- 类命名：PascalCase
- 常量命名：camelCase（Dart 惯例）

## 数据流规则
- 写作流：UI → NovelApplicationService → NovelWritingLoop → AIProvider → candidate_store → 用户确认 → 原子写入
- 上下文流：ContextCompiler 收集 Canon + 前文 + 大纲 → token 预算分配 → 组装提示词
- 配置流：SettingsService → RuntimeModelSelection → 各消费者同步

## 新增功能的标准步骤
1. 在 services/interfaces/ 定义接口
2. 在 services/ 实现服务
3. 在 ui_v2/pages/ 或 ui_v2/components/ 实现 UI
4. 在 shared/di/service_locator.dart 注册
5. 运行 flutter analyze lib/ 和 flutter test --exclude-tags network

## PR 审查清单
- [ ] flutter analyze lib/ 零问题
- [ ] flutter test --exclude-tags network 全部通过
- [ ] 没有绕过 NovelApplicationService 直接操作管线
- [ ] AI 生成内容经过候选正文机制
- [ ] 新增 Provider 已更新所有 7 个供应商

## 已知技术债务
- settings_page.dart (52KB) / ai_assistant.dart (43KB) / onboarding_wizard.dart (41KB) 过大需拆分
- ui/ 和 ui_v2/ 双 UI 共存，ui/ 应逐步废弃
- service_locator.dart (467行) 单文件管理 50+ 服务，应拆分
- Layer-first 结构导致功能开发需跨多目录跳转

## 禁止事项
- 不要在没有运行 flutter analyze lib/ 的情况下提交
- 不要让 UI 直接调用 services/ 而不经过 NovelApplicationService
- 不要在 AI 生成内容未经用户确认的情况下写入项目文件
- 不要修改 shared/ai/ai_provider.dart 的接口签名而不更新所有 7 个供应商
- 不要在没有 --enforce-lockfile 的情况下运行 flutter pub get
