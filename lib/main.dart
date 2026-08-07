import 'dart:io';

import 'package:flutter/material.dart';
import 'shared/di/service_locator.dart';
import 'shared/utils/paths.dart';

import 'ui_v2/theme/app_theme.dart';
import 'ui_v2/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  runApp(const LingBiApp());
}

/// 解析默认本地写作目录。
///
/// Windows 默认返回 %USERPROFILE%\Documents\灵笔。
/// [userProfile] 用于测试注入；为 null 时从环境变量读取。
String resolveDefaultLocalDir({String? userProfile}) =>
    resolveDefaultProjectRoot(userProfile: userProfile);

class LingBiApp extends StatefulWidget {

  const LingBiApp({super.key, this.locator, this.localWorkDir});
  final ServiceLocator? locator;
  final String? localWorkDir;

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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _locator.initSucceeded
          ? _locator.settingsService.themeMode
          : ThemeMode.light,
      home: _locator.initSucceeded
          ? LingBiAppV3(locator: _locator)
          : _LocalModeHome(workDir: widget.localWorkDir),
    );
  }
}

/// 降级模式本地写作入口 — 不依赖 ServiceLocator，仅使用 dart:io 文件操作。
class _LocalModeHome extends StatefulWidget {

  const _LocalModeHome({this.workDir});
  final String? workDir;

  @override
  State<_LocalModeHome> createState() => _LocalModeHomeState();
}

class _LocalModeHomeState extends State<_LocalModeHome> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController(text: '新章节');
  final _dirInputController = TextEditingController();

  String _workDir = '';
  List<String> _files = [];
  String _currentFilePath = '';
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _dirInputController.dispose();
    super.dispose();
  }

  void _initDir() {
    if (widget.workDir != null) {
      _workDir = widget.workDir!.replaceAll(r'\', '/');
      Directory(_workDir).createSync(recursive: true);
      _refreshFilesSync();
      return;
    }
    try {
      _workDir = resolveDefaultLocalDir().replaceAll(r'\', '/');
      Directory(_workDir).createSync(recursive: true);
      _refreshFilesSync();
    } on UnsupportedError catch (e) {
      if (mounted) setState(() => _initError = e.message);
    }
  }

  void _applyCustomDir() {
    final path = _dirInputController.text.trim();
    if (path.isEmpty) return;
    setState(() {
      _initError = null;
      _workDir = path.replaceAll(r'\', '/');
    });
    Directory(_workDir).createSync(recursive: true);
    _refreshFilesSync();
  }

  void _refreshFilesSync() {
    final dir = Directory(_workDir);
    if (!dir.existsSync()) {
      _files = [];
    } else {
      _files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toList()
        ..sort();
    }
    if (mounted) setState(() {});
  }

  void _newChapter() {
    final name =
        _titleController.text.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final baseName = name.isEmpty ? '新章节' : name;
    // Never overwrite an existing chapter with the same name: append a
    // numeric suffix until the path is free (same policy as the desktop).
    var fileName = baseName;
    var index = 2;
    while (File('$_workDir/$fileName.md').existsSync()) {
      fileName = '$baseName-$index';
      index += 1;
    }
    final path = '$_workDir/$fileName.md'.replaceAll(r'\', '/');
    File(path).writeAsStringSync('# $fileName\n\n');
    _refreshFilesSync();
    _openFile(path);
  }

  void _openFile(String rawPath) {
    final path = rawPath.replaceAll(r'\', '/');
    final file = File(path);
    final content = file.existsSync() ? file.readAsStringSync() : '';
    setState(() {
      _currentFilePath = path;
      _contentController.text = content;
      _titleController.text =
          path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
    });
  }

  void _save() {
    if (_currentFilePath.isEmpty) return;
    File(_currentFilePath.replaceAll(r'\', '/'))
        .writeAsStringSync(_contentController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('灵笔 — 本地模式'),
            if (_workDir.isNotEmpty)
              Text(
                _workDir,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initError != null) {
      return _buildErrorUi();
    }
    if (_workDir.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
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
    );
  }

  Widget _buildErrorUi() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '无法确定默认工作目录',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_initError!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('dirInputField'),
              controller: _dirInputController,
              decoration: const InputDecoration(
                labelText: '请手动输入工作目录路径',
                border: OutlineInputBorder(),
                hintText: r'C:\Users\用户名\Documents\灵笔',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const ValueKey('confirmDirBtn'),
              onPressed: _applyCustomDir,
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }
}
