/// 首次配置向导
///
/// 引导用户完成：选择供应商 → 输入 API Key → 选择模型 → 测试连接
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
  String _selectedProvider = '';
  final _apiKeyController = TextEditingController();
  String _selectedModelId = '';
  String _statusMessage = '';
  bool _isTesting = false;
  bool _testSuccess = false;

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
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '欢迎使用灵笔',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '配置 AI 模型，开始您的创作之旅',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStepIndicator(),
              const SizedBox(height: 24),
              _buildStepContent(),
              const SizedBox(height: 24),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _testSuccess ? Colors.green : Colors.orange,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i <= _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
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
    return switch (_currentStep) {
      0 => _buildProviderStep(),
      1 => _buildApiKeyStep(),
      _ => _buildModelStep(),
    };
  }

  Widget _buildProviderStep() {
    final platforms = ModelRegistry.allPlatforms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('选择 AI 供应商', style: TextStyle(fontSize: 18)),
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
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildApiKeyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '输入 ${ModelRegistry.allPlatforms[_selectedProvider]?.name ?? ''} API Key',
          style: const TextStyle(fontSize: 18),
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

  Widget _buildModelStep() {
    final models =
        ModelRegistry.instance.getModelsForProvider(_selectedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('选择模型', style: TextStyle(fontSize: 18)),
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
              subtitle: Text(
                '上下文: ${model.contextWindowLabel} | '
                '输出: ${model.maxOutputLabel} | '
                '${model.metadataSourceLabel}',
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => setState(() => _selectedModelId = model.id),
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(_isTesting ? '测试中...' : '测试连接'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('上一步'),
          )
        else
          TextButton(
            onPressed: widget.onComplete,
            child: const Text('跳过配置'),
          ),
        FilledButton(
          onPressed: _canProceed ? _next : null,
          child: Text(_currentStep == 2 ? '完成配置' : '下一步'),
        ),
      ],
    );
  }

  bool get _canProceed {
    return switch (_currentStep) {
      0 => _selectedProvider.isNotEmpty,
      1 => _apiKeyController.text.trim().isNotEmpty,
      _ => _selectedModelId.isNotEmpty,
    };
  }

  void _next() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveAndComplete();
    }
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

      final result = await ServiceLocator.instance.aiService.testConnection();
      setState(() {
        _testSuccess = result.success;
        _statusMessage = result.success
            ? '连接成功 (${result.latencyMs}ms)'
            : result.message;
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _statusMessage = '测试失败: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _saveAndComplete() {
    final settings = ServiceLocator.instance.settingsService;
    settings.setApiKey(_selectedProvider, _apiKeyController.text.trim());
    settings.setProvider(_selectedProvider);
    if (_selectedModelId.isNotEmpty) {
      settings.setSelectedModelId(_selectedProvider, _selectedModelId);
    }
    widget.onComplete();
  }
}
