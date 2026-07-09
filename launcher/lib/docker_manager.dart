import 'dart:io';

/// Docker Manager — Docker 模式：docker-compose 启动/停止
class DockerManager {
  static Future<void> startAll() async {
    await _runCompose(['up', '-d']);
  }

  static Future<void> stopAll() async {
    await _runCompose(['down']);
  }

  static Future<void> restartAll() async {
    await stopAll();
    await startAll();
  }

  static Future<List<String>> getStatus() async {
    final result = await _runCompose(['ps', '--format', 'json']);
    return result.split('\n').where((s) => s.trim().isNotEmpty).toList();
  }

  static Future<bool> isAvailable() async {
    try {
      final result = await Process.run('docker', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _runCompose(List<String> args) async {
    final composeFile = File('docker-compose.yml');
    final fullArgs = ['-f', composeFile.path, ...args];

    final result = await Process.run('docker-compose', fullArgs);
    if (result.exitCode != 0) {
      throw Exception('docker-compose 失败:\n${result.stderr}');
    }
    return result.stdout.toString();
  }
}
