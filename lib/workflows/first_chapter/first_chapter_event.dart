enum FirstChapterStage {
  idle,
  readingAssets,
  generating,
  candidateReady,
  waitingForConfirmation,
  writing,
  completed,
  rejected,
  cancelled,
  failed,
}

class FirstChapterRequest {
  const FirstChapterRequest({
    required this.projectId,
    required this.chapterId,
    required this.targetFilePath,
    this.previousChapterId,
    this.instruction = '',
  });

  final String projectId;
  final String chapterId;
  final String targetFilePath;
  final String? previousChapterId;
  final String instruction;
}

class FirstChapterEvent {
  const FirstChapterEvent({
    required this.stage,
    required this.message,
    this.candidateId,
    this.contentChunk,
  });

  final FirstChapterStage stage;
  final String message;
  final String? candidateId;
  final String? contentChunk;
}

class FirstChapterState {
  const FirstChapterState({
    required this.projectId,
    required this.chapterId,
    required this.targetFilePath,
    required this.stage,
    required this.updatedAt,
    this.candidateId,
    this.candidateContent,
    this.sourceVersion,
    this.error,
    this.instruction,
  });

  factory FirstChapterState.fromJson(Map<String, dynamic> json) =>
      FirstChapterState(
        projectId: json['projectId'] as String,
        chapterId: json['chapterId'] as String,
        targetFilePath: json['targetFilePath'] as String,
        stage: FirstChapterStage.values.byName(json['stage'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        candidateId: json['candidateId'] as String?,
        candidateContent: json['candidateContent'] as String?,
        sourceVersion: json['sourceVersion'] as String?,
        error: json['error'] as String?,
        instruction: json['instruction'] as String?,
      );

  final String projectId;
  final String chapterId;
  final String targetFilePath;
  final FirstChapterStage stage;
  final DateTime updatedAt;
  final String? candidateId;
  final String? candidateContent;
  final String? sourceVersion;
  final String? error;

  /// 用户填写的第一章生成指令（来自向导「第一章目标」维度）
  final String? instruction;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'chapterId': chapterId,
        'targetFilePath': targetFilePath,
        'stage': stage.name,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        if (candidateId != null) 'candidateId': candidateId,
        if (candidateContent != null) 'candidateContent': candidateContent,
        if (sourceVersion != null) 'sourceVersion': sourceVersion,
        if (error != null) 'error': error,
        if (instruction != null) 'instruction': instruction,
      };

  FirstChapterState copyWith({
    FirstChapterStage? stage,
    DateTime? updatedAt,
    String? candidateId,
    String? candidateContent,
    String? sourceVersion,
    String? error,
    String? instruction,
    bool clearError = false,
  }) =>
      FirstChapterState(
        projectId: projectId,
        chapterId: chapterId,
        targetFilePath: targetFilePath,
        stage: stage ?? this.stage,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        candidateId: candidateId ?? this.candidateId,
        candidateContent: candidateContent ?? this.candidateContent,
        sourceVersion: sourceVersion ?? this.sourceVersion,
        error: clearError ? null : error ?? this.error,
        instruction: instruction ?? this.instruction,
      );
}
