import 'package:flutter/material.dart';

import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class ApiKeySettingsSection extends StatefulWidget {
  const ApiKeySettingsSection({super.key});

  @override
  State<ApiKeySettingsSection> createState() => _ApiKeySettingsSectionState();
}

class _ApiKeySettingsSectionState extends State<ApiKeySettingsSection>
    with SettingsAwareState {
  late final TextEditingController _openaiKeyController;
  late final TextEditingController _anthropicKeyController;
  late final TextEditingController _deepseekKeyController;
  late final TextEditingController _sensenovaKeyController;

  @override
  void initState() {
    super.initState();
    final settings = ServiceLocator.instance.settingsService;
    _openaiKeyController =
        TextEditingController(text: settings.getApiKey('openai'));
    _anthropicKeyController =
        TextEditingController(text: settings.getApiKey('claude'));
    _deepseekKeyController =
        TextEditingController(text: settings.getApiKey('deepseek'));
    _sensenovaKeyController =
        TextEditingController(text: settings.getApiKey('sensenova'));
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
    _anthropicKeyController.dispose();
    _deepseekKeyController.dispose();
    _sensenovaKeyController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteKey(String provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 API Key'),
        content: const Text(
          '删除后，该供应商将无法继续调用，现有项目内容不会被删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ServiceLocator.instance.settingsService.deleteApiKey(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final settings = ServiceLocator.instance.settingsService;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.isUsingSessionOnlyKeys)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.secureStorageWarning ??
                        '安全存储不可用，API Key 仅在本次会话有效，不会保存到磁盘。',
                    style:
                        TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        SettingsSectionScaffold(
          c: c,
          items: [
            SettingsSectionItem(
              icon: LingBiIcons.apiKey,
              title: 'SenseNova API Key',
              subtitle: settings.hasApiKey('sensenova')
                  ? (settings.isSessionOnlyKey('sensenova')
                      ? '已配置（仅本次会话）'
                      : '已配置')
                  : '未配置',
              trailing: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sensenovaKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'sk-...',
                          suffixIcon: Icon(LingBiIcons.edit, size: 16),
                        ),
                        onSubmitted: (value) =>
                            settings.setApiKey('sensenova', value.trim()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '删除 Key',
                      onPressed: () => _confirmDeleteKey('sensenova'),
                    ),
                  ],
                ),
              ),
            ),
            SettingsSectionItem(
              icon: LingBiIcons.apiKey,
              title: 'DeepSeek API Key',
              subtitle: settings.hasApiKey('deepseek')
                  ? (settings.isSessionOnlyKey('deepseek')
                      ? '已配置（仅本次会话）'
                      : '已配置')
                  : '未配置',
              trailing: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deepseekKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'sk-...',
                          suffixIcon: Icon(LingBiIcons.edit, size: 16),
                        ),
                        onSubmitted: (value) =>
                            settings.setApiKey('deepseek', value.trim()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '删除 Key',
                      onPressed: () => _confirmDeleteKey('deepseek'),
                    ),
                  ],
                ),
              ),
            ),
            SettingsSectionItem(
              icon: LingBiIcons.apiKey,
              title: 'OpenAI API Key',
              subtitle: settings.hasApiKey('openai')
                  ? (settings.isSessionOnlyKey('openai') ? '已配置（仅本次会话）' : '已配置')
                  : '未配置',
              trailing: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _openaiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'sk-...',
                          suffixIcon: Icon(LingBiIcons.edit, size: 16),
                        ),
                        onSubmitted: (value) =>
                            settings.setApiKey('openai', value.trim()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '删除 Key',
                      onPressed: () => _confirmDeleteKey('openai'),
                    ),
                  ],
                ),
              ),
            ),
            SettingsSectionItem(
              icon: LingBiIcons.apiKey,
              title: 'Anthropic API Key',
              subtitle: settings.hasApiKey('claude')
                  ? (settings.isSessionOnlyKey('claude') ? '已配置（仅本次会话）' : '已配置')
                  : '未配置',
              trailing: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _anthropicKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'sk-ant-...',
                          suffixIcon: Icon(LingBiIcons.edit, size: 16),
                        ),
                        onSubmitted: (value) =>
                            settings.setApiKey('claude', value.trim()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '删除 Key',
                      onPressed: () => _confirmDeleteKey('claude'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
