/// Provider event stream variants.
///
/// Domain-layer — normalized streaming events across all Providers.
library;

import 'package:lingbi/domain/provider/provider_failure.dart';

/// Events emitted during a Provider generation stream.
sealed class ProviderEvent {
  const ProviderEvent();
}

/// Generation has started.
final class ProviderStarted extends ProviderEvent {
  const ProviderStarted({this.requestId});
  final String? requestId;
}

/// A text content delta.
final class ProviderTextDelta extends ProviderEvent {
  const ProviderTextDelta(this.text);
  final String text;
}

/// A reasoning/thinking delta (for reasoning-capable models).
final class ProviderReasoningDelta extends ProviderEvent {
  const ProviderReasoningDelta(this.text);
  final String text;
}

/// A tool call delta (streaming tool arguments).
final class ProviderToolCallDelta extends ProviderEvent {
  const ProviderToolCallDelta({
    required this.toolCallId,
    required this.name,
    required this.argumentsDelta,
  });
  final String toolCallId;
  final String name;
  final String argumentsDelta;
}

/// Structured output result (JSON mode).
final class ProviderStructuredResult extends ProviderEvent {
  const ProviderStructuredResult(this.json);
  final Map<String, dynamic> json;
}

/// Token usage report.
final class ProviderUsage extends ProviderEvent {
  const ProviderUsage({
    required this.promptTokens,
    required this.completionTokens,
    this.totalTokens,
  });
  final int promptTokens;
  final int completionTokens;
  final int? totalTokens;
}

/// Generation completed successfully.
final class ProviderCompleted extends ProviderEvent {
  const ProviderCompleted({this.finishReason});
  final String? finishReason;
}

/// Generation failed.
final class ProviderFailed extends ProviderEvent {
  const ProviderFailed(this.failure);
  final ProviderFailure failure;
}
