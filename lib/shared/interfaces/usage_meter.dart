/// Usage meter — tracks counts/tokens without content.
///
/// Local pilot: records locally. Future: RemoteQuotaUsageAdapter.
library;

import 'package:lingbi/shared/errors/result.dart';

/// A usage record (no prompt or project content).
final class UsageRecord {
  const UsageRecord({
    required this.featureId,
    required this.providerId,
    required this.modelId,
    required this.promptTokens,
    required this.completionTokens,
    required this.timestamp,
  });

  final String featureId;
  final String providerId;
  final String modelId;
  final int promptTokens;
  final int completionTokens;
  final DateTime timestamp;
}

/// Records and queries usage metrics.
abstract interface class UsageMeter {
  /// Record a usage event (no content, only counts).
  Future<Result<void>> record(UsageRecord record);

  /// Get total usage for a time period.
  Future<Result<List<UsageRecord>>> query({
    DateTime? from,
    DateTime? to,
    String? featureId,
  });

  /// Get aggregate token counts.
  Future<Result<int>> totalTokens({DateTime? from, DateTime? to});
}
