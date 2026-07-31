/// 备忘录服务 — 复刻 OpenWrite 的备忘录功能。
///
/// 轻量笔记：创建/编辑/删除/列表，按项目分组 + 未归类。
/// 存储：项目目录下 .lingbi/memos.json
library;

import 'dart:convert';
import 'dart:io';

class Memo {
  Memo({
    required this.id,
    required this.content,
    this.projectId,
    this.createdAt,
    this.updatedAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) => Memo(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    projectId: json['projectId'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
  );

  final String id;
  String content;
  String? projectId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'projectId': projectId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class MemoService {
  MemoService(this._basePath);

  final String _basePath;

  String get _filePath => '$_basePath${Platform.pathSeparator}.lingbi${Platform.pathSeparator}memos.json';

  Future<List<Memo>> loadAll() async {
    final file = File(_filePath);
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List;
      return data.map((e) => Memo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(Memo memo) async {
    final memos = await loadAll();
    final idx = memos.indexWhere((m) => m.id == memo.id);
    memo.updatedAt = DateTime.now();
    if (idx >= 0) {
      memos[idx] = memo;
    } else {
      memo.createdAt = DateTime.now();
      memos.add(memo);
    }
    await _writeAll(memos);
  }

  Future<void> delete(String id) async {
    final memos = await loadAll();
    memos.removeWhere((m) => m.id == id);
    await _writeAll(memos);
  }

  Future<List<Memo>> getByProject(String? projectId) async {
    final all = await loadAll();
    if (projectId == null) return all.where((m) => m.projectId == null).toList();
    return all.where((m) => m.projectId == projectId).toList();
  }

  Future<void> _writeAll(List<Memo> memos) async {
    final file = File(_filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(memos.map((m) => m.toJson()).toList()));
  }
}
