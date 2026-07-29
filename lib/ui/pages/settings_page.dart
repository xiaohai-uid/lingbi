import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/settings_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = ServiceLocator.instance.settingsService;
  final Map<String, TextEditingController> _keyControllers = {};

  @override
  void initState() {
    super.initState();
    _keyControllers['sensenova'] = TextEditingController(text: _settings.getApiKey('sensenova'));
    _keyControllers['deepseek'] = TextEditingController(text: _settings.getApiKey('deepseek'));
    _keyControllers['openai'] = TextEditingController(text: _settings.getApiKey('openai'));
    _keyControllers['claude'] = TextEditingController(text: _settings.getApiKey('claude'));
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换深色/浅色主题'),
            value: _settings.themeMode == ThemeMode.dark,
            onChanged: (v) {
              _settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            title: const Text('跟随系统'),
            subtitle: const Text('自动匹配系统主题'),
            value: _settings.themeMode == ThemeMode.system,
            onChanged: (v) {
              if (v) _settings.setThemeMode(ThemeMode.system);
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'AI 模型'),
          ListTile(
            title: const Text('默认 AI 模型'),
            subtitle: Text(_providerLabel(_settings.selectedProvider)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectProvider(),
          ),
          const Divider(),
          const _SectionHeader(title: 'API 密钥'),
          ..._buildApiKeyFields(theme),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '灵笔 v0.4.0',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildApiKeyFields(ThemeData theme) {
    final providers = [
      ('sensenova', 'SenseNova API Key', Icons.auto_awesome),
      ('deepseek', 'DeepSeek API Key', Icons.psychology),
      ('openai', 'OpenAI API Key', Icons.token),
      ('claude', 'Claude API Key', Icons.auto_awesome),
    ];

    return providers.map((p) {
      final key = p.$1;
      final label = p.$2;
      final icon = p.$3;
      final controller = _keyControllers[key]!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: 'sk-...',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, size: 18),
                    tooltip: '保存密钥',
                    onPressed: () => _settings.setApiKey(key, controller.text.trim()),
                  ),
                ),
                obscureText: true,
                onSubmitted: (v) => _settings.setApiKey(key, v.trim()),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _selectProvider() {
    final providers = ['free', 'sensenova', 'deepseek', 'openai', 'claude'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => SimpleDialog(
          title: const Text('选择 AI 模型'),
          children: providers.map((p) {
            return RadioListTile<String>(
              title: Text(_providerLabel(p)),
              subtitle: Text(_providerDesc(p)),
              value: p,
              // ignore: deprecated_member_use
              groupValue: _settings.selectedProvider,
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) {
                  _settings.setProvider(v);
                  setDialogState(() {});
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _providerLabel(String name) {
    switch (name) {
      case 'sensenova': return 'SenseNova (商汤)';
      case 'free': return '免费模式 (内置)';
      case 'deepseek': return 'DeepSeek';
      case 'openai': return 'OpenAI';
      case 'claude': return 'Claude';
      default: return name;
    }
  }

  String _providerDesc(String name) {
    switch (name) {
      case 'sensenova': return '商汤 SenseNova API，需配置 API Key';
      case 'free': return '内置免费模型，每天有限额';
      case 'deepseek': return 'DeepSeek V3/R1，需配置 API Key';
      case 'openai': return 'GPT-4o / GPT-3.5，需配置 API Key';
      case 'claude': return 'Claude Sonnet 4，需配置 API Key';
      default: return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
