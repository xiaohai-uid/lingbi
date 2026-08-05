import 'package:flutter/material.dart';

import '../../../../services/license_service.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class SubscriptionSettingsSection extends StatefulWidget {
  const SubscriptionSettingsSection({super.key});

  @override
  State<SubscriptionSettingsSection> createState() =>
      _SubscriptionSettingsSectionState();
}

class _SubscriptionSettingsSectionState
    extends State<SubscriptionSettingsSection> with SettingsAwareState {
  late final TextEditingController _licenseKeyController;
  bool _activatingLicense = false;
  LicenseInfo? _currentLicense;

  @override
  void initState() {
    super.initState();
    _licenseKeyController = TextEditingController();
    _loadSubscriptionState();
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    super.dispose();
  }

  void _loadSubscriptionState() {
    ServiceLocator.instance.licenseService.loadLicense().then((license) {
      if (mounted) setState(() => _currentLicense = license);
    });
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

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final sub = ServiceLocator.instance.subscriptionService;
    final isPro = sub.isPro;

    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: LingBiIcons.subscription,
          title: '当前方案',
          subtitle:
              isPro ? 'Pro — 全部功能已解锁' : 'Free — 本地编辑 + 自带 API Key + 基础 Skill',
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
        SettingsSectionItem(
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
                  decoration:
                      settingsInputDecoration(c, 'LINGBI-PRO-XXXX-XXXX-XXXX'),
                ),
              ),
              const SizedBox(width: LingBiTokens.space2),
              FilledButton(
                onPressed: _activatingLicense ? null : _activateLicense,
                child: _activatingLicense
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('激活'),
              ),
            ],
          ),
        ),
        SettingsSectionItem(
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
}
