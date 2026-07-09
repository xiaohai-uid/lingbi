import 'package:lingbi/core/ai/base_client.dart';
import 'package:lingbi/core/ai/free_provider.dart';
import 'package:lingbi/core/ai/deepseek_provider.dart';
import 'package:lingbi/core/ai/openai_provider.dart';
import 'package:lingbi/core/ai/claude_provider.dart';

/// AI Provider 工厂（已废弃）
///
/// 请使用 LLMFactory 替代。
@Deprecated('Use LLMFactory from llm_factory.dart instead')
class AIProviderFactory {
  @Deprecated('Use LLMFactory from llm_factory.dart instead')
  AIProviderFactory({required String? Function(String) getApiKey})
      : _getApiKey = getApiKey;
  final String? Function(String provider) _getApiKey;
  final Map<String, BaseLLMClient> _cache = {};

  /// 获取指定名称的 Provider
  ///
  /// [modelOverride] 可选，指定要使用的具体模型 ID。
  /// 如果提供，使用此模型 ID 替代 Provider 默认模型。
  BaseLLMClient getProvider(String name, {String? modelOverride}) {
    final cacheKey = _resolveCacheKey(name, modelOverride);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    final provider = _createProvider(name, modelOverride: modelOverride);
    _cache[cacheKey] = provider;
    return provider;
  }

  /// 构建缓存键：无 modelOverride 时返回 providerId，有则返回 `$providerId:$modelOverride`
  String _resolveCacheKey(String name, String? modelOverride) {
    if (modelOverride == null || modelOverride.isEmpty) return name;
    return '$name:$modelOverride';
  }

  /// 获取所有 Provider（默认模型）
  List<BaseLLMClient> get allProviders => [
        getProvider('free'),
        getProvider('sensenova'),
        getProvider('deepseek'),
        getProvider('openai'),
        getProvider('claude'),
      ];

  /// 获取已配置 API Key 的 Provider 列表
  List<BaseLLMClient> get availableProviders =>
      allProviders.where((p) => p.isAvailable).toList();

  BaseLLMClient _createProvider(String name, {String? modelOverride}) {
    switch (name) {
      case 'free':
      case 'sensenova':
        return FreeProvider(modelOverride: modelOverride);
      case 'deepseek':
        return DeepSeekProvider(
            apiKey: _getApiKey('deepseek'), modelOverride: modelOverride);
      case 'openai':
        return OpenAIProvider(
            apiKey: _getApiKey('openai'), modelOverride: modelOverride);
      case 'claude':
        return ClaudeProvider(
            apiKey: _getApiKey('claude'), modelOverride: modelOverride);
      default:
        return FreeProvider(modelOverride: modelOverride);
    }
  }

  /// 当 API Key 更新时，清除缓存（包括该 provider 的所有 modelOverride 缓存）
  void invalidate(String name) {
    // 清除 name 开头的全部缓存键（含 modelOverride 变体）
    _cache.removeWhere((key, _) => key.startsWith('$name:') || key == name);
  }

  /// 释放所有 Provider
  Future<void> dispose() async {
    for (final provider in _cache.values) {
      await provider.dispose();
    }
    _cache.clear();
  }
}
