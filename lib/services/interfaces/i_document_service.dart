import 'package:lingbi/core/models/document.dart';

/// 文档服务接口
abstract class IDocumentService {
  Future<Document> createDocument({
    required String projectId,
    required String title,
    required String directoryPath,
    String content = '',
    String? sceneId,
  });

  Future<String> readContent(String filePath);
  Future<Document> saveDocument(Document doc, String content);
  Future<List<Document>> getDocuments(String projectId);
  Future<Document?> getDocument(String id);
  Future<Document?> getDocumentBySceneId(String sceneId);
  Future<void> deleteDocument(Document doc);
  Future<void> renameDocument(Document doc, String newTitle);
}
