import 'ai_provider.dart';
import 'models/endpoint_config.dart';
import '../../services/ai_service.dart';

typedef ModelConnectionValidator = Future<ConnectionTestResult> Function(
  EndpointConfig candidate,
);
typedef ProviderConsumerSynchronizer = void Function(AIProvider provider);
typedef ModelSelectionPersister = Future<void> Function(
  String providerId,
  String modelId,
);

class RuntimeModelSnapshot {
  const RuntimeModelSnapshot({
    required this.providerId,
    required this.modelId,
  });

  final String providerId;
  final String modelId;
}

class ModelSelectionResult {
  const ModelSelectionResult._({
    required this.isSuccess,
    required this.message,
    required this.selection,
  });

  factory ModelSelectionResult.success(RuntimeModelSnapshot selection) {
    return ModelSelectionResult._(
      isSuccess: true,
      message: '模型已切换',
      selection: selection,
    );
  }

  factory ModelSelectionResult.failure(
    String message,
    RuntimeModelSnapshot selection,
  ) {
    return ModelSelectionResult._(
      isSuccess: false,
      message: message,
      selection: selection,
    );
  }

  final bool isSuccess;
  final String message;
  final RuntimeModelSnapshot selection;
}

/// Validates and commits a provider/model change as one recoverable operation.
///
/// Validation happens against an isolated provider first. Runtime consumers and
/// settings only observe the candidate after it is proven usable. Any commit
/// failure restores the previous endpoint, provider and consumer bindings.
class RuntimeModelSelection {
  RuntimeModelSelection({
    required AIService aiService,
    required ModelConnectionValidator validateConnection,
    required List<ProviderConsumerSynchronizer> synchronizeConsumers,
    required ModelSelectionPersister persistSelection,
  })  : _aiService = aiService,
        _validateConnection = validateConnection,
        _synchronizeConsumers = List.unmodifiable(synchronizeConsumers),
        _persistSelection = persistSelection;

  final AIService _aiService;
  final ModelConnectionValidator _validateConnection;
  final List<ProviderConsumerSynchronizer> _synchronizeConsumers;
  final ModelSelectionPersister _persistSelection;

  bool _isSelecting = false;

  RuntimeModelSnapshot get current => RuntimeModelSnapshot(
        providerId: _aiService.currentProviderName,
        modelId: _aiService.currentModelId,
      );

  bool get isSelecting => _isSelecting;

  Future<ModelSelectionResult> select(
    String providerId,
    String modelId,
  ) async {
    if (_isSelecting) {
      return ModelSelectionResult.failure('正在切换模型，请稍候', current);
    }

    final previousProviderId = _aiService.currentProviderName;
    final previousEndpoint = _aiService.getEndpoint(previousProviderId);
    final targetEndpoint = _aiService.getEndpoint(providerId);
    if (targetEndpoint == null) {
      return ModelSelectionResult.failure('未找到指定的 AI 服务商', current);
    }
    if (modelId.trim().isEmpty) {
      return ModelSelectionResult.failure('模型 ID 不能为空', current);
    }

    final candidate = targetEndpoint.copyWith(modelId: modelId.trim());
    _isSelecting = true;
    try {
      final validation = await _validateConnection(candidate);
      if (!validation.success) {
        return ModelSelectionResult.failure(validation.message, current);
      }

      _aiService.addEndpoint(candidate);
      _aiService.setProvider(providerId);
      _synchronize(_aiService.currentProvider);

      try {
        await _persistSelection(providerId, candidate.modelId);
      } catch (error) {
        _restore(previousProviderId, previousEndpoint, targetEndpoint);
        return ModelSelectionResult.failure(
          '保存模型设置失败，已恢复原设置：$error',
          current,
        );
      }

      return ModelSelectionResult.success(current);
    } catch (error) {
      _restore(previousProviderId, previousEndpoint, targetEndpoint);
      return ModelSelectionResult.failure('切换模型失败：$error', current);
    } finally {
      _isSelecting = false;
    }
  }

  void _synchronize(AIProvider provider) {
    for (final synchronize in _synchronizeConsumers) {
      synchronize(provider);
    }
  }

  void _restore(
    String previousProviderId,
    EndpointConfig? previousEndpoint,
    EndpointConfig targetEndpoint,
  ) {
    if (previousProviderId == targetEndpoint.id && previousEndpoint != null) {
      _aiService.addEndpoint(previousEndpoint);
    } else {
      _aiService.addEndpoint(targetEndpoint);
    }
    _aiService.setProvider(previousProviderId);
    _synchronize(_aiService.currentProvider);
  }
}
