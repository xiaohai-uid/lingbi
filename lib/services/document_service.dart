import 'package:lingbi/services/interfaces/i_document_service.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/core/file_system/sync_service.dart';

class DocumentService implements IDocumentService {
  final ZVecService? _zvec;
  final FileService _file;

  DocumentService({
    ZVecService? zvecService,
    required FileService fileService,
    SyncService? syncService,
  })  : _zvec = zvecService,
        _file = fileService;

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
    final filePath = '$directoryPath/$safeTitle.md'.replaceAll('\\', '/');
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
    final files = await _file.listDocuments(directoryPath);
    final documents = <Document>[];
    for (final rawPath in files) {
      final path = rawPath.replaceAll('\\', '/');
      if (path.contains('/.lingbi/')) continue;
      final content = await _file.readDocument(path);
      final fileName = path.split('/').last;
      final title = fileName.endsWith('.md')
          ? fileName.substring(0, fileName.length - 3)
          : fileName;
      documents.add(Document(
        projectId: projectId,
        title: title,
        filePath: path,
        wordCount: _file.countWords(content),
      ));
    }
    return documents;
  }

  @override
  Future<String> readContent(String filePath) async {
    return await _file.readDocument(filePath);
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
    final normalPath = doc.filePath.replaceAll('\\', '/');
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
