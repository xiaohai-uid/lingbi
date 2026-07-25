/// 首次配置向导（8 步）
///
/// 步骤：
/// 0. 欢迎和数据说明
/// 1. 选择使用模式（AI 辅助 / 本地写作）
/// 2. 选择供应商（统一列表：预置+自定义平级 + 添加自定义入口）
/// 3. 填写密钥（环境变量已配置或自定义已填则跳过）
/// 4. 选择模型（自定义供应商自动拉取 /v1/models）
/// 5. 测试连接（延迟+错误分类）
/// 6. 测试生成
/// 7. 完成
///
/// 本地模式跳过步骤 2-6。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingbi/core/ai/model_registry.dart';
import 'package:lingbi/core/ai/models/endpoint_config.dart';
import 'package:lingbi/core/ai/provider_factory.dart';
import 'package:lingbi/core/di/service_locator.dart';

/// 首次配置向导页面
class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int _currentStep = 0;
  bool _localMode = false;
  String _selectedProvider = '';
  final _apiKeyController = TextEditingController();
  String _selectedModelId = '';
  String _statusMessage = '';
  bool _isTesting = false;
  bool _connectionTestSuccess = false;
  bool _testGenerationSuccess = false;

  // 测试生成状态
  String _generationOutput = '';
  bool _isGenerating = false;

  // 模型发现状态
  bool _isDiscovering = false;

  // 自定义供应商表单
  bool _showCustomForm = false;
  final _customNameCtrl = TextEditingController();
  final _customUrlCtrl = TextEditingController();
  final _customKeyCtrl = TextEditingController();
  Protocol _customProtocol = Protocol.openai;
  bool _isAddingCustom = false;
  List<String> _discoveredModelIds = [];

  static const _totalSteps = 8;

  /// 环境变量已配置的 provider ids
  static const _envMappings = {
    'sensenova': 'SENSENOVA_API_KEY',
    'deepseek': 'DEEPSEEK_API_KEY',
    'openai': 'OPENAI_API_KEY',
    'claude': 'ANTHROPIC_API_KEY',
  };

  bool _hasEnvKey(String providerId) {
    final envVar = _envMappings[providerId];
    if (envVar == null) return false;
    final val = Platform.environment[envVar];
    return val != null && val.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // 从上次中断步骤恢复
    final settings = ServiceLocator.instance.settingsService;
    final lastStep = settings.onboardingState.lastStep;
    if (lastStep > 0 && lastStep < _totalSteps - 1) {
      _currentStep = lastStep;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customNameCtrl.dispose();
    _customUrlCtrl.dispose();
    _customKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              Expanded(child: _buildStepContent()),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _connectionTestSuccess || _testGenerationSuccess
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final effectiveSteps = _localMode ? 3 : _totalSteps;
    final effectiveCurrent = _localMode
        ? (_currentStep > 1 ? 2 : _currentStep)
        : _currentStep;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(effectiveSteps, (i) {
        final isActive = i <= effectiveCurrent;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    return SingleChildScrollView(
      child: switch (_currentStep) {
        0 => _buildWelcomeStep(),
        1 => _buildModeStep(),
        2 => _buildProviderStep(),
        3 => _buildApiKeyStep(),
        4 => _buildModelStep(),
        5 => _buildConnectionTestStep(),
        6 => _buildTestGenerationStep(),
        _ => _buildCompleteStep(),
      },
    );
  }

  // ——— Step 0: 欢迎和数据说明 ———
  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '欢迎使用灵笔',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '灵笔是一款 AI 辅助小说创作工具。',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildDataNotice(),
      ],
    );
  }

  Widget _buildDataNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('数据说明',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _dataItem('您的作品数据保存在本地，不会上传到任何服务器'),
          _dataItem('AI 功能需要配置第三方 API Key，调用时数据发送至对应供应商'),
          _dataItem('API Key 安全存储在本地，不会写入配置文件或日志'),
          _dataItem('您可以随时选择纯本地写作模式，不使用任何 AI 功能'),
        ],
      ),
    );
  }

  Widget _dataItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ——— Step 1: 选择使用模式 ———
  Widget _buildModeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('选择使用模式',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          '您可以随时在设置中更改',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _buildModeCard(
          icon: Icons.auto_awesome,
          title: 'AI 辅助写作',
          desc: '配置 AI 模型，获得续写、改写、风格分析等智能辅助',
          selected: !_localMode,
          onTap: () => setState(() => _localMode = false),
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          icon: Icons.edit_note,
          title: '本地写作',
          desc: '不使用 AI 功能，纯粹本地 Markdown 写作',
          selected: _localMode,
          onTap: () => setState(() => _localMode = true),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String desc,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 13)),
        trailing: selected
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  // ——— Step 2: 选择供应商（统一列表：预置+自定义平级） ———
  Widget _buildProviderStep() {
    final platforms = ModelRegistry.allPlatforms;
    final settings = ServiceLocator.instance.settingsService;
    final customEndpoints = settings.customEndpoints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('选择 AI 供应商',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '预置供应商和自定义供应商享有相同地位',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // 预置供应商
        ...platforms.entries.map((entry) {
          final isSelected = _selectedProvider == entry.key;
          final hasEnv = _hasEnvKey(entry.key);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: ListTile(
              title: Row(
                children: [
                  Text(entry.value.name),
                  if (hasEnv) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text('环境变量已配置',
                          style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                    ),
                  ],
                ],
              ),
              subtitle: Text('${entry.value.models.length} 个内置模型'),
              trailing: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => setState(() {
                _selectedProvider = entry.key;
                _selectedModelId = '';
                _connectionTestSuccess = false;
                _testGenerationSuccess = false;
                _showCustomForm = false;
              }),
            ),
          );
        }),
        // 已有自定义端点
        ...customEndpoints.map((ep) {
          final isSelected = _selectedProvider == ep.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.dns_outlined, size: 20),
              title: Text(ep.name),
              subtitle: Text('${ep.baseUrl} · ${ep.protocol.name}'),
              trailing: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => setState(() {
                _selectedProvider = ep.id;
                _selectedModelId = ep.modelId;
                _connectionTestSuccess = false;
                _testGenerationSuccess = false;
                _showCustomForm = false;
              }),
            ),
          );
        }),
        // 添加自定义供应商（平级入口）
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: _showCustomForm ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _showCustomForm
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary),
                title: Text('添加自定义供应商',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                subtitle: const Text('任何 OpenAI 兼容或 Anthropic 格式的 API 端点'),
                onTap: () => setState(() => _showCustomForm = !_showCustomForm),
              ),
              if (_showCustomForm) _buildCustomProviderForm(),
            ],
          ),
        ),
      ],
    );
  }

  /// 自定义供应商表单
  Widget _buildCustomProviderForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _customNameCtrl,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '例如：我的中转站',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'API 地址 (Base URL)',
              hintText: 'https://api.example.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          // 协议选择 + 格式指引
          Row(
            children: [
              const Text('协议：', style: TextStyle(fontSize: 13)),
              ChoiceChip(
                label: const Text('OpenAI 兼容'),
                selected: _customProtocol == Protocol.openai,
                onSelected: (_) => setState(() => _customProtocol = Protocol.openai),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Anthropic'),
                selected: _customProtocol == Protocol.anthropic,
                onSelected: (_) => setState(() => _customProtocol = Protocol.anthropic),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _customProtocol == Protocol.openai
                  ? 'OpenAI 兼容格式：\n'
                    '• 请求地址：{baseUrl}/v1/chat/completions\n'
                    '• 模型列表：{baseUrl}/v1/models\n'
                    '• 适用于：DeepSeek、通义千问、Moonshot、任何中转站'
                  : 'Anthropic 格式：\n'
                    '• 请求地址：{baseUrl}/v1/messages\n'
                    '• 认证方式：x-api-key 请求头\n'
                    '• 适用于：Claude 系列模型',
              style: const TextStyle(fontSize: 11, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customKeyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isAddingCustom ? null : _addCustomProvider,
            icon: _isAddingCustom
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add, size: 16),
            label: Text(_isAddingCustom ? '添加中...' : '添加并拉取模型'),
          ),
          if (_discoveredModelIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('已发现 ${_discoveredModelIds.length} 个模型，请在下一步选择。',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
          ],
        ],
      ),
    );
  }

  /// 添加自定义供应商并自动拉取模型列表
  Future<void> _addCustomProvider() async {
    final name = _customNameCtrl.text.trim();
    final url = _customUrlCtrl.text.trim();
    final key = _customKeyCtrl.text.trim();
    if (name.isEmpty || url.isEmpty || key.isEmpty) {
      setState(() => _statusMessage = '请填写名称、API 地址和 API Key');
      return;
    }
    setState(() {
      _isAddingCustom = true;
      _statusMessage = '';
      _discoveredModelIds = [];
    });

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final config = EndpointConfig(
      id: id,
      name: name,
      baseUrl: url,
      apiKey: key,
      protocol: _customProtocol,
      modelId: '',
    );

    try {
      // 注册到 SettingsService + AIService
      final settings = ServiceLocator.instance.settingsService;
      settings.addCustomEndpoint(config);

      // 自动拉取模型列表
      if (_customProtocol == Protocol.openai) {
        final models = await ProviderFactory.discoverModels(config);
        if (models.isNotEmpty) {
          ModelRegistry.instance.replaceRemoteModels(id, models);
          setState(() => _discoveredModelIds = models);
        }
      }

      setState(() {
        _selectedProvider = id;
        _selectedModelId = '';
        _connectionTestSuccess = false;
        _testGenerationSuccess = false;
        _showCustomForm = false;
        _statusMessage = '已添加「$name」${_discoveredModelIds.isNotEmpty ? '，发现 ${_discoveredModelIds.length} 个模型' : ''}';
      });
    } catch (e) {
      setState(() => _statusMessage = '添加失败: $e');
    } finally {
      setState(() => _isAddingCustom = false);
    }
  }

  // ——— Step 3: 填写密钥 ———
  // 如果环境变量已配置或自定义供应商已填写 key，此步显示确认信息
  Widget _buildApiKeyStep() {
    final hasEnv = _hasEnvKey(_selectedProvider);
    final isCustom = _selectedProvider.startsWith('custom_');
    final skipKey = hasEnv || isCustom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          skipKey
              ? 'API Key 已就绪'
              : '输入 ${ModelRegistry.allPlatforms[_selectedProvider]?.name ?? ''} API Key',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (hasEnv) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '已通过环境变量 ${_envMappings[_selectedProvider]} 配置 API Key，无需重复输入。',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isCustom) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '自定义供应商的 API Key 已在上一步配置完成。',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您的 API Key 将安全存储在本地，不会上传到任何服务器。',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  // ——— Step 4: 选择模型 ———
  Widget _buildModelStep() {
    final models =
        ModelRegistry.instance.getModelsForProvider(_selectedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('选择模型',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: _isDiscovering ? null : _discoverModels,
              icon: _isDiscovering
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(_isDiscovering ? '发现中...' : '发现更多模型'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...models.map((model) {
          final isSelected = _selectedModelId == model.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: ListTile(
              title: Text(model.displayName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${model.id} · ${model.metadataSourceLabel}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '上下文: ${model.contextWindowLabel} | '
                    '输出: ${model.maxOutputLabel} | '
                    '流式: ${model.capabilities.supportsStreaming ? "支持" : "未验证"} | '
                    '${model.pricing.isKnown ? "输入 ¥${model.pricing.inputPerMillion}/M · 输出 ¥${model.pricing.outputPerMillion}/M" : "费用未知"}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => setState(() => _selectedModelId = model.id),
            ),
          );
        }),
      ],
    );
  }

  // ——— Step 5: 测试连接 ———
  Widget _buildConnectionTestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('测试连接',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text(
          '将向 ${ModelRegistry.allPlatforms[_selectedProvider]?.name ?? _selectedProvider} '
          '发送一条最小请求验证配置是否正确。',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '此操作可能消耗极少量 Token 费用。',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (_connectionTestSuccess)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusMessage,
                    style: TextStyle(color: Colors.green.shade800, fontSize: 13))),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering, size: 18),
            label: Text(_isTesting ? '测试中...' : '开始测试连接'),
          ),
      ],
    );
  }

  // ——— Step 6: 测试生成 ———
  Widget _buildTestGenerationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('测试生成',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Text(
          '将使用固定提示词生成一段文字，验证模型可正常工作。',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '提示词：「请用一句不超过 30 字的中文，描写雨夜中的旧车站。」',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '此操作可能产生少量 Token 费用。测试结果不会写入任何项目。',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (_generationOutput.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('生成结果：', style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 4),
                Text(_generationOutput, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (!_testGenerationSuccess)
          OutlinedButton.icon(
            onPressed: _isGenerating ? null : _testGeneration,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(_isGenerating ? '生成中...' : '开始测试生成'),
          ),
      ],
    );
  }

  // ——— Step 7: 完成 ———
  Widget _buildCompleteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.celebration_outlined,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        const Text(
          '配置完成！',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _localMode
              ? '您已选择本地写作模式，可以开始创作了。'
              : 'AI 模型已就绪，开始您的创作之旅吧！',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (!_localMode) ...[
          const SizedBox(height: 12),
          Text(
            '供应商: ${ModelRegistry.allPlatforms[_selectedProvider]?.name ?? _selectedProvider}\n'
            '模型: $_selectedModelId',
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ——— 导航按钮 ———
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧按钮
        Row(
          children: [
            if (_currentStep > 0 && _currentStep < 7)
              TextButton(
                onPressed: _goBack,
                child: const Text('上一步'),
              ),
            if (_currentStep == 0)
              TextButton(
                onPressed: _exitApp,
                child: const Text('退出应用'),
              ),
          ],
        ),
        // 右侧按钮
        Row(
          children: [
            // "先使用本地写作" — 仅在步骤 0-1 显示
            if (_currentStep <= 1)
              TextButton(
                onPressed: _completeAsLocalMode,
                child: const Text('先使用本地写作'),
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canProceed ? _next : null,
              child: Text(_nextButtonLabel),
            ),
          ],
        ),
      ],
    );
  }

  String get _nextButtonLabel {
    if (_currentStep == 7) return '进入灵笔';
    if (_currentStep == 1 && _localMode) return '完成';
    return '下一步';
  }

  /// 当前选中的供应商是否已有 API Key（环境变量或自定义已填）
  bool get _keyAlreadyProvided {
    if (_hasEnvKey(_selectedProvider)) return true;
    if (_selectedProvider.startsWith('custom_')) return true;
    return false;
  }

  bool get _canProceed {
    return switch (_currentStep) {
      0 => true,
      1 => true,
      2 => _selectedProvider.isNotEmpty,
      3 => _keyAlreadyProvided || _apiKeyController.text.trim().isNotEmpty,
      4 => _selectedModelId.isNotEmpty,
      5 => _connectionTestSuccess,
      6 => _testGenerationSuccess,
      _ => true,
    };
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _saveStep();
    }
  }

  void _next() {
    // 本地模式在步骤 1 直接完成
    if (_currentStep == 1 && _localMode) {
      _completeAsLocalMode();
      return;
    }
    if (_currentStep == 7) {
      _saveAndComplete();
      return;
    }
    // 步骤 3 → 4：如果 key 已提供，自动应用并跳到模型选择
    if (_currentStep == 3 && _keyAlreadyProvided) {
      // 环境变量 key 已在 _load 时应用到 AIService
      // 自定义 key 已在 addCustomEndpoint 时应用
      _currentStep = 4;
      _autoDiscoverForCustom();
    } else if (_currentStep < 7) {
      _currentStep++;
      // 进入模型步骤时，如果是自定义供应商，自动拉取
      if (_currentStep == 4) _autoDiscoverForCustom();
    }
    setState(() {});
    _saveStep();
  }

  /// 自定义供应商进入模型步骤时自动拉取模型列表
  void _autoDiscoverForCustom() {
    if (_selectedProvider.startsWith('custom_')) {
      _discoverModels();
    }
  }

  void _completeAsLocalMode() {
    final settings = ServiceLocator.instance.settingsService;
    settings.completeOnboarding(localOnly: true);
    widget.onComplete();
  }

  void _saveAndComplete() {
    final settings = ServiceLocator.instance.settingsService;
    // 仅在用户手动输入 key 时设置（环境变量/自定义已处理）
    if (!_keyAlreadyProvided && _apiKeyController.text.trim().isNotEmpty) {
      settings.setApiKey(_selectedProvider, _apiKeyController.text.trim());
    }
    settings.setProvider(_selectedProvider);
    if (_selectedModelId.isNotEmpty) {
      settings.setSelectedModelId(_selectedProvider, _selectedModelId);
      // 更新自定义端点的 modelId
      if (_selectedProvider.startsWith('custom_')) {
        final ep = settings.customEndpoints
            .where((e) => e.id == _selectedProvider)
            .firstOrNull;
        if (ep != null) {
          settings.updateCustomEndpoint(ep.copyWith(modelId: _selectedModelId));
        }
      }
    }
    settings.completeOnboarding(
      providerId: _selectedProvider,
      modelId: _selectedModelId,
    );
    widget.onComplete();
  }

  void _saveStep() {
    ServiceLocator.instance.settingsService.updateOnboardingStep(_currentStep);
  }

  void _exitApp() {
    _saveStep();
    // 桌面应用退出
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('退出灵笔'),
          content: const Text('配置尚未完成，下次启动时将继续。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('返回'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx), // 桌面端暂不实现退出
              child: const Text('退出'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = '';
    });

    try {
      final settings = ServiceLocator.instance.settingsService;
      // 仅在手动输入时设置 key
      if (!_keyAlreadyProvided && _apiKeyController.text.trim().isNotEmpty) {
        settings.setApiKey(_selectedProvider, _apiKeyController.text.trim());
      }
      settings.setProvider(_selectedProvider);
      if (_selectedModelId.isNotEmpty) {
        settings.setSelectedModelId(_selectedProvider, _selectedModelId);
      }

      // 使用统一连接测试（含延迟+错误分类）
      final result = await ServiceLocator.instance.aiService.testConnectionUnified(
        providerId: _selectedProvider,
        modelId: _selectedModelId.isNotEmpty ? _selectedModelId : null,
      );
      setState(() {
        _connectionTestSuccess = result.success;
        _statusMessage = result.success
            ? '连接成功 (${result.latencyMs}ms)'
            : '${result.errorCategory ?? "连接失败"} (${result.latencyMs}ms)';
      });
    } catch (e) {
      setState(() {
        _connectionTestSuccess = false;
        _statusMessage = '测试失败: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testGeneration() async {
    setState(() {
      _isGenerating = true;
      _generationOutput = '';
      _statusMessage = '';
    });

    try {
      final aiService = ServiceLocator.instance.aiService;
      final buffer = StringBuffer();
      await for (final chunk in aiService.testGeneration(
        providerId: _selectedProvider,
      )) {
        buffer.write(chunk);
        if (mounted) {
          setState(() => _generationOutput = buffer.toString());
        }
      }
      setState(() {
        _testGenerationSuccess = buffer.isNotEmpty;
        _generationOutput = buffer.toString();
        _statusMessage =
            _testGenerationSuccess ? '测试生成成功' : '生成结果为空，请重试';
      });
    } catch (e) {
      setState(() {
        _testGenerationSuccess = false;
        _statusMessage = '测试生成失败: $e';
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _discoverModels() async {
    setState(() => _isDiscovering = true);
    try {
      final aiService = ServiceLocator.instance.aiService;
      await aiService.discoverModels(_selectedProvider);
      if (mounted) setState(() {});
    } catch (_) {
      // 发现失败不阻止手工选择
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }
}
