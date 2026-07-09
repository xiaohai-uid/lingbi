import 'package:lingbi/services/interfaces/i_document_service.dart';
import 'dart:io';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/core/file_system/sync_service.dart';

class DocumentService implements IDocumentService {
  DocumentService({
    required ZVecService zvecService,
    required FileService fileService,
    required SyncService syncService,
  })  : _zvec = zvecService,
        _file = fileService,
        _sync = syncService;
  final ZVecService _zvec;
  final FileService _file;
  final SyncService _sync;

  /// 新建文档
  @override
  Future<Document> createDocument({
    required String projectId,
    required String title,
    required String directoryPath,
    String content = '',
    String? sceneId,
  }) async {
    final safeTitle = title.replaceAll(RegExp(r'[\./\\]'), '_');
    final filePath = '$directoryPath/$safeTitle.md';
    await _file.writeDocument(
        filePath, content.isEmpty ? '# $title\n\n' : content);
    final wordCount =
        _file.countWords(content.isEmpty ? '# $title\n\n' : content);
    final doc = Document(
      projectId: projectId,
      title: title,
      filePath: filePath,
      wordCount: wordCount,
      currentSceneId: sceneId,
    );
    await _zvec.upsert('documents', doc.id, doc.toJson());
    return doc;
  }

  /// 读取文档内容
  @override
  Future<String> readContent(String filePath) async {
    return _file.readDocument(filePath);
  }

  /// 保存文档
  @override
  Future<Document> saveDocument(Document doc, String content) async {
    await _file.writeDocument(doc.filePath, content);
    doc.wordCount = _file.countWords(content);
    doc.updatedAt = DateTime.now();
    await _zvec.upsert('documents', doc.id, doc.toJson());
    return doc;
  }

  /// 保存 v4 Drift 文档索引指向的正文文件。
  Future<void> writeDocumentContent(String filePath, String content) async {
    await _file.writeDocument(filePath, content);
  }

  /// 根据 sceneId 查找关联文档
  @override
  Future<Document?> getDocumentBySceneId(String sceneId) async {
    final results =
        await _zvec.query('documents', filter: {'currentSceneId': sceneId});
    if (results.isEmpty) return null;
    return Document.fromJson(results.first);
  }

  /// 获取项目的所有文档
  @override
  Future<List<Document>> getDocuments(String projectId) async {
    final results =
        await _zvec.query('documents', filter: {'projectId': projectId});
    return results.map((json) => Document.fromJson(json)).toList();
  }

  /// 根据 ID 获取文档
  @override
  Future<Document?> getDocument(String id) async {
    final result = await _zvec.get<Map<String, dynamic>>('documents', id);
    if (result == null) return null;
    return Document.fromJson(result);
  }

  /// 删除文档
  @override
  Future<void> deleteDocument(Document doc) async {
    await _sync.deleteDocument(doc);
  }

  /// 重命名文档
  @override
  Future<void> renameDocument(Document doc, String newTitle) async {
    final sep = Platform.pathSeparator;
    final oldPath = doc.filePath;
    final dir = oldPath.substring(0, oldPath.lastIndexOf('/'));
    final dir2 = oldPath.substring(0, oldPath.lastIndexOf(sep));
    doc.filePath = '${dir.isNotEmpty ? dir : dir2}/$newTitle.md';
    await _file.renameDocument(oldPath, doc.filePath);
    doc.title = newTitle;
    doc.updatedAt = DateTime.now();
    await _zvec.upsert('documents', doc.id, doc.toJson());
  }
}
