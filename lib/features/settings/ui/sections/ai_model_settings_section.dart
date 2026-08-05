import 'package:flutter/material.dart';

import '../../../../shared/ai/model_registry.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/components/model_status_bar.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class AiModelSettingsSection extends StatefulWidget {
  const AiModelSettingsSection({super.key});

  @override
  State<AiModelSettingsSection> createState() => _AiModelSettingsSectionState();
}

class _AiModelSettingsSectionState extends State<AiModelSettingsSection>
    with SettingsAwareState {
  static const _providerLabels = {
    'free': '免费模型',
    'sensenova': 'SenseNova',
    'deepseek': 'DeepSeek V3',
    'openai': 'OpenAI',
    'claude': 'Claude',
  };

  bool _isLoadingModels = false;
  double _temperature = 0.7;

  Future<void> _refreshModels([String? providerId]) async {
    final pid =
        providerId ?? ServiceLocator.instance.settingsService.selectedProvider;
    if (_isLoadingModels) return;
    setState(() => _isLoadingModels = true);
    try {
      await ServiceLocator.instance.aiService.discoverModels(pid);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingModels = false);
  }

  Future<void> _testConnection() async {
    final result =
        await ServiceLocator.instance.aiService.testConnectionUnified();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '连接成功 (${result.latencyMs}ms)${result.responsePreview != null ? " — ${result.responsePreview}" : ""}'
            : result.message),
        backgroundColor:
            result.success ? LingBiTokens.success : LingBiTokens.warning,
      ),
    );
  }

  Future<void> _testGeneration() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试生成中，请稍候...')),
    );
    try {
      final buffer = StringBuffer();
      await ServiceLocator.instance.aiService
          .testGeneration()
          .forEach(buffer.write);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(buffer.isNotEmpty
              ? '测试生成成功：${buffer.toString().length > 60 ? "${buffer.toString().substring(0, 57)}..." : buffer}'
              : '生成结果为空，请检查配置'),
          backgroundColor:
              buffer.isNotEmpty ? LingBiTokens.success : LingBiTokens.warning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试生成失败: $e'),
          backgroundColor: LingBiTokens.warning,
        ),
      );
    }
  }

  void _reopenWizard() {
    ServiceLocator.instance.settingsService.resetOnboarding();
  }

  String _sourceLabel(MetadataSource source) {
    switch (source) {
      case MetadataSource.remote:
        return '远程';
      case MetadataSource.manual:
        return '手动';
      case MetadataSource.builtin:
        return '内置';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final settings = ServiceLocator.instance.settingsService;
    final currentProvider = settings.selectedProvider;
    final models = ModelRegistry.instance.getModelsForProvider(currentProvider);
    final selectedModelId = settings.getSelectedModelId(currentProvider);

    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: LingBiIcons.model,
          title: '默认供应商',
          subtitle: 'AI 对话使用的默认供应商',
          trailing: SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: currentProvider,
              items: _providerLabels.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                final pid = value ?? 'free';
                settings.setProvider(pid);
                _refreshModels(pid);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  borderSide: BorderSide(color: c.borderOpaque),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space3,
                  vertical: LingBiTokens.space2,
                ),
              ),
            ),
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.model,
          title: '模型选择',
          subtitle: '当前供应商的可用模型',
          trailing: SizedBox(
            width: 240,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedModelId.isEmpty && models.isNotEmpty
                        ? models.first.id
                        : selectedModelId,
                    items: models
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                '${m.displayName} (${m.contextWindowLabel})'
                                '${m.metadataSource != MetadataSource.builtin ? ' · ${_sourceLabel(m.metadataSource)}' : ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        settings.setSelectedModelId(currentProvider, value);
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusSm),
                        borderSide: BorderSide(color: c.borderOpaque),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: LingBiTokens.space3,
                        vertical: LingBiTokens.space2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _isLoadingModels
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: '从服务器刷新模型列表',
                        onPressed: () => _refreshModels(),
                      ),
              ],
            ),
          ),
        ),
        SettingsSectionItem(
          icon: LingBiIcons.tune,
          title: '创意度 (Temperature)',
          subtitle: '控制 AI 输出的随机性',
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: _temperature,
              divisions: 10,
              onChanged: (value) => setState(() => _temperature = value),
              activeColor: c.accent,
            ),
          ),
        ),
        SettingsSectionItem(
          icon: Icons.wifi_tethering,
          title: '连接测试',
          subtitle: '测试当前供应商连接是否正常',
          trailing: OutlinedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('测试'),
          ),
        ),
        SettingsSectionItem(
          icon: Icons.science_outlined,
          title: '测试生成',
          subtitle: '使用固定提示词验证模型可正常工作（可能产生少量 Token 费用）',
          trailing: OutlinedButton.icon(
            onPressed: _testGeneration,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('测试生成'),
          ),
        ),
        const SettingsSectionItem(
          icon: Icons.info_outline,
          title: '模型信息',
          subtitle: '当前模型的详细元数据',
          trailing: ModelStatusBar(compact: true),
        ),
        SettingsSectionItem(
          icon: Icons.replay,
          title: '重新配置向导',
          subtitle: '重新打开首次配置向导，重新选择供应商和模型',
          trailing: OutlinedButton.icon(
            onPressed: _reopenWizard,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('打开向导'),
          ),
        ),
      ],
    );
  }
}
