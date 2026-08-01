/// Contained process runner interface.
///
/// Replaces raw shell command execution with a sandboxed runner.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Configuration for a contained process execution.
final class ProcessSpec {
  const ProcessSpec({
    required this.executableId,
    required this.arguments,
    required this.workingDirectory,
    this.environment = const {},
    this.timeoutSeconds = 30,
    this.maxOutputBytes = 1048576, // 1 MiB
  });

  /// Manifest-approved executable identifier (not a raw path).
  final String executableId;

  /// Argument vector — shell metacharacters are literal arguments.
  final List<String> arguments;

  /// Must be inside the project directory.
  final String workingDirectory;

  /// Only allowlisted variables (PATH, TEMP, task-specific non-secret).
  final Map<String, String> environment;

  final int timeoutSeconds;
  final int maxOutputBytes;
}

/// Result of a contained process execution.
final class ProcessResult {
  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
    required this.terminated,
    required this.durationMs,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
  final bool terminated;
  final int durationMs;
}

/// Runs processes in a contained sandbox.
abstract interface class ProcessRunner {
  /// Execute a process with containment guarantees.
  ///
  /// - No shell interpretation of arguments
  /// - Working directory validated inside project
  /// - Environment starts empty, adds only allowlist
  /// - Timeout terminates process tree
  /// - Output capped at maxOutputBytes
  /// - stdin closed, interactive denied
  Future<Result<ProcessResult>> run(ProcessSpec spec);
}
