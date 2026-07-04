# Task 2: AIProviderFactory — 模型选择支持

**Goal:** Update AIProviderFactory to support selecting specific models per provider.

**Files:**
- Modify: `lib/core/ai/ai_provider_factory.dart`
- Modify: `lib/core/ai/openai_provider.dart`
- Modify: `lib/core/ai/claude_provider.dart`
- Modify: `lib/core/ai/deepseek_provider.dart`
- Modify: `lib/core/ai/free_provider.dart`
- Test: `test/ai_provider_factory_test.dart`

**Requirements:**
- AIProviderFactory.getProvider() should accept an optional `modelOverride` parameter
- When modelOverride is provided, use that model ID instead of the default
- AIProviderFactory should maintain separate cache entries for different model overrides
- AIProviderFactory.invalidate() should clear both default and model-specific caches
- Each Provider's constructor should accept `String? modelOverride` and store it
- The modelOverride should be passed through to the API call

**Constraints:**
- Must maintain backward compatibility (modelOverride is optional)
- Cache key format: `$providerId:$modelOverride` when modelOverride is provided
- Invalidating a provider with modelOverride should clear all cache entries for that provider
- Each Provider must properly store and use the modelOverride

**Test Requirements:**
- Test getProvider with and without modelOverride
- Test cache behavior with modelOverride
- Test invalidate with modelOverride
- Test that modelOverride is passed through to API calls
