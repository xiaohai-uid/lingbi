import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
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
  Future<List<RecoveryIncident>>? _incidents;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _load();
    _incidents = _loadIncidents();
  }

  Future<List<RecoveryItem>> _load() async {
    final project = await ServiceLocator.instance.projectService
        .getProject(widget.projectId);
    if (project == null) return [];
    return ServiceLocator.instance.recoveryCenterService
        .scan(project.directoryPath, projectId: widget.projectId);
  }

  Future<List<RecoveryIncident>> _loadIncidents() async {
    final project = await ServiceLocator.instance.projectService
        .getProject(widget.projectId);
    if (project == null) return [];
    final result =
        await ServiceLocator.instance.recoveryCenterService.scanIncidents();
    return result.getOrNull() ?? const [];
  }

  Future<void> _decideIncident(
    RecoveryIncident incident,
    bool approveCurrentBytes,
  ) async {
    final result = await ServiceLocator.instance.recoveryCenterService
        .decideIncident(
            incident: incident, approveCurrentBytes: approveCurrentBytes);
    if (!mounted) return;
    final message = result.errorOrNull() != null
        ? '决定失败：${result.errorOrNull()}'
        : approveCurrentBytes
            ? '已批准当前字节作为最终内容'
            : '已放弃该写入；当前字节已存入回收站';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (result.errorOrNull() == null) setState(_reload);
  }

  Future<void> _restore(RecoveryItem item) async {
    try {
      final result =
          await ServiceLocator.instance.recoveryCenterService.restore(item);
      if (!mounted) return;
      if (result.errorOrNull() == null) {
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件已恢复到原位置')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：${result.errorOrNull()}')),
        );
      }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FutureBuilder<List<RecoveryItem>>(
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
              return ListView(
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
          ),
        ),
        FutureBuilder<List<RecoveryIncident>>(
          future: _incidents,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final incidents = snapshot.data ?? const <RecoveryIncident>[];
            if (incidents.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(LingBiTokens.space5),
                  child: Text('待决定的恢复事故',
                      style: TextStyle(
                        color: colors.fg,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                ...incidents.take(5).map((incident) => ListTile(
                      dense: true,
                      title: Text(
                        '${incident.targetPath}（写入中断）',
                        style: TextStyle(color: colors.fg),
                      ),
                      subtitle: Text(
                        '当前字节已保留，等待决定',
                        style: TextStyle(color: colors.muted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _decideIncident(incident, true),
                            child: const Text('批准当前字节'),
                          ),
                          TextButton(
                            onPressed: () => _decideIncident(incident, false),
                            child: const Text('放弃并存入回收站'),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 1),
              ],
            );
          },
        ),
      ],
    );
  }

  String _label(RecoveryItemType type) => switch (type) {
        RecoveryItemType.candidate => '候选稿',
        RecoveryItemType.version => '历史版本',
        RecoveryItemType.snapshot => '安全快照',
        RecoveryItemType.trash => '回收站',
      };
}
