import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/di/service_locator.dart';
import '../../../../shared/utils/paths.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class StorageSettingsSection extends StatefulWidget {
  const StorageSettingsSection({super.key});

  @override
  State<StorageSettingsSection> createState() => _StorageSettingsSectionState();
}

class _StorageSettingsSectionState extends State<StorageSettingsSection>
    with SettingsAwareState {
  void _offerMigration({required String oldRoot, required String newRoot}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('迁移已有项目'),
        content: const Text(
          '是否将已有项目从旧位置移动到新目录？\n\n'
          '• 移动失败的项目会保留在原位置\n'
          '• 已打开的项目建议先关闭',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('不迁移'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _migrateProjects(oldRoot: oldRoot, newRoot: newRoot);
            },
            child: const Text('开始迁移'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateProjects({
    required String oldRoot,
    required String newRoot,
  }) async {
    final projectService = ServiceLocator.instance.projectServiceApi;
    final result = await projectService.migratePortableProjects(
      oldRoot: oldRoot,
      newRoot: newRoot,
    );

    if (!mounted) return;
    result.when(
      success: (summary) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              summary.failed == 0
                  ? '迁移完成：${summary.migrated} 个项目已移动到新目录'
                  : '迁移部分完成：${summary.migrated} 个成功，'
                      '${summary.failed} 个失败（保留在原位置）',
            ),
          ),
        );
      },
      failure: (error) => _showStorageError(error.message),
    );
  }

  void _showStorageError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final settings = ServiceLocator.instance.settingsService;
    final currentPath = settings.customStoragePath;
    return SettingsSectionScaffold(
      c: c,
      items: [
        SettingsSectionItem(
          icon: Icons.folder_outlined,
          title: '自定义存储位置',
          subtitle: currentPath ?? '使用默认路径（文档目录）',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: '选择小说存储目录',
                  );
                  if (result != null) {
                    final oldRoot = settings.customStoragePath ??
                        resolveDefaultProjectRoot();
                    final saveResult =
                        await settings.setCustomStoragePath(result);
                    if (!mounted) return;
                    saveResult.when(
                      success: (_) {
                        setState(() {});
                        if (oldRoot != result) {
                          _offerMigration(oldRoot: oldRoot, newRoot: result);
                        }
                      },
                      failure: (error) => _showStorageError(error.message),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('选择目录'),
              ),
              if (currentPath != null)
                TextButton(
                  onPressed: () async {
                    final oldRoot = currentPath;
                    final saveResult =
                        await settings.setCustomStoragePath(null);
                    if (!mounted) return;
                    saveResult.when(
                      success: (_) {
                        setState(() {});
                        _offerMigration(
                          oldRoot: oldRoot,
                          newRoot: resolveDefaultProjectRoot(),
                        );
                      },
                      failure: (error) => _showStorageError(error.message),
                    );
                  },
                  child: Text(
                    '重置默认',
                    style: TextStyle(color: c.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
