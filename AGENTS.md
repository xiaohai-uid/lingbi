# 灵笔 AGENTS.md

## 项目概述
灵笔（LingBi）是 Windows 桌面小说写作工具，Flutter Desktop 实现。
核心卖点：正典（Canon）驱动的 AI 辅助写作、候选正文机制、7 个题材专属技能。

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
- Feature-first 分层：shared → domain → features → services → ui_v2 → workflows
- features/ 下按功能域组织：writing, canon, skill, settings, project, onboarding, sync, import_export, strand, review, style
- 每个 feature 内部结构：data/（服务+仓库）+ ui/（页面+组件）
- 上层只允许引用下层，不可反向依赖
- Feature 之间不直接 import 对方 data/ 内部类，通过 services/interfaces/ 抽象
- UI 不得绕过 NovelApplicationService 直接操作文件系统
- AI 生成内容必须经过候选正文机制（candidate_store），不可直接落盘
- service_locator.dart 是唯一的 DI 注入点

## AI Provider 架构
- 7 个供应商：OpenAI / Anthropic / DeepSeek / SenseNova / Claude / OpenAI-Compatible / Free
- 所有供应商继承 AIProvider 基类（shared/ai/ai_provider.dart）
- 运行时模型选择通过 RuntimeModelSelection 策略
- 新增供应商步骤：继承基类 → 注册到 ProviderFactory → 加入 ModelRegistry

## 代码规范
- Dart >=3.6，使用 ES module 风格 import
- features/ 内统一使用 package:lingbi/ 绝对导入
- 每个服务必须有对应的接口（shared/interfaces/）
- 错误处理使用 Result 模式（shared/errors/result.dart），不抛异常
- 文件命名：snake_case
- 类命名：PascalCase
- 变量和函数：camelCase（Dart 惯例）

## 数据流规则
- 写作管线：UI → NovelApplicationService → NovelWritingLoop → AIProvider → candidate_store → 用户确认 → 原子写入
- 上下文编译：ContextCompiler 收集 Canon + 前文 + 大纲 → token 预算裁剪 → 组装提示词
- 模型切换：SettingsService → RuntimeModelSelection → 所有管线同步

## 新增功能的标准步骤
1. 在 shared/interfaces/ 定义接口
2. 在 features/<name>/data/ 实现服务
3. 在 features/<name>/ui/ 实现 UI
4. 在 shared/di/service_locator.dart 注册
5. 运行 flutter analyze lib/ 和 flutter test --exclude-tags network

## PR 审查清单
- [ ] flutter analyze lib/ 零问题
- [ ] flutter test --exclude-tags network 全部通过
- [ ] 没有绕过 NovelApplicationService 直接操作文件系统
- [ ] AI 生成内容经过候选正文机制
- [ ] 新增 Provider 已覆盖全部 7 个供应商

## 已知技术债务
- settings_page.dart (52KB) / ai_assistant.dart (43KB) / onboarding_wizard.dart (41KB) 需要拆分
- settings_service.dart (636行) 管理过多职责（主题、API Key、引导、WebDAV、订阅）
- service_locator.dart (467行) 单文件注册 50+ 服务，应拆分

## 禁止事项
- 不要在未运行 flutter analyze lib/ 的情况下提交
- 不要在 UI 直接调用 services/ 而绕过 NovelApplicationService
- 不要让 AI 生成内容未经用户确认就写入项目文件
- 不要修改 shared/ai/ai_provider.dart 的接口签名（会影响全部 7 个供应商）
- 不要在没有 --enforce-lockfile 的情况下运行 flutter pub get
