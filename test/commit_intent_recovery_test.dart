import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

void main() {
  late Directory tempDir;
  late LocalMutationJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('intent_recovery_test_');
    journal = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: 'proj-1', rootPath: tempDir.path),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  CommitIntent makeIntent({
    String id = 'intent-1',
    String idempotencyKey = 'idem-1',
  }) =>
      CommitIntent(
        id: id,
        projectId: 'proj-1',
        candidateId: 'cand-1',
        targetPath: '章节内容/第一章.md',
        baseRevision: 3,
        expectedRevision: 4,
        expectedContentHash: 'a' * 64,
        idempotencyKey: idempotencyKey,
      );

  RecoveryOutcome makeOutcome(
    String intentId, {
    RecoveryOutcomeType outcome = RecoveryOutcomeType.intentAbandoned,
  }) =>
      RecoveryOutcome(
        id: 'outcome-$intentId',
        intentId: intentId,
        projectId: 'proj-1',
        targetPath: '章节内容/第一章.md',
        outcome: outcome,
        resolvedAt: DateTime.utc(2026, 8, 3),
        reason: 'test recovery',
      );

  group('commit intent persistence', () {
    test('intent is persisted as a commit_intent event before any target write',
        () async {
      await journal.appendCommitIntent(makeIntent());

      final events = await journal.readAll();
      expect(events, hasLength(1));
      expect(events.single.eventType, 'commit_intent');

      final intent = CommitIntent.fromJson(events.single.payload);
      expect(intent, makeIntent());

      // Durability: a fresh journal instance reads the same intent back.
      final reopened = LocalMutationJournal.projectOwned(
        ResolvedProjectRoot(projectId: 'proj-1', rootPath: tempDir.path),
      );
      final reloaded = await reopened.readAll();
      expect(reloaded, hasLength(1));
      expect(reloaded.single.eventType, 'commit_intent');
    });

    test('re-appending the same intent is idempotent', () async {
      await journal.appendCommitIntent(makeIntent());
      final second = await journal.appendCommitIntent(makeIntent());

      expect(second.duplicate, isTrue);
      expect(await journal.readAll(), hasLength(1));
    });

    test('unresolved intents are discovered', () async {
      await journal
          .appendCommitIntent(makeIntent(id: 'intent-a', idempotencyKey: 'idem-a'));
      await journal
          .appendCommitIntent(makeIntent(id: 'intent-b', idempotencyKey: 'idem-b'));

      final unresolved = await journal.readUnresolvedIntents();
      expect(unresolved.map((i) => i.id), containsAll(['intent-a', 'intent-b']));
    });
  });

  group('intent resolution', () {
    test('a matching receipt resolves the intent', () async {
      final intent = makeIntent();
      await journal.appendCommitIntent(intent);
      await journal.append(JournalEvent(
        eventId: 'evt-receipt-1',
        eventType: LocalMutationJournal.receiptEventType,
        aggregateId: 'cand-1',
        idempotencyKey: intent.idempotencyKey,
        payload: {
          'id': 'rcpt-1',
          'candidate_id': 'cand-1',
          'idempotency_key': intent.idempotencyKey,
        },
      ));

      expect(await journal.readUnresolvedIntents(), isEmpty);
    });

    test('an unrelated idempotency key does not resolve the intent', () async {
      final intent = makeIntent();
      await journal.appendCommitIntent(intent);
      await journal.append(JournalEvent(
        eventId: 'evt-receipt-other',
        eventType: LocalMutationJournal.receiptEventType,
        aggregateId: 'cand-other',
        idempotencyKey: 'other-key',
        payload: {'id': 'rcpt-other'},
      ));

      final unresolved = await journal.readUnresolvedIntents();
      expect(unresolved, hasLength(1));
      expect(unresolved.single.id, intent.id);
    });

    test('an explicit recovery outcome resolves the intent', () async {
      final intent = makeIntent();
      await journal.appendCommitIntent(intent);
      await journal.appendRecoveryOutcome(makeOutcome(intent.id));

      expect(await journal.readUnresolvedIntents(), isEmpty);
    });

    test('resolution never deletes the intent event', () async {
      final intent = makeIntent();
      await journal.appendCommitIntent(intent);
      await journal.appendRecoveryOutcome(makeOutcome(
        intent.id,
        outcome: RecoveryOutcomeType.receiptCompleted,
      ));

      final events = await journal.readAll();
      expect(
        events.where((e) => e.eventType == 'commit_intent'),
        hasLength(1),
      );
      expect(await journal.validateChain(), isTrue);
    });

    test('all recovery outcome types round-trip through the journal',
        () async {
      for (final outcome in RecoveryOutcomeType.values) {
        final intent = makeIntent(id: 'intent-${outcome.name}');
        await journal.appendCommitIntent(intent);
        await journal.appendRecoveryOutcome(makeOutcome(intent.id, outcome: outcome));
      }

      expect(await journal.readUnresolvedIntents(), isEmpty);
      expect(await journal.validateChain(), isTrue);
    });
  });
}
