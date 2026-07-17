import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/settings_service.dart';
import 'package:lingbi/services/quota_service.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/ui/components/wg_nav.dart';
import 'package:lingbi/ui/components/wg_popover.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedSection = 0;
  final _sections = ['帐户', '主题', 'AI 配置', '关于'];
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  SettingsService get _settings => ServiceLocator.instance.settingsService;
  QuotaService get _quota => ServiceLocator.instance.quotaService;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _syncFields();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _syncFields() {
    final sel = _settings.selectedProvider;
    _apiKeyCtrl.text = _settings.getApiKey(sel);
    final active = _settings.providerRegistry.getAll().where((p) => p.name == sel).firstOrNull;
    _modelCtrl.text = active?.selectedModel ?? _defaultModel(sel);
    setState(() {});
  }

  String _defaultModel(String name) {
    switch (name) {
      case 'DeepSeek':
        return 'deepseek-chat';
      case 'OpenAI':
        return 'gpt-4o';
      case 'Claude':
        return 'claude-3-5-sonnet';
      case 'SenseNova':
        return 'nova-ptc-xl-v1';
      default:
        return '内置免费模型';
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      body: Row(children: [
        _sidebar(d),
        Expanded(child: Column(children: [
          _topbar(d),
          Expanded(child: _content(d)),
        ])),
      ]),
    );
  }

  Widget _sidebar(bool d) => WgSidebar(items: wgNavItems(context, 'settings'));

  Widget _topbar(bool d) {
    return Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: (d ? WgTokens.darkBg : WgTokens.bg).withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: WgTokens.borderFor(context)))),
      child: Row(children: [
        const Text('设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSerifSC')),
        const Spacer(),
        WgPopover(trigger: wgIconButton(Icons.search, d: d), contentBuilder: (context, close) => WgSearchPanel(d: d, onClose: close)),
        const SizedBox(width: 4),
        WgPopover(trigger: wgIconButton(Icons.notifications_outlined, d: d), contentBuilder: (context, close) => WgNotificationPanel(d: d)),
      ]),
    );
  }

  Widget _content(bool d) {
    final f = d ? WgTokens.darkFg : WgTokens.fg;
    final f2 = d ? WgTokens.darkFg2 : WgTokens.fg2;
    return SingleChildScrollView(padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (int i = 0; i < _sections.length; i++)
            Padding(padding: const EdgeInsets.only(right: 8), child: _sectionTab(_sections[i], i == _selectedSection, () => setState(() => _selectedSection = i))),
        ]),
        const SizedBox(height: 24),
        if (_selectedSection == 0) _buildAccount(f, f2),
        if (_selectedSection == 1) _buildThemeSection(d, f, f2),
        if (_selectedSection == 2) _buildAiConfig(f, f2),
        if (_selectedSection == 3) _buildAbout(f, f2),
      ]),
    );
  }

  Widget _sectionTab(String label, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? WgTokens.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8), border: active ? null : Border.all(color: WgTokens.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w500 : FontWeight.w400, color: active ? WgTokens.accent : WgTokens.fg2))));
  }

  Widget _buildAccount(Color f, Color f2) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field('邮箱', 'user@example.com', f, f2),
      const SizedBox(height: 16), _field('用户名', '吾名', f, f2),
    ]);
  }

  Widget _buildThemeSection(bool d, Color f, Color f2) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('主题模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Row(children: [
        _themeOption('亮色', _settings.themeMode == ThemeMode.light, () => _settings.setThemeMode(ThemeMode.light)),
        const SizedBox(width: 12), _themeOption('暗色', _settings.themeMode == ThemeMode.dark, () => _settings.setThemeMode(ThemeMode.dark)),
        const SizedBox(width: 12), _themeOption('系统', _settings.themeMode == ThemeMode.system, () => _settings.setThemeMode(ThemeMode.system)),
      ]),
    ]);
  }

  Widget _themeOption(String label, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? WgTokens.accent : WgTokens.surface,
          borderRadius: BorderRadius.circular(8), border: active ? null : Border.all(color: WgTokens.border)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : WgTokens.fg))));
  }

  Widget _buildAiConfig(Color f, Color f2) {
    final providers = <String>['free', 'DeepSeek', 'OpenAI', 'Claude', 'SenseNova'];
    for (final p in _settings.providerRegistry.getAll()) {
      if (!providers.contains(p.name)) providers.add(p.name);
    }
    final sel = _settings.selectedProvider;
    final active = _settings.providerRegistry.getAll().where((p) => p.name == sel).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('AI Provider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _field('Provider', sel, f, f2, trailing: DropdownButton<String>(
        value: sel,
        items: providers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) {
          if (v != null) {
            _settings.setProvider(v);
            _syncFields();
          }
        },
      )),
      const SizedBox(height: 16),
      _field('API Key', _settings.getApiKey(sel).isEmpty ? '未设置' : '????????', f, f2,
        trailing: SizedBox(width: 240, child: WgInput(hintText: 'sk-...', controller: _apiKeyCtrl,
          onChanged: (v) => _settings.setApiKey(sel, v)))),
      const SizedBox(height: 16),
      _field('模型', active?.selectedModel ?? _defaultModel(sel), f, f2,
        trailing: SizedBox(width: 240, child: WgInput(hintText: '模型名称', controller: _modelCtrl,
          onChanged: (v) {
            if (active != null) {
              _settings.providerRegistry.update(active.id, selectedModel: v);
              _settings.saveProviderRegistry();
            }
          }))),
      const SizedBox(height: 16),
      _field('今日额度', '${_quota.remaining} / ${_quota.dailyLimit}', f, f2),
    ]);
  }

  Widget _buildAbout(Color f, Color f2) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field('版本', '1.0.0', f, f2),
      const SizedBox(height: 16), _field('作者', '吾名', f, f2),
    ]);
  }

  Widget _field(String label, String value, Color f, Color f2, {Widget? trailing}) {
    return Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: f2))),
      trailing ?? Text(value, style: TextStyle(fontSize: 13, color: f, fontWeight: FontWeight.w500)),
    ]);
  }
}
