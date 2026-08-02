import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/runtime/run_models.dart';
import 'package:lingbi/domain/runtime/run_transitions.dart';

void main() {
  group('RunStatus transitions - legal', () {
    test('queued → running', () {
      final r = transitionRun(RunStatus.queued, RunTrigger.start);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.running);
    });

    test('queued → cancelled', () {
      final r = transitionRun(RunStatus.queued, RunTrigger.cancel);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.cancelled);
    });

    test('running → waitingProvider', () {
      final r = transitionRun(RunStatus.running, RunTrigger.awaitProvider);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.waitingProvider);
    });

    test('running → waitingApproval', () {
      final r = transitionRun(RunStatus.running, RunTrigger.awaitApproval);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.waitingApproval);
    });

    test('running → committing', () {
      final r = transitionRun(RunStatus.running, RunTrigger.beginCommit);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.committing);
    });

    test('running → failed', () {
      final r = transitionRun(RunStatus.running, RunTrigger.fail);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.failed);
    });

    test('running → cancelled', () {
      final r = transitionRun(RunStatus.running, RunTrigger.cancel);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.cancelled);
    });

    test('running → interrupted', () {
      final r = transitionRun(RunStatus.running, RunTrigger.interrupt);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.interrupted);
    });

    test('waitingProvider → running', () {
      final r = transitionRun(RunStatus.waitingProvider, RunTrigger.resume);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.running);
    });

    test('waitingProvider → failed', () {
      final r = transitionRun(RunStatus.waitingProvider, RunTrigger.fail);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.failed);
    });

    test('waitingProvider → cancelled', () {
      final r = transitionRun(RunStatus.waitingProvider, RunTrigger.cancel);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.cancelled);
    });

    test('waitingProvider → interrupted', () {
      final r = transitionRun(RunStatus.waitingProvider, RunTrigger.interrupt);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.interrupted);
    });

    test('waitingApproval → running', () {
      final r = transitionRun(RunStatus.waitingApproval, RunTrigger.resume);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.running);
    });

    test('waitingApproval → committing', () {
      final r = transitionRun(RunStatus.waitingApproval, RunTrigger.beginCommit);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.committing);
    });

    test('waitingApproval → cancelled', () {
      final r = transitionRun(RunStatus.waitingApproval, RunTrigger.cancel);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.cancelled);
    });

    test('waitingApproval → interrupted', () {
      final r = transitionRun(RunStatus.waitingApproval, RunTrigger.interrupt);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.interrupted);
    });

    test('committing → succeeded', () {
      final r = transitionRun(RunStatus.committing, RunTrigger.succeed);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.succeeded);
    });

    test('committing → failed', () {
      final r = transitionRun(RunStatus.committing, RunTrigger.fail);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.failed);
    });

    test('committing → interrupted', () {
      final r = transitionRun(RunStatus.committing, RunTrigger.interrupt);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.interrupted);
    });

    test('interrupted → running', () {
      final r = transitionRun(RunStatus.interrupted, RunTrigger.resume);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.running);
    });

    test('interrupted → failed', () {
      final r = transitionRun(RunStatus.interrupted, RunTrigger.fail);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.failed);
    });

    test('interrupted → cancelled', () {
      final r = transitionRun(RunStatus.interrupted, RunTrigger.cancel);
      expect(r.success, isTrue);
      expect(r.status, RunStatus.cancelled);
    });
  });

  group('RunStatus transitions - terminal states reject all', () {
    for (final terminal in [
      RunStatus.succeeded,
      RunStatus.failed,
      RunStatus.cancelled,
    ]) {
      for (final trigger in RunTrigger.values) {
        test('${terminal.name} + ${trigger.name} is rejected', () {
          final r = transitionRun(terminal, trigger);
          expect(r.success, isFalse);
          expect(r.error, contains('ILLEGAL_TRANSITION'));
        });
      }
    }
  });

  group('RunStatus transitions - illegal non-terminal', () {
    test('queued → committing is illegal', () {
      final r = transitionRun(RunStatus.queued, RunTrigger.beginCommit);
      expect(r.success, isFalse);
    });

    test('queued → succeeded is illegal', () {
      final r = transitionRun(RunStatus.queued, RunTrigger.succeed);
      expect(r.success, isFalse);
    });

    test('committing → running is illegal', () {
      final r = transitionRun(RunStatus.committing, RunTrigger.resume);
      expect(r.success, isFalse);
    });
  });

  group('RunStatus properties', () {
    test('has exactly 9 values', () {
      expect(RunStatus.values.length, 9);
    });

    test('terminal states are terminal', () {
      expect(RunStatus.succeeded.isTerminal, isTrue);
      expect(RunStatus.failed.isTerminal, isTrue);
      expect(RunStatus.cancelled.isTerminal, isTrue);
    });

    test('non-terminal states are not terminal', () {
      expect(RunStatus.queued.isTerminal, isFalse);
      expect(RunStatus.running.isTerminal, isFalse);
      expect(RunStatus.interrupted.isTerminal, isFalse);
    });
  });
}
