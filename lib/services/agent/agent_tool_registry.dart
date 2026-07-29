/// AgentToolRegistry — Agent 工具循环的沙箱工具集。
///
/// 对标 OpenWrite 的 AI 工具链（file_read / file_write / list_dir /
/// question / skill_lookup），但所有文件操作被严格限制在**当前项目目录**内，
/// 越界的绝对路径 / `..` 逃逸一律拒绝。写操作默认经确认回调（先展示后保存）。
///
/// 设计原则（符合"模型控制走 Skill/Agent 沙箱"约束）：
/// - 工具即受控 API：模型只能通过这里声明的工具影响外部世界；
/// - 不提供 system_command（本轮安全考量，见 plan 非目标）；
/// - 每个工具都返回可回灌模型的文本结果，同时通过 onToolEvent 上报
///   一句人类可读的步骤描述供 UI 渲染。
library;

import 'dart:convert';
import 'dart:io';

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/atomic_file_store.dart';

/// 单个工具的执行结果。
class ToolResult {
  const ToolResult({
    required this.content,
    this.isError = false,
    this.display,
  });

  /// 回灌给模型的文本（作为 role:'tool' 消息内容）。
  final String content;

  /// 是否为错误结果（模型可据此调整策略）。
  final bool isError;

  /// UI 可见的简短步骤描述（如"写入 章节内容/第1章.md"）。
  final String? display;
}

/// 写入确认回调：返回 true 表示允许落盘。null 表示不需确认（自动批准）。
typedef WriteConfirm = Future<bool> Function(String relativePath, String content);

/// 向用户提问回调（ask_user）。返回用户选择/输入的文本。
typedef AskUser = Future<String> Function(String question, List<String> options);

/// Skill 查找回调：返回匹配 Skill 的 SKILL.md 正文，未找到返回 null。
typedef SkillLookup = Future<String?> Function(String nameOrId);

/// 工具调用事件回调（供 UI 渲染步骤）。
typedef ToolEvent = void Function(String toolName, String display);

/// Agent 沙箱工具注册表。
class AgentToolRegistry {
  AgentToolRegistry({
    required this.projectDir,
    AtomicFileStore? store,
    this.confirmWrite,
    this.askUser,
    this.skillLookup,
    this.onToolEvent,
    this.readCapChars = 8000,
  }) : store = store ?? AtomicFileStore();

  /// 沙箱根目录（所有文件操作限定在此目录内）。
  final String projectDir;
  final AtomicFileStore store;

  /// 写操作确认回调；为 null 时自动批准（供无人值守测试）。
  final WriteConfirm? confirmWrite;
  final AskUser? askUser;
  final SkillLookup? skillLookup;
  final ToolEvent? onToolEvent;

  /// file_read 单次返回的最大字符数（防止撑爆上下文）。
  final int readCapChars;

