import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';

enum OnboardingQuestion { protagonistGoal, coreObstacle, openingEvent }

class ProjectOnboardingState {
  const ProjectOnboardingState({
    required this.projectId,
    this.currentIndex = 0,
    this.answers = const {},
    this.skipped = const {},
    this.events = const [],
  });

  factory ProjectOnboardingState.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map? ?? const {};
    return ProjectOnboardingState(
      projectId: json['projectId'] as String,
      currentIndex: json['currentIndex'] as int? ?? 0,
      answers: {
        for (final entry in rawAnswers.entries)
          OnboardingQuestion.values.byName(entry.key.toString()):
              entry.value.toString(),
      },
      skipped: (json['skipped'] as List? ?? const [])
          .map((name) => OnboardingQuestion.values.byName(name.toString()))
          .toSet(),
      events: (json['events'] as List? ?? const [])
          .whereType<Map>()
          .map((event) => Map<String, dynamic>.from(event))
          .toList(),
    );
  }

  final String projectId;
  final int currentIndex;
  final Map<OnboardingQuestion, String> answers;
  final Set<OnboardingQuestion> skipped;
  final List<Map<String, dynamic>> events;

  bool get isCompleted => currentIndex >= OnboardingQuestion.values.length;
  OnboardingQuestion? get currentQuestion =>
      isCompleted ? null : OnboardingQuestion.values[currentIndex];

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'currentIndex': currentIndex,
        'answers': {
          for (final entry in answers.entries) entry.key.name: entry.value,
        },
        'skipped': skipped.map((question) => question.name).toList(),
        'events': events,
      };

  ProjectOnboardingState copyWith({
    int? currentIndex,
    Map<OnboardingQuestion, String>? answers,
    Set<OnboardingQuestion>? skipped,
    List<Map<String, dynamic>>? events,
  }) =>
      ProjectOnboardingState(
        projectId: projectId,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        skipped: skipped ?? this.skipped,
        events: events ?? this.events,
      );
}

class ProjectOnboardingWorkflow {
  ProjectOnboardingWorkflow({
    required IProjectMetaRepository metaRepository,
    required ProjectAssetRepository assetRepository,
  })  : _metaRepository = metaRepository,
        _assetRepository = assetRepository;

  static const stateFileName = 'project_onboarding.json';
  final IProjectMetaRepository _metaRepository;
  final ProjectAssetRepository _assetRepository;

  Future<ProjectOnboardingState> resume(String projectId) async {
    final json = await _metaRepository.read(projectId, stateFileName);
    return json == null
        ? ProjectOnboardingState(projectId: projectId)
        : ProjectOnboardingState.fromJson(json);
  }

  Future<ProjectOnboardingState> answer(
    String projectId,
    String value,
  ) async {
    final state = await resume(projectId);
    final question = state.currentQuestion;
    if (question == null) return state;
    return answerQuestion(projectId, question, value);
  }

  Future<ProjectOnboardingState> answerQuestion(
    String projectId,
    OnboardingQuestion question,
    String value,
  ) async {
    final answer = value.trim();
    if (answer.isEmpty) throw ArgumentError.value(value, 'value');
    final state = await resume(projectId);
    if (state.answers[question] == answer) return state;

    await _writeAnswerAsset(projectId, question, answer);
    final answers = Map<OnboardingQuestion, String>.from(state.answers)
      ..[question] = answer;
    final skipped = Set<OnboardingQuestion>.from(state.skipped)
      ..remove(question);
    final nextIndex = state.currentIndex > question.index
        ? state.currentIndex
        : question.index + 1;
    final events = List<Map<String, dynamic>>.from(state.events)
      ..add({
        'id': 'answer:${question.name}:${nextIndex + 1}',
        'type': 'answered',
        'question': question.name,
        'value': answer,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      });
    final updated = state.copyWith(
      currentIndex: nextIndex,
      answers: answers,
      skipped: skipped,
      events: events,
    );
    await _metaRepository.write(projectId, stateFileName, updated.toJson());
    return updated;
  }

  Future<ProjectOnboardingState> skip(String projectId) async {
    final state = await resume(projectId);
    final question = state.currentQuestion;
    if (question == null) return state;
    final skipped = Set<OnboardingQuestion>.from(state.skipped)..add(question);
    final events = List<Map<String, dynamic>>.from(state.events)
      ..add({
        'id': 'skip:${question.name}:${state.currentIndex + 1}',
        'type': 'skipped',
        'question': question.name,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      });
    final updated = state.copyWith(
      currentIndex: state.currentIndex + 1,
      skipped: skipped,
      events: events,
    );
    await _metaRepository.write(projectId, stateFileName, updated.toJson());
    return updated;
  }

  Future<void> _writeAnswerAsset(
    String projectId,
    OnboardingQuestion question,
    String answer,
  ) async {
    final definition = switch (question) {
      OnboardingQuestion.protagonistGoal => (
          file: 'characters.json',
          field: 'protagonistGoal',
          type: ProjectAssetType.protagonist,
        ),
      OnboardingQuestion.coreObstacle => (
          file: 'worldbuilding.json',
          field: 'coreObstacle',
          type: ProjectAssetType.worldRules,
        ),
      OnboardingQuestion.openingEvent => (
          file: 'opening_scene.json',
          field: 'openingEvent',
          type: ProjectAssetType.openingScene,
        ),
    };
    final current =
        await _metaRepository.read(projectId, definition.file) ?? {};
    if (current[definition.field] != answer) {
      await _metaRepository.write(projectId, definition.file, {
        ...current,
        definition.field: answer,
        'summary': answer,
      });
    }

    final assets = await _assetRepository.ensureOverviewAssets(projectId);
    final asset = assets.firstWhere((asset) => asset.type == definition.type);
    await _assetRepository.save(
      asset.copyWith(
        state: ProjectAssetState.editable,
        source: ProjectAssetSource.user,
      ),
      expectedRevision: asset.revision,
    );
  }
}
