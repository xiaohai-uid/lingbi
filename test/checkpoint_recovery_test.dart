import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/runtime/checkpoint.dart';
import 'package:lingbi/domain/runtime/run_models.dart';
import 'package:lingbi/services/runtime/file_checkpoint_store.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_loop.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/features/writing/services/agent/session_compactor.dart';
import 'package:lingbi/services/runtime/jsonl_run_store.dart';

void main() {
  late Directory tempDir;
  late FileCheckpointStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('checkpoint_test_');
    store = FileCheckpointStore(basePath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Checkpoint makeCheckpoint({
    String runId = 'run-001',
    RunStatus status = RunStatus.running,
    int sequence = 5,
  }) {
    return Checkpoint(
      runId: runId,
      lastEventSequence: sequence,
      lastEventHash: 'abc123',
      status: status,
      projectBriefRevision: 2,
      projectBriefHash: 'brief-hash',
      checkpointHash: '', // computed by store
      candidateIds: ['cand-1', 'cand-2'],
      pendingApprovalId: 'appr-1',
      completedReceiptIds: ['rcpt-1'],
    );
  }

  group('save and load', () {
    test('saved checkpoint can be loaded back', () async {
      final cp = makeCheckpoint();
      final saveResult = await store.save(cp);
      expect(saveResult, isA<Success>());

      final loadResult = await store.load('run-001');
      expect(loadResult, isA<Success<Checkpoint?>>());
      final loaded = (loadResult as Success).value;
      expect(loaded, isNotNull);
      expect(loaded!.runId, 'run-001');
      expect(loaded.lastEventSequence, 5);
      expect(loaded.status, RunStatus.running);
      expect(loaded.candidateIds, ['cand-1', 'cand-2']);
      expect(loaded.pendingApprovalId, 'appr-1');
    });

    test('load returns null for nonexistent run', () async {
      final result = await store.load('nonexistent');
      expect(result, isA<Success<Checkpoint?>>());
      expect((result as Success).value, isNull);
    });

    test('overwrite replaces previous checkpoint', () async {
      await store.save(makeCheckpoint(sequence: 1));
      await store.save(makeCheckpoint(sequence: 10));

      final result = await store.load('run-001');
      final loaded = (result as Success).value!;
      expect(loaded.lastEventSequence, 10);
    });
  });

  group('delete', () {
    test('delete removes checkpoint', () async {
      await store.save(makeCheckpoint());
      await store.delete('run-001');

      final result = await store.load('run-001');
      expect((result as Success).value, isNull);
    });

    test('delete on nonexistent is safe', () async {
      final result = await store.delete('ghost');
      expect(result, isA<Success>());
    });
  });

  group('integrity', () {
    test('corrupted checkpoint returns null', () async {
      await store.save(makeCheckpoint());

      // Corrupt the file
      final file = File('${tempDir.path}/run-001/checkpoint.json');
      await file.writeAsString('{"run_id":"run-001","tampered":true}');

      final result = await store.load('run-001');
      expect((result as Success).value, isNull);
    });
  });

  group('serialization', () {
    test('checkpoint toJson/fromJson round-trips', () {
      final cp = makeCheckpoint(status: RunStatus.waitingApproval);
      final json = cp.toJson();
      final restored = Checkpoint.fromJson(json);
      expect(restored.runId, cp.runId);
      expect(restored.status, RunStatus.waitingApproval);
      expect(restored.projectBriefRevision, 2);
    });
  });

  group('AgentToolLoop checkpoint integration', () {
    test('saves checkpoint before provider call and deletes on success',
        () async {
      final projectDir =
          Directory.systemTemp.createTempSync('lingbi_cp_integration_');
      final cpDir = Directory('${projectDir.path}/checkpoints')..createSync();
      final runDir = Directory('${projectDir.path}/runs')..createSync();
      addTearDown(() => projectDir.deleteSync(recursive: true));

      final cpStore = FileCheckpointStore(basePath: cpDir.path);
      final runStore = JsonlRunStore(basePath: runDir.path);

      // Scripted provider: one tool call then stop
      final provider = _ScriptedProvider([
        ToolTurn(toolCalls: [
          ToolCall(
            id: 'c1',
            name: 'list_dir',
            argumentsJson: jsonEncode({'path': ''}),
          ),
        ], finishReason: 'tool_calls'),
        const ToolTurn(content: 'done', finishReason: 'stop'),
      ]);

      final loop = AgentToolLoop(
        provider: provider,
        registry: AgentToolRegistry(
          projectDir: projectDir.path,
          confirmWrite: (p, c) async => true,
        ),
        compactor: const SessionCompactor(),
        runStore: runStore,
        checkpointStore: cpStore,
      );

      final result = await loop.run(systemPrompt: 'sys', userGoal: 'test');
      expect(result.usedFallback, isFalse);

      // After successful run, checkpoint should be cleaned up
      final runs = (await runStore.listRuns()).orThrow();
      expect(runs, isNotEmpty);
      final cpResult = await cpStore.load(runs.first);
      expect((cpResult as Success).value, isNull);
    });
  });
}

/// Minimal scripted provider for checkpoint tests.
class _ScriptedProvider extends AIProvider {
  _ScriptedProvider(this.turns);
  final List<ToolTurn> turns;
  int _idx = 0;

  @override
  bool get supportsTools => true;
  @override
  String get name => 'scripted-cp';
  @override
  String get displayName => 'Scripted CP';
  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield 'fallback';
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      'fallback';

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (_idx < turns.length) return turns[_idx++];
    return const ToolTurn(content: 'end', finishReason: 'stop');
  }

  @override
  Future<List<double>> embed(String text) async => [];
  @override
  Future<void> dispose() async {}
}
