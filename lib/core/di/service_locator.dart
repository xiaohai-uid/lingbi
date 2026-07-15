import '../../services/ai_service.dart';
import '../../services/document_service.dart';
import '../../services/export_service.dart';
import '../../services/project_tab_controller.dart';
import '../../services/quota_service.dart';
import '../../services/settings_service.dart';
import '../../services/search_service.dart';
import '../../services/storage_service.dart';
import '../../services/version_history_service.dart';
import '../../services/world_service.dart';
import '../../services/canon_service.dart';
import '../database/zvec_service.dart';
import '../database/database_manager.dart';
import '../file_system/file_service.dart';
import '../file_system/sync_service.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/scene_repository.dart';
import '../../data/repositories/timeline_repository.dart';
import '../../data/repositories/work_repository.dart';
import '../../data/repositories/volume_repository.dart';
import '../../data/repositories/chapter_repository.dart';
import '../../data/repositories/canon_repository.dart';
import '../../data/repositories/faction_repository.dart';

/// 服务定位器 - 集中管理所有 Service 的创建和生命周期
///
/// 注入顺序（依赖拓扑排序）：
/// 1. StorageService, FileService, QuotaService (叶子 — 无依赖)
/// 2. ZVecService ← StorageService
/// 3. DatabaseManager (Drift 多世界数据库管理)
/// 4. Repository 层 ← DatabaseManager
/// 5. SyncService ← FileService, ZVecService
/// 6. DocumentService ← ZVecService, FileService, SyncService
/// 7. WorldService ← DatabaseManager + Repositories
/// 8. CanonService ← DatabaseManager + CanonRepository
/// 9. AIService ← QuotaService
/// 12. SettingsService ← AIService
/// 13. ExportService, VersionHistoryService, ProjectTabController (无依赖)
class ServiceLocator {
  ServiceLocator._();
  static late final ServiceLocator _instance;
  static ServiceLocator get instance => _instance;

  /// ——— 叶子服务（无依赖） ———
  late final StorageService storageService;
  late final FileService fileService;
  late final QuotaService quotaService;

  /// ——— 数据层服务 ———
  late final ZVecService zvecService;
  late final DatabaseManager databaseManager;

  /// ——— Repository 层 ———
  late final CharacterRepository characterRepository;
  late final SceneRepository sceneRepository;
  late final TimelineRepository timelineRepository;
  late final WorkRepository workRepository;
  late final VolumeRepository volumeRepository;
  late final ChapterRepository chapterRepository;
  late final CanonRepository canonRepository;
  late final FactionRepository factionRepository;

  /// ——— 业务服务 ———
  late final SyncService syncService;
  late final DocumentService documentService;
  late final WorldService worldService;
  late final CanonService canonService;
  late final AIService aiService;
  late final SettingsService settingsService;
  late final ExportService exportService;
  late final VersionHistoryService versionHistoryService;
  late final SearchService searchService;
  late final ProjectTabController projectTabController;

  /// 初始化所有服务（按依赖拓扑升序）
  static Future<ServiceLocator> init() async {
    final locator = ServiceLocator._();
    _instance = locator;

    // 层级 1: 叶子服务（无依赖）
    locator.storageService = StorageService();
    locator.fileService = FileService();
    locator.quotaService = QuotaService();
    await locator.quotaService.loadMemberState();

    // 层级 2: 数据层服务
    locator.zvecService = ZVecService(storageService: locator.storageService);
    locator.databaseManager = DatabaseManager();

    // 层级 3: Repository 层
    // 注意：Repository 需要 Database，但 Database 在首次访问 WorldService 时才创建
    // 这里先初始化 Repository 实例，db 在首次使用时通过 DatabaseManager 获取
    locator.characterRepository = CharacterRepository(locator.databaseManager);
    locator.sceneRepository = SceneRepository(locator.databaseManager);
    locator.timelineRepository = TimelineRepository(locator.databaseManager);
    locator.workRepository = WorkRepository(locator.databaseManager);
    locator.volumeRepository = VolumeRepository(locator.databaseManager);
    locator.chapterRepository = ChapterRepository(locator.databaseManager);
    locator.canonRepository = CanonRepository(locator.databaseManager);
    locator.factionRepository = FactionRepository(locator.databaseManager);

    // 层级 4: 特性服务
    locator.syncService = SyncService(
      fileService: locator.fileService,
      zvecService: locator.zvecService,
    );
    locator.documentService = DocumentService(
      zvecService: locator.zvecService,
      fileService: locator.fileService,
      syncService: locator.syncService,
    );
    locator.worldService = WorldService(
      databaseManager: locator.databaseManager,
      characterRepository: locator.characterRepository,
      sceneRepository: locator.sceneRepository,
      timelineRepository: locator.timelineRepository,
      workRepository: locator.workRepository,
      volumeRepository: locator.volumeRepository,
      chapterRepository: locator.chapterRepository,
      canonRepository: locator.canonRepository,
      factionRepository: locator.factionRepository,
    );
    locator.canonService = CanonService(
      databaseManager: locator.databaseManager,
      canonRepository: locator.canonRepository,
    );
    locator.aiService = AIService(quotaService: locator.quotaService);

    // 层级 5: 依赖特性服务
    locator.settingsService = SettingsService(aiService: locator.aiService);

    // 将 ProviderRegistry 注入到 AIService（settings 创建后才可用）
    locator.aiService
        .setProviderRegistry(locator.settingsService.providerRegistry);

    // 层级 6: 无依赖工具服务
    locator.exportService = ExportService();
    locator.versionHistoryService = VersionHistoryService();
    locator.searchService = SearchService();
    locator.projectTabController = ProjectTabController();

    // 初始化需要异步初始化的服务
    await locator.storageService.initialize();
    await locator.zvecService.initialize();
    await locator.settingsService.initialize();

    return locator;
  }

  /// 释放资源
  Future<void> dispose() async {
    settingsService.removeListener(() {});
    await zvecService.close();
    await databaseManager.closeAll();
  }
}
