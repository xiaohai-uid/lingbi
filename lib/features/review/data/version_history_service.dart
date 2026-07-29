import 'package:lingbi/shared/interfaces/i_version_history_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/recovery_center_service.dart';

/// 版本快照元数据
class VersionInfo {
  VersionInfo({
    required this.id,
    required this.docId,
    required this.timestamp,
    required this.wordCount,
    this.summary = '',
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
        id: json['id'] as String,
        docId: json['docId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        wordCount: json['wordCount'] as int? ?? 0,
        summary: json['summary'] as String? ?? '',
      );
  final String id;
  final String docId;
  final DateTime timestamp;
  final int wordCount;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'docId': docId,
        'timestamp': timestamp.toIso8601String(),
        'wordCount': wordCount,
        'summary': summary,
      };
}

/// 版本历史服务 - 文档快照存储与恢复
class VersionHistoryService implements IVersionHistoryService {
  VersionHistoryService({
    AtomicFileStore? atomicStore,
    RecoveryCenterService? recoveryCenter,
  })  : _atomicStore = atomicStore ?? AtomicFileStore(),
        _recoveryCenter = recoveryCenter ?? RecoveryCenterService();

  final AtomicFileStore _atomicStore;
  final RecoveryCenterService _recoveryCenter;

  /// 保存一个新版本快照
  @override
  Future<void> saveVersion({
    required String projectDir,
    required String docId,
    required String content,
    String? summary,
  }) async {
    final timestamp = DateTime.now();
    final id = 'v_${timestamp.millisecondsSinceEpoch}';
    final safeDocId = docId.replaceAll(RegExp(r'[^\w-]'), '_');
    final versionsDir = Directory('$projectDir/.lingbi/versions/$safeDocId');
    if (!await versionsDir.exists()) {
      await versionsDir.create(recursive: true);
    }

    // 保存内容快照
    final contentFile = File('${versionsDir.path}/$id.md');
    await _atomicStore.writeString(contentFile.path, content);

    // 更新元数据
    final metadataFile = File('${versionsDir.path}/metadata.json');
    List<VersionInfo> versions = [];
    if (await metadataFile.exists()) {
      final json = jsonDecode(await metadataFile.readAsString()) as List;
      versions = json
          .map((j) => VersionInfo.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final wordCount = _countWords(content);
    versions.add(VersionInfo(
      id: id,
      docId: docId,
      timestamp: timestamp,
      wordCount: wordCount,
      summary: summary ?? _generateSummary(content),
    ));

    // 只保留最近 50 个版本
    if (versions.length > 50) {
      final toRemove = versions.sublist(0, versions.length - 50);
      for (final old in toRemove) {
        final oldFile = File('${versionsDir.path}/${old.id}.md');
        if (await oldFile.exists()) {
          await _recoveryCenter.softDelete(projectDir, oldFile.path);
        }
      }
      versions = versions.sublist(versions.length - 50);
    }

    await _atomicStore.writeString(
      metadataFile.path,
      jsonEncode(versions.map((v) => v.toJson()).toList()),
    );
  }

  /// 获取文档的所有版本列表（按时间倒序）
  @override
  Future<List<VersionInfo>> getVersions({
    required String projectDir,
    required String docId,
  }) async {
    final metadataFile =
        File('$projectDir/.lingbi/versions/$docId/metadata.json');
    if (!await metadataFile.exists()) return [];

    try {
      final json = jsonDecode(await metadataFile.readAsString()) as List;
      final versions = json
          .map((j) => VersionInfo.fromJson(j as Map<String, dynamic>))
          .toList();
      versions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 新版本在前
      return versions;
    } catch (_) {
      return [];
    }
  }

  /// 获取指定版本的内容
  @override
  Future<String?> getVersionContent({
    required String projectDir,
    required String docId,
    required String versionId,
  }) async {
    final file = File('$projectDir/.lingbi/versions/$docId/$versionId.md');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// 恢复指定版本到文档
  @override
  Future<String> restoreVersion({
    required String projectDir,
    required String docId,
    required String versionId,
  }) async {
    final content = await getVersionContent(
      projectDir: projectDir,
      docId: docId,
      versionId: versionId,
    );
    if (content == null) throw Exception('版本文件不存在');
    return content;
  }

  /// 生成变更摘要
  String _generateSummary(String content) {
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '空文档';
    // 取第一个非空行作为摘要
    final first = lines.first.replaceAll(RegExp(r'^#+\s*'), '').trim();
    return first.length > 40 ? '${first.substring(0, 40)}...' : first;
  }

  /// 计算字数
  int _countWords(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    final chineseChars = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]');
    final chineseCount = chineseChars.allMatches(trimmed).length;
    final englishText = trimmed.replaceAll(chineseChars, ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(w))
        .length;
    final punctuation = RegExp(r'[\p{P}\p{S}]', unicode: true);
    final puncCount = punctuation.allMatches(trimmed).length;
    return chineseCount + englishWords + puncCount;
  }
}
