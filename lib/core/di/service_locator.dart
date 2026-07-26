import 'package:path_provider/path_provider.dart';

import '../../services/anti_hallucination_service.dart';
import '../../services/ai_service.dart';
import '../../services/foreshadowing_service.dart';
import '../../services/strand_weave_service.dart';
import '../../services/style_distillation_service.dart';
import '../../services/web_search_service.dart';
import '../../services/canon_service.dart';
import '../../services/canon_linking_service.dart';
import '../../services/document_service.dart';
import '../../services/export_service.dart';
import '../../services/guided_flow_engine.dart';
import '../../services/guided_flow_defaults.dart';
import '../../services/skill/guided_flow_skill_loader.dart';
import '../../services/skills/xuanhuan_flow_skill.dart';
import '../../services/skills/xianxia_flow_skill.dart';
import '../../services/skills/dushi_flow_skill.dart';
import '../../services/skills/xuanyi_flow_skill.dart';
import '../../services/skills/yanqing_flow_skill.dart';
import '../../services/skills/kehuan_flow_skill.dart';
import '../../services/skills/lishi_flow_skill.dart';
import '../../services/intent_confirmation_service.dart';
import '../../services/project_meta_repository.dart';
import '../../services/project_service.dart';
import '../../services/project_tab_controller.dart';
import '../../services/quota_service.dart';
import '../../services/settings_service.dart';
import '../../services/skill_action_service.dart';
import '../../services/skill/skill_loader.dart';
import '../../services/skill/distillation_service.dart';
import '../../services/skill_marketplace.dart';
import '../../services/market_intel_service.dart';
import '../../services/vector_knowledge_service.dart';
import '../../services/reference_book_service.dart';
import '../../services/task_queue_service.dart';
import '../../services/public_benefit_service.dart';
import '../../services/six_dimension_review_service.dart';
import '../../services/change_propagation_service.dart';
import '../../services/model_router_service.dart';
import '../../services/de_ai_flavor_service.dart';
import '../../services/drama_conversion_service.dart';
import '../../services/parallel_world_service.dart';
import '../../services/character_relation_graph_service.dart';
import '../../services/sync/sync_manager.dart';
import '../../services/subscription_service.dart';
import '../../services/license_service.dart';
import '../../services/storage_service.dart';
import '../database/story_beats_repository.dart';
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
/// 5. CanonService ← ZVecService
/// 6. ProjectService ← ZVecService
/// 7. AIService ← QuotaService
/// 8. CanonLinkingService ← CanonService
/// 9. SettingsService ← AIService
/// 10. SkillActionService, IntentConfirmationService (无依赖)
/// 11. ExportService, VersionHistoryService, ProjectTabController (无依赖)
class ServiceLocator {

  ServiceLocator._();
  // ignore: use_late_for_private_fields_and_variables
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

  /// ——— 仓储 ———
  late final StoryBeatsRepository storyBeatsRepository;

  /// ——— 中间层服务 ———
  late final ZVecService zvecService;
  late final SyncService syncService;

  /// ——— 特性服务 ———
  late final DocumentService documentService;
  late final CanonService canonService;
  late final ProjectService projectService;
  late final AIService aiService;
  late final CanonLinkingService canonLinkingService;
  late final SettingsService settingsService;
  late final SkillActionService skillActionService;
  late final IntentConfirmationService intentConfirmationService;
  late final ExportService exportService;
  late final VersionHistoryService versionHistoryService;
  late final ProjectTabController projectTabController;

  /// ——— 项目元数据 + 引导流程 ———
  late final ProjectMetaRepository projectMetaRepository;
  late final GuidedFlowEngine guidedFlowEngine;
  late final GuidedFlowSkillLoader guidedFlowSkillLoader;
  late final AntiHallucinationService antiHallucinationService;
  late final ForeshadowingService foreshadowingService;
  late final StrandWeaveService strandWeaveService;
  late final StyleDistillationService styleDistillationService;
  late final WebSearchService webSearchService;
  late final VectorKnowledgeService vectorKnowledgeService;
  late final ReferenceBookService referenceBookService;
  late final TaskQueueService taskQueueService;
  late final PublicBenefitService publicBenefitService;
  late final SixDimensionReviewService sixDimensionReviewService;
  late final ChangePropagationService changePropagationService;
  late final ModelRouterService modelRouterService;
  late final DeAiFlavorService deAiFlavorService;
  late final DramaConversionService dramaConversionService;
  late final ParallelWorldService parallelWorldService;
  late final CharacterRelationGraphService characterRelationGraphService;

  /// ——— Skill 生态服务 ———
  late final SkillMarketplace skillMarketplace;
  late final SkillLoader skillLoader;
  late final DistillationService distillationService;

  /// ——— 市场情报 + 云同步 ———
  late final MarketIntelService marketIntelService;
  late final MarketIntelAnalysisService marketIntelAnalysisService;
  late final SyncManager syncManager;

