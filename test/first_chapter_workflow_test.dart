import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_workflow.dart';

class _MemoryStore implements FirstChapterStateStore {
  FirstChapterState? value;
  Object? writeError;

  @override
  Future<FirstChapterState?> read(String projectId) async => value;

  @override
  Future<void> write(FirstChapterState state) async {
    if (writeError != null) throw writeError!;
    value = state;
  }
}

class _FakePipeline implements FirstChapterPipeline {
  String sourceVersion = 'v1';
  bool rejected = false;
  bool adopted = false;
  bool cancelled = false;
  AdoptionResult adoptionResult = const AdoptionResult.success('chapter.md');

  @override
  Future<FirstChapterPreparation> prepare(FirstChapterRequest request) async =>
      FirstChapterPreparation(sourceVersion: sourceVersion);

  @override
  Stream<String> generate(
    FirstChapterRequest request,
    FirstChapterPreparation preparation,
  ) async* {
    yield '候选正文';
  }

  @override
  Future<FirstChapterCandidate> latestCandidate(String chapterId) async =>
      const FirstChapterCandidate(id: 'candidate-1', content: '候选正文');

  @override
  Future<AdoptionResult> adopt({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) async {
    adopted = adoptionResult.isSuccess;
    return adoptionResult;
  }

  @override
  Future<void> reject(String candidateId) async => rejected = true;

  @override
  Future<void> cancel() async => cancelled = true;
}

const _request = FirstChapterRequest(
  projectId: 'p1',
  chapterId: 'chapter-1',
  targetFilePath: 'chapter.md',
  instruction: '写一个开场',
);

void main() {
  test('generation yields a candidate without writing the chapter', () async {
    final store = _MemoryStore();
    final workflow = FirstChapterWorkflowController(
      pipeline: _FakePipeline(),
      stateStore: store,
    );

    final events = await workflow.start(_request).toList();

    expect(
        events.map((event) => event.stage),
        containsAllInOrder([
          FirstChapterStage.readingAssets,
          FirstChapterStage.generating,
          FirstChapterStage.candidateReady,
          FirstChapterStage.waitingForConfirmation,
        ]));
    expect(store.value?.candidateId, 'candidate-1');
    expect(store.value?.candidateContent, '候选正文');
  });

  test('a new controller resumes the persisted confirmation state', () async {
    final store = _MemoryStore();
    await FirstChapterWorkflowController(
      pipeline: _FakePipeline(),
      stateStore: store,
    ).start(_request).drain<void>();

    final restored = await FirstChapterWorkflowController(
      pipeline: _FakePipeline(),
      stateStore: store,
    ).resume('p1');

    expect(restored?.stage, FirstChapterStage.waitingForConfirmation);
    expect(restored?.candidateId, 'candidate-1');
  });

  test('source conflict keeps candidate recoverable', () async {
    final store = _MemoryStore();
    final pipeline = _FakePipeline()
      ..adoptionResult = const AdoptionResult.failure(
        code: 'SOURCE_VERSION_CONFLICT',
        message: '正文已被修改',
      );
    final workflow = FirstChapterWorkflowController(
      pipeline: pipeline,
      stateStore: store,
    );
    await workflow.start(_request).drain<void>();

    final result = await workflow.adopt('candidate-1');

    expect(result.isSuccess, isFalse);
    expect(store.value?.stage, FirstChapterStage.waitingForConfirmation);
    expect(store.value?.error, '正文已被修改');
  });

  test('adopt reject and cancel delegate to the safe pipeline', () async {
    final store = _MemoryStore();
    final pipeline = _FakePipeline();
    final workflow = FirstChapterWorkflowController(
      pipeline: pipeline,
      stateStore: store,
    );
    await workflow.start(_request).drain<void>();

    final adopted = await workflow.adopt('candidate-1');
    expect(adopted.isSuccess, isTrue);
    expect(pipeline.adopted, isTrue);
    expect(store.value?.stage, FirstChapterStage.completed);

    await workflow.start(_request).drain<void>();
    await workflow.reject('candidate-1');
    expect(pipeline.rejected, isTrue);
    expect(store.value?.stage, FirstChapterStage.rejected);

    await workflow.cancel();
    expect(pipeline.cancelled, isTrue);
  });

  test('state-store failure surfaces a failed event and skips generation',
      () async {
    final store = _MemoryStore()..writeError = StateError('disk full');
    final workflow = FirstChapterWorkflowController(
      pipeline: _FakePipeline(),
      stateStore: store,
    );

    final events = await workflow.start(_request).toList();

    expect(events.single.stage, FirstChapterStage.failed);
    expect(events.single.message, contains('disk full'));
  });
}
