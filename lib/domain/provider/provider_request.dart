/// ProviderClient interface — the target contract for all Providers.
///
/// Domain-layer interface. Existing AIProvider implementations will be
/// wrapped by a LegacyAIProviderAdapter (Task 11) without signature changes.
library;

import 'package:lingbi/domain/provider/provider_capabilities.dart';
import 'package:lingbi/domain/provider/provider_event.dart';

/// A request to generate content from a Provider.
final class ProviderRequest {
  const ProviderRequest({
    required this.modelId,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.tools = const [],
    this.responseFormat,
    this.timeoutSeconds = 60,
    this.maxRetries = 2,
  });

  final String modelId;
  final List<ProviderMessage> messages;
  final double temperature;
  final int maxTokens;
  final List<ProviderToolSpec> tools;
  final String? responseFormat;
  final int timeoutSeconds;
  final int maxRetries;
}

/// A message in a Provider conversation.
final class ProviderMessage {
  const ProviderMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
  });

  final String role;
  final String content;
  final List<Map<String, dynamic>>? toolCalls;
  final String? toolCallId;
}

/// A tool specification for function calling.
final class ProviderToolSpec {
  const ProviderToolSpec({
    required this.name,
    required this.description,
    required this.parametersSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> parametersSchema;
}

/// The target interface for Provider capability-driven routing.
abstract interface class ProviderClient {
  String get providerId;

  /// Probe or refresh the capabilities of this Provider.
  Future<ProviderCapabilities> probeCapabilities({bool refresh = false});

  /// Generate content as a stream of events.
  Stream<ProviderEvent> generate(ProviderRequest request);

  /// Discover available models.
  Future<List<ProviderModel>> discoverModels();

  /// Cancel an in-flight request.
  Future<void> cancel(String requestId);
}
