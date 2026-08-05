import 'package:flutter/material.dart';

import '../../../../shared/ai/models/endpoint_config.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class CustomEndpointSettingsSection extends StatefulWidget {
  const CustomEndpointSettingsSection({super.key});

  @override
  State<CustomEndpointSettingsSection> createState() =>
      _CustomEndpointSettingsSectionState();
}

class _CustomEndpointSettingsSectionState
    extends State<CustomEndpointSettingsSection> with SettingsAwareState {
  void _showAddEndpointDialog(BuildContext context, LingBiColors c) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    String testResult = '';
    bool testing = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加自定义端点'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如：本地 Ollama',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.example.com/v1/chat/completions',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: '模型 ID',
                    hintText: 'gpt-4o-mini',
                  ),
                ),
                if (testResult.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    testResult,
                    style: TextStyle(
                      fontSize: 13,
                      color: testResult == '连接成功'
                          ? LingBiTokens.success
                          : (testing ? c.fgSecondary : LingBiTokens.warning),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            OutlinedButton(
              onPressed: testing
                  ? null
                  : () async {
                      setDialogState(() {
                        testing = true;
                        testResult = '正在测试连接…';
                      });
                      final config = EndpointConfig(
                        protocol: Protocol.openai,
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        baseUrl: urlCtrl.text.trim(),
                        apiKey: keyCtrl.text.trim(),
                        modelId: modelCtrl.text.trim(),
                      );
                      ServiceLocator.instance.aiService.addEndpoint(config);
                      const result = '连接已添加';
                      setDialogState(() {
                        testResult = result;
                        testing = false;
                      });
                    },
              child: const Text('测试连接'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                final key = keyCtrl.text.trim();
                final model = modelCtrl.text.trim();
                if (name.isEmpty || url.isEmpty || model.isEmpty) return;
                final config = EndpointConfig(
                  protocol: Protocol.openai,
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  baseUrl: url,
                  apiKey: key,
                  modelId: model,
                );
                ServiceLocator.instance.settingsService
                    .addCustomEndpoint(config);
                Navigator.of(ctx).pop();
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      urlCtrl.dispose();
      keyCtrl.dispose();
      modelCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final settings = ServiceLocator.instance.settingsService;
    final endpoints = settings.customEndpoints;

    return Padding(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LingBiIcons.globe, size: 20, color: c.fgSecondary),
              const SizedBox(width: LingBiTokens.space2),
              Text(
                '自定义端点',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddEndpointDialog(context, c),
                icon: const Icon(LingBiIcons.add, size: 16),
                label: const Text('添加端点'),
              ),
            ],
          ),
          const SizedBox(height: LingBiTokens.space4),
          if (endpoints.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LingBiTokens.space6),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
                border: Border.all(
                  color: c.borderOpaque.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '暂无自定义端点。点击"添加端点"以添加 OpenAI 兼容的自定义提供商。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: c.muted,
                ),
              ),
            )
          else
            ...endpoints.map(
              (ep) => Padding(
                padding: const EdgeInsets.only(bottom: LingBiTokens.space3),
                child: Container(
                  padding: const EdgeInsets.all(LingBiTokens.space4),
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
                    border: Border.all(
                      color: c.borderOpaque.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LingBiIcons.globe, size: 20, color: c.fgSecondary),
                      const SizedBox(width: LingBiTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.fg,
                              ),
                            ),
                            Text(
                              '${ep.baseUrl}  ·  ${ep.modelId}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(LingBiIcons.delete, size: 18, color: c.muted),
                        tooltip: '删除',
                        onPressed: () => settings.removeCustomEndpoint(ep.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
