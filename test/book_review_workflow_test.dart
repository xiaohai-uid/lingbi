import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/workflows/review/book_review_workflow.dart';
import 'package:lingbi/workflows/review/change_plan.dart';

void main() {
  late Directory tempDir;
  late BookReviewWorkflow workflow;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_review_');
    workflow = BookReviewWorkflow(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('evidence-linked findings', () {
    test('each finding carries source location and evidence text', () {
      final findings = [
        ReviewFinding(
          id: 'f-1',
          mode: ReviewMode.developmental,
          severity: FindingSeverity.high,
          description: 'Protagonist motivation unclear in act 2',
          evidence: 'Chapter 15: "He went to the mountain." No reason given.',
          sourceDocumentId: 'doc-ch15',
          sourceRange: const TextRange(start: 0, end: 42),
          suggestedAction: 'Add internal monologue explaining the quest',
        ),
        ReviewFinding(
          id: 'f-2',
          mode: ReviewMode.line,
          severity: FindingSeverity.medium,
          description: 'Repetitive sentence structure',
          evidence: 'Paragraph 3: five consecutive "He" subjects',
          sourceDocumentId: 'doc-ch03',
          sourceRange: const TextRange(start: 100, end: 300),
          suggestedAction: 'Vary sentence openings',
        ),
      ];

      final report = workflow.buildReport(
        projectId: 'proj-1',
        findings: findings,
      );

      expect(report.findings, hasLength(2));
      expect(report.findings.first.evidence, isNotEmpty);
      expect(report.findings.first.sourceDocumentId, 'doc-ch15');
      expect(report.summary.totalFindings, 2);
      expect(report.summary.bySeverity[FindingSeverity.high], 1);
    });

    test('review modes are distinct and selectable', () {
      expect(ReviewMode.values, containsAll([
        ReviewMode.developmental,
        ReviewMode.line,
        ReviewMode.dialogue,
        ReviewMode.copy,
        ReviewMode.custom,
      ]));
    });
  });

  group('selective diff application', () {
    test('applies only selected changes and preserves the rest', () async {
      final original = 'The hero walked slowly to the gate.';
      final changes = [
        ProposedChange(
          id: 'c-1',
          findingId: 'f-1',
          documentId: 'doc-1',
          originalText: 'walked slowly',
          replacementText: 'strode',
          range: const TextRange(start: 9, end: 22),
        ),
        ProposedChange(
          id: 'c-2',
          findingId: 'f-2',
          documentId: 'doc-1',
          originalText: 'the gate',
          replacementText: 'the ancient gate',
          range: const TextRange(start: 27, end: 35),
        ),
      ];

      final plan = ChangePlan(
        projectId: 'proj-1',
        changes: changes,
      );

      // Apply only c-1
      final result = workflow.applyChanges(
        originalText: original,
        plan: plan,
        selectedChangeIds: {'c-1'},
      );

      expect(result.text, 'The hero strode to the gate.');
      expect(result.appliedIds, ['c-1']);
      expect(result.skippedIds, ['c-2']);
    });

    test('conflicting ranges are detected and rejected', () {
      final original = 'AAAA BBBB CCCC';
      final changes = [
        ProposedChange(
          id: 'c-1',
          findingId: 'f-1',
          documentId: 'doc-1',
          originalText: 'AAAA BBBB',
          replacementText: 'XXXX',
          range: const TextRange(start: 0, end: 9),
        ),
        ProposedChange(
          id: 'c-2',
          findingId: 'f-2',
          documentId: 'doc-1',
          originalText: 'BBBB CCCC',
          replacementText: 'YYYY',
          range: const TextRange(start: 5, end: 14),
        ),
      ];

      final plan = ChangePlan(projectId: 'proj-1', changes: changes);

      final result = workflow.applyChanges(
        originalText: original,
        plan: plan,
        selectedChangeIds: {'c-1', 'c-2'},
      );

      // Overlapping ranges: only the first (by position) is applied
      expect(result.appliedIds, ['c-1']);
      expect(result.conflicts, contains('c-2'));
    });
  });

  group('change propagation safety', () {
    test('generates ordered impact plan from canon change', () {
      final canonChange = CanonChange(
        entityId: 'character:ye-lan',
        field: 'status',
        oldValue: 'alive',
        newValue: 'dead',
        sourceChapter: 50,
      );

      final affectedDocs = [
        AffectedDocument(documentId: 'doc-ch51', mentionCount: 3),
        AffectedDocument(documentId: 'doc-ch52', mentionCount: 1),
        AffectedDocument(documentId: 'doc-ch55', mentionCount: 5),
      ];

      final impactPlan = workflow.buildImpactPlan(
        canonChange: canonChange,
        affectedDocuments: affectedDocs,
      );

      expect(impactPlan.steps, hasLength(3));
      // Ordered by chapter proximity to source
      expect(impactPlan.steps.first.documentId, 'doc-ch51');
      expect(impactPlan.steps.last.documentId, 'doc-ch55');
      expect(impactPlan.requiresConfirmation, isTrue);
    });

    test('never performs silent batch edits', () {
      final canonChange = CanonChange(
        entityId: 'location:city',
        field: 'name',
        oldValue: 'Qingwu',
        newValue: 'New Qingwu',
        sourceChapter: 1,
      );

      final impactPlan = workflow.buildImpactPlan(
        canonChange: canonChange,
        affectedDocuments: [
          AffectedDocument(documentId: 'doc-1', mentionCount: 10),
        ],
      );

      // Every step requires explicit confirmation
      for (final step in impactPlan.steps) {
        expect(step.autoApply, isFalse);
      }
    });
  });

  group('undo', () {
    test('reverts applied changes to original text', () async {
      final original = 'The hero walked slowly.';
      final changes = [
        ProposedChange(
          id: 'c-1',
          findingId: 'f-1',
          documentId: 'doc-1',
          originalText: 'walked slowly',
          replacementText: 'ran',
          range: const TextRange(start: 9, end: 22),
        ),
      ];
      final plan = ChangePlan(projectId: 'proj-1', changes: changes);

      final result = workflow.applyChanges(
        originalText: original,
        plan: plan,
        selectedChangeIds: {'c-1'},
      );
      expect(result.text, 'The hero ran.');

      final reverted = workflow.undoChanges(result);
      expect(reverted, original);
    });
  });
}
