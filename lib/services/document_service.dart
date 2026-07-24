import 'package:lingbi/services/interfaces/i_document_service.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/file_system/file_service.dart';

class DocumentService implements IDocumentService {

  DocumentService({
    ZVecService? zvecService,
    required FileService fileService,
  })  : _zvec = zvecService,
        _file = fileService;
  final ZVecService? _zvec;
  final FileService _file;

  String _sanitizeFileName(String title) {
    return title.replaceAll(RegExp(r'[<>:"/\\|?*\.]'), '_');
  }

  @override
  Future<Document> createDocument({
    required String projectId,
    required String title,
    required String directoryPath,
    String content = '',
  }) async {
    final safeTitle = _sanitizeFileName(title);
    final filePath = '$directoryPath/$safeTitle.md'.replaceAll(r'\', '/');
    await _file.writeDocument(
        filePath, content.isEmpty ? '# $title\n\n' : content);
    final wordCount =
        _file.countWords(content.isEmpty ? '# $title\n\n' : content);
    final doc = Document(
      projectId: projectId,
      title: title,
      filePath: filePath,
      wordCount: wordCount,
    );
    await _zvec?.upsert('documents', doc.id, doc.toJson());
    return doc;
  }

  Future<List<Document>> scanDocuments(
    String directoryPath,
    String projectId,
  ) async {
    return _file.scanMarkdownDocuments(directoryPath, projectId);
  }

  @override
  Future<String> readContent(String filePath) async {
    return _file.readDocument(filePath);
  }

  @override
  Future<Document> saveDocument(Document doc, String content) async {
    await _file.writeDocument(doc.filePath, content);
    doc.wordCount = _file.countWords(content);
    doc.updatedAt = DateTime.now();
    await _zvec?.upsert('documents', doc.id, doc.toJson());
    return doc;
  }

  @override
  Future<List<Document>> getDocuments(String projectId) async {
    if (_zvec == null) return [];
    final results =
        await _zvec.query('documents', filter: {'projectId': projectId});
    return results.map((json) => Document.fromJson(json)).toList();
  }

  @override
  Future<Document?> getDocument(String id) async {
    if (_zvec == null) return null;
    final result = await _zvec.get<Map<String, dynamic>>('documents', id);
    if (result == null) return null;
    return Document.fromJson(result);
  }

  @override
  Future<void> deleteDocument(Document doc) async {
    await _file.deleteDocument(doc.filePath);
    await _zvec?.delete('documents', doc.id);
  }

  @override
  Future<void> renameDocument(Document doc, String newTitle) async {
    final normalPath = doc.filePath.replaceAll(r'\', '/');
    final lastSlash = normalPath.lastIndexOf('/');
    final dir = lastSlash >= 0 ? normalPath.substring(0, lastSlash) : '';
    final safeTitle = _sanitizeFileName(newTitle);
    final newPath = '$dir/$safeTitle.md';
    await _file.renameDocument(doc.filePath, newPath);
    doc.filePath = newPath;
    doc.title = newTitle;
    doc.updatedAt = DateTime.now();
    await _zvec?.upsert('documents', doc.id, doc.toJson());
  }
}
