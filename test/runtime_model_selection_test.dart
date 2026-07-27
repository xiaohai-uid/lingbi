import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/ai/models/endpoint_config.dart';
import 'package:lingbi/core/ai/runtime_model_selection.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/quota_service.dart';

void main() {
  late AIService aiService;
  late EndpointConfig endpoint;

  setUp(() {
    aiService = AIService(quotaService: QuotaService());
    endpoint = const EndpointConfig(
      id: 'provider-a',
      name: 'Provider A',
      baseUrl: 'https://example.invalid/v1',
      apiKey: 'test-key',
      protocol: Protocol.openai,
      modelId: 'model-a',
    );
    aiService.addEndpoint(endpoint);
    aiService.setProvider(endpoint.id);
  });

  tearDown(() => aiService.dispose());

  test('successful switch commits runtime provider consumers and settings',
      () async {
    String? consumerModel;
    String? persistedProvider;
    String? persistedModel;
    final runtime = RuntimeModelSelection(
      aiService: aiService,
      validateConnection: (candidate) async => ConnectionTestResult(
        success: true,
        latencyMs: 1,
        modelId: candidate.modelId,
        providerId: candidate.id,
        message: '连接成功',
      ),
      synchronizeConsumers: [
        (provider) => consumerModel = provider.currentModelId,
      ],
      persistSelection: (providerId, modelId) async {
        persistedProvider = providerId;
        persistedModel = modelId;
      },
    );

    final result = await runtime.select('provider-a', 'model-b');

    expect(result.isSuccess, isTrue);
    expect(aiService.currentProviderName, 'provider-a');
    expect(aiService.currentModelId, 'model-b');
    expect(aiService.getEndpoint('provider-a')?.modelId, 'model-b');
    expect(consumerModel, 'model-b');
    expect(persistedProvider, 'provider-a');
    expect(persistedModel, 'model-b');
    expect(runtime.current.modelId, 'model-b');
  });

  test('failed validation leaves the previous runtime selection untouched',
      () async {
    var consumerCalls = 0;
    var persistCalls = 0;
    final runtime = RuntimeModelSelection(
      aiService: aiService,
      validateConnection: (candidate) async => ConnectionTestResult(
        success: false,
        latencyMs: 1,
        modelId: candidate.modelId,
        providerId: candidate.id,
        message: '模型不存在',
      ),
      synchronizeConsumers: [(_) => consumerCalls++],
      persistSelection: (_, __) async => persistCalls++,
    );

    final result = await runtime.select('provider-a', 'missing-model');

    expect(result.isSuccess, isFalse);
    expect(result.message, '模型不存在');
    expect(aiService.currentModelId, 'model-a');
    expect(aiService.getEndpoint('provider-a')?.modelId, 'model-a');
    expect(consumerCalls, 0);
    expect(persistCalls, 0);
  });

  test('persistence failure rolls back runtime and consumer state', () async {
    final seenModels = <String>[];
    final runtime = RuntimeModelSelection(
      aiService: aiService,
      validateConnection: (candidate) async => ConnectionTestResult(
        success: true,
        latencyMs: 1,
        modelId: candidate.modelId,
        providerId: candidate.id,
        message: '连接成功',
      ),
      synchronizeConsumers: [
        (provider) => seenModels.add(provider.currentModelId),
      ],
      persistSelection: (_, __) async => throw StateError('disk full'),
    );

    final result = await runtime.select('provider-a', 'model-b');

    expect(result.isSuccess, isFalse);
    expect(aiService.currentModelId, 'model-a');
    expect(seenModels, ['model-b', 'model-a']);
  });
}
