import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';

void main() {
  late Directory tempDir;
  late LocalMutationJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('journal_test_');
    journal = LocalMutationJournal(basePath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  JournalEvent makeEvent({
    String? eventId,
    String eventType = 'candidate_proposed',
    String aggregateId = 'cand-001',
    Map<String, dynamic>? payload,
  }) {
    return JournalEvent(
      eventId: eventId ?? 'evt-${DateTime.now().microsecondsSinceEpoch}',
      eventType: eventType,
      aggregateId: aggregateId,
      payload: payload ?? {'key': 'value'},
    );
  }

  group('append and read order', () {
    test('appended events are read back in order', () async {
      final e1 = makeEvent(eventId: 'evt-1', eventType: 'proposed');
      final e2 = makeEvent(eventId: 'evt-2', eventType: 'approved');
      final e3 = makeEvent(eventId: 'evt-3', eventType: 'committed');

      await journal.append(e1);
      await journal.append(e2);
      await journal.append(e3);

      final events = await journal.readAll();
      expect(events.length, 3);
      expect(events[0].eventId, 'evt-1');
      expect(events[1].eventId, 'evt-2');
      expect(events[2].eventId, 'evt-3');
    });

    test('sequence numbers are monotonically increasing', () async {
      await journal.append(makeEvent(eventId: 'a'));
      await journal.append(makeEvent(eventId: 'b'));
      await journal.append(makeEvent(eventId: 'c'));

      final events = await journal.readAll();
      expect(events[0].sequence, 1);
      expect(events[1].sequence, 2);
      expect(events[2].sequence, 3);
    });

    test('each event carries schema_version 1', () async {
      await journal.append(makeEvent(eventId: 'x'));
      final events = await journal.readAll();
      expect(events[0].schemaVersion, 1);
    });
  });

  group('hash chain validation', () {
    test('first event has previous_event_hash of zeros', () async {
      await journal.append(makeEvent(eventId: 'first'));
      final events = await journal.readAll();
      expect(events[0].previousEventHash,
          '0000000000000000000000000000000000000000000000000000000000000000');
    });

    test('subsequent events chain to previous hash', () async {
      await journal.append(makeEvent(eventId: 'e1'));
      await journal.append(makeEvent(eventId: 'e2'));

      final events = await journal.readAll();
      expect(events[1].previousEventHash, isNot(equals(
          '0000000000000000000000000000000000000000000000000000000000000000')));
      expect(events[1].previousEventHash, hasLength(64));
    });

    test('validateChain returns true for intact journal', () async {
      await journal.append(makeEvent(eventId: 'a'));
      await journal.append(makeEvent(eventId: 'b'));
      await journal.append(makeEvent(eventId: 'c'));

      final valid = await journal.validateChain();
      expect(valid, isTrue);
    });

    test('validateChain detects corrupted middle line', () async {
      await journal.append(makeEvent(eventId: 'a'));
      await journal.append(makeEvent(eventId: 'b'));
      await journal.append(makeEvent(eventId: 'c'));

      // Corrupt the second line in events.jsonl
      final file = File('${tempDir.path}/events.jsonl');
      final lines = await file.readAsLines();
      final corrupted = jsonDecode(lines[1]) as Map<String, dynamic>;
      corrupted['event_type'] = 'TAMPERED';
      lines[1] = jsonEncode(corrupted);
      await file.writeAsString(lines.join('\n'));

      // Re-open journal to read corrupted state
      final journal2 = LocalMutationJournal(basePath: tempDir.path);
      final valid = await journal2.validateChain();
      expect(valid, isFalse);
    });
  });

  group('truncated final line recovery', () {
    test('truncated last line is discarded, earlier events survive',
        () async {
      await journal.append(makeEvent(eventId: 'good-1'));
      await journal.append(makeEvent(eventId: 'good-2'));

      // Append garbage (simulating crash mid-write)
      final file = File('${tempDir.path}/events.jsonl');
      await file.writeAsString(
        '{"schema_version":1,"sequence":3,"event_id":"bad',
        mode: FileMode.append,
      );

      final journal2 = LocalMutationJournal(basePath: tempDir.path);
      final events = await journal2.readAll();
      expect(events.length, 2);
      expect(events[0].eventId, 'good-1');
      expect(events[1].eventId, 'good-2');
    });
  });

  group('duplicate event_id', () {
    test('duplicate event_id returns existing record without appending',
        () async {
      final event = makeEvent(eventId: 'dup-1', eventType: 'proposed');
      final result1 = await journal.append(event);
      final result2 = await journal.append(event);

      expect(result1.duplicate, isFalse);
      expect(result2.duplicate, isTrue);
      expect(result2.event.eventId, 'dup-1');

      final events = await journal.readAll();
      expect(events.length, 1);
    });
  });

  group('duplicate idempotency key', () {
    test('same idempotency key returns existing without appending', () async {
      final e1 = JournalEvent(
        eventId: 'evt-a',
        eventType: 'commit',
        aggregateId: 'cand-1',
        payload: {'data': 'first'},
        idempotencyKey: 'idem-001',
      );
      final e2 = JournalEvent(
        eventId: 'evt-b',
        eventType: 'commit',
        aggregateId: 'cand-1',
        payload: {'data': 'second'},
        idempotencyKey: 'idem-001',
      );

      final r1 = await journal.append(e1);
      final r2 = await journal.append(e2);

      expect(r1.duplicate, isFalse);
      expect(r2.duplicate, isTrue);
      expect(r2.event.eventId, 'evt-a');

      final events = await journal.readAll();
      expect(events.length, 1);
    });
  });

  group('serialized concurrent append', () {
    test('concurrent appends are serialized with an intact chain', () async {
      final futures = [
        for (var i = 0; i < 15; i++)
          journal.append(JournalEvent(
            eventId: 'evt-$i',
            eventType: 'proposed',
            aggregateId: 'cand-$i',
            payload: {'i': i},
          )),
      ];
      final results = await Future.wait(futures);
      expect(results.every((r) => !r.duplicate), isTrue);

      final events = await journal.readAll();
      expect(events.length, 15);
      expect(
        events.map((e) => e.sequence).toList(),
        List.generate(15, (i) => i + 1),
      );
      expect(await journal.validateChain(), isTrue);
    });
  });

  group('read by aggregate', () {
    test('readByAggregate filters correctly', () async {
      await journal.append(
          makeEvent(eventId: 'e1', aggregateId: 'cand-A'));
      await journal.append(
          makeEvent(eventId: 'e2', aggregateId: 'cand-B'));
      await journal.append(
          makeEvent(eventId: 'e3', aggregateId: 'cand-A'));

      final result = await journal.readByAggregate('cand-A');
      expect(result.length, 2);
      expect(result[0].eventId, 'e1');
      expect(result[1].eventId, 'e3');
    });
  });

  group('empty journal', () {
    test('readAll on empty journal returns empty list', () async {
      final events = await journal.readAll();
      expect(events, isEmpty);
    });

    test('validateChain on empty journal returns true', () async {
      final valid = await journal.validateChain();
      expect(valid, isTrue);
    });
  });
}
