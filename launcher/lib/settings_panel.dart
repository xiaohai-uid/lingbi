import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'docker_manager.dart';

/// 启动器设置面板 — 端口配置、Docker 路径、开机自启
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final TextEditingController _projectRootController = TextEditingController();
  final TextEditingController _dockerComposePathController =
      TextEditingController();
  bool _dockerMode = false;
  bool _autoStart = false;
  bool _checkingDocker = false;
  String _dockerStatus = '';

  @override
  void initState() {
    super.initState();
    _projectRootController.text = '.';
    _dockerComposePathController.text = 'docker-compose.yml';
    _loadSettings();
  }

  /// 加载已持久化的设置（覆盖默认值）
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dockerMode = prefs.getBool('dockerMode') ?? false;
      _autoStart = prefs.getBool('autoStart') ?? false;
      _projectRootController.text =
          prefs.getString('projectRoot') ?? _projectRootController.text;
      _dockerComposePathController.text =
          prefs.getString('dockerComposePath') ??
              _dockerComposePathController.text;
    });
  }

  /// 持久化设置到 shared_preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dockerMode', _dockerMode);
    await prefs.setBool('autoStart', _autoStart);
    await prefs.setString('projectRoot', _projectRootController.text);
    await prefs.setString('dockerComposePath', _dockerComposePathController.text);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
  }

  @override
  void dispose() {
    _projectRootController.dispose();
    _dockerComposePathController.dispose();
    super.dispose();
  }

  Future<void> _checkDocker() async {
    setState(() => _checkingDocker = true);
    final available = await DockerManager.isDockerAvailable();
    final composeAvailable = await DockerManager.isDockerComposeAvailable();
    setState(() {
      _checkingDocker = false;
      _dockerStatus = available
          ? (composeAvailable ? 'Docker + Compose 可用' : 'Docker 可用，Compose 不可用')
          : 'Docker 未安装';
    });
  }

  /// Windows 开机自启 — 写入/删除注册表 Run 键
  Future<void> _toggleAutoStart(bool value) async {
    setState(() => _autoStart = value);
    try {
      if (value) {
        // 开启：写入注册表实现开机自启
        final exePath = Platform.resolvedExecutable;
        final result = await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          'LingbiLauncher',
          '/t',
          'REG_SZ',
          '/d',
          exePath,
          '/f',
        ]);
        if (result.exitCode != 0) {
          throw Exception('reg add 失败: ${result.stderr}');
        }
      } else {
        // 关闭：移除注册表键值
        final result = await Process.run('reg', [
          'delete',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          'LingbiLauncher',
          '/f',
        ]);
        // 键不存在（exitCode 1）视为已成功移除
        if (result.exitCode != 0) {
          final err = result.stderr.toString();
          if (!err.contains('无法找到') &&
              !err.contains('not found') &&
              !err.contains('Unable to find')) {
            throw Exception('reg delete 失败: $err');
          }
        }
      }
      // 同步持久化自启开关状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoStart', _autoStart);
    } catch (e) {
      // 失败：回滚开关状态并反馈用户，不崩溃
      if (mounted) {
        setState(() => _autoStart = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置开机自启失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('启动器设置'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目根目录
              Text('项目根目录', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _projectRootController,
                decoration: const InputDecoration(
                  hintText: '输入灵笔项目根目录路径',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // 启动模式
              Text('启动模式', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('本地模式'),
                    selected: !_dockerMode,
                    onSelected: (v) => setState(() => _dockerMode = !v),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Docker 模式'),
                    selected: _dockerMode,
                    onSelected: (v) => setState(() => _dockerMode = v),
                  ),
                  const SizedBox(width: 12),
                  if (_checkingDocker)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: _checkDocker,
                      child: const Text('检测 Docker'),
                    ),
                ],
              ),
              if (_dockerStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_dockerStatus,
                    style: TextStyle(
                      color: _dockerStatus.contains('可用')
                          ? Colors.green
                          : Colors.red,
                    )),
              ],
              const SizedBox(height: 12),

              // Docker Compose 路径
              if (_dockerMode) ...[
                Text('docker-compose.yml 路径',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _dockerComposePathController,
                  decoration: const InputDecoration(
                    hintText: 'docker-compose.yml',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 开机自启
              SwitchListTile(
                title: const Text('开机自启动'),
                subtitle: const Text('Windows 启动时自动运行灵笔启动器'),
                value: _autoStart,
                onChanged: _toggleAutoStart,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saveSettings,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
