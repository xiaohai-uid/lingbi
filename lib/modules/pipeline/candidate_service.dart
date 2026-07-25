/// 候选区管理服务
///
/// 借鉴 OpenWrite "AI 输出默认是候选" 设计思想。
/// 所有 AI 生成内容先写入候选区，经作者采纳后才成为正式正文。
library;

import 'dart:convert';
import 'dart:io';

/// 候选条目状态
enum CandidateStatus {
  /// 刚生成，待审稿
  pending,

  /// 审稿中
  reviewing,

  /// 审稿通过，待采纳
  approved,

  /// 审稿未通过
  revisionNeeded,

  /// 作者已采纳
  adopted,

  /// 作者已拒绝
  rejected,

  /// 已归档
  archived,
}

/// 候选条目
class CandidateEntry {
  CandidateEntry({
    required this.id,
    required this.chapterId,
    required this.content,
    this.status = CandidateStatus.pending,
    this.model = '',
    this.reviewReport,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  factory CandidateEntry.fromJson(Map<String, dynamic> json) =>
      CandidateEntry(
        id: json['id'] as String? ?? '',
        chapterId: json['chapter_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: CandidateStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CandidateStatus.pending,
        ),
        model: json['model'] as String? ?? '',
        reviewReport: json['review_report'] as Map<String, dynamic>?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  final String id;
  final String chapterId;
  String content;
  CandidateStatus status;
  final String model;
  Map<String, dynamic>? reviewReport;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter_id': chapterId,
        'content': content,
        'status': status.name,
        'model': model,
        if (reviewReport != null) 'review_report': reviewReport,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'metadata': metadata,
      };
}

/// 候选区管理服务
///
/// 管理 {projectDir}/.lingbi/candidates/ 目录下的所有 AI 候选输出。
/// 每个候选以 JSON 文件存储（含元数据），正文内容以 .md 文件存储。
class CandidateService {
  CandidateService({required String projectDir})
      : _candidatesDir = Directory('$projectDir/.lingbi/candidates');

  final Directory _candidatesDir;

  /// 确保候选区目录存在
  void ensureDir() {
    if (!_candidatesDir.existsSync()) {
      _candidatesDir.createSync(recursive: true);
    }
  }

  /// 创建新候选
  CandidateEntry createCandidate({
    required String chapterId,
    required String content,
    String model = '',
    Map<String, dynamic> metadata = const {},
  }) {
    ensureDir();
    final id = _generateId(chapterId);
    final entry = CandidateEntry(
      id: id,
      chapterId: chapterId,
      content: content,
      model: model,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: metadata,
    );
    _save(entry);
    return entry;
  }

  /// 获取候选
  CandidateEntry? getCandidate(String id) {
    final metaFile = File('${_candidatesDir.path}/$id.json');
    if (!metaFile.existsSync()) return null;
    try {
      final json =
          jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      final entry = CandidateEntry.fromJson(json);
      // 读取正文
      final contentFile = File('${_candidatesDir.path}/$id.md');
      if (contentFile.existsSync()) {
        entry.content = contentFile.readAsStringSync();
      }
      return entry;
    } catch (_) {
      return null;
    }
  }

  /// 列出某章节的所有候选
  List<CandidateEntry> listCandidates(String chapterId) {
    ensureDir();
    final results = <CandidateEntry>[];
    for (final file in _candidatesDir.listSync()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json = jsonDecode(file.readAsStringSync())
              as Map<String, dynamic>;
          if (json['chapter_id'] == chapterId) {
            results.add(CandidateEntry.fromJson(json));
          }
        } catch (_) {
          // 跳过损坏的文件
        }
      }
    }
    results.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return results;
  }

  /// 列出所有待采纳的候选
  List<CandidateEntry> listPendingAdoption() {
    ensureDir();
    final results = <CandidateEntry>[];
    for (final file in _candidatesDir.listSync()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json = jsonDecode(file.readAsStringSync())
              as Map<String, dynamic>;
          final status = json['status'] as String? ?? '';
          if (status == CandidateStatus.pending.name ||
              status == CandidateStatus.approved.name) {
            results.add(CandidateEntry.fromJson(json));
          }
        } catch (_) {}
      }
    }
    return results;
  }

  /// 采纳候选：将候选内容写入正式正文文件
  ///
  /// 返回采纳后的正文文件路径。
  String adopt(String candidateId, String targetFilePath) {
    final entry = getCandidate(candidateId);
    if (entry == null) {
      throw StateError('候选不存在: $candidateId');
    }
    if (entry.status == CandidateStatus.adopted) {
      throw StateError('候选已被采纳');
    }
    if (entry.status == CandidateStatus.rejected) {
      throw StateError('候选已被拒绝，不能采纳');
    }

    // 写入正式正文
    final targetFile = File(targetFilePath);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(entry.content);

    // 更新候选状态
    entry.status = CandidateStatus.adopted;
    entry.updatedAt = DateTime.now();
    _save(entry);

    return targetFilePath;
  }

  /// 拒绝候选
  void reject(String candidateId, {String? reason}) {
    final entry = getCandidate(candidateId);
    if (entry == null) {
      throw StateError('候选不存在: $candidateId');
    }
    entry.status = CandidateStatus.rejected;
    entry.updatedAt = DateTime.now();
    if (reason != null) {
      entry.metadata['reject_reason'] = reason;
    }
    _save(entry);
  }

  /// 更新候选审稿报告
  void updateReview(String candidateId, Map<String, dynamic> report) {
    final entry = getCandidate(candidateId);
    if (entry == null) {
      throw StateError('候选不存在: $candidateId');
    }
    entry.reviewReport = report;
    final passed = report['passed'] == true;
    entry.status =
        passed ? CandidateStatus.approved : CandidateStatus.revisionNeeded;
    entry.updatedAt = DateTime.now();
    _save(entry);
  }

  /// 归档已处理的候选（采纳或拒绝超过 7 天）
  int archiveOld({Duration olderThan = const Duration(days: 7)}) {
    ensureDir();
    var count = 0;
    final cutoff = DateTime.now().subtract(olderThan);
    for (final file in _candidatesDir.listSync()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json = jsonDecode(file.readAsStringSync())
              as Map<String, dynamic>;
          final status = json['status'] as String? ?? '';
          final updatedStr = json['updated_at'] as String?;
          if (updatedStr == null) continue;
          final updated = DateTime.parse(updatedStr);
          if ((status == CandidateStatus.adopted.name ||
                  status == CandidateStatus.rejected.name) &&
              updated.isBefore(cutoff)) {
            // 删除 JSON 和 MD 文件
            file.deleteSync();
            final mdFile =
                File(file.path.replaceAll('.json', '.md'));
            if (mdFile.existsSync()) mdFile.deleteSync();
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  void _save(CandidateEntry entry) {
    ensureDir();
    // 保存元数据 JSON
    final metaFile = File('${_candidatesDir.path}/${entry.id}.json');
    metaFile.writeAsStringSync(jsonEncode(entry.toJson()));
    // 保存正文 MD
    final contentFile = File('${_candidatesDir.path}/${entry.id}.md');
    contentFile.writeAsStringSync(entry.content);
  }

  static int _counter = 0;

  String _generateId(String chapterId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seq = _counter++;
    return '${chapterId}_${timestamp}_$seq';
  }
}
