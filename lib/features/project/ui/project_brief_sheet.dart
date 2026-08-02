import 'package:flutter/material.dart';
import 'package:lingbi/domain/project/project_brief.dart';

import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class ProjectBriefSheet extends StatefulWidget {
  const ProjectBriefSheet({
    super.key,
    required this.template,
    required this.onCancel,
    required this.onSubmit,
  });

  final ProjectTemplate template;
  final VoidCallback onCancel;
  final ValueChanged<ProjectBrief> onSubmit;

  static Future<ProjectBrief?> show(
    BuildContext context, {
    required ProjectTemplate template,
  }) {
    return showGeneralDialog<ProjectBrief>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭项目简报',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 560,
            height: MediaQuery.sizeOf(dialogContext).height,
            child: ProjectBriefSheet(
              template: template,
              onCancel: () => Navigator.pop(dialogContext),
              onSubmit: (brief) => Navigator.pop(dialogContext, brief),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  @override
  State<ProjectBriefSheet> createState() => _ProjectBriefSheetState();
}

class _ProjectBriefSheetState extends State<ProjectBriefSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _premise = TextEditingController();
  final _audience = TextEditingController();
  final _targetLength = TextEditingController();
  late String _genreId;
  String? _platform;

  @override
  void initState() {
    super.initState();
    _genreId = widget.template.genreId;
  }

  @override
  void dispose() {
    _title.dispose();
    _premise.dispose();
    _audience.dispose();
    _targetLength.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final selectedTemplate = ProjectTemplate.byGenreId(_genreId);
    widget.onSubmit(ProjectBrief(
      title: _title.text.trim(),
      genreId: _genreId,
      templateId: selectedTemplate?.templateId ?? widget.template.templateId,
      targetPlatform: _platform,
      targetLength: int.tryParse(_targetLength.text.trim()),
      audience: _emptyToNull(_audience.text),
      premise: _emptyToNull(_premise.text),
    ));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('项目简报',
                              style: TextStyle(
                                color: c.fg,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text('题材已从入口带入，只需补充作品名称即可开始。',
                              style: TextStyle(color: c.fgSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.borderOpaque),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      key: const ValueKey('project-title-field'),
                      controller: _title,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '作品名称 *',
                        hintText: '例如：万界守夜人',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? '请输入作品名称'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('project-genre-field'),
                      initialValue: _genreId.isEmpty ? null : _genreId,
                      decoration: const InputDecoration(labelText: '题材'),
                      items: ProjectTemplate.values
                          .map((template) => DropdownMenuItem(
                                value: template.genreId,
                                child: Text(template.genreLabel),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _genreId = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('project-platform-field'),
                      initialValue: _platform,
                      decoration: const InputDecoration(labelText: '目标平台（可选）'),
                      items: const ['起点', '番茄', '七猫', '其他']
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _platform = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetLength,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '目标字数（可选）',
                        hintText: '例如：1200000',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final parsed = int.tryParse(value.trim());
                        return parsed == null || parsed <= 0 ? '请输入正整数' : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audience,
                      decoration: const InputDecoration(labelText: '目标读者（可选）'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _premise,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '一句话创意（可选）',
                        hintText: '主角、目标、阻碍或最独特的设定',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('将创建',
                        style: TextStyle(
                          color: c.fg,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      '人物骨架 · 世界规则 · 开篇场景计划 · 本地项目文件',
                      style: TextStyle(color: c.fgSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.borderOpaque),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      key: const ValueKey('project-create-submit'),
                      onPressed: _submit,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('创建并开始构思'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
