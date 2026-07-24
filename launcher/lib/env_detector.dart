import 'dart:io';

/// 环境检测结果
class EnvResult {
  final String name;
  final bool available;
  final String? version;
  final String? hint;

  const EnvResult({
    required this.name,
    required this.available,
    this.version,
    this.hint,
  });
}

/// 环境自动检测 — 检查 Dart/Node/端口是否可用
class EnvDetector {
  /// 检测所有必需环境
  static Future<List<EnvResult>> detectAll() async {
    return [
      await _detectDart(),
      await _detectNode(),
      await _detectPorts(),
    ];
  }

  /// 检测 Dart SDK
  static Future<EnvResult> _detectDart() async {
    try {
      final result = await Process.run('dart', ['--version']);
      final output = result.stdout.toString() + result.stderr.toString();
      final version = output.trim().split('\n').first;
      return EnvResult(name: 'Dart SDK', available: true, version: version);
    } catch (e) {
      return EnvResult(
        name: 'Dart SDK',
        available: false,
        hint: '请安装 Dart SDK: https://dart.dev/get-dart',
      );
    }
  }

  /// 检测 Node.js
  static Future<EnvResult> _detectNode() async {
    try {
      final result = await Process.run('node', ['--version']);
      final version = result.stdout.toString().trim();
      return EnvResult(name: 'Node.js', available: true, version: version);
    } catch (e) {
      return EnvResult(
        name: 'Node.js',
        available: false,
        hint: '请安装 Node.js: https://nodejs.org/',
      );
    }
  }

  /// 检测常用端口是否被占用
  static Future<EnvResult> _detectPorts() async {
    final ports = [8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090, 8091];
    final occupied = <int>[];

    for (final port in ports) {
      try {
        final socket = await Socket.connect('localhost', port,
            timeout: const Duration(milliseconds: 500));
        socket.destroy();
        occupied.add(port);
      } catch (_) {
        // Port is free — good
      }
    }

    if (occupied.isEmpty) {
      return EnvResult(
        name: '端口检测',
        available: true,
        version: '8080-8091 全部可用',
      );
    } else {
      return EnvResult(
        name: '端口检测',
        available: false,
        version: '${occupied.join(', ')} 已被占用',
        hint: '请关闭占用端口的程序后重试',
      );
    }
  }
}
