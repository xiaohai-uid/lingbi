import '../../services/ai_service.dart';
import '../../services/codex_service.dart';
import '../../services/codex_linking_service.dart';
import '../../services/document_service.dart';
import '../../services/export_service.dart';
import '../../services/project_service.dart';
import '../../services/project_tab_controller.dart';
import '../../services/quota_service.dart';
import '../../services/settings_service.dart';
import '../../services/storage_service.dart';
import '../../services/version_history_service.dart';
import '../database/zvec_service.dart';
import '../file_system/file_service.dart';
import '../file_system/sync_service.dart';

/// 服务定位器 - 集中管理所有 Service 的创建和生命周期
///
/// 注入顺序（依赖拓扑排序）：
/// 1. StorageService, FileService, QuotaService (叶子 — 无依赖)
/// 2. ZVecService ← StorageService
/// 3. SyncService ← FileService, ZVecService
/// 4. DocumentService ← ZVecService, FileService, SyncService
/// 5. CodexService ← ZVecService
/// 6. ProjectService ← ZVecService
/// 7. AIService ← QuotaService
/// 8. CodexLinkingService ← CodexService
/// 9. SettingsService ← AIService
/// 10. ExportService, VersionHistoryService, ProjectTabController (无依赖)
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance!;

  /// 初始化是否完全成功；false 表示部分服务初始化失败，进入降级模式
  bool initSucceeded = true;
  String? initError;

  /// 创建一个降级 ServiceLocator 用于测试（所有服务字段均未初始化）。
  static ServiceLocator failed({String? error}) {
    final locator = ServiceLocator._();
    locator.initSucceeded = false;
    locator.initError = error ?? 'Degraded mode (test)';
    return locator;
  }

  /// ——— 叶子服务（无依赖） ———
  late final StorageService storageService;
  late final FileService fileService;
  late final QuotaService quotaService;

  /// ——— 中间层服务 ———
  late final ZVecService zvecService;
  late final SyncService syncService;

  /// ——— 特性服务 ———
  late final DocumentService documentService;
  late final CodexService codexService;
  late final ProjectService projectService;
  late final AIService aiService;
  late final CodexLinkingService codexLinkingService;
  late final SettingsService settingsService;
  late final ExportService exportService;
  late final VersionHistoryService versionHistoryService;
  late final ProjectTabController projectTabController;

  ServiceLocator._();

  /// 初始化所有服务（按依赖拓扑升序）
  ///
  /// 如果初始化失败，[initSucceeded] 变为 false 并记录 [initError]，
  /// 调用方仍可获取 ServiceLocator 实例。
  static Future<ServiceLocator> init() async {
    final locator = ServiceLocator._();
    _instance = locator;

    try {
      // 层级 1: 叶子服务（无依赖）
      locator.storageService = StorageService();
      locator.fileService = FileService();
      locator.quotaService = QuotaService();

      // 层级 2: 依赖叶子服务
      locator.zvecService = ZVecService(storageService: locator.storageService);
      locator.syncService = SyncService(
        fileService: locator.fileService,
        zvecService: locator.zvecService,
      );

      // 层级 3: 特性服务
      locator.documentService = DocumentService(
        zvecService: locator.zvecService,
        fileService: locator.fileService,
        syncService: locator.syncService,
      );
      locator.codexService = CodexService(zvecService: locator.zvecService);
      locator.projectService = ProjectService(zvecService: locator.zvecService);
      locator.aiService = AIService(quotaService: locator.quotaService);

      // 层级 4: 依赖特性服务
      locator.codexLinkingService =
          CodexLinkingService(codexService: locator.codexService);
      locator.settingsService =
          SettingsService(aiService: locator.aiService);

      // 层级 5: 无依赖工具服务
      locator.exportService = ExportService();
      locator.versionHistoryService = VersionHistoryService();
      locator.projectTabController = ProjectTabController();

      // 初始化需要异步初始化的服务
      await locator.storageService.initialize();
      await locator.zvecService.initialize();
      await locator.settingsService.initialize();
    } catch (e) {
      locator.initSucceeded = false;
      locator.initError = e.toString();
    }

    return locator;
  }

  /// 释放资源
  Future<void> dispose() async {
    if (initSucceeded) {
      settingsService.removeListener(() {});
      await zvecService.close();
    }
  }
}