  /// ——— 收费系统 ———
  late final SubscriptionService subscriptionService;
  late final LicenseService licenseService;

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
      );
      locator.canonService = CanonService(zvecService: locator.zvecService);
      locator.projectService = ProjectService(zvecService: locator.zvecService);
      locator.aiService = AIService(quotaService: locator.quotaService);

      // 层级 4: 依赖特性服务
      locator.canonLinkingService =
          CanonLinkingService(canonService: locator.canonService);
      locator.settingsService = SettingsService(aiService: locator.aiService);

      // 层级 4.5: 项目元数据 + 引导流程引擎
      locator.projectMetaRepository = ProjectMetaRepository(
        projectService: locator.projectService,
        canonService: locator.canonService,
      );
      locator.guidedFlowEngine = GuidedFlowEngine(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      // 注册默认引导流程（通用长篇/短篇）
      locator.guidedFlowEngine.registerDefinition(defaultLongFlowDefinition);
      locator.guidedFlowEngine.registerDefinition(defaultShortFlowDefinition);

      // 引导流程 Skill 加载器 + 官方预装题材
      locator.guidedFlowSkillLoader = GuidedFlowSkillLoader(locator.guidedFlowEngine);
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        xuanhuanLongFlowDefinition, '玄幻',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        xuanhuanShortFlowDefinition, '玄幻',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        xianxiaLongFlowDefinition, '仙侠',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        dushiLongFlowDefinition, '都市',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        xuanyiLongFlowDefinition, '悬疑',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        yanqingLongFlowDefinition, '言情',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        kehuanLongFlowDefinition, '科幻',
      );
      locator.guidedFlowSkillLoader.registerBuiltinFlow(
        lishiLongFlowDefinition, '历史',
      );

      // 反幻觉三定律 + 监督智能体
      locator.antiHallucinationService = AntiHallucinationService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.foreshadowingService = ForeshadowingService(
        metaRepository: locator.projectMetaRepository,
      );
      locator.strandWeaveService = StrandWeaveService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.styleDistillationService = StyleDistillationService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.webSearchService = WebSearchService();
      locator.vectorKnowledgeService = VectorKnowledgeService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.referenceBookService = ReferenceBookService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.taskQueueService = TaskQueueService();
      locator.publicBenefitService = PublicBenefitService();
      locator.sixDimensionReviewService = SixDimensionReviewService(
        aiProvider: locator.aiService.currentProvider,
      );
      locator.changePropagationService = ChangePropagationService(
        vectorKnowledgeService: locator.vectorKnowledgeService,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.modelRouterService = ModelRouterService();
      locator.deAiFlavorService = DeAiFlavorService(
        aiProvider: locator.aiService.currentProvider,
      );
      locator.dramaConversionService = DramaConversionService(
        aiProvider: locator.aiService.currentProvider,
      );
      locator.parallelWorldService = ParallelWorldService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.characterRelationGraphService = CharacterRelationGraphService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );

      // 层级 5: 技能服务（无依赖）
      locator.skillActionService = SkillActionService()
        ..initializeBuiltinSkills();
      locator.intentConfirmationService = IntentConfirmationService();

      // 层级 5.5: Skill 生态（Marketplace + Loader + Distillation）
      locator.skillMarketplace = SkillMarketplace();
      locator.skillLoader = SkillLoader(locator.skillActionService);
      locator.distillationService = DistillationService(
        canonService: locator.canonService,
        aiService: locator.aiService,
        documentService: locator.documentService,
        marketplace: locator.skillMarketplace,
      );
      try {
        final installDir = await _getSkillsInstallDir();
        await locator.skillMarketplace.initialize();
        await locator.skillLoader.loadAll(installDir);
        // 监听安装/卸载事件，实时刷新 Runtime
        locator.skillLoader.listenToMarketplace(locator.skillMarketplace);
      } catch (_) {
        // Skill 生态加载失败不影响其他服务
      }

      // 层级 6: 无依赖工具服务
      locator.exportService = ExportService();
      locator.versionHistoryService = VersionHistoryService();
      locator.projectTabController = ProjectTabController();

      // 层级 7: 市场情报 + 云同步
      final cacheDir = '${(await getApplicationDocumentsDirectory()).path}/lingbi_data/market_cache';
      locator.marketIntelService = MarketIntelService(cacheDir: cacheDir);
      locator.marketIntelAnalysisService = MarketIntelAnalysisService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.syncManager = SyncManager(
        config: locator.settingsService.webDavConfig,
      );

      // 层级 8: 收费系统（订阅 + 许可证）
      locator.subscriptionService = SubscriptionService();
      final licenseDir = '${(await getApplicationDocumentsDirectory()).path}/lingbi_data';
      locator.licenseService = LicenseService(storageDir: licenseDir);
      // 启动时恢复订阅状态
      try {
        final license = await locator.licenseService.loadLicense();
        if (license != null && license.isValid) {
          locator.subscriptionService.activatePro(
            licenseKey: license.key,
            expiresAt: license.expiresAt,
          );
        }
      } catch (_) {
        // 许可证加载失败不影响其他服务
      }

      // 初始化需要异步初始化的服务
      await locator.storageService.initialize();
      locator.storyBeatsRepository =
          StoryBeatsRepository(storageService: locator.storageService);
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
      skillLoader.dispose();
      skillMarketplace.dispose();
      marketIntelService.dispose();
      syncManager.dispose();
      await zvecService.close();
    }
  }

  /// 获取 Skill 安装目录（复用 SkillMarketplace 的约定路径）
  static Future<String> _getSkillsInstallDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/lingbi_skills';
  }
}
