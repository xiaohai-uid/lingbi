import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/recovery_center_service.dart';

import '../theme/tokens.dart';

class RecoveryCenterPage extends StatefulWidget {
  const RecoveryCenterPage({super.key, required this.projectId});

  final String projectId;

  @override
  State<RecoveryCenterPage> createState() => _RecoveryCenterPageState();
}

class _RecoveryCenterPageState extends State<RecoveryCenterPage> {
  Future<List<RecoveryItem>>? _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _load();
  }

  Future<List<RecoveryItem>> _load() async {
    final project = await ServiceLocator.instance.projectService
        .getProject(widget.projectId);
    if (project == null) return [];
    return ServiceLocator.instance.recoveryCenterService
        .scan(project.directoryPath);
  }

  Future<void> _restore(RecoveryItem item) async {
    try {
      await ServiceLocator.instance.recoveryCenterService.restore(item);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件已恢复到原位置')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败：$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return FutureBuilder<List<RecoveryItem>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <RecoveryItem>[];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(LingBiTokens.space5),
            child: Text('暂无候选稿、历史版本、快照或回收站文件',
                style: TextStyle(color: colors.fgSecondary)),
          );
        }
        return Column(
          children: items.take(20).map((item) {
            final canRestore = item.type == RecoveryItemType.trash &&
                item.originalPath != null;
            return ListTile(
              dense: true,
              title: Text(item.title, style: TextStyle(color: colors.fg)),
              subtitle: Text(
                '${_label(item.type)} · ${item.updatedAt.toLocal()}',
                style: TextStyle(color: colors.muted),
              ),
              trailing: canRestore
                  ? TextButton(
                      onPressed: () => _restore(item),
                      child: const Text('恢复'),
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  String _label(RecoveryItemType type) => switch (type) {
        RecoveryItemType.candidate => '候选稿',
        RecoveryItemType.version => '历史版本',
        RecoveryItemType.snapshot => '安全快照',
        RecoveryItemType.trash => '回收站',
      };
}
