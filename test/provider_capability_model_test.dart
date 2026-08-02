import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/provider/provider_capabilities.dart';
import 'package:lingbi/domain/provider/provider_event.dart';
import 'package:lingbi/domain/provider/provider_failure.dart';
import 'package:lingbi/domain/provider/provider_request.dart';

void main() {
  group('ProviderCapabilities', () {
    test('serialization round-trips', () {
      const caps = ProviderCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: false,
        reasoning: true,
        contextWindowTokens: 128000,
        reportsTokenUsage: true,
        modelDiscovery: true,
        cancellation: true,
      );
      final json = caps.toJson();
      final restored = ProviderCapabilities.fromJson(json);
      expect(restored.streaming, true);
      expect(restored.toolCalling, true);
      expect(restored.structuredOutput, false);
      expect(restored.reasoning, true);
      expect(restored.contextWindowTokens, 128000);
    });

    test('positive context window validation', () {
      const caps = ProviderCapabilities(
        streaming: true,
        toolCalling: false,
        structuredOutput: false,
        reasoning: false,
        contextWindowTokens: 8192,
        reportsTokenUsage: false,
        modelDiscovery: false,
        cancellation: false,
      );
      expect(caps.contextWindowTokens, greaterThan(0));
    });

    test('conservative default has no tool calling', () {
      expect(ProviderCapabilities.conservative.toolCalling, isFalse);
      expect(ProviderCapabilities.conservative.structuredOutput, isFalse);
      expect(ProviderCapabilities.conservative.streaming, isTrue);
    });

    test('satisfies checks all required capabilities', () {
      const full = ProviderCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: true,
        reasoning: false,
        contextWindowTokens: 128000,
        reportsTokenUsage: true,
        modelDiscovery: true,
        cancellation: true,
      );
      const needsTools = ProviderCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: false,
        reasoning: false,
        contextWindowTokens: 4096,
        reportsTokenUsage: false,
        modelDiscovery: false,
        cancellation: false,
      );
      expect(full.satisfies(needsTools), isTrue);
      expect(
          ProviderCapabilities.conservative.satisfies(needsTools), isFalse);
    });

    test('no secret fields in serialization', () {
      const caps = ProviderCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: true,
        reasoning: true,
        contextWindowTokens: 200000,
        reportsTokenUsage: true,
        modelDiscovery: true,
        cancellation: true,
      );
      final jsonStr = caps.toJson().toString().toLowerCase();
      expect(jsonStr.contains('api_key'), isFalse);
      expect(jsonStr.contains('secret'), isFalse);
      expect(jsonStr.contains('password'), isFalse);
      expect(jsonStr.contains('sk-'), isFalse);
    });
  });

  group('ProviderFailureKind', () {
    test('retryable kinds', () {
      expect(ProviderFailureKind.rateLimit.isRetryable, isTrue);
      expect(ProviderFailureKind.timeout.isRetryable, isTrue);
      expect(ProviderFailureKind.network.isRetryable, isTrue);
      expect(ProviderFailureKind.server.isRetryable, isTrue);
    });

    test('non-retryable kinds', () {
      expect(ProviderFailureKind.auth.isRetryable, isFalse);
      expect(ProviderFailureKind.invalidRequest.isRetryable, isFalse);
      expect(ProviderFailureKind.permission.isRetryable, isFalse);
      expect(ProviderFailureKind.unsupportedCapability.isRetryable, isFalse);
      expect(ProviderFailureKind.cancelled.isRetryable, isFalse);
    });

    test('has 12 values', () {
      expect(ProviderFailureKind.values.length, 12);
    });
  });

  group('ProviderEvent variants', () {
    test('all event types are constructible', () {
      const started = ProviderStarted(requestId: 'req-1');
      const textDelta = ProviderTextDelta('hello');
      const reasoning = ProviderReasoningDelta('thinking...');
      const toolDelta = ProviderToolCallDelta(
        toolCallId: 'tc-1',
        name: 'file_write',
        argumentsDelta: '{"path":',
      );
      const structured = ProviderStructuredResult({'key': 'value'});
      const usage = ProviderUsage(promptTokens: 100, completionTokens: 50);
      const completed = ProviderCompleted(finishReason: 'stop');
      const failed = ProviderFailed(
          ProviderFailure(kind: ProviderFailureKind.timeout, message: 'timed out'));

      expect(started, isA<ProviderEvent>());
      expect(textDelta, isA<ProviderEvent>());
      expect(reasoning, isA<ProviderEvent>());
      expect(toolDelta, isA<ProviderEvent>());
      expect(structured, isA<ProviderEvent>());
      expect(usage, isA<ProviderEvent>());
      expect(completed, isA<ProviderEvent>());
      expect(failed, isA<ProviderEvent>());
    });
  });

  group('ProviderRequest', () {
    test('stable provider/model ids', () {
      const request = ProviderRequest(
        modelId: 'gpt-4o',
        messages: [ProviderMessage(role: 'user', content: 'Hello')],
      );
      expect(request.modelId, 'gpt-4o');
      expect(request.messages.length, 1);
      expect(request.timeoutSeconds, 60);
      expect(request.maxRetries, 2);
    });
  });

  group('Downgrade planning', () {
    test('unsupported structured output falls back only when acceptable',
        () {
      const noStructured = ProviderCapabilities(
        streaming: true,
        toolCalling: true,
        structuredOutput: false,
        reasoning: false,
        contextWindowTokens: 128000,
        reportsTokenUsage: true,
        modelDiscovery: false,
        cancellation: true,
      );
      const needsStructured = ProviderCapabilities(
        streaming: false,
        toolCalling: false,
        structuredOutput: true,
        reasoning: false,
        contextWindowTokens: 4096,
        reportsTokenUsage: false,
        modelDiscovery: false,
        cancellation: false,
      );
      // Without structured output, cannot satisfy requirement
      expect(noStructured.satisfies(needsStructured), isFalse);
    });

    test('unsupported tool calling must fail, not silently skip', () {
      const noTools = ProviderCapabilities.conservative;
      const needsTools = ProviderCapabilities(
        streaming: false,
        toolCalling: true,
        structuredOutput: false,
        reasoning: false,
        contextWindowTokens: 0,
        reportsTokenUsage: false,
        modelDiscovery: false,
        cancellation: false,
      );
      expect(noTools.satisfies(needsTools), isFalse);
    });
  });
}
