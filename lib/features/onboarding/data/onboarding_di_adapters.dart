/// DI 适配器：将已有服务适配到 onboarding 模块的抽象接口
///
/// - ProjectServiceAdapter: ProjectService → ProjectCreator
/// - CanonServiceAdapter: CanonService → CanonWriter
/// - ProjectFirstChapterTarget: FirstChapterWorkflowController → FirstChapterTriggerTarget
library;

import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/onboarding/data/first_chapter_trigger.dart';
import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_workflow.dart';

/// 将 [ProjectService.createPortableProject] 适配为 [ProjectCreator]
class ProjectServiceAdapter implements ProjectCreator {
  ProjectServiceAdapter(this._service);
  final ProjectService _service;

  @override
  Future<Project> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  }) =>
      _service.createPortableProject(directoryPath: directoryPath, brief: brief);
}

/// 将 [CanonService.create] 适配为 [CanonWriter]
class CanonServiceAdapter implements CanonWriter {
  CanonServiceAdapter(this._service);
  final CanonService _service;

  @override
  Future<void> createEntry(CanonEntry entry) async {
    await _service.create(entry);
  }
}

/// 将 [FirstChapterWorkflowController] 适配为 [FirstChapterTriggerTarget]
///
/// 按项目构建：需要已创建项目的 directoryPath 和 projectId。
/// 内部组装 NovelFirstChapterPipeline + FileFirstChapterStateStore。
class ProjectFirstChapterTarget implements FirstChapterTriggerTarget {
  ProjectFirstChapterTarget({
    required String projectDir,
    required String projectId,
    required DocumentService documentService,
    required CanonService canonService,
    required AIService aiService,
  }) : _controller = FirstChapterWorkflowController(
          pipeline: NovelFirstChapterPipeline(
            NovelApplicationService(
              projectDir: projectDir,
              projectId: projectId,
              documentService: documentService,
              canonService: canonService,
              aiService: aiService,
            ),
          ),
          stateStore: FileFirstChapterStateStore(projectDirectory: projectDir),
        );

  final FirstChapterWorkflowController _controller;

  @override
  Stream<FirstChapterEvent> start(FirstChapterRequest request) =>
      _controller.start(request);

  @override
  Future<void> cancel() => _controller.cancel();
}
