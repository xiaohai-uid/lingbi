import 'package:flutter/material.dart';

import '../../../../features/sync/data/sync/sync_manager.dart';
import '../../../../features/sync/data/sync/webdav_service.dart';
import '../../../../ui_v2/theme/lingbi_icons.dart';
import '../../../../ui_v2/theme/tokens.dart';
import '../../data/subscription_service.dart';
import '../pro_gate.dart';
import 'settings_section_scaffold.dart';

class CloudSyncSettingsSection extends StatefulWidget {
  const CloudSyncSettingsSection({super.key});

  @override
  State<CloudSyncSettingsSection> createState() =>
      _CloudSyncSettingsSectionState();
}

class _CloudSyncSettingsSectionState extends State<CloudSyncSettingsSection>
    with SettingsAwareState {
  late final TextEditingController _webdavUrlController;
  late final TextEditingController _webdavUserController;
  late final TextEditingController _webdavPassController;
  bool _webdavEnabled = false;
  bool _testingConnection = false;
  String _syncStatusText = '';
  bool _syncing = false;
  String _lastSyncText = '尚未同步';

  @override
  void initState() {
    super.initState();
    _webdavUrlController = TextEditingController();
    _webdavUserController = TextEditingController();
    _webdavPassController = TextEditingController();
  }

  @override
  void dispose() {
    _webdavUrlController.dispose();
    _webdavUserController.dispose();
    _webdavPassController.dispose();
    super.dispose();
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

  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    try {
      final config = WebDavConfig(
        serverUrl: _webdavUrlController.text.trim(),
        username: _webdavUserController.text.trim(),
        password: _webdavPassController.text,
      );
      final manager = SyncManager(config: config);
      final synced = await manager.syncAll({});
      manager.dispose();
      if (mounted) {
        setState(() {
          _lastSyncText =
              '上次同步: ${DateTime.now().toString().substring(0, 19)} ($synced 个文件)';
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

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return ProGate(
      feature: ProFeature.cloudSync,
      child: SettingsSectionScaffold(
        c: c,
        items: [
          SettingsSectionItem(
            icon: LingBiIcons.cloudSync,
            title: 'WebDAV 云同步',
            subtitle: '支持坚果云/Nextcloud/ownCloud',
            trailing: Switch(
              value: _webdavEnabled,
              onChanged: (v) => setState(() => _webdavEnabled = v),
            ),
          ),
          SettingsSectionItem(
            icon: LingBiIcons.globe,
            title: '服务器地址',
            subtitle: 'WebDAV 服务 URL',
            trailing: SizedBox(
              width: 260,
              child: TextField(
                controller: _webdavUrlController,
                enabled: _webdavEnabled,
                decoration: settingsInputDecoration(
                    c, 'https://dav.jianguoyun.com/dav/'),
              ),
            ),
          ),
          SettingsSectionItem(
            icon: LingBiIcons.character,
            title: '用户名',
            subtitle: 'WebDAV 登录账号',
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _webdavUserController,
                enabled: _webdavEnabled,
                decoration: settingsInputDecoration(c, '用户名'),
              ),
            ),
          ),
          SettingsSectionItem(
            icon: LingBiIcons.apiKey,
            title: '密码',
            subtitle: 'WebDAV 登录密码（安全存储）',
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _webdavPassController,
                enabled: _webdavEnabled,
                obscureText: true,
                decoration: settingsInputDecoration(c, '密码'),
              ),
            ),
          ),
          SettingsSectionItem(
            icon: LingBiIcons.cloud,
            title: '连接测试',
            subtitle:
                _syncStatusText.isEmpty ? '测试 WebDAV 连接可用性' : _syncStatusText,
            trailing: FilledButton.tonal(
              onPressed: _webdavEnabled && !_testingConnection
                  ? _testWebDavConnection
                  : null,
              child: _testingConnection
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('测试连接'),
            ),
          ),
          SettingsSectionItem(
            icon: LingBiIcons.refresh,
            title: '立即同步',
            subtitle: _lastSyncText,
            trailing: FilledButton(
              onPressed: _webdavEnabled && !_syncing ? _triggerSync : null,
              child: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('同步'),
            ),
          ),
        ],
      ),
    );
  }
}
