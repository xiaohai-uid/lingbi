/// ⚠️ DEPRECATED: This launcher references the v3.0 monolithic architecture.
/// The v4.0 architecture uses Go and Rust microservices in go/ and rust/ directories.
/// TODO: Rewrite launcher to manage Go binary processes and Rust binary processes.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/process_run.dart';

/// Service Manager — 本地模式：启动/停止所有微服务子进程
class ServiceManager {
  static final Map<String, ServiceConfig> _services = {
    'API Gateway': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server',
      port: 8080,
      env: {'PORT': '8080'},
    ),
    'AI Provider': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/ai_provider',
      port: 8081,
      env: {'PORT': '8081'},
    ),
    'Project': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/project',
      port: 8082,
      env: {'PORT': '8082'},
    ),
    'Document': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/document',
      port: 8083,
      env: {'PORT': '8083'},
    ),
    'Codex': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/codex',
      port: 8084,
      env: {'PORT': '8084'},
    ),
    'Export': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/export',
      port: 8085,
      env: {'PORT': '8085'},
    ),
    'Version': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/version',
      port: 8086,
      env: {'PORT': '8086'},
    ),
    'Settings': ServiceConfig(
      command: 'node',
      args: ['index.js'],
      cwd: 'lingbi_server/microservices/settings',
      port: 8087,
      env: {'PORT': '8087', 'NODE_ENV': 'production'},
    ),
    'Quota': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/quota',
      port: 8088,
      env: {'PORT': '8088'},
    ),
    'Storage': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/storage',
      port: 8089,
      env: {'PORT': '8089'},
    ),
    'Sync': ServiceConfig(
      command: 'dart',
      args: ['run', 'bin/server.dart'],
      cwd: 'lingbi_server/microservices/sync',
      port: 8090,
      env: {'PORT': '8090'},
    ),
    'Canvas': ServiceConfig(
      command: 'node',
      args: ['index.js'],
      cwd: 'lingbi_server/microservices/canvas',
      port: 8091,
      env: {'PORT': '8091', 'NODE_ENV': 'production'},
    ),
    // v3.0 新增服务
    'Novel Engine': ServiceConfig(
      command: 'dart',
      args: ['run', 'main.dart'],
      cwd: 'services/novel-engine',
      port: 8092,
      env: {'PORT': '8092', 'LITELLM_URL': 'http://localhost:4000'},
    ),
    'Quality Review': ServiceConfig(
      command: 'dart',
      args: ['run', 'main.dart'],
      cwd: 'services/quality-review',
      port: 8093,
      env: {'PORT': '8093', 'LITELLM_URL': 'http://localhost:4000'},
    ),
    // 灵笔主程序
    'Lingbi Client': ServiceConfig(
      command: 'lingbi.exe',
      args: [],
      cwd: 'build/windows/x64/runner/Release',
      port: 0,
      env: {},
    ),
  };

  static Future<void> startAllLocal(
    Map<String, ServiceStatus> statusMap,
    Map<String, Process> processes,
    Map<String, StringBuffer> logs,
  ) async {
    for (final entry in _services.entries) {
      await startService(entry.key, statusMap, processes, logs);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  static Future<void> startService(
    String name,
    Map<String, ServiceStatus> statusMap,
    Map<String, Process> processes,
    Map<String, StringBuffer> logs,
  ) async {
    final config = _services[name]!;
    statusMap[name] = ServiceStatus.starting;

    try {
      final process = await Process.start(
        config.command,
        config.args,
        workingDirectory: config.cwd,
        environment: config.env,
        includeParentEnvironment: true,
      );

      processes[name] = process;

      // 收集输出
      final logBuffer = StringBuffer();
      logs[name] = logBuffer;

      process.stdout.listen((data) {
        final text = utf8.decode(data);
        logBuffer.write(text);
      });

      process.stderr.listen((data) {
        final text = utf8.decode(data);
        logBuffer.write(text);
      });

      // 等待健康检查
      final healthy = await _waitForHealth(config.port, timeout: 15);

      if (healthy) {
        statusMap[name] = ServiceStatus.running;
      } else {
        statusMap[name] = ServiceStatus.error;
      }
    } catch (e) {
      statusMap[name] = ServiceStatus.error;
      logs[name]?.writeln('启动失败: $e');
    }
  }

  static Future<void> stopAllLocal(Map<String, Process> processes) async {
    for (final entry in processes.entries) {
      try {
        await entry.value.kill();
        await entry.value.exitCode;
      } catch (_) {}
    }
    processes.clear();
  }

  static Future<bool> _waitForHealth(int port, {int timeout = 15}) async {
    final deadline = DateTime.now().add(Duration(seconds: timeout));

    while (DateTime.now().isBefore(deadline)) {
      try {
        final socket = await Socket.connect('localhost', port, timeout: 2);
        socket.destroy();
        return true;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }
}

class ServiceConfig {
  final String command;
  final List<String> args;
  final String cwd;
  final int port;
  final Map<String, String> env;

  ServiceConfig({
    required this.command,
    required this.args,
    required this.cwd,
    required this.port,
    required this.env,
  });
}

enum ServiceStatus {
  stopped,
  starting,
  running,
  error,
  degraded,
}
