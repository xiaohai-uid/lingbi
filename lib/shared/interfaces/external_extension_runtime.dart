/// External extension runtime interface and disabled adapter.
///
/// Local-pilot safe mode: MCP, external plugins, and marketplace
/// execution are disabled by default.
library;

import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';

/// Result returned when an extension runtime is disabled.
final class DisabledExtensionResult {
  const DisabledExtensionResult({
    required this.extensionId,
    required this.reason,
  });

  final String extensionId;
  final String reason;
}

/// Runtime for external extensions (MCP servers, plugins, marketplace code).
abstract interface class ExternalExtensionRuntime {
  /// Whether this runtime allows execution.
  bool get isExecutionAllowed;

  /// Attempt to connect to an MCP server.
  Future<Result<void>> connectMcp(String serverId, String uri);

  /// Attempt to execute a plugin.
  Future<Result<void>> executePlugin(String pluginId, String entrypoint);

  /// Disconnect and revoke all active connections.
  Future<Result<void>> disconnectAll();
}

/// Disabled adapter — returns typed disabled result for all operations.
///
/// Used in local-pilot safe mode. Text Skills still render;
/// executable abilities are denied.
final class DisabledExtensionRuntime implements ExternalExtensionRuntime {
  const DisabledExtensionRuntime();

  @override
  bool get isExecutionAllowed => false;

  @override
  Future<Result<void>> connectMcp(String serverId, String uri) async {
    return Result.failure(ExtensionDisabledError(
      'MCP connection disabled in safe mode: $serverId',
    ));
  }

  @override
  Future<Result<void>> executePlugin(
      String pluginId, String entrypoint) async {
    return Result.failure(ExtensionDisabledError(
      'Plugin execution disabled in safe mode: $pluginId',
    ));
  }

  @override
  Future<Result<void>> disconnectAll() async {
    return Result.success(null);
  }
}

/// Error indicating an extension operation was blocked by safe mode.
final class ExtensionDisabledError extends AppError {
  ExtensionDisabledError(super.message, {super.code = 'EXTENSION_DISABLED'});
}
