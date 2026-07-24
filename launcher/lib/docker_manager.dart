import 'dart:io';

/// Docker 模式管理器 — 通过 docker-compose 启动/停止所有服务
class DockerManager {
  /// 检查 Docker 是否安装
  static Future<bool> isDockerAvailable() async {
    try {
      final result = await Process.run('docker', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 检查 docker-compose 是否可用
  static Future<bool> isDockerComposeAvailable() async {
    try {
      final result = await Process.run('docker', ['compose', 'version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// docker-compose up -d (后台启动所有服务)
  static Future<ProcessResult> startAll(String composeFilePath) async {
    return await Process.run(
      'docker',
      ['compose', '-f', composeFilePath, 'up', '-d'],
      runInShell: true,
    );
  }

  /// docker-compose down (停止所有服务)
  static Future<ProcessResult> stopAll(String composeFilePath) async {
    return await Process.run(
      'docker',
      ['compose', '-f', composeFilePath, 'down'],
      runInShell: true,
    );
  }

  /// docker-compose ps (查看服务状态)
  static Future<ProcessResult> getStatus(String composeFilePath) async {
    return await Process.run(
      'docker',
      ['compose', '-f', composeFilePath, 'ps'],
      runInShell: true,
    );
  }

  /// docker-compose logs (获取服务日志)
  static Future<ProcessResult> getLogs(
    String composeFilePath, {
    String? service,
    int tail = 100,
  }) async {
    final args = ['compose', '-f', composeFilePath, 'logs', '--tail', '$tail'];
    if (service != null) args.add(service);
    return await Process.run('docker', args, runInShell: true);
  }

  /// docker-compose build (重新构建所有服务)
  static Future<ProcessResult> buildAll(String composeFilePath) async {
    return await Process.run(
      'docker',
      ['compose', '-f', composeFilePath, 'build'],
      runInShell: true,
    );
  }
}
