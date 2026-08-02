/// Local contained process runner.
///
/// Implements ProcessRunner with filesystem containment:
/// - Working directory validated inside project root
/// - No shell interpretation (arguments are literal)
/// - Timeout terminates process
/// - Output capped at maxOutputBytes
/// - stdin closed
library;

import 'dart:io';

import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/process_runner.dart';
import 'package:path/path.dart' as p;

/// Runs processes with containment guarantees on the local filesystem.
final class LocalProcessRunner implements ProcessRunner {
  LocalProcessRunner({required this.projectRoot});

  /// All working directories must be inside this root.
  final String projectRoot;

  @override
  Future<Result<ProcessResult>> run(ProcessSpec spec) async {
    // Validate working directory is inside project root
    final normalizedWork = p.normalize(p.absolute(spec.workingDirectory));
    final normalizedRoot = p.normalize(p.absolute(projectRoot));
    if (!p.isWithin(normalizedRoot, normalizedWork) &&
        normalizedWork != normalizedRoot) {
      return Result.failure(FileError(
        'Working directory escapes project root: ${spec.workingDirectory}',
        code: 'CONTAINMENT_VIOLATION',
      ));
    }

    final stopwatch = Stopwatch()..start();
    try {
      final process = await Process.start(
        spec.executableId,
        spec.arguments,
        workingDirectory: normalizedWork,
        environment: spec.environment.isEmpty ? null : spec.environment,
      );

      // Close stdin immediately (interactive denied)
      process.stdin.close();

      // Collect output with cap
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      var stdoutBytes = 0;
      var stderrBytes = 0;

      process.stdout.listen((data) {
        stdoutBytes += data.length;
        if (stdoutBytes <= spec.maxOutputBytes) {
          stdoutBuffer.write(String.fromCharCodes(data));
        }
      });
      process.stderr.listen((data) {
        stderrBytes += data.length;
        if (stderrBytes <= spec.maxOutputBytes) {
          stderrBuffer.write(String.fromCharCodes(data));
        }
      });

      // Wait with timeout
      final exitCode = await process.exitCode.timeout(
        Duration(seconds: spec.timeoutSeconds),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      stopwatch.stop();
      final timedOut = exitCode == -1;

      return Result.success(ProcessResult(
        exitCode: timedOut ? -1 : exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        timedOut: timedOut,
        terminated: timedOut,
        durationMs: stopwatch.elapsedMilliseconds,
      ));
    } on ProcessException catch (e) {
      stopwatch.stop();
      return Result.failure(FileError(
        'Process execution failed: ${e.message}',
        code: 'PROCESS_ERROR',
      ));
    }
  }
}
