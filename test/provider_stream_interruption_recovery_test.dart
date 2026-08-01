import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/runtime/run_models.dart';
import 'package:lingbi/services/runtime/jsonl_run_store.dart';
import 'package:lingbi/shared/errors/result.dart';

void main() {
  late Directory tempDir;
  late JsonlRunStore runStore;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('run_recovery_test_');
    runStore = JsonlRunStore(basePath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  RunEvent makeEvent({
    required String runId,
    String? eventId,
    String eventType = 'status_changed',
    String? idempotencyKey,
  }) {
    return RunEvent(
      eventId: eventId ?? 'evt-${DateTime.now().microsecondsSinceEpoch}',
      runId: runId,
      sequence: 0,
      eventType: eventType,
      occurredAt: '',
      projectBriefRevision: 1,
      payloadHash: '',
      previousEventHash: '',
      idempotencyKey: idempotencyKey,
      payload: {'status': 'running'},
    );
  }

  group('RunStore append and ordering', () {
    test('events are appended in sequence order', () async {
      final e1 = makeEvent(runId: 'run-A', eventId: 'e1');
      final e2 = makeEvent(runId: 'run-A', eventId: 'e2');
      final e3 = makeEvent(runId: 'run-A', eventId: 'e3');

      await runStore.append(e1);
      await runStore.append(e2);
      await runStore.append(e3);

      final result = await runStore.readAll('run-A');
      final events = (result as Success).value;
      expect(events.length, 3);
      expect(events[0].sequence, 1);
      expect(events[1].sequence, 2);
      expect(events[2].sequence, 3);
    });

    test('duplicate idempotency key returns existing', () async {
      final e1 = makeEvent(
          runId: 'run-B', eventId: 'e1', idempotencyKey: 'idem-1');
      final e2 = makeEvent(
          runId: 'run-B', eventId: 'e2', idempotencyKey: 'idem-1');

      await runStore.append(e1);
      final r2 = await runStore.append(e2);

      final stored = (r2 as Success).value;
      expect(stored.eventId, 'e1'); // Returns existing, not new

      final all = await runStore.readAll('run-B');
      expect((all as Success).value.length, 1);
    });
  });

  group('Hash chain validation', () {
    test('intact chain validates', () async {
      await runStore.append(makeEvent(runId: 'run-C', eventId: 'a'));
      await runStore.append(makeEvent(runId: 'run-C', eventId: 'b'));

      final result = await runStore.validateChain('run-C');
      expect((result as Success).value, isTrue);
    });

    test('empty run validates', () async {
      final result = await runStore.validateChain('nonexistent');
      expect((result as Success).value, isTrue);
    });
  });

  group('Truncation recovery', () {
    test('truncated final line is discarded', () async {
      await runStore.append(makeEvent(runId: 'run-D', eventId: 'good'));

      // Simulate crash: append garbage
      final file = File('${tempDir.path}/run-D/events.jsonl');
      await file.writeAsString('{"event_id":"trunc',
          mode: FileMode.append);

      final result = await runStore.readAll('run-D');
      final events = (result as Success).value;
      expect(events.length, 1);
      expect(events[0].eventId, 'good');
    });
  });

  group('Provider interruption simulation', () {
    test('interrupted run has events up to interruption point', () async {
      // Simulate: run starts, provider responds, then disconnects
      await runStore.append(makeEvent(
        runId: 'run-int',
        eventId: 'started',
        eventType: 'run_started',
      ));
      await runStore.append(makeEvent(
        runId: 'run-int',
        eventId: 'provider-chunk',
        eventType: 'text_delta',
      ));
      // Provider disconnects here - no more events appended

      final result = await runStore.readAll('run-int');
      final events = (result as Success).value;
      expect(events.length, 2);
      expect(events.last.eventType, 'text_delta');

      // Chain is still valid (no corruption)
      final chain = await runStore.validateChain('run-int');
      expect((chain as Success).value, isTrue);
    });

    test('resume appends new events after interruption', () async {
      await runStore.append(makeEvent(
        runId: 'run-resume',
        eventId: 'before-crash',
        eventType: 'run_started',
      ));

      // Simulate restart: append resume event
      await runStore.append(makeEvent(
        runId: 'run-resume',
        eventId: 'after-resume',
        eventType: 'run_resumed',
      ));

      final result = await runStore.readAll('run-resume');
      final events = (result as Success).value;
      expect(events.length, 2);
      expect(events[1].eventType, 'run_resumed');
      expect(events[1].sequence, 2);
    });
  });

  group('listRuns', () {
    test('lists all runs with events', () async {
      await runStore.append(makeEvent(runId: 'run-X', eventId: 'x1'));
      await runStore.append(makeEvent(runId: 'run-Y', eventId: 'y1'));

      final result = await runStore.listRuns();
      final runs = (result as Success).value;
      expect(runs, containsAll(['run-X', 'run-Y']));
    });
  });

  group('readFrom', () {
    test('reads events from a given sequence', () async {
      await runStore.append(makeEvent(runId: 'run-F', eventId: 'f1'));
      await runStore.append(makeEvent(runId: 'run-F', eventId: 'f2'));
      await runStore.append(makeEvent(runId: 'run-F', eventId: 'f3'));

      final result = await runStore.readFrom('run-F', 2);
      final events = (result as Success).value;
      expect(events.length, 2);
      expect(events[0].eventId, 'f2');
      expect(events[1].eventId, 'f3');
    });
  });
}
