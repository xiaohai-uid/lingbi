/// 首次配置向导（8 步）
///
/// 步骤：
/// 0. 欢迎和数据说明
/// 1. 选择使用模式（AI 辅助 / 本地写作）
/// 2. 选择供应商
/// 3. 填写密钥
/// 4. 选择模型
/// 5. 测试连接
/// 6. 测试生成
/// 7. 完成
///
/// 本地模式跳过步骤 2-6。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/ai/model_registry.dart';
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

  static const _totalSteps = 8;

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

  // ——— Step 2: 选择供应商 ———
  Widget _buildProviderStep() {
    final platforms = ModelRegistry.allPlatforms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('选择 AI 供应商',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...platforms.entries.map((entry) {
          final isSelected = _selectedProvider == entry.key;
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
              title: Text(entry.value.name),
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
              }),
            ),
          );
        }),
      ],
    );
  }

  // ——— Step 3: 填写密钥 ———
  Widget _buildApiKeyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '输入 ${ModelRegistry.allPlatforms[_selectedProvider]?.name ?? ''} API Key',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
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

  bool get _canProceed {
    return switch (_currentStep) {
      0 => true,
      1 => true,
      2 => _selectedProvider.isNotEmpty,
      3 => _apiKeyController.text.trim().isNotEmpty,
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
    // 本地模式跳过 2-6
    if (_localMode && _currentStep == 1) {
      _currentStep = 7;
    } else if (_currentStep < 7) {
      _currentStep++;
    }
    setState(() {});
    _saveStep();
  }

  void _completeAsLocalMode() {
    final settings = ServiceLocator.instance.settingsService;
    settings.completeOnboarding(localOnly: true);
    widget.onComplete();
  }

  void _saveAndComplete() {
    final settings = ServiceLocator.instance.settingsService;
    settings.setApiKey(_selectedProvider, _apiKeyController.text.trim());
    settings.setProvider(_selectedProvider);
    if (_selectedModelId.isNotEmpty) {
      settings.setSelectedModelId(_selectedProvider, _selectedModelId);
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
      settings.setApiKey(_selectedProvider, _apiKeyController.text.trim());
      settings.setProvider(_selectedProvider);
      if (_selectedModelId.isNotEmpty) {
        settings.setSelectedModelId(_selectedProvider, _selectedModelId);
      }

      final result = await ServiceLocator.instance.aiService.testConnection();
      setState(() {
        _connectionTestSuccess = result.success;
        _statusMessage = result.success
            ? '连接成功 (${result.latencyMs}ms)'
            : result.message;
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
      await for (final chunk in aiService.chat(
        message: '请用一句不超过 30 字的中文，描写雨夜中的旧车站。',
        maxTokens: 100,
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
