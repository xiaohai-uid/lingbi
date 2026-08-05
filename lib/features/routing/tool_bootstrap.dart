import 'dart:io';

/// Tool kinds known to the Fusion bootstrap gate.
enum ToolKind { git, python, crawl4ai, llmGateway }

/// A tool required before a workflow or skill may execute.
class ToolRequirement {
  const ToolRequirement({
    required this.kind,
    required this.label,
    this.installHint = '',
  });

  final ToolKind kind;
  final String label;
  final String installHint;
}

/// Result of a tool probe.
class ToolStatus {
  const ToolStatus({
    required this.available,
    this.detail = '',
    this.installHint = '',
  });

  final bool available;
  final String detail;
  final String installHint;
}

typedef ToolProbe = Future<ToolStatus> Function(ToolKind kind);

/// Pre-execution capability detection for workflows and skills.
class ToolBootstrap {
  ToolBootstrap({ToolProbe? probe}) : _probe = probe ?? _defaultProbe;

  final ToolProbe _probe;

  Future<ToolStatus> check(ToolRequirement requirement) =>
      _probe(requirement.kind);

  Future<Map<ToolKind, ToolStatus>> checkAll(
    List<ToolRequirement> requirements,
  ) async {
    final results = <ToolKind, ToolStatus>{};
    for (final requirement in requirements) {
      results[requirement.kind] = await check(requirement);
    }
    return results;
  }

  static Future<ToolStatus> _defaultProbe(ToolKind kind) async {
    switch (kind) {
      case ToolKind.git:
        return _runVersionProbe(
          ['git', '--version'],
          installHint: '请安装 git 后重试',
        );
      case ToolKind.python:
        try {
          final python = await Process.run('python3', ['--version']);
          if (python.exitCode == 0) {
            return ToolStatus(
              available: true,
              detail: python.stdout.toString().trim(),
            );
          }
        } catch (_) {}
        return _runVersionProbe(
          ['python', '--version'],
          installHint: '请安装 Python 后重试',
        );
      case ToolKind.crawl4ai:
        return _probeCrawl4ai();
      case ToolKind.llmGateway:
        return const ToolStatus(
          available: true,
          detail: 'LLM 网关由 Provider 路由探测',
        );
    }
  }

  static Future<ToolStatus> _runVersionProbe(
    List<String> command, {
    required String installHint,
  }) async {
    try {
      final result = await Process.run(command.first, command.sublist(1));
      if (result.exitCode == 0) {
        return ToolStatus(
          available: true,
          detail: result.stdout.toString().trim(),
        );
      }
      return ToolStatus(
        available: false,
        detail: result.stderr.toString().trim(),
        installHint: installHint,
      );
    } catch (e) {
      return ToolStatus(
        available: false,
        detail: e.toString(),
        installHint: installHint,
      );
    }
  }

  static Future<ToolStatus> _probeCrawl4ai() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request =
          await client.getUrl(Uri.parse('http://127.0.0.1:11235/health'));
      final response = await request.close();
      return ToolStatus(
        available: response.statusCode == 200,
        detail: 'HTTP ${response.statusCode}',
        installHint: '请启动本地 Crawl4AI 服务',
      );
    } catch (e) {
      return ToolStatus(
        available: false,
        detail: e.toString(),
        installHint: '请启动本地 Crawl4AI 服务',
      );
    } finally {
      client.close(force: true);
    }
  }
}
