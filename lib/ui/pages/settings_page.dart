import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import 'package:lingbi/services/settings_service.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:lingbi/services/provider_registry.dart';
import 'package:lingbi/services/quota_service.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/ui/theme/wg_components.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = ServiceLocator.instance.settingsService;
  final WorldService _worldService = ServiceLocator.instance.worldService;
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, TextEditingController> _urlControllers = {};
  List<World> _worlds = [];
  final QuotaService _quota = ServiceLocator.instance.quotaService;
  bool _loadingWorlds = true;

  @override
  void initState() {
    super.initState();
    for (final key in ['sensenova', 'deepseek', 'openai', 'claude']) {
      _keyControllers[key] =
          TextEditingController(text: _settings.getApiKey(key));
      _urlControllers[key] =
          TextEditingController(text: _settings.getApiUrl(key));
    }
    _loadWorlds();
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _urlControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWorlds() async {
    setState(() => _loadingWorlds = true);
    try {
      _worlds = await _worldService.listWorlds();
    } catch (_) {}
    if (mounted) setState(() => _loadingWorlds = false);
  }

  Future<void> _deleteWorld(World world) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s83),
        content: Text('确定要删除世界「${world.name}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.s33)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
              child: Text(AppLocalizations.of(context)!.s25)),
        ],
      ),
    );
    if (confirm == true) {
      await _worldService.deleteWorld(world.id);
      _loadWorlds();
    }
  }

  Future<void> _testConnection(String provider, String apiKey) async {
    final aiService = ServiceLocator.instance.aiService;
    final urlCtrl = _urlControllers[provider];
    if (urlCtrl != null && urlCtrl.text.trim().isNotEmpty) {
      aiService.setBaseUrl(provider, urlCtrl.text.trim());
    }
    final result = await aiService.testConnection(provider, apiKey);
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('测试 $provider'),
              content: Text(result,
                  style: TextStyle(
                      fontSize: 14,
                      color: result.startsWith('✅')
                          ? const Color(0xFF5B8C5A)
                          : const Color(0xFFC45A5A))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.s22))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WgTokens.bgFor(context),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.s99),
        backgroundColor: WgTokens.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSerifSC',
          color: WgTokens.fgFor(context),
        ),
        iconTheme: IconThemeData(color: WgTokens.fgFor(context)),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh, color: WgTokens.fg2For(context)),
              tooltip: '刷新',
              onPressed: _loadWorlds),
        ],
      ),
      body: ListView(
        children: [
          _buildQuotaCard(context),
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title:
                Text('深色模式', style: TextStyle(color: WgTokens.fgFor(context))),
            subtitle: Text('切换深色/浅色主题',
                style: TextStyle(color: WgTokens.fg2For(context))),
            value: _settings.themeMode == ThemeMode.dark,
            activeColor: WgTokens.accent,
            activeTrackColor: WgTokens.accent.withValues(alpha: 0.4),
            onChanged: (v) {
              _settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            title:
                Text('跟随系统', style: TextStyle(color: WgTokens.fgFor(context))),
            subtitle: Text('自动匹配系统主题',
                style: TextStyle(color: WgTokens.fg2For(context))),
            value: _settings.themeMode == ThemeMode.system,
            activeColor: WgTokens.accent,
            activeTrackColor: WgTokens.accent.withValues(alpha: 0.4),
            onChanged: (v) {
              if (v) _settings.setThemeMode(ThemeMode.system);
            },
          ),
          Divider(height: 1, color: WgTokens.borderLightFor(context)),
          const _SectionHeader(title: 'AI 模型'),
          ListTile(
            title: Text('默认 AI 模型',
                style: TextStyle(color: WgTokens.fgFor(context))),
            subtitle: Text(_providerLabel(_settings.selectedProvider),
                style: TextStyle(color: WgTokens.fg2For(context))),
            trailing:
                Icon(Icons.chevron_right, color: WgTokens.fg3For(context)),
            onTap: () => _selectProvider(),
          ),
          Divider(height: 1, color: WgTokens.borderLightFor(context)),
          const _SectionHeader(title: '供应商管理'),
          ..._buildProviderSection(context),
          Divider(height: 1, color: WgTokens.borderLightFor(context)),
          const _SectionHeader(title: 'API 密钥'),
          ..._buildApiKeyFields(context),
          const SizedBox(height: WgTokens.space4),
          Divider(height: 1, color: WgTokens.borderLightFor(context)),
          const _SectionHeader(title: '世界管理'),
          if (_loadingWorlds)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else if (_worlds.isEmpty)
            Padding(
                padding: const EdgeInsets.all(WgTokens.space4),
                child: Text('暂无世界',
                    style: TextStyle(color: WgTokens.fg3For(context))))
          else
            ..._worlds.map((w) => ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: WgTokens.accentSoft,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.public,
                        size: 18, color: WgTokens.accent),
                  ),
                  title: Text(w.name,
                      style: TextStyle(color: WgTokens.fgFor(context))),
                  subtitle: Text(w.description,
                      style: TextStyle(color: WgTokens.fg3For(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: WgTokens.danger),
                    onPressed: () => _deleteWorld(w),
                  ),
                )),
          const SizedBox(height: WgTokens.space6),
          Center(
            child: Text(
              '灵笔 v0.4.0',
              style: TextStyle(fontSize: 12, color: WgTokens.fg3For(context)),
            ),
          ),
          const SizedBox(height: WgTokens.space8),
        ],
      ),
    );
  }

  List<Widget> _buildProviderSection(BuildContext context) {
    final registry = _settings.providerRegistry;
    final providers = registry.getAll();
    if (providers.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('暂无自定义供应商，点击下方按钮添加',
              style: TextStyle(color: WgTokens.fg3For(context), fontSize: 13)),
        ),
        _buildAddProviderButton(context),
      ];
    }
    return [
      ...providers.map((p) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: WgTokens.accentSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.dns, size: 18, color: WgTokens.accent),
            ),
            title: Text(p.name, style: TextStyle(color: WgTokens.fgFor(context))),
            subtitle: Text(p.selectedModel ?? '未选择模型', style: TextStyle(color: WgTokens.fg3For(context), fontSize: 12)),
trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: WgTokens.accent, size: 18),
                    tooltip: '参数配置',
                    onPressed: () => _showParameterConfig(p),
                  ),
                  if (p.selectedModel != null)
                    IconButton(
                      icon: Icon(
                        registry.getActiveProvider()?.id == p.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: WgTokens.accent, size: 18),
                      tooltip: '设为当前',
                      onPressed: () {
                        registry.setActiveProvider(p.id);
                        _settings.saveProviderRegistry();
                        setState(() {});
                      },
                    ),
                  if (p.selectedModel == null)
                    IconButton(
                      icon: const Icon(Icons.wifi_find, color: WgTokens.info, size: 18),
                      tooltip: '发现模型',
                      onPressed: () => _showModelSelector(p),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: WgTokens.danger, size: 18),
                    onPressed: () {
                      _settings.removeProvider(p.id);
                      setState(() {});
                    },
                  ),
                ],
              ),
          )),
      _buildAddProviderButton(context),
    ];
  }

  Widget _buildAddProviderButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('添加供应商', style: TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: WgTokens.accent,
          side: BorderSide(color: WgTokens.accent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _showAddProviderDialog(),
      ),
    );
  }

  Widget _buildQuotaCard(BuildContext context) {
    final isMember = _quota.isMember;
    final usage = _quota.dailyUsage;
    final limit = _quota.dailyLimit;
    final remaining = _quota.remaining;
    final ratio = limit > 0 ? usage / limit : 0.0;
    const afdUrl = 'https://afdian.com/a/lingbi';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFE8A838)),
                const SizedBox(width: 8),
                Text('AI 调用配额',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: WgTokens.fgFor(context))),
                const Spacer(),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A838).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('会员',
                        style: TextStyle(color: Color(0xFFE8A838), fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: WgTokens.borderFor(context),
              color: ratio > 0.8 ? Colors.orange : WgTokens.accent,
            ),
            const SizedBox(height: 8),
            Text('今日已用 $usage / $limit · 剩余 $remaining 次',
                style: TextStyle(color: WgTokens.fg2For(context), fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.favorite, size: 16),
                    label: Text(AppLocalizations.of(context)!.s30),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE8A838),
                      side: const BorderSide(color: Color(0xFFE8A838)),
                    ),
                    onPressed: () => _activateMembership(context, afdUrl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateMembership(BuildContext context, String afdUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s76),
        content: const Text('请在爱发电完成捐赠后，将获得的 tokens.json 放入程序目录，'
            '然后点击下方「验证并激活」。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.s33)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.s112),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _quota.activateMemberToken();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '会员激活成功！' : '未找到有效的 tokens.json'),
          ),
        );
        setState(() {});
      }
    }
  }

  void _showAddProviderDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final keyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WgTokens.surfaceFor(context),
        title: const Text('添加供应商', style: TextStyle(fontFamily: 'NotoSerifSC', fontSize: 17, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '供应商名称', hintText: '例如：我的中转站'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: 'API Key', hintText: 'sk-...'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.s33)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WgTokens.accent),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
              final config = ProviderConfig(
                name: nameCtrl.text.trim(),
                baseUrl: urlCtrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
                apiKey: keyCtrl.text.trim(),
              );
              _settings.addProvider(config);
              Navigator.pop(ctx);
              setState(() {});
              _showModelSelector(config);
            },
            child: Text(AppLocalizations.of(context)!.s85),
          ),
        ],
      ),
    );
  }

  void _showModelSelector(ProviderConfig config) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return FutureBuilder<List<ModelInfo>>(
            future: ProviderRegistry.getModels(config.baseUrl, apiKey: config.apiKey),
            builder: (ctx, snapshot) {
              final title = Text('选择模型 — ${config.name}',
                  style: const TextStyle(fontFamily: 'NotoSerifSC', fontSize: 17, fontWeight: FontWeight.w600));
              Widget content;
              if (snapshot.connectionState == ConnectionState.waiting) {
                content = const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 16),
                    Text('正在发现模型...', style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))),
                  ]),
                );
              } else if (snapshot.hasError) {
                content = Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('发现失败: ${snapshot.error}', style: const TextStyle(color: Color(0xFFC45A5A), fontSize: 13)),
                );
              } else {
                final models = snapshot.data ?? [];
                if (models.isEmpty) {
                  content = const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('未发现可用模型', style: TextStyle(fontSize: 14, color: Color(0xFF8A7B68))),
                  );
                } else {
                  content = SizedBox(
                    width: 400,
                    height: 300,
                    child: ListView.builder(
                      itemCount: models.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.smart_toy, size: 20, color: Color(0xFFE8A838)),
                        title: Text(models[i].id, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(models[i].ownedBy, style: const TextStyle(fontSize: 11, color: Color(0xFF8A7B68))),
                        onTap: () {
                          _settings.providerRegistry.update(config.id, selectedModel: models[i].id);
                          _settings.saveProviderRegistry();
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  );
                }
              }
              return AlertDialog(
                backgroundColor: WgTokens.surfaceFor(context),
                title: title,
                content: content,
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.s101)),
                ],
              );
            },
          );
        });
      },
    );
  }

  void _showParameterConfig(ProviderConfig config) {
    double temp = config.defaultParams.temperature;
    int maxT = config.defaultParams.maxTokens;
    double topP = config.defaultParams.topP;
    final maxTokensOptions = [1024, 2048, 4096, 8192, 16384, 32768];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: WgTokens.surfaceFor(context),
          title: Text('参数配置 — ${config.name}',
              style: const TextStyle(
                  fontFamily: 'NotoSerifSC',
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Temperature',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: temp,
                        max: 2,
                        divisions: 20,
                        activeColor: WgTokens.accent,
                        onChanged: (v) => setDialogState(() => temp = v),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(temp.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Max Tokens',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                DropdownButton<int>(
                  value: maxT,
                  isExpanded: true,
                  items: maxTokensOptions.map((v) {
                    return DropdownMenuItem(value: v, child: Text(v.toString()));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => maxT = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Top P',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: topP,
                        divisions: 20,
                        activeColor: WgTokens.accent,
                        onChanged: (v) => setDialogState(() => topP = v),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(topP.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.s33)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: WgTokens.accent),
              onPressed: () {
                _settings.providerRegistry.update(config.id,
                    defaultParams:
                        DefaultParams(temperature: temp, maxTokens: maxT, topP: topP));
                _settings.saveProviderRegistry();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context)!.s17),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildApiKeyFields(BuildContext context) {
    final providers = [
      (
        'sensenova',
        'SenseNova API Key',
        'https://token.sensenova.cn/v1',
        Icons.auto_awesome
      ),
      (
        'deepseek',
        'DeepSeek API Key',
        'https://api.deepseek.com',
        Icons.psychology
      ),
      ('openai', 'OpenAI API Key', 'https://api.openai.com/v1', Icons.token),
      (
        'claude',
        'Claude API Key',
        'https://api.anthropic.com',
        Icons.auto_awesome
      ),
    ];

    return providers.expand((p) {
      final key = p.$1;
      final label = p.$2;
      final defaultUrl = p.$3;
      final icon = p.$4;
      final keyCtrl = _keyControllers[key]!;
      final urlCtrl = _urlControllers[key]!;
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: WgTokens.space4, vertical: WgTokens.space1),
          child: Row(
            children: [
              Icon(icon, size: 20, color: WgTokens.accent),
              const SizedBox(width: WgTokens.space3),
              Expanded(
                child: TextField(
                  controller: keyCtrl,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: WgTokens.fg2For(context)),
                    hintText: 'sk-...',
                    hintStyle: TextStyle(color: WgTokens.fg3For(context)),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: WgTokens.borderFor(context))),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: WgTokens.borderLightFor(context))),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: WgTokens.accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: WgTokens.space3,
                        vertical: WgTokens.space2 + 2),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.wifi_find,
                              size: 18, color: WgTokens.info),
                          tooltip: '测试连接',
                          onPressed: () =>
                              _testConnection(key, keyCtrl.text.trim()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save,
                              size: 18, color: WgTokens.accent),
                          tooltip: '保存密钥',
                          onPressed: () {
                            _settings.setApiKey(key, keyCtrl.text.trim());
                            _settings.setApiUrl(key, urlCtrl.text.trim());
                          },
                        ),
                      ],
                    ),
                  ),
                  style: TextStyle(color: WgTokens.fgFor(context)),
                  obscureText: true,
                  onSubmitted: (v) {
                    _settings.setApiKey(key, v.trim());
                    _settings.setApiUrl(key, urlCtrl.text.trim());
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 48, right: WgTokens.space4, bottom: WgTokens.space2),
          child: TextField(
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: '$label URL',
              hintText: defaultUrl,
              hintStyle: TextStyle(color: WgTokens.fg3For(context)),
              isDense: true,
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: WgTokens.borderFor(context))),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: WgTokens.borderLightFor(context))),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: WgTokens.accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: WgTokens.space3, vertical: WgTokens.space2),
            ),
            style: TextStyle(fontSize: 12, color: WgTokens.fgFor(context)),
            onSubmitted: (v) => _settings.setApiUrl(key, v.trim()),
          ),
        ),
      ];
    }).toList();
  }

  void _selectProvider() {
    final providers = ['free', 'sensenova', 'deepseek', 'openai', 'claude'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => SimpleDialog(
          backgroundColor: WgTokens.surfaceFor(context),
          title: Text(
            '选择 AI 模型',
            style: TextStyle(
              fontFamily: 'NotoSerifSC',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: WgTokens.fgFor(context),
            ),
          ),
          children: providers.map((p) {
            return RadioListTile<String>(
              title: Text(_providerLabel(p),
                  style: TextStyle(color: WgTokens.fgFor(context))),
              subtitle: Text(_providerDesc(p),
                  style: TextStyle(color: WgTokens.fg2For(context))),
              value: p,
              groupValue: _settings.selectedProvider,
              activeColor: WgTokens.accent,
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
      case 'sensenova':
        return 'SenseNova (商汤)';
      case 'free':
        return '免费模式 (内置)';
      case 'deepseek':
        return 'DeepSeek';
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Claude';
      default:
        return name;
    }
  }

  String _providerDesc(String name) {
    switch (name) {
      case 'sensenova':
        return '商汤 SenseNova API，需配置 API Key';
      case 'free':
        return '内置免费模型，每天有限额';
      case 'deepseek':
        return 'DeepSeek V3/R1，需配置 API Key';
      case 'openai':
        return 'GPT-4o / GPT-3.5，需配置 API Key';
      case 'claude':
        return 'Claude Sonnet 4，需配置 API Key';
      default:
        return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WgTokens.space4, WgTokens.space6, WgTokens.space4, WgTokens.space2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansSC',
          color: WgTokens.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
