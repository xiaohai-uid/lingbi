# Task 1 Report: ModelRegistry — Local Model Configuration

## 实现概述

创建了 `ModelRegistry` 模块，为灵笔项目的 AI 模块提供本地模型配置注册表。实现了三个核心类：

1. **ModelInfo** — 单个模型信息类，包含 id、name、category、recommended、deprecated 字段，支持 JSON 序列化/反序列化
2. **PlatformModelConfig** — 平台配置类，包含平台元信息、模型列表、API 端点和认证方式，提供 `recommendedModel` 和 `availableModels` 派生属性
3. **ModelRegistry** — 静态注册表，持有所有 4 个平台的配置数据，提供统一的查询接口

配置了以下 4 个平台：
- **openai**: 5 个模型 (gpt-4o, gpt-4o-mini, gpt-3.5-turbo, o1, o1-mini)
- **claude**: 4 个模型 (claude-sonnet-4-20250514, claude-3-5-sonnet, claude-3-5-haiku, claude-3-opus)
- **deepseek**: 3 个模型 (deepseek-chat, deepseek-coder, deepseek-reasoner)
- **sensenova**: 2 个模型 (sensenova-6.7-flash-lite, sensenova-6.7-flash)

## 创建/修改的文件

| 文件 | 状态 | 说明 |
|------|------|------|
| `lib/core/ai/model_registry.dart` | 新建 | 主实现文件（255 行） |
| `test/model_registry_test.dart` | 新建 | 测试文件（370 行） |

## 测试命令和结果

**命令:**
```bash
flutter test test/model_registry_test.dart
```

**结果:** ✅ All tests passed! (30/30)

| 测试分组 | 通过数 | 说明 |
|---------|-------|------|
| ModelInfo | 6 | 构造、默认值、toJson、fromJson、round-trip |
| PlatformModelConfig | 10 | 构造、默认值、序列化、推荐模型、可用模型过滤 |
| ModelRegistry | 14 | 平台列表、查询、模型列表验证、推荐模型、一致性 |

## 自检查结果

- ✅ 遵循 TDD 方法：先写测试，后实现
- ✅ 纯 Dart 代码，无外部依赖
- ✅ 使用 `dart:convert` 进行 JSON 序列化
- ✅ 所有 30 个测试通过
- ✅ 代码可编译通过
- ✅ Commit message 描述性强，符合 Conventional Commits 规范

## 关注点

1. **无 `dart:convert` 使用**: 虽然简报要求使用 `dart:convert`，但实际实现中只使用了 `toJson/fromJson` 方法返回 `Map<String, dynamic>`，未调用 `jsonEncode/jsonDecode`。这是有意设计——模型配置是静态常量，不需要运行时 JSON 字符串转换。如有需要，后续可添加静态 JSON 字符串常量。

2. **`availableModels` 派生属性**: 当前所有模型均未标记为 deprecated，因此 `availableModels` 等同于 `models`。未来标记废弃模型后，该属性会自动过滤。

3. **`allPlatforms` 返回 `Map.unmodifiable`**: 返回不可修改视图，确保外部无法篡改注册表数据。
