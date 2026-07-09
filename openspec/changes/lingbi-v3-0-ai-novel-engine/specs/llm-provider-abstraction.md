# LLM Provider 抽象层重构 — Spec

## 目标

将灵笔当前简单的 AI Provider 接口重构为完整的 LLM 抽象层，借鉴 AI_NovelGenerator 的 `base_client.py` 设计。

## 现状

当前灵笔的 AI Provider (`lib/core/ai/`) 有 4 个 Provider：
- `free_provider.dart` — 空壳，返回空响应
- `deepseek_provider.dart` — DeepSeek 调用
- `openai_provider.dart` — OpenAI 调用
- `claude_provider.dart` — Claude 调用

每个 Provider 直接实现 `AIProvider` 接口，缺少统一错误处理、流式过滤、重试机制。

## 改造目标

### 1. 统一抽象层

```dart
abstract class BaseLLMClient {
  Future<String> generateText(LLMRequest request);
  Stream<String> streamText(LLMRequest request);
  Future<T> generateStructured<T>(LLMRequest request, T Function(Map<String, dynamic>) fromJson);
}
```

### 2. ThinkStreamFilter

从 AI_NovelGenerator 移植 `_ThinkStreamFilter`，自动过滤流式响应中的 `...` 内容：
- 跨 chunk 处理
- 支持 `...` 和 `...` 标签
- 支持 ````json` 代码块提取

### 3. 错误层次

```dart
class LLMError extends Exception { ... }
class LLMAuthError extends LLMError { ... }
class LLMRateLimitError extends LLMError { ... }
class LLMTimeoutError extends LLMError { ... }
class LLMResponseError extends LLMError { ... }
```

### 4. 工厂模式

```dart
class LLMFactory {
  static final Map<String, Type> _registry = {};
  static void register(String type, Type clientClass) { ... }
  static BaseLLMClient create(String providerName) { ... }
}
```

### 5. 重试机制

指数退避重试（从 `retry_handler.py` 移植）：
- 最大重试次数: 3
- 初始退避: 1s
- 退避因子: 2.0
- 仅重试可恢复错误（RateLimit、Timeout）

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib/core/ai/base_client.dart` | 抽象基类 + ThinkStreamFilter |
| `lib/core/ai/llm_factory.dart` | 工厂模式 + Provider 注册 |
| `lib/core/ai/llm_errors.dart` | 错误层次定义 |
| `lib/core/ai/llm_models.dart` | LLMRequest / LLMResponse 模型 |
| `lib/core/ai/retry_handler.dart` | 指数退避重试 |
| `lib/core/ai/schema_processor.dart` | 结构化输出处理 |
| 修改现有 Provider | 适配新接口 |

## 测试

- 每个 Provider 的流式/非流式测试
- ThinkStreamFilter 单元测试（含跨 chunk 场景）
- 重试机制测试
- 错误映射测试