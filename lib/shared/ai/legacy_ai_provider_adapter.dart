/// Legacy AIProvider adapter wrapping existing implementations
/// into the new ProviderClient interface without signature changes.
///
/// Capability values are conservative — unknown means unsupported.
library;

import 'dart:async';

import 'package:lingbi/domain/provider/provider_capabilities.dart';
import 'package:lingbi/domain/provider/provider_event.dart';
import 'package:lingbi/domain/provider/provider_failure.dart';
import 'package:lingbi/domain/provider/provider_request.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

/// Wraps an existing [AIProvider] as a [ProviderClient]-compatible adapter.
///
/// Does NOT modify the AIProvider interface signature.
final class LegacyAIProviderAdapter {
  LegacyAIProviderAdapter(this._provider);

  final AIProvider _provider;

  String get providerId => _provider.name;

  /// Probe capabilities conservatively from the legacy provider.
  Future<ProviderCapabilities> probeCapabilities({bool refresh = false}) async {
    return ProviderCapabilities(
      streaming: true, // All legacy providers support streaming chat
      toolCalling: _provider.supportsTools,
      structuredOutput: false, // Unknown → unsupported
      reasoning: false, // Unknown → unsupported
      contextWindowTokens: 4096, // Conservative default
      reportsTokenUsage: false, // Unknown → unsupported
      modelDiscovery: false, // Legacy providers don't discover models
      cancellation: true, // All have cancel() method
    );
  }

  /// Generate content by mapping legacy chat stream to ProviderEvents.
  Stream<ProviderEvent> generate(ProviderRequest request) async* {
    yield ProviderStarted(requestId: DateTime.now().microsecondsSinceEpoch.toString());

    final messages = request.messages
        .map((m) => ChatMessage(role: m.role, content: m.content))
        .toList();

    try {
      // Timeout enforcement at the adapter level
      final stream = _provider.chat(
        messages: messages,
        temperature: request.temperature,
        maxTokens: request.maxTokens,
      ).timeout(Duration(seconds: request.timeoutSeconds));

      await for (final chunk in stream) {
        yield ProviderTextDelta(chunk);
      }

      yield const ProviderCompleted(finishReason: 'stop');
    } on TimeoutException {
      yield const ProviderFailed(ProviderFailure(
        kind: ProviderFailureKind.timeout,
        message: 'Request timed out at adapter level',
      ));
    } on UnsupportedError catch (e) {
      yield ProviderFailed(ProviderFailure(
        kind: ProviderFailureKind.unsupportedCapability,
        message: e.message ?? 'Unsupported operation',
      ));
    } catch (e) {
      yield ProviderFailed(ProviderFailure(
        kind: _classifyError(e),
        message: e.toString(),
      ));
    }
  }

  /// Discover models — legacy providers don't support this.
  Future<List<ProviderModel>> discoverModels() async {
    if (_provider.currentModelId.isEmpty) return [];
    return [
      ProviderModel(
        modelId: _provider.currentModelId,
        displayName: _provider.currentModelId,
      ),
    ];
  }

  /// Cancel delegates to the legacy provider.
  Future<void> cancel(String requestId) async {
    _provider.cancel();
  }

  /// Map exceptions through the normalized failure taxonomy.
  ProviderFailureKind _classifyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('auth') || msg.contains('401') || msg.contains('api key')) {
      return ProviderFailureKind.auth;
    }
    if (msg.contains('403') || msg.contains('permission')) {
      return ProviderFailureKind.permission;
    }
    if (msg.contains('429') || msg.contains('rate limit')) {
      return ProviderFailureKind.rateLimit;
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return ProviderFailureKind.timeout;
    }
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return ProviderFailureKind.network;
    }
    if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
      return ProviderFailureKind.server;
    }
    if (msg.contains('400') || msg.contains('invalid')) {
      return ProviderFailureKind.invalidRequest;
    }
    return ProviderFailureKind.unknown;
  }
}
