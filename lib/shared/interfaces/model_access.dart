/// Model access port — upgrade seam for official model gateway.
///
/// Local pilot: BYOK reads credentials through secure storage.
/// Future: OfficialModelGatewayAdapter replaces this.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Provides model access credentials (BYOK in local pilot).
abstract interface class ModelAccess {
  /// Get the API key for a provider (from secure storage only).
  Future<Result<String>> getApiKey(String providerId);

  /// Store an API key in secure storage.
  Future<Result<void>> storeApiKey(String providerId, String apiKey);

  /// Delete a stored API key.
  Future<Result<void>> deleteApiKey(String providerId);

  /// List providers with stored credentials (ids only, never values).
  Future<Result<List<String>>> listConfiguredProviders();
}
