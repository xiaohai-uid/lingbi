import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingbi/features/import_export/data/import_service.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';
import 'package:lingbi/ui_v2/theme/lingbi_icons.dart';
import 'package:lingbi/ui_v2/pages/recovery_center_page.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key, this.projectId});
  final String? projectId;

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool _busy = false;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  /// 获取当前项目的第一篇文档内容（用于单文件导出）
  Future<({String content, String title})?> _getFirstDocContent() async {
    final pid = widget.projectId;
    if (pid == null) {
      _showSnack('请先打开一个项目');
      return null;
    }
    final docs =
        await ServiceLocator.instance.documentService.getDocuments(pid);
    if (docs.isEmpty) {
      _showSnack('当前项目没有文档');
      return null;
    }
    final content = await ServiceLocator.instance.documentService
        .readContent(docs.first.filePath);
    return (content: content, title: docs.first.title);
  }

  /// 获取项目所有文档内容
  Future<
      ({
        Map<String, String> contents,
        List<dynamic> docs,
        String projectName
      })?> _getAllDocContents() async {
    final pid = widget.projectId;
    if (pid == null) {
      _showSnack('请先打开一个项目');
      return null;
    }
    final project =
        await ServiceLocator.instance.projectService.getProject(pid);
    if (project == null) {
      _showSnack('项目不存在');
      return null;
    }
    final docs =
        await ServiceLocator.instance.documentService.getDocuments(pid);
    if (docs.isEmpty) {
      _showSnack('当前项目没有文档');
      return null;
    }
    final contents = <String, String>{};
    for (final doc in docs) {
      contents[doc.id] = await ServiceLocator.instance.documentService
          .readContent(doc.filePath);
    }
    return (contents: contents, docs: docs, projectName: project.name);
  }

  // ── 导出操作 ──

  Future<void> _exportMarkdown() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _getFirstDocContent();
      if (data == null) return;
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '导出 Markdown',
        fileName: '${data.title}.md',
        allowedExtensions: ['md'],
      );
      if (savePath == null) return;
      await ServiceLocator.instance.exportService.exportAsMarkdown(
        content: data.content,
        savePath: savePath,
      );
      _showSnack('Markdown 导出成功');
    } catch (e) {
      _showSnack('导出失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportTxt() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _getFirstDocContent();
      if (data == null) return;
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '导出纯文本',
        fileName: '${data.title}.txt',
        allowedExtensions: ['txt'],
      );
      if (savePath == null) return;
      await ServiceLocator.instance.exportService.exportAsTxt(
        content: data.content,
        savePath: savePath,
      );
      _showSnack('纯文本导出成功');
    } catch (e) {
      _showSnack('导出失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _getFirstDocContent();
      if (data == null) return;
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '导出 PDF',
        fileName: '${data.title}.pdf',
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return;
      await ServiceLocator.instance.exportService.exportAsPdf(
        title: data.title,
        content: data.content,
        savePath: savePath,
      );
      _showSnack('PDF 导出成功');
    } catch (e) {
      _showSnack('导出失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── 导入操作 ──

  Future<void> _pickAndImportFile() async {
    if (_busy) return;
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择导入文件',
      type: FileType.custom,
      allowedExtensions: const ['md', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) {
      _showSnack('无法读取文件路径');
      return;
    }
    await _importFileFromPath(path);
  }

  Future<void> _importFileFromPath(String path) async {
    if (_busy) return;
    final pid = widget.projectId;
    if (pid == null) {
      _showSnack('请先打开一个项目');
      return;
    }
    setState(() => _busy = true);
    try {
      final project =
          await ServiceLocator.instance.projectService.getProject(pid);
      if (project == null) {
        _showSnack('项目不存在');
        return;
      }
      final document = await importTextFileIntoProject(
        project: project,
        documentService: ServiceLocator.instance.documentService,
        filePath: path,
      );
      _showSnack('导入成功: ${document.title}');
    } catch (e) {
      _showSnack('导入失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── 批量操作 ──

  Future<void> _exportAllChapters() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _getAllDocContents();
      if (data == null) return;
      final outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择导出目录',
      );
      if (outputDir == null) return;
      final project = await ServiceLocator.instance.projectService
          .getProject(widget.projectId!);
      if (project == null) return;
      final docs = await ServiceLocator.instance.documentService
          .getDocuments(widget.projectId!);
      await ServiceLocator.instance.exportService.exportProjectToDirectory(
        project: project,
        documents: docs,
        contents: data.contents,
        outputDir: outputDir,
      );
      _showSnack('全部章节已导出到 $outputDir');
    } catch (e) {
      _showSnack('导出失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importProjectFolder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final dirPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择项目文件夹',
      );
      if (dirPath == null) return;
      final result = await ServiceLocator.instance.projectService
          .openPortableProject(dirPath);
      ServiceLocator.instance.projectTabController.openProject(result.project);
      _showSnack('项目导入成功: ${result.project.name}');
    } catch (e) {
      _showSnack('导入失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importProjectPackage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final selected = await FilePicker.platform.pickFiles(
        dialogTitle: '选择灵笔项目包',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      final packagePath = selected?.files.single.path;
      if (packagePath == null) return;
      final destination = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择空目录以恢复项目',
      );
      if (destination == null) return;
      await ServiceLocator.instance.portableProjectPackageService
          .importPackage(packagePath, destination);
      final opened = await ServiceLocator.instance.projectService
          .openPortableProject(destination);
      ServiceLocator.instance.projectTabController.openProject(opened.project);
      _showSnack('项目包已校验并恢复: ${opened.project.name}');
    } catch (e) {
      _showSnack('项目包导入失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupProject() async {
    if (_busy) return;
    final pid = widget.projectId;
    if (pid == null) {
      _showSnack('请先打开一个项目');
      return;
    }
    setState(() => _busy = true);
    try {
      final project =
          await ServiceLocator.instance.projectService.getProject(pid);
      if (project == null) return;
      final packagePath = await FilePicker.platform.saveFile(
        dialogTitle: '导出可恢复项目包',
        fileName: '${project.name}.lingbi.zip',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (packagePath == null) return;
      await ServiceLocator.instance.portableProjectPackageService
          .exportPackage(project.directoryPath, packagePath);
      _showSnack('完整项目包已校验并保存');
    } catch (e) {
      _showSnack('备份失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LingBiTokens.space6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExportSection(c),
                      const SizedBox(height: LingBiTokens.space10),
                      _buildImportSection(c),
                      const SizedBox(height: LingBiTokens.space10),
                      _buildBatchSection(c),
                      if (widget.projectId != null) ...[
                        const SizedBox(height: LingBiTokens.space10),
                        Text(
                          '恢复中心',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.fg,
                          ),
                        ),
                        const SizedBox(height: LingBiTokens.space4),
                        RecoveryCenterPage(projectId: widget.projectId!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_busy)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Row(
        children: [
          Text(
            '导入 / 导出',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: -0.625 / 26 * 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(LingBiColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.fg,
          ),
        ),
        const SizedBox(height: LingBiTokens.space4),
        Row(
          children: [
            _buildFormatCard(
                c, 'Markdown', '.md', LingBiIcons.download, _exportMarkdown),
            const SizedBox(width: LingBiTokens.space4),
            _buildFormatCard(
                c, '纯文本', '.txt', LingBiIcons.download, _exportTxt),
            const SizedBox(width: LingBiTokens.space4),
            _buildFormatCard(
                c, 'PDF', '.pdf', LingBiIcons.download, _exportPdf),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatCard(
    LingBiColors c,
    String label,
    String ext,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space5),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            border: Border.all(
              color: c.borderOpaque.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: c.accent),
              const SizedBox(height: LingBiTokens.space3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
              const SizedBox(height: LingBiTokens.space1),
              Text(
                ext,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportSection(LingBiColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导入',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.fg,
          ),
        ),
        const SizedBox(height: LingBiTokens.space4),
        DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            final ext = details.data.toLowerCase();
            return ext.endsWith('.md') || ext.endsWith('.txt');
          },
          onAcceptWithDetails: (details) => _importFileFromPath(details.data),
          builder: (context, candidateData, rejectedData) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LingBiTokens.space8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? c.accent
                    : c.borderOpaque.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LingBiIcons.upload,
                  size: 40,
                  color: c.muted,
                ),
                const SizedBox(height: LingBiTokens.space4),
                Text(
                  '拖放文件到此处',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.fgSecondary,
                  ),
                ),
                const SizedBox(height: LingBiTokens.space2),
                Text(
                  '支持 Markdown (.md)、纯文本 (.txt) 格式',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: LingBiTokens.space4),
                OutlinedButton.icon(
                  onPressed: _pickAndImportFile,
                  icon: const Icon(LingBiIcons.upload, size: 16),
                  label: const Text('选择文件'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: LingBiTokens.space5,
                      vertical: LingBiTokens.space2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchSection(LingBiColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '批量操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: c.fg,
          ),
        ),
        const SizedBox(height: LingBiTokens.space4),
        Row(
          children: [
            _buildBatchCard(c, '导出全部章节', '将所有章节合并导出', LingBiIcons.download,
                _exportAllChapters),
            const SizedBox(width: LingBiTokens.space4),
            _buildBatchCard(c, '导入项目文件夹', '导入包含多文件的文件夹', LingBiIcons.upload,
                _importProjectFolder),
            const SizedBox(width: LingBiTokens.space4),
            _buildBatchCard(c, '导入项目包', '校验完整性后恢复到空目录', LingBiIcons.upload,
                _importProjectPackage),
            const SizedBox(width: LingBiTokens.space4),
            _buildBatchCard(
                c, '备份项目', '创建带校验清单的完整项目包', LingBiIcons.save, _backupProject),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchCard(
    LingBiColors c,
    String title,
    String desc,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(LingBiTokens.space4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            border: Border.all(
              color: c.borderOpaque.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c.fgSecondary),
              const SizedBox(width: LingBiTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.fgSecondary,
                      ),
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
