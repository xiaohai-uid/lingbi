import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/document.dart';

class SyncService {

  SyncService({
    required FileService fileService,
    required ZVecService zvecService,
  })  : _fileService = fileService,
        _zvecService = zvecService;
  final FileService _fileService;
  final ZVecService _zvecService;

  /// 将项目元数据同步到 ZVec
  Future<void> syncProjectToDb(Project project) async {
    await _zvecService.upsert('projects', project.id, project.toJson());
  }

  /// 将文档元数据同步到 ZVec
  Future<void> syncDocumentToDb(Document doc) async {
    await _zvecService.upsert('documents', doc.id, doc.toJson());
    // 同时确保 .md 文件存在
    final file = await _fileService.directoryExists(doc.filePath);
    if (!file) {
      await _fileService.writeDocument(doc.filePath, '# ${doc.title}\n\n');
    }
  }

  /// 从磁盘扫描文档并更新 ZVec
  Future<List<Document>> syncFromDisk(String projectId, String directoryPath) async {
    final files = await _fileService.listDocuments(directoryPath);
    final documents = <Document>[];

    for (final filePath in files) {
      final fileName = filePath.split(r'\').last.split('/').last;
      final title = fileName.endsWith('.md') ? fileName.substring(0, fileName.length - 3) : fileName;
      final content = await _fileService.readDocument(filePath);
      final wordCount = _fileService.countWords(content);

      documents.add(Document(
        projectId: projectId,
        title: title,
        filePath: filePath,
        wordCount: wordCount,
      ));
    }

    // 批量写入 ZVec
    for (final doc in documents) {
      await _zvecService.upsert('documents', doc.id, doc.toJson());
    }

    return documents;
  }

  /// 删除文档（从磁盘和 ZVec）
  Future<void> deleteDocument(Document doc) async {
    await _fileService.deleteDocument(doc.filePath);
    await _zvecService.delete('documents', doc.id);
  }

  /// 双向同步项目目录
  Future<List<Document>> fullSync(Project project) async {
    // 1. 从磁盘扫描所有 .md 文件
    final files = await _fileService.listDocuments(project.directoryPath);

    // 2. 从 ZVec 获取已知文档
    final knownDocs = await _zvecService.query('documents', filter: {'projectId': project.id});

    final knownPaths = knownDocs.map((d) => d['filePath'] as String).toSet();
    final diskPaths = files.toSet();

    // 3. 新增：磁盘上有但 ZVec 没有的
    final toAdd = diskPaths.difference(knownPaths);
    final addedDocs = <Document>[];
    for (final path in toAdd) {
      final content = await _fileService.readDocument(path);
      final fileName = path.split(r'\').last.split('/').last;
      final title = fileName.endsWith('.md') ? fileName.substring(0, fileName.length - 3) : fileName;
      final doc = Document(
        projectId: project.id,
        title: title,
        filePath: path,
        wordCount: _fileService.countWords(content),
      );
      await _zvecService.upsert('documents', doc.id, doc.toJson());
      addedDocs.add(doc);
    }

    // 4. 删除：ZVec 有但磁盘上没有的
    final toRemove = knownPaths.difference(diskPaths);
    for (final path in toRemove) {
      final match = knownDocs.firstWhere((d) => d['filePath'] == path);
      await _zvecService.delete('documents', match['id'] as String);
    }

    return addedDocs;
  }
}
