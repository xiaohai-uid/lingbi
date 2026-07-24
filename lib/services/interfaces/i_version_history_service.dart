import 'package:lingbi/services/version_history_service.dart';

/// 版本历史服务接口
abstract class IVersionHistoryService {
  Future<void> saveVersion({
    required String projectDir,
    required String docId,
    required String content,
    String? summary,
  });

  Future<List<VersionInfo>> getVersions({
    required String projectDir,
    required String docId,
  });

  Future<String?> getVersionContent({
    required String projectDir,
    required String docId,
    required String versionId,
  });

  Future<String> restoreVersion({
    required String projectDir,
    required String docId,
    required String versionId,
  });
}
