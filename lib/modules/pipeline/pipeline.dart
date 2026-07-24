/// 写作流水线模块
///
/// 包含章节生成的完整生命周期管理：
/// - GenerationContext: 上下文包数据模型
/// - ContextAssembler: 上下文组装器
/// - WritingPipelineState: 状态机
/// - WriteLockService: 写作锁
/// - CandidateService: 候选区管理
/// - BookState: 书籍状态追踪
/// - CreativeCompass: 创作罗盘
library;

export 'generation_context.dart';
export 'context_assembler.dart';
export 'writing_pipeline_state.dart';
export 'write_lock_service.dart';
export 'candidate_service.dart';
export 'book_state.dart';
export 'creative_compass.dart';
export 'project_data_source.dart';
export 'novel_application_service.dart';
