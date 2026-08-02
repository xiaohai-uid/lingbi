/// Provider capability model and contract.
///
/// Domain-layer — no Flutter, no dart:io.
library;

/// Describes what a Provider model can do.
final class ProviderCapabilities {
  const ProviderCapabilities({
    required this.streaming,
    required this.toolCalling,
    required this.structuredOutput,
    required this.reasoning,
    required this.contextWindowTokens,
    required this.reportsTokenUsage,
    required this.modelDiscovery,
    required this.cancellation,
  });

  factory ProviderCapabilities.fromJson(Map<String, dynamic> json) =>
      ProviderCapabilities(
        streaming: json['streaming'] as bool? ?? false,
        toolCalling: json['tool_calling'] as bool? ?? false,
        structuredOutput: json['structured_output'] as bool? ?? false,
        reasoning: json['reasoning'] as bool? ?? false,
        contextWindowTokens: json['context_window_tokens'] as int? ?? 4096,
        reportsTokenUsage: json['reports_token_usage'] as bool? ?? false,
        modelDiscovery: json['model_discovery'] as bool? ?? false,
        cancellation: json['cancellation'] as bool? ?? false,
      );

  final bool streaming;
  final bool toolCalling;
  final bool structuredOutput;
  final bool reasoning;
  final int contextWindowTokens;
  final bool reportsTokenUsage;
  final bool modelDiscovery;
  final bool cancellation;

  /// Conservative default: everything unsupported except streaming.
  static const conservative = ProviderCapabilities(
    streaming: true,
    toolCalling: false,
    structuredOutput: false,
    reasoning: false,
    contextWindowTokens: 4096,
    reportsTokenUsage: false,
    modelDiscovery: false,
    cancellation: false,
  );

  Map<String, dynamic> toJson() => {
        'streaming': streaming,
        'tool_calling': toolCalling,
        'structured_output': structuredOutput,
        'reasoning': reasoning,
        'context_window_tokens': contextWindowTokens,
        'reports_token_usage': reportsTokenUsage,
        'model_discovery': modelDiscovery,
        'cancellation': cancellation,
      };

  /// Returns true if this satisfies all requirements of [required].
  bool satisfies(ProviderCapabilities required) {
    if (required.streaming && !streaming) return false;
    if (required.toolCalling && !toolCalling) return false;
    if (required.structuredOutput && !structuredOutput) return false;
    if (required.reasoning && !reasoning) return false;
    if (required.cancellation && !cancellation) return false;
    if (contextWindowTokens < required.contextWindowTokens) return false;
    return true;
  }
}

/// A model available from a Provider.
final class ProviderModel {
  const ProviderModel({
    required this.modelId,
    required this.displayName,
    this.capabilities,
  });

  final String modelId;
  final String displayName;
  final ProviderCapabilities? capabilities;
}
