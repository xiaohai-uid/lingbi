import 'package:path_provider/path_provider.dart';
import '../../domain/mutation/mutation_models.dart';
import '../errors/app_error.dart';
import '../errors/result.dart';

import 'package:lingbi/features/review/data/anti_hallucination_service.dart';
import '../../services/ai_service.dart';
import 'package:lingbi/features/writing/data/foreshadowing_service.dart';
import '../../features/strand/data/strand_weave_service.dart';
import '../../features/style/data/style_distillation_service.dart';
import 'package:lingbi/features/knowledge/data/web_search_service.dart';
import '../../features/canon/data/canon_service.dart';
import '../../features/canon/data/canon_linking_service.dart';
import '../../services/document_service.dart';
import '../../features/import_export/data/export_service.dart';

import '../../services/intent_confirmation_service.dart';
import '../../features/project/data/project_meta_repository.dart';
import '../../features/project/data/project_asset_repository.dart';
import '../../features/onboarding/data/wizard_completion_workflow.dart';
import '../../features/onboarding/data/onboarding_di_adapters.dart';
import '../../features/project/data/project_service.dart';
import '../../features/project/data/project_root_resolver.dart';
import '../../features/project/data/project_tab_controller.dart';
import '../../shared/interfaces/i_project_service.dart';
import '../../shared/interfaces/mutation_protocol.dart';
import '../../shared/interfaces/project_root_resolver.dart';
import '../../features/settings/data/quota_service.dart';
import '../../features/settings/data/settings_service.dart';
import '../../features/skill/data/skill_action_service.dart';
import '../../features/skill/data/skill/skill_loader.dart';
import '../../features/skill/data/skill/distillation_service.dart';
import '../../features/skill/data/skill_marketplace.dart';
import 'package:lingbi/features/skill/data/market_intel_service.dart';
import 'package:lingbi/features/knowledge/data/vector_knowledge_service.dart';
import 'package:lingbi/features/knowledge/data/reference_book_service.dart';
import '../../services/task_queue_service.dart';
import '../../services/public_benefit_service.dart';
import '../../features/review/data/six_dimension_review_service.dart';
import 'package:lingbi/features/canon/data/change_propagation_service.dart';
import '../../services/model_router_service.dart';
import 'package:lingbi/features/review/data/de_ai_flavor_service.dart';
import 'package:lingbi/features/import_export/data/drama_conversion_service.dart';
import 'package:lingbi/features/parallel_world/data/parallel_world_service.dart';
import 'package:lingbi/features/canon/data/character_relation_graph_service.dart';
import 'package:lingbi/features/collaboration/data/workflow_approval_service.dart';
import 'package:lingbi/features/writing/data/short_story_service.dart';
import '../../features/sync/data/sync/sync_manager.dart';
import '../../features/settings/data/subscription_service.dart';
import '../../services/license_service.dart';
import '../../services/storage_service.dart';
import '../database/story_beats_repository.dart';
import '../../features/review/data/version_history_service.dart';
import '../../services/atomic_file_store.dart';
import '../../services/mutation/local_mutation_journal.dart';
import '../../services/mutation/project_mutation_journal_factory.dart';
import '../../services/recovery_center_service.dart';
import '../../features/import_export/data/portable_project_package_service.dart';
import '../database/zvec_service.dart';
import '../file_system/file_service.dart';
import '../file_system/sync_service.dart';
import '../ai/provider_factory.dart';
import '../ai/runtime_model_selection.dart';
import '../utils/paths.dart';

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
  late final AtomicFileStore atomicFileStore;
  late final LocalMutationJournal mutationJournal;
  late final ProjectMutationJournalFactory projectMutationJournalFactory;
  late final MutationProtocol mutationProtocol;
  late final RecoveryCenterService recoveryCenterService;
  late final PortableProjectPackageService portableProjectPackageService;

  /// ——— 仓储 ———
  late final StoryBeatsRepository storyBeatsRepository;

  /// ——— 中间层服务 ———
  late final ZVecService zvecService;
  late final SyncService syncService;

  /// ——— 特性服务 ———
  late final DocumentService documentService;
  late final CanonService canonService;
  late final ProjectService projectService;
  IProjectService get projectServiceApi => projectService;
  late final ProjectRootResolver projectRootResolver;
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
  late final ProjectAssetRepository projectAssetRepository;
  late final WizardCompletionWorkflow wizardCompletionWorkflow;

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
  late final WorkflowApprovalService workflowApprovalService;
  late final ShortStoryService shortStoryService;
  late final RuntimeModelSelection runtimeModelSelection;

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
      locator.atomicFileStore = AtomicFileStore();
      final appDir = await getApplicationSupportDirectory();
      locator.mutationJournal = LocalMutationJournal(
        basePath: '${appDir.path}/mutations',
      );

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
        atomicStore: locator.atomicFileStore,
      );
      locator.canonService = CanonService(zvecService: locator.zvecService);
      locator.projectService = ProjectService(zvecService: locator.zvecService);
      locator.projectRootResolver = ProjectRootResolverAdapter(
        projectService: locator.projectService,
      );
      locator.projectMutationJournalFactory = ProjectMutationJournalFactory(
        resolver: locator.projectRootResolver,
      );
      locator.mutationProtocol = _UnavailableMutationProtocol(
        projectRootResolver: locator.projectRootResolver,
      );
      locator.recoveryCenterService = RecoveryCenterService(
        atomicStore: locator.atomicFileStore,
        mutationProtocol: locator.mutationProtocol,
      );
      locator.aiService = AIService(quotaService: locator.quotaService);

      // 层级 4: 依赖特性服务
      locator.canonLinkingService =
          CanonLinkingService(canonService: locator.canonService);
      locator.settingsService = SettingsService(aiService: locator.aiService);
      // 提前初始化 SettingsService 以加载环境变量 API Key，
      // 确保后续服务获取的 currentProvider 是真实 provider 而非 FreeProvider
      await locator.settingsService.initialize();

      // 层级 4.5: 项目元数据 + 引导流程引擎
      locator.projectMetaRepository = ProjectMetaRepository(
        projectService: locator.projectService,
        canonService: locator.canonService,
      );
      locator.projectAssetRepository = ProjectAssetRepository(
        metaRepository: locator.projectMetaRepository,
      );
      locator.wizardCompletionWorkflow = WizardCompletionWorkflow(
        projectCreator: ProjectServiceAdapter(locator.projectService),
        canonWriter: CanonServiceAdapter(locator.canonService),
        projectRootResolver: () =>
            locator.settingsService.customStoragePath ??
            resolveDefaultProjectRoot(),
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
      locator.workflowApprovalService = WorkflowApprovalService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );
      locator.shortStoryService = ShortStoryService(
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
      locator.exportService =
          ExportService(atomicStore: locator.atomicFileStore);
      locator.versionHistoryService = VersionHistoryService(
        atomicStore: locator.atomicFileStore,
        recoveryCenter: locator.recoveryCenterService,
      );
      locator.portableProjectPackageService = PortableProjectPackageService(
        atomicStore: locator.atomicFileStore,
        rebuildIndexes: (directoryPath) async {
          final opened =
              await locator.projectService.openPortableProject(directoryPath);
          await locator.zvecService.upsert(
            'projects',
            opened.project.id,
            opened.project.toJson(),
          );
          for (final document in opened.documents) {
            await locator.zvecService.upsert(
              'documents',
              document.id,
              document.toJson(),
            );
          }
        },
      );
      locator.projectTabController = ProjectTabController();

      // 层级 7: 市场情报 + 云同步
      final cacheDir =
          '${(await getApplicationDocumentsDirectory()).path}/lingbi_data/market_cache';
      locator.marketIntelService = MarketIntelService(cacheDir: cacheDir);
      locator.marketIntelAnalysisService = MarketIntelAnalysisService(
        metaRepository: locator.projectMetaRepository,
        aiProvider: locator.aiService.currentProvider,
      );

      // One validated transaction owns every runtime model change. This keeps
      // long-lived services from silently retaining a stale provider instance.
      locator.runtimeModelSelection = RuntimeModelSelection(
        aiService: locator.aiService,
        validateConnection: ProviderFactory.testConnection,
        synchronizeConsumers: [
          (provider) => locator.antiHallucinationService.aiProvider = provider,
          (provider) => locator.strandWeaveService.aiProvider = provider,
          (provider) => locator.styleDistillationService.aiProvider = provider,
          (provider) => locator.vectorKnowledgeService.aiProvider = provider,
          (provider) => locator.referenceBookService.aiProvider = provider,
          (provider) => locator.sixDimensionReviewService.aiProvider = provider,
          (provider) => locator.changePropagationService.aiProvider = provider,
          (provider) => locator.deAiFlavorService.aiProvider = provider,
          (provider) => locator.dramaConversionService.aiProvider = provider,
          (provider) => locator.parallelWorldService.aiProvider = provider,
          (provider) =>
              locator.characterRelationGraphService.aiProvider = provider,
          (provider) => locator.workflowApprovalService.aiProvider = provider,
          (provider) => locator.shortStoryService.aiProvider = provider,
          (provider) =>
              locator.marketIntelAnalysisService.aiProvider = provider,
        ],
        persistSelection: locator.settingsService.commitRuntimeSelection,
      );
      locator.syncManager = SyncManager(
        config: locator.settingsService.webDavConfig,
        mutationProtocol: locator.mutationProtocol,
      );

      // 层级 8: 收费系统（订阅 + 许可证）
      locator.subscriptionService = SubscriptionService();
      final licenseDir =
          '${(await getApplicationDocumentsDirectory()).path}/lingbi_data';
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

/// Keeps canonical writes fail-closed until the project-owned mutation
/// factory is introduced by the later journal/commit tickets.
final class _UnavailableMutationProtocol implements MutationProtocol {
  const _UnavailableMutationProtocol({required this.projectRootResolver});

  final ProjectRootResolver projectRootResolver;

  Result<T> _unavailable<T>(String operation) => Result.failure(
        FileError(
          '$operation requires a project-root-aware MutationProtocol',
          typedCode: MutationErrorCode.protocolUnavailable,
        ),
      );

  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      _unavailable('propose');

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      _unavailable('decide');

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      _unavailable('commit');

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async =>
      _unavailable('applyUserEdit');

  @override
  Future<Result<void>> reject(RejectCommand command) async =>
      _unavailable('reject');
}
