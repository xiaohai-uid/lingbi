/// 风格档案查看/编辑/选择界面
///
/// 支持：查看风格档案列表、选择绑定到项目、
/// 编辑微调 AI 提取结果、导入作品提取新风格。
library;

import 'package:flutter/material.dart';

import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/style_profile.dart';

/// 风格档案面板
class StyleProfilePanel extends StatefulWidget {
  const StyleProfilePanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<StyleProfilePanel> createState() => _StyleProfilePanelState();
}

class _StyleProfilePanelState extends State<StyleProfilePanel> {
  List<StyleProfile> _profiles = [];
  String? _boundProfileId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final svc = ServiceLocator.instance.styleDistillationService;
    final profiles = await svc.listProfiles(widget.projectId);
    final bound = await svc.getBoundProfile(widget.projectId);
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _boundProfileId = bound?.id;
        _loading = false;
      });
    }
  }

  Future<void> _bindProfile(String profileId) async {
    await ServiceLocator.instance.styleDistillationService.bindProfile(
      widget.projectId,
      profileId,
    );
    if (mounted) setState(() => _boundProfileId = profileId);
  }

  Future<void> _unbindProfile() async {
    await ServiceLocator.instance.styleDistillationService.unbindProfile(
      widget.projectId,
    );
    if (mounted) setState(() => _boundProfileId = null);
  }

  Future<void> _deleteProfile(String profileId) async {
    await ServiceLocator.instance.styleDistillationService.deleteProfile(
      widget.projectId,
      profileId,
    );
    if (_boundProfileId == profileId) {
      _boundProfileId = null;
    }
    await _loadData();
  }

  Future<void> _importAndExtract() async {
    final textController = TextEditingController();
    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入作品提取风格'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '风格名称'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '粘贴作品文本（至少5000字）',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('提取风格'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        nameController.text.isNotEmpty &&
        textController.text.isNotEmpty) {
      try {
        final profile =
            await ServiceLocator.instance.styleDistillationService.extractStyle(
          sourceText: textController.text,
          name: nameController.text.trim(),
        );
        await ServiceLocator.instance.styleDistillationService.saveProfile(
          widget.projectId,
          profile,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('风格提取完成')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('提取失败: $e')),
          );
        }
      }
    }
  }

  void _showProfileDetail(StyleProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => _ProfileDetailDialog(
        profile: profile,
        projectId: widget.projectId,
        onUpdated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('风格档案',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_boundProfileId != null)
                TextButton.icon(
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('解绑'),
                  onPressed: _unbindProfile,
                ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('导入提取'),
                onPressed: _importAndExtract,
              ),
            ],
          ),
        ),

        // 档案列表
        Expanded(
          child: _profiles.isEmpty
              ? const Center(
                  child: Text('暂无风格档案\n点击「导入提取」从作品中提取文笔DNA',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (ctx, i) {
                    final profile = _profiles[i];
                    final isBound = profile.id == _boundProfileId;
                    return ListTile(
                      leading: Icon(
                        isBound ? Icons.check_circle : Icons.palette_outlined,
                        color: isBound ? Colors.green : null,
                      ),
                      title: Text(profile.name),
                      subtitle: Text(
                        profile.description.isNotEmpty
                            ? profile.description
                            : '句式${profile.sentencePatterns.length}项 · '
                                '修辞${profile.rhetoricPreferences.length}项',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isBound)
                            TextButton(
                              child: const Text('绑定'),
                              onPressed: () => _bindProfile(profile.id),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showProfileDetail(profile),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteProfile(profile.id),
                          ),
                        ],
                      ),
                      onTap: () => _showProfileDetail(profile),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// 风格档案详情/编辑对话框
class _ProfileDetailDialog extends StatefulWidget {
  const _ProfileDetailDialog({
    required this.profile,
    required this.projectId,
    required this.onUpdated,
  });

  final StyleProfile profile;
  final String projectId;
  final VoidCallback onUpdated;

  @override
  State<_ProfileDetailDialog> createState() => _ProfileDetailDialogState();
}

class _ProfileDetailDialogState extends State<_ProfileDetailDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _patternsCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _descCtrl = TextEditingController(text: widget.profile.description);
    _patternsCtrl = TextEditingController(
        text: widget.profile.sentencePatterns.join('\n'));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _patternsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.profile.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      sentencePatterns: _patternsCtrl.text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList(),
    );
    await ServiceLocator.instance.styleDistillationService.updateProfile(
      widget.projectId,
      updated,
    );
    widget.onUpdated();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return AlertDialog(
      title: const Text('风格档案详情'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '风格描述'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _patternsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '句式特征（每行一条）',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              // 只读展示
              if (p.vocabulary.isNotEmpty) ...[
                const Text('用词特征:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                for (final v in p.vocabulary)
                  Text('  · ${v.trait} (${v.frequency})'),
                const SizedBox(height: 8),
              ],
              if (p.rhetoricPreferences.isNotEmpty) ...[
                const Text('修辞偏好:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                for (final r in p.rhetoricPreferences)
                  Text('  · ${r.name} (${r.frequency})'),
                const SizedBox(height: 8),
              ],
              Text('节奏: 平均句长${p.rhythm.avgSentenceLength}字 · '
                  '${p.rhythm.pacing} · ${p.rhythm.tensionCurve}'),
              const SizedBox(height: 8),
              Text('源文本: ${p.sourceWordCount} 字',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存修改'),
        ),
      ],
    );
  }
}
