import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/ai/free_provider.dart';
import 'package:lingbi/shared/ai/models/endpoint_config.dart';
import 'package:lingbi/shared/ai/runtime_model_selection.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';

/// #40 验证：模型配置链路在向导上下文中端到端可用
///
/// 验收条件：
/// 1. Free 模式选择后无需任何 Key 即可标记配置有效
/// 2. 付费 Provider 选择后 Key 持久化，重启后仍有效
/// 3. 无效 Key 或不可达端点返回明确错误信息（非空、非泛化）
/// 4. 配置变更后 RuntimeModelSelection 立即反映新选择，无需重启
void main() {
  late AIService aiService;

  setUp(() {
    aiService = AIService(quotaService: QuotaService());
  });

  tearDown(() => aiService.dispose());

  group('Free 模式零配置路径', () {
    test('FreeProvider 无需 API Key 即 isAvailable', () {
      final provider = FreeProvider();
      expect(provider.isAvailable, isTrue);
      expect(provider.currentModelId, isNotEmpty);
    });

    test('通过 RuntimeModelSelection 选择 free 路径成功', () async {
      // 模拟向导中选择 Free 模式
      const freeEndpoint = EndpointConfig(
        id: 'free',
        name: '免费模型',
        baseUrl: '',
        apiKey: '',
        protocol: Protocol.openai,
        modelId: 'free-default',
      );
      aiService.addEndpoint(freeEndpoint);
      aiService.setProvider('free');

      String? persistedProvider;
      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: true,
          latencyMs: 0,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: '免费模型无需验证',
        ),
        synchronizeConsumers: [],
        persistSelection: (providerId, modelId) async {
          persistedProvider = providerId;
        },
      );

      final result = await runtime.select('free', 'free-default');

      expect(result.isSuccess, isTrue);
      expect(runtime.current.providerId, 'free');
      expect(persistedProvider, 'free');
    });

    test('Free 模式不需要 apiKey 字段', () {
      const freeEndpoint = EndpointConfig(
        id: 'free',
        name: '免费模型',
        baseUrl: '',
        apiKey: '', // 空 Key
        protocol: Protocol.openai,
        modelId: 'free-default',
      );
      // 空 apiKey 不影响 endpoint 创建
      expect(freeEndpoint.apiKey, isEmpty);
      expect(freeEndpoint.id, 'free');
    });
  });

  group('付费 Provider 配置持久化', () {
    test('选择后 persistSelection 被调用（模拟持久化）', () async {
      const endpoint = EndpointConfig(
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'sk-test-key',
        protocol: Protocol.openai,
        modelId: 'deepseek-chat',
      );
      aiService.addEndpoint(endpoint);
      aiService.setProvider('deepseek');

      String? savedProvider;
      String? savedModel;
      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: true,
          latencyMs: 50,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: '连接成功',
        ),
        synchronizeConsumers: [],
        persistSelection: (providerId, modelId) async {
          savedProvider = providerId;
          savedModel = modelId;
        },
      );

      final result = await runtime.select('deepseek', 'deepseek-chat');

      expect(result.isSuccess, isTrue);
      expect(savedProvider, 'deepseek');
      expect(savedModel, 'deepseek-chat');
    });
  });

  group('无效配置错误路径', () {
    test('无效 Key 返回明确中文错误（非空、非泛化）', () async {
      const endpoint = EndpointConfig(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-invalid',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      aiService.addEndpoint(endpoint);
      aiService.setProvider('openai');

      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => const ConnectionTestResult(
          success: false,
          latencyMs: 100,
          message: '密钥无效，请检查 API Key 是否复制完整',
          errorCategory: '密钥无效',
        ),
        synchronizeConsumers: [],
        persistSelection: (_, __) async {},
      );

      final result = await runtime.select('openai', 'gpt-4o');

      expect(result.isSuccess, isFalse);
      expect(result.message, isNotEmpty);
      expect(result.message, contains('密钥无效'));
      expect(result.message, contains('请'));
    });

    test('不存在的 provider 返回明确错误', () async {
      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: true,
          latencyMs: 0,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: '',
        ),
        synchronizeConsumers: [],
        persistSelection: (_, __) async {},
      );

      final result = await runtime.select('nonexistent', 'model');

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('未找到'));
    });

    test('空 modelId 返回明确错误', () async {
      const endpoint = EndpointConfig(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-test',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      aiService.addEndpoint(endpoint);

      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: true,
          latencyMs: 0,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: '',
        ),
        synchronizeConsumers: [],
        persistSelection: (_, __) async {},
      );

      final result = await runtime.select('openai', '  ');

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('不能为空'));
    });
  });

  group('运行时切换即时生效', () {
    test('切换后 current 立即反映新选择', () async {
      const endpointA = EndpointConfig(
        id: 'provider-a',
        name: 'A',
        baseUrl: 'https://a.invalid/v1',
        apiKey: 'key-a',
        protocol: Protocol.openai,
        modelId: 'model-a',
      );
      aiService.addEndpoint(endpointA);
      aiService.setProvider('provider-a');

      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: true,
          latencyMs: 1,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: '连接成功',
        ),
        synchronizeConsumers: [],
        persistSelection: (_, __) async {},
      );

      expect(runtime.current.modelId, 'model-a');

      await runtime.select('provider-a', 'model-b');

      // 无需重启，立即生效
      expect(runtime.current.modelId, 'model-b');
      expect(aiService.currentModelId, 'model-b');
    });

    test('切换失败后 current 保持原值', () async {
      const endpoint = EndpointConfig(
        id: 'provider-a',
        name: 'A',
        baseUrl: 'https://a.invalid/v1',
        apiKey: 'key-a',
        protocol: Protocol.openai,
        modelId: 'model-a',
      );
      aiService.addEndpoint(endpoint);
      aiService.setProvider('provider-a');

      final runtime = RuntimeModelSelection(
        aiService: aiService,
        validateConnection: (candidate) async => ConnectionTestResult(
          success: candidate.modelId != 'bad-model',
          latencyMs: 1,
          modelId: candidate.modelId,
          providerId: candidate.id,
          message: candidate.modelId == 'bad-model' ? '模型不存在' : '连接成功',
        ),
        synchronizeConsumers: [],
        persistSelection: (_, __) async {},
      );

      await runtime.select('provider-a', 'bad-model');

      expect(runtime.current.modelId, 'model-a');
    });
  });
}
