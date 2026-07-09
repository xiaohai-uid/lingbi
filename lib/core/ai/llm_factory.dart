import 'base_client.dart';
import 'free_provider.dart';
import 'deepseek_provider.dart';
import 'openai_provider.dart';
import 'claude_provider.dart';

/// LLM 客户端工厂 — 插件式注册 + 按名创建
///
/// 用法：
/// ```dart
/// LLMFactory.register('openai', () => OpenAICompatibleClient(config));
/// final client = LLMFactory.create('openai');
/// ```
class LLMFactory {
  LLMFactory._(); // 防止实例化

  static final Map<String, BaseLLMClient Function()> _registry = {};
  static bool _initialized = false;

  /// 注册一个 Provider 创建函数
  ///
  /// [name] 是唯一标识，如 'openai', 'claude', 'deepseek'。
  /// [factory] 是懒加载创建函数，每次调用 [create] 时都会执行。
  static void register(String name, BaseLLMClient Function() factory) {
    _registry[name] = factory;
  }

  /// 创建指定名称的 Provider 实例
  ///
  /// 如果未找到注册的 Provider，抛出 [ArgumentError]。
  static BaseLLMClient create(String name) {
    if (!_initialized) initBuiltins();
    final factory = _registry[name];
    if (factory == null) {
      throw ArgumentError('Unknown LLM provider: $name. '
          'Available: ${_registry.keys.join(", ")}');
    }
    return factory();
  }

  /// 获取所有已注册的 Provider 名称
  static List<String> get availableProviders => _registry.keys.toList();

  /// 注册内置 Provider
  ///
  /// 默认注册：free, openai, claude, deepseek。
  /// 可通过 [register] 覆盖或添加自定义 Provider。
  static void initBuiltins() {
    if (_initialized) return;
    register('free', () => FreeProvider() as BaseLLMClient);
    register('openai', () => OpenAIProvider() as BaseLLMClient);
    register('claude', () => ClaudeProvider() as BaseLLMClient);
    register('deepseek', () => DeepSeekProvider() as BaseLLMClient);
    _initialized = true;
  }

  /// 重置所有注册（用于测试）
  static void reset() {
    _registry.clear();
    _initialized = false;
  }
}