  /// 工具规格列表 —— 传给 [AIProvider.chatWithTools] 的模型。
  ///
  /// question / skill_lookup 仅在提供了对应回调时才暴露。
  List<ToolSpec> get specs {
    final list = <ToolSpec>[
      const ToolSpec(
        name: 'file_read',
        description:
            '读取当前项目内的文件，或列出目录内容。path 为相对项目根目录的路径。'
            'mode="read" 读取文件正文，mode="list" 列出目录条目。',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {'type': 'string', 'description': '相对项目根目录的路径，如 "小说资料/人物库.md"'},
            'mode': {
              'type': 'string',
              'enum': ['read', 'list'],
              'description': '读取文件或列目录，默认 read',
            },
          },
          'required': ['path'],
        },
      ),
      const ToolSpec(
        name: 'file_write',
        description:
            '写入/覆盖当前项目内的文件（先展示后保存，需用户确认）。'
            '用于保存章节正文到 "章节内容/第X章.md" 或更新 "小说资料/*.md" 维护文档。',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {'type': 'string', 'description': '相对项目根目录的路径'},
            'content': {'type': 'string', 'description': '要写入的完整文本'},
          },
          'required': ['path', 'content'],
        },
      ),
      const ToolSpec(
        name: 'list_dir',
        description: '列出当前项目某个目录下的文件与子目录。path 为空时列项目根目录。',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {'type': 'string', 'description': '相对项目根目录的路径，默认根目录'},
          },
        },
      ),
    ];
    if (askUser != null) {
      list.add(const ToolSpec(
        name: 'question',
        description: '在执行过程中向用户提问：澄清偏好、确认方向或提供选项。',
        parameters: {
          'type': 'object',
          'properties': {
            'question': {'type': 'string', 'description': '要问用户的问题'},
            'options': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': '可选项（2-4 个），可为空表示开放回答',
            },
          },
          'required': ['question'],
        },
      ));
    }
    if (skillLookup != null) {
      list.add(const ToolSpec(
        name: 'skill_lookup',
        description: '按名称或 ID 加载一个写作技能（Skill）的正文，获取其详细工作流程。',
        parameters: {
          'type': 'object',
          'properties': {
            'skill_name': {'type': 'string', 'description': 'Skill 名称或 ID'},
          },
          'required': ['skill_name'],
        },
      ));
    }
    return list;
  }

  /// 执行一次工具调用，返回可回灌模型的结果。
  Future<ToolResult> execute(ToolCall call) async {
    final args = call.arguments;
    switch (call.name) {
      case 'file_read':
        return _fileRead(args);
      case 'file_write':
        return _fileWrite(args);
      case 'list_dir':
        return _listDir((args['path'] as String?) ?? '');
      case 'question':
        return _question(args);
      case 'skill_lookup':
        return _skillLookup(args);
      default:
        return ToolResult(
          content: '未知工具：${call.name}',
          isError: true,
          display: '未知工具 ${call.name}',
        );
    }
  }

  // ─── 工具实现 ──────────────────────────────────────────────

  Future<ToolResult> _fileRead(Map<String, dynamic> args) async {
    final rawPath = (args['path'] as String?) ?? '';
    final mode = (args['mode'] as String?) ?? 'read';
    if (mode == 'list') return _listDir(rawPath);

    final resolved = _resolveInside(rawPath);
    if (resolved == null) {
      return _deny(rawPath);
    }
    final file = File(resolved);
    if (!await file.exists()) {
      return ToolResult(
        content: '文件不存在：$rawPath',
        isError: true,
        display: '读取失败（不存在）$rawPath',
      );
    }
    var content = await store.readString(resolved) ?? await file.readAsString();
    var truncated = false;
    if (content.length > readCapChars) {
      content = content.substring(0, readCapChars);
      truncated = true;
    }
    onToolEvent?.call('file_read', '读取 $rawPath');
    return ToolResult(
      content: truncated ? '$content\n\n[内容过长已截断，共 $readCapChars+ 字符]' : content,
      display: '读取 $rawPath',
    );
  }

  Future<ToolResult> _fileWrite(Map<String, dynamic> args) async {
    final rawPath = (args['path'] as String?) ?? '';
    final content = (args['content'] as String?) ?? '';
    final resolved = _resolveInside(rawPath);
    if (resolved == null) {
      return _deny(rawPath);
    }
    if (content.trim().isEmpty) {
      return ToolResult(
        content: '写入内容为空，已忽略：$rawPath',
        isError: true,
        display: '跳过空写入 $rawPath',
      );
    }
    // 先展示后保存：交由确认回调裁决（无回调则自动批准）。
    final approved = confirmWrite == null || await confirmWrite!(rawPath, content);
    if (!approved) {
      return ToolResult(
        content: '用户拒绝了对 $rawPath 的写入，请调整后再试或征询用户意见。',
        display: '用户拒绝写入 $rawPath',
      );
    }
    await store.writeString(resolved, content);
    onToolEvent?.call('file_write', '写入 $rawPath');
    return ToolResult(
      content: '已写入 $rawPath（${content.length} 字符）。',
      display: '写入 $rawPath',
    );
  }

  Future<ToolResult> _listDir(String rawPath) async {
    final resolved = _resolveInside(rawPath.isEmpty ? '.' : rawPath);
    if (resolved == null) {
      return _deny(rawPath);
    }
    final dir = Directory(resolved);
    if (!await dir.exists()) {
      return ToolResult(
        content: '目录不存在：${rawPath.isEmpty ? '(根目录)' : rawPath}',
        isError: true,
        display: '列目录失败 $rawPath',
      );
    }
    final entries = <String>[];
    await for (final e in dir.list()) {
      final name = e.path.split(Platform.pathSeparator).last;
      entries.add(e is Directory ? '$name/' : name);
    }
    entries.sort();
    onToolEvent?.call('list_dir', '列出 ${rawPath.isEmpty ? '项目根目录' : rawPath}');
    return ToolResult(
      content: entries.isEmpty ? '(空目录)' : entries.join('\n'),
      display: '列出 ${rawPath.isEmpty ? '项目根目录' : rawPath}',
    );
  }

  Future<ToolResult> _question(Map<String, dynamic> args) async {
    final question = (args['question'] as String?) ?? '';
    final options = ((args['options'] as List<dynamic>?) ?? const [])
        .map((e) => e.toString())
        .toList();
    if (askUser == null) {
      return const ToolResult(
        content: '当前为无人值守模式，请自行决定并继续。',
        display: '提问被跳过（无人值守）',
      );
    }
    onToolEvent?.call('question', '向用户提问');
    final answer = await askUser!(question, options);
    return ToolResult(content: '用户回答：$answer', display: '用户已回答');
  }

  Future<ToolResult> _skillLookup(Map<String, dynamic> args) async {
    final name = (args['skill_name'] as String?) ?? '';
    if (skillLookup == null) {
      return const ToolResult(
        content: '当前未启用 Skill 查找。',
        isError: true,
        display: 'skill_lookup 未启用',
      );
    }
    final body = await skillLookup!(name);
    if (body == null || body.trim().isEmpty) {
      return ToolResult(
        content: '未找到名为 "$name" 的 Skill。',
        isError: true,
        display: '未找到 Skill $name',
      );
    }
    onToolEvent?.call('skill_lookup', '加载 Skill $name');
    return ToolResult(content: body, display: '加载 Skill $name');
  }

  ToolResult _deny(String rawPath) => ToolResult(
        content: '拒绝访问：路径 "$rawPath" 超出当前项目目录，仅允许操作项目内文件。',
        isError: true,
        display: '拒绝越界访问 $rawPath',
      );

  // ─── 沙箱路径解析 ──────────────────────────────────────────

  /// 把 [rawPath] 解析为项目目录内的绝对路径；越界返回 null。
  ///
  /// 手工归一化（不引入第三方 path 包）：统一分隔符、消解 `.`/`..`，
  /// 再校验结果仍在 [projectDir] 之下。
  String? _resolveInside(String rawPath) {
    final root = _normalize(projectDir);
    final joined = _isAbsolute(rawPath) ? _normalize(rawPath) : _normalize('$projectDir/$rawPath');
    if (joined == root) return _toNative(joined);
    if (joined.startsWith('$root/')) return _toNative(joined);
    return null;
  }

  bool _isAbsolute(String path) {
    final p = path.replaceAll(r'\', '/');
    return p.startsWith('/') || RegExp(r'^[A-Za-z]:/').hasMatch(p);
  }

  /// 归一化为 `/` 分隔、消解 `.`/`..` 的路径（保留盘符/前导斜杠）。
  String _normalize(String path) {
    var p = path.replaceAll(r'\', '/');
    String prefix = '';
    final driveMatch = RegExp(r'^([A-Za-z]:)/').firstMatch(p);
    if (driveMatch != null) {
      prefix = driveMatch.group(1)!; // 如 "C:"
      p = p.substring(prefix.length);
    }
    final leadingSlash = p.startsWith('/');
    final segments = p.split('/').where((s) => s.isNotEmpty && s != '.');
    final stack = <String>[];
    for (final seg in segments) {
      if (seg == '..') {
        if (stack.isNotEmpty) stack.removeLast();
      } else {
        stack.add(seg);
      }
    }
    final body = stack.join('/');
    if (prefix.isNotEmpty) return '$prefix/$body';
    return leadingSlash ? '/$body' : body;
  }

  String _toNative(String normalized) {
    if (Platform.pathSeparator == r'\') {
      return normalized.replaceAll('/', r'\');
    }
    return normalized;
  }

  /// 供测试/日志：把工具结果序列化为简短 JSON。
  static String encodePreview(ToolResult r) =>
      jsonEncode({'error': r.isError, 'display': r.display});
}
