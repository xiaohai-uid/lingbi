/// Capability-driven Provider routing.
///
/// Selects only Providers whose probed capabilities satisfy the task's
/// required set. Applies explicit downgrades only when caller permits.
library;

import 'package:lingbi/domain/provider/provider_capabilities.dart';

/// A registered Provider with its probed capabilities.
final class RegisteredProvider {
  const RegisteredProvider({
    required this.providerId,
    required this.capabilities,
    required this.priority,
  });

  final String providerId;
  final ProviderCapabilities capabilities;

  /// Lower number = higher priority when multiple satisfy.
  final int priority;
}

/// Result of a routing decision.
final class RoutingDecision {
  const RoutingDecision({
    required this.selectedProviderId,
    required this.downgraded,
    this.downgradeReason,
  });

  final String selectedProviderId;
  final bool downgraded;
  final String? downgradeReason;
}

/// Capability-driven Provider router.
///
/// Never silently sends tools to a Provider that reports no tool calling.
final class CapabilityRouter {
  CapabilityRouter({required this.providers});

  final List<RegisteredProvider> providers;

  /// Select the best Provider satisfying all required capabilities.
  ///
  /// Returns null if no Provider can satisfy and no downgrade is acceptable.
  RoutingDecision? route({
    required ProviderCapabilities required,
    bool allowDowngrade = false,
  }) {
    // First: exact matches sorted by priority
    final exact = providers
        .where((p) => p.capabilities.satisfies(required))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (exact.isNotEmpty) {
      return RoutingDecision(
        selectedProviderId: exact.first.providerId,
        downgraded: false,
      );
    }

    // No exact match — try downgrade if allowed
    if (!allowDowngrade) return null;

    // Downgrade: find providers that satisfy everything except
    // structuredOutput (can fall back to validated JSON text)
    final partial = providers.where((p) {
      final relaxed = ProviderCapabilities(
        streaming: required.streaming,
        toolCalling: required.toolCalling,
        structuredOutput: false, // Relaxed
        reasoning: required.reasoning,
        contextWindowTokens: required.contextWindowTokens,
        reportsTokenUsage: false,
        modelDiscovery: false,
        cancellation: required.cancellation,
      );
      return p.capabilities.satisfies(relaxed);
    }).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (partial.isNotEmpty) {
      return RoutingDecision(
        selectedProviderId: partial.first.providerId,
        downgraded: true,
        downgradeReason: 'structured_output unavailable; '
            'falling back to validated JSON text',
      );
    }

    return null;
  }

  /// Tool calling cannot be downgraded — must fail explicitly.
  bool canRouteTools(ProviderCapabilities required) {
    if (!required.toolCalling) return true;
    return providers.any(
        (p) => p.capabilities.toolCalling && p.capabilities.satisfies(required));
  }
}
