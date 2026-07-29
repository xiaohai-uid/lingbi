import 'package:flutter/material.dart';
import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/shared/ai/models/endpoint_config.dart';
import 'package:lingbi/shared/di/service_locator.dart';

import 'package:lingbi/services/license_service.dart';
import 'package:lingbi/features/settings/data/subscription_service.dart';
import 'package:lingbi/features/sync/data/sync/webdav_service.dart';
import 'package:lingbi/features/sync/data/sync/sync_manager.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';
import 'package:lingbi/ui_v2/theme/lingbi_icons.dart';
import 'package:lingbi/ui_v2/components/model_status_bar.dart';
import 'pro_gate.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = '外观';

  final _sections = ['外观', '编辑器', 'AI 模型', 'API 密钥', '自定义端点', '快捷键', '云同步', '隐私', '订阅'];

  // API Key controllers
  late final TextEditingController _openaiKeyController;
  late final TextEditingController _anthropicKeyController;
  late final TextEditingController _deepseekKeyController;
  late final TextEditingController _sensenovaKeyController;

  // Local state for settings not managed by SettingsService
  double _fontSize = 16;
  bool _wordCount = true;
  bool _autoSave = true;
  String _editorWidth = 'medium';
  double _temperature = 0.7;
  bool _isLoadingModels = false;

  // Cloud sync state
  late final TextEditingController _webdavUrlController;
  late final TextEditingController _webdavUserController;
  late final TextEditingController _webdavPassController;
  bool _webdavEnabled = false;
  bool _testingConnection = false;
  String _syncStatusText = '';
  bool _syncing = false;
  String _lastSyncText = '尚未同步';

  // Privacy state
  bool _analyticsEnabled = true;

  // Subscription state
  late final TextEditingController _licenseKeyController;
  bool _activatingLicense = false;
  LicenseInfo? _currentLicense;

  @override
  void initState() {
    super.initState();
    final settings = ServiceLocator.instance.settingsService;
    _openaiKeyController = TextEditingController(text: settings.getApiKey('openai'));
    _anthropicKeyController = TextEditingController(text: settings.getApiKey('claude'));
    _deepseekKeyController = TextEditingController(text: settings.getApiKey('deepseek'));
    _sensenovaKeyController = TextEditingController(text: settings.getApiKey('sensenova'));
    _webdavUrlController = TextEditingController();
    _webdavUserController = TextEditingController();
    _webdavPassController = TextEditingController();
    _licenseKeyController = TextEditingController();
    settings.addListener(_onSettingsChanged);
    _loadSubscriptionState();
  }

  @override
  void dispose() {
    final settings = ServiceLocator.instance.settingsService;
    settings.removeListener(_onSettingsChanged);
    _openaiKeyController.dispose();
    _anthropicKeyController.dispose();
    _deepseekKeyController.dispose();
    _sensenovaKeyController.dispose();
    _webdavUrlController.dispose();
    _webdavUserController.dispose();
    _webdavPassController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshModels([String? providerId]) async {
    final pid = providerId ??
        ServiceLocator.instance.settingsService.selectedProvider;
    if (_isLoadingModels) return;
    setState(() => _isLoadingModels = true);
    try {
      await ServiceLocator.instance.aiService.discoverModels(pid);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingModels = false);
  }

  String get _themeModeValue {
    final mode = ServiceLocator.instance.settingsService.themeMode;
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static const _providerLabels = {
    'free': '免费模型',
    'sensenova': 'SenseNova',
    'deepseek': 'DeepSeek V3',
    'openai': 'OpenAI',
    'claude': 'Claude',
  };

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        Expanded(
          child: Row(
            children: [
              _buildSideNav(c),
              Container(
                width: 1,
                color: c.borderOpaque.withValues(alpha: 0.3),
              ),
              Expanded(child: _buildSectionContent(c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Text(
        '设置',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: c.fg,
          letterSpacing: -0.625 / 26 * 26,
        ),
      ),
    );
  }

  Widget _buildSideNav(LingBiColors c) {
    return SizedBox(
      width: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space2,
        ),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          final isActive = section == _selectedSection;
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => setState(() => _selectedSection = section),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space3,
                  vertical: LingBiTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? c.accent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                ),
                child: Text(
                  section,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? c.accent : c.fgSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent(LingBiColors c) {
    switch (_selectedSection) {
      case '外观':
        return _buildAppearanceSection(c);
      case '编辑器':
        return _buildEditorSection(c);
      case 'AI 模型':
        return _buildAiModelSection(c);
      case 'API 密钥':
        return _buildApiKeySection(c);
      case '自定义端点':
        return _buildCustomEndpointSection(c);
      case '快捷键':
        return _buildShortcutsSection(c);
      case '云同步':
        return _buildCloudSyncSection(c);
      case '隐私':
        return _buildPrivacySection(c);
      case '订阅':
        return _buildSubscriptionSection(c);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppearanceSection(LingBiColors c) {
    return _buildSection(
      c: c,
      items: [
        _SettingItem(
          icon: LingBiIcons.sun,
          title: '主题',
          subtitle: '选择应用外观',
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('浅色')),
              ButtonSegment(value: 'dark', label: Text('深色')),
              ButtonSegment(value: 'system', label: Text('跟随系统')),
            ],
            selected: {_themeModeValue},
            onSelectionChanged: (value) {
              final mode = value.first;
              final service = ServiceLocator.instance.settingsService;
              if (mode == 'light') {
                service.setThemeMode(ThemeMode.light);
              } else if (mode == 'dark') {
                service.setThemeMode(ThemeMode.dark);
              } else {
                service.setThemeMode(ThemeMode.system);
              }
            },
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.palette,
          title: '强调色',
          subtitle: '自定义主色调',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _colorDot(c.accent, true, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(c.cinnabar, false, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(LingBiTokens.warning, false, c),
              const SizedBox(width: LingBiTokens.space1),
              _colorDot(LingBiTokens.success, false, c),
            ],
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.wordCount,
          title: '字体大小',
          subtitle: '编辑器字体大小',
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              onChanged: (value) => setState(() => _fontSize = value),
              activeColor: c.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(Color color, bool isActive, LingBiColors c) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: c.accent, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
    );
  }

  Widget _buildEditorSection(LingBiColors c) {
    return _buildSection(
      c: c,
      items: [
        _SettingItem(
          icon: LingBiIcons.wordCount,
          title: '字数统计',
          subtitle: '在状态栏显示实时字数',
          trailing: Switch(
            value: _wordCount,
            onChanged: (value) => setState(() => _wordCount = value),
            activeThumbColor: c.accent,
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.check,
          title: '自动保存',
          subtitle: '每 30 秒自动保存当前内容',
          trailing: Switch(
            value: _autoSave,
            onChanged: (value) => setState(() => _autoSave = value),
            activeThumbColor: c.accent,
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.chapter,
          title: '默认编辑器宽度',
          subtitle: '编辑区域的最大宽度',
          trailing: SizedBox(
            width: 160,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'narrow', label: Text('窄')),
                ButtonSegment(value: 'medium', label: Text('中')),
                ButtonSegment(value: 'wide', label: Text('宽')),
              ],
              selected: {_editorWidth},
              onSelectionChanged: (value) =>
                  setState(() => _editorWidth = value.first),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiModelSection(LingBiColors c) {
    final settings = ServiceLocator.instance.settingsService;
    final currentProvider = settings.selectedProvider;
    final models = ModelRegistry.instance.getModelsForProvider(currentProvider);
    final selectedModelId = settings.getSelectedModelId(currentProvider);

    return _buildSection(
      c: c,
      items: [
        _SettingItem(
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
        _SettingItem(
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
        _SettingItem(
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
        _SettingItem(
          icon: Icons.wifi_tethering,
          title: '连接测试',
          subtitle: '测试当前供应商连接是否正常',
          trailing: OutlinedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('测试'),
          ),
        ),
        _SettingItem(
          icon: Icons.science_outlined,
          title: '测试生成',
          subtitle: '使用固定提示词验证模型可正常工作（可能产生少量 Token 费用）',
          trailing: OutlinedButton.icon(
            onPressed: _testGeneration,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('测试生成'),
          ),
        ),
        // 模型状态栏预览
        const _SettingItem(
          icon: Icons.info_outline,
          title: '模型信息',
          subtitle: '当前模型的详细元数据',
          trailing: ModelStatusBar(compact: true),
        ),
        _SettingItem(
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

  Future<void> _testConnection() async {
    final result = await ServiceLocator.instance.aiService.testConnectionUnified();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '连接成功 (${result.latencyMs}ms)${result.responsePreview != null ? " — ${result.responsePreview}" : ""}'
            : result.message),
        backgroundColor: result.success ? LingBiTokens.success : LingBiTokens.warning,
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
      await ServiceLocator.instance.aiService.testGeneration().forEach(buffer.write);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(buffer.isNotEmpty
              ? '测试生成成功：${buffer.toString().length > 60 ? "${buffer.toString().substring(0, 57)}..." : buffer}'
              : '生成结果为空，请检查配置'),
          backgroundColor: buffer.isNotEmpty ? LingBiTokens.success : LingBiTokens.warning,
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

  Widget _buildApiKeySection(LingBiColors c) {
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
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.secureStorageWarning ??
                        '安全存储不可用，API Key 仅在本次会话有效，不会保存到磁盘。',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        _buildSection(
      c: c,
      items: [
        _SettingItem(
          icon: LingBiIcons.apiKey,
          title: 'SenseNova API Key',
          subtitle: settings.hasApiKey('sensenova')
              ? (settings.isSessionOnlyKey('sensenova') ? '已配置（仅本次会话）' : '已配置')
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
        _SettingItem(
          icon: LingBiIcons.apiKey,
          title: 'DeepSeek API Key',
          subtitle: settings.hasApiKey('deepseek')
              ? (settings.isSessionOnlyKey('deepseek') ? '已配置（仅本次会话）' : '已配置')
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
        _SettingItem(
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
        _SettingItem(
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

  Widget _buildCustomEndpointSection(LingBiColors c) {
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
                onPressed: () => _showAddEndpointDialog(c),
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
                        icon: Icon(LingBiIcons.delete, size: 18, color: c.muted),
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

  void _showAddEndpointDialog(LingBiColors c) {
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

  Widget _buildShortcutsSection(LingBiColors c) {
    final shortcuts = [
      ('Ctrl + S', '保存当前章节'),
      ('Ctrl + Z', '撤销'),
      ('Ctrl + Shift + Z', '重做'),
      ('Ctrl + B', '粗体'),
      ('Ctrl + I', '斜体'),
      ('Ctrl + K', '插入链接'),
      ('Ctrl + Shift + K', '打开 AI 助手'),
      ('Ctrl + Shift + B', '切换侧栏'),
      ('Ctrl + Shift + T', '切换主题'),
      ('Ctrl + Shift + M', '技能市场'),
    ];

    return Padding(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷键',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.fg,
            ),
          ),
          const SizedBox(height: LingBiTokens.space4),
          ...shortcuts.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: LingBiTokens.space2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space4,
                  vertical: LingBiTokens.space3,
                ),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
                  border: Border.all(
                    color: c.borderOpaque.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: c.fg,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LingBiTokens.space2,
                        vertical: LingBiTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(LingBiTokens.radiusSm),
                      ),
                      child: Text(
                        s.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.fgSecondary,
                          fontFamily: LingBiTokens.fontMono,
                        ),
                      ),
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

  // ==================== 云同步 ====================

  Widget _buildCloudSyncSection(LingBiColors c) {
    return ProGate(
      feature: ProFeature.cloudSync,
      child: _buildSection(
        c: c,
        items: [
          _SettingItem(
            icon: LingBiIcons.cloudSync,
            title: 'WebDAV 云同步',
            subtitle: '支持坚果云/Nextcloud/ownCloud',
            trailing: Switch(
              value: _webdavEnabled,
              onChanged: (v) => setState(() => _webdavEnabled = v),
            ),
          ),
          _SettingItem(
            icon: LingBiIcons.globe,
            title: '服务器地址',
            subtitle: 'WebDAV 服务 URL',
            trailing: SizedBox(
              width: 260,
              child: TextField(
                controller: _webdavUrlController,
                enabled: _webdavEnabled,
                decoration: _inputDecoration(c, 'https://dav.jianguoyun.com/dav/'),
              ),
            ),
          ),
          _SettingItem(
            icon: LingBiIcons.character,
            title: '用户名',
            subtitle: 'WebDAV 登录账号',
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _webdavUserController,
                enabled: _webdavEnabled,
                decoration: _inputDecoration(c, '用户名'),
              ),
            ),
          ),
          _SettingItem(
            icon: LingBiIcons.apiKey,
            title: '密码',
            subtitle: 'WebDAV 登录密码（安全存储）',
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _webdavPassController,
                enabled: _webdavEnabled,
                obscureText: true,
                decoration: _inputDecoration(c, '密码'),
              ),
            ),
          ),
          _SettingItem(
            icon: LingBiIcons.cloud,
            title: '连接测试',
            subtitle: _syncStatusText.isEmpty ? '测试 WebDAV 连接可用性' : _syncStatusText,
            trailing: FilledButton.tonal(
              onPressed: _webdavEnabled && !_testingConnection
                  ? _testWebDavConnection
                  : null,
              child: _testingConnection
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('测试连接'),
            ),
          ),
          _SettingItem(
            icon: LingBiIcons.refresh,
            title: '立即同步',
            subtitle: _lastSyncText,
            trailing: FilledButton(
              onPressed: _webdavEnabled && !_syncing ? _triggerSync : null,
              child: _syncing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('同步'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testWebDavConnection() async {
    setState(() {
      _testingConnection = true;
      _syncStatusText = '';
    });
    try {
      final config = WebDavConfig(
        serverUrl: _webdavUrlController.text.trim(),
        username: _webdavUserController.text.trim(),
        password: _webdavPassController.text,
      );
      final manager = SyncManager(config: config);
      final ok = await manager.testConnection();
      manager.dispose();
      if (mounted) {
        setState(() => _syncStatusText = ok ? '✅ 连接成功' : '❌ 连接失败');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncStatusText = '❌ 错误: $e');
      }
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  /// P1.8: 手动触发同步
  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    try {
      final config = WebDavConfig(
        serverUrl: _webdavUrlController.text.trim(),
        username: _webdavUserController.text.trim(),
        password: _webdavPassController.text,
      );
      final manager = SyncManager(config: config);
      // 收集当前项目文件（简化：同步 .lingbi 目录下的 JSON）
      final synced = await manager.syncAll({});
      manager.dispose();
      if (mounted) {
        setState(() {
          _lastSyncText = '上次同步: ${DateTime.now().toString().substring(0, 19)} ($synced 个文件)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastSyncText = '同步失败: $e');
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ==================== 隐私 ====================

  Widget _buildPrivacySection(LingBiColors c) {
    return _buildSection(
      c: c,
      items: [
        _SettingItem(
          icon: LingBiIcons.privacy,
          title: '匿名数据贡献',
          subtitle: '仅传送不可逆聚合统计（题材/字数/技能使用次数），不含任何个人内容',
          trailing: Switch(
            value: _analyticsEnabled,
            onChanged: (v) => setState(() => _analyticsEnabled = v),
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.privacy,
          title: '数据范围',
          subtitle: '题材分布、章节数、总字数、Skill 使用频次',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LingBiTokens.space2,
              vertical: LingBiTokens.space1,
            ),
            decoration: BoxDecoration(
              color: _analyticsEnabled
                  ? LingBiTokens.success.withValues(alpha: 0.1)
                  : c.surfaceContainer,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
            ),
            child: Text(
              _analyticsEnabled ? '已开启' : '已关闭',
              style: TextStyle(
                fontSize: 12,
                color: _analyticsEnabled ? LingBiTokens.success : c.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 订阅 ====================

  void _loadSubscriptionState() {
    // 尝试加载已保存的许可证
    ServiceLocator.instance.licenseService.loadLicense().then((license) {
      if (mounted) setState(() => _currentLicense = license);
    });
  }

  Widget _buildSubscriptionSection(LingBiColors c) {
    final sub = ServiceLocator.instance.subscriptionService;
    final isPro = sub.isPro;

    return _buildSection(
      c: c,
      items: [
        _SettingItem(
          icon: LingBiIcons.subscription,
          title: '当前方案',
          subtitle: isPro ? 'Pro — 全部功能已解锁' : 'Free — 本地编辑 + 自带 API Key + 基础 Skill',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LingBiTokens.space3,
              vertical: LingBiTokens.space1,
            ),
            decoration: BoxDecoration(
              color: isPro
                  ? LingBiTokens.blue.withValues(alpha: 0.1)
                  : c.surfaceContainer,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
              border: Border.all(
                color: isPro ? LingBiTokens.blue : c.borderOpaque,
              ),
            ),
            child: Text(
              isPro ? 'Pro' : 'Free',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPro ? LingBiTokens.blue : c.fgSecondary,
              ),
            ),
          ),
        ),
        _SettingItem(
          icon: LingBiIcons.apiKey,
          title: '许可证激活',
          subtitle: _currentLicense != null
              ? '已激活 — 到期: ${_currentLicense!.expiresAt.year}-${_currentLicense!.expiresAt.month.toString().padLeft(2, '0')}-${_currentLicense!.expiresAt.day.toString().padLeft(2, '0')}'
              : '输入许可证密钥解锁 Pro 功能',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _licenseKeyController,
                  decoration: _inputDecoration(c, 'LINGBI-PRO-XXXX-XXXX-XXXX'),
                ),
              ),
              const SizedBox(width: LingBiTokens.space2),
              FilledButton(
                onPressed: _activatingLicense ? null : _activateLicense,
                child: _activatingLicense
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('激活'),
              ),
            ],
          ),
        ),
        _SettingItem(
          icon: isPro ? LingBiIcons.check : LingBiIcons.lock,
          title: 'Pro 功能',
          subtitle: '云同步 / 高级导出 / 批量操作 / 官方模型套餐',
          trailing: Text(
            isPro ? '已全部解锁' : '需 Pro 许可证',
            style: TextStyle(
              fontSize: 12,
              color: isPro ? LingBiTokens.success : c.muted,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _activateLicense() async {
    final key = _licenseKeyController.text.trim();
    if (key.isEmpty) return;
    setState(() => _activatingLicense = true);
    try {
      final licenseService = ServiceLocator.instance.licenseService;
      final license = await licenseService.activate(
        key: key,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      if (license != null) {
        ServiceLocator.instance.subscriptionService.activatePro(
          licenseKey: key,
          expiresAt: license.expiresAt,
        );
        if (mounted) {
          setState(() {
            _currentLicense = license;
            _licenseKeyController.clear();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('许可证格式无效')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _activatingLicense = false);
    }
  }

  // ==================== 输入框装饰 ====================

  InputDecoration _inputDecoration(LingBiColors c, String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  Widget _buildSection({
    required LingBiColors c,
    required List<_SettingItem> items,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: LingBiTokens.space3),
                child: _buildSettingItem(item, c),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSettingItem(_SettingItem item, LingBiColors c) {
    return Container(
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
          Icon(item.icon, size: 20, color: c.fgSecondary),
          const SizedBox(width: LingBiTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.fg,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          item.trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _SettingItem {

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
}
