import 'dart:io';

import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';

import 'ui/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  runApp(const LingBiApp());
}

class LingBiApp extends StatefulWidget {
  final ServiceLocator? locator;
  final String? localWorkDir;

  const LingBiApp({super.key, this.locator, this.localWorkDir});

  @override
  State<LingBiApp> createState() => _LingBiAppState();
}

class _LingBiAppState extends State<LingBiApp> {
  ServiceLocator get _locator => widget.locator ?? ServiceLocator.instance;

  @override
  void initState() {
    super.initState();
    if (_locator.initSucceeded) {
      _locator.settingsService.addListener(_onSettingsChanged);
    }
  }

  @override
  void dispose() {
    if (_locator.initSucceeded) {
      _locator.settingsService.removeListener(_onSettingsChanged);
    }
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '灵笔',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _locator.initSucceeded
          ? _locator.settingsService.themeMode
          : ThemeMode.light,
      home: _locator.initSucceeded
          ? const HomePage()
          : _LocalModeHome(workDir: widget.localWorkDir),
    );
  }
}

/// 降级模式本地写作入口 — 不依赖 ServiceLocator，仅使用 dart:io 文件操作。
class _LocalModeHome extends StatefulWidget {
  final String? workDir;

  const _LocalModeHome({this.workDir});

  @override
  State<_LocalModeHome> createState() => _LocalModeHomeState();
}

class _LocalModeHomeState extends State<_LocalModeHome> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController(text: '新章节');

  String _workDir = '';
  List<String> _files = [];
  String _currentFilePath = '';

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _initDir() {
    String dir;
    if (widget.workDir != null) {
      dir = widget.workDir!;
    } else {
      dir = '${Directory.systemTemp.path}/lingbi_local';
    }
    _workDir = dir.replaceAll('\\', '/');
    Directory(_workDir).createSync(recursive: true);
    _refreshFilesSync();
  }

  void _refreshFilesSync() {
    final dir = Directory(_workDir);
    if (!dir.existsSync()) {
      _files = [];
    } else {
      _files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => f.path.replaceAll('\\', '/'))
          .toList()
        ..sort();
    }
    if (mounted) setState(() {});
  }

  void _newChapter() {
    final name = _titleController.text.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = name.isEmpty ? '新章节' : name;
    final path = '$_workDir/$fileName.md'.replaceAll('\\', '/');
    File(path).writeAsStringSync('# $fileName\n\n');
    _refreshFilesSync();
    _openFile(path);
  }

  void _openFile(String rawPath) {
    final path = rawPath.replaceAll('\\', '/');
    final file = File(path);
    final content = file.existsSync() ? file.readAsStringSync() : '';
    setState(() {
      _currentFilePath = path;
      _contentController.text = content;
      _titleController.text = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
    });
  }

  void _save() {
    if (_currentFilePath.isEmpty) return;
    File(_currentFilePath.replaceAll('\\', '/')).writeAsStringSync(_contentController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('灵笔 — 本地模式')),
      body: Column(
        children: [
          if (_workDir.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('chapterTitleInput'),
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: '章节名',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                key: const ValueKey('newChapterBtn'),
                                icon: const Icon(Icons.add),
                                tooltip: '新建章节',
                                onPressed: _newChapter,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _files.isEmpty
                              ? const Center(child: Text('暂无章节，点击 + 新建'))
                              : ListView.builder(
                                  itemCount: _files.length,
                                  itemBuilder: (_, i) {
                                    final name = _files[i]
                                        .split(RegExp(r'[/\\]'))
                                        .last
                                        .replaceAll('.md', '');
                                    return ListTile(
                                      key: ValueKey('file_${_files[i]}'),
                                      dense: true,
                                      title: Text(name),
                                      selected: _files[i] == _currentFilePath,
                                      onTap: () => _openFile(_files[i]),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              key: const ValueKey('editorField'),
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: '在此编辑 Markdown 内容…',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                key: const ValueKey('saveBtn'),
                                icon: const Icon(Icons.save),
                                label: const Text('保存'),
                                onPressed: _save,
                              ),
                              const Spacer(),
                              if (_currentFilePath.isNotEmpty)
                                Text(
                                  _currentFilePath.split(RegExp(r'[/\\]')).last,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
