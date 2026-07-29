import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/continuity/continuity_gate.dart';

void main() {
  group('pre-generation constraints', () {
    test('emits hard constraints from confirmed story graph facts', () {
      const gate = ContinuityGate();
      final facts = [
        const ContinuityFact(
          id: 'fact-1',
          entityId: 'character:ye-lan',
          claim: 'Ye Lan lost her left arm in chapter 12',
          validFromChapter: 12,
          validToChapter: null,
          confirmed: true,
          severity: ContinuitySeverity.critical,
        ),
        const ContinuityFact(
          id: 'fact-2',
          entityId: 'location:qing-wu',
          claim: 'Qingwu City is destroyed in chapter 30',
          validFromChapter: 30,
          validToChapter: null,
          confirmed: true,
          severity: ContinuitySeverity.high,
        ),
        const ContinuityFact(
          id: 'fact-3',
          entityId: 'character:gu-chen',
          claim: 'Gu Chen might be a traitor (unconfirmed)',
          validFromChapter: 5,
          validToChapter: null,
          confirmed: false,
          severity: ContinuitySeverity.low,
        ),
      ];

      final constraints = gate.preGenerationConstraints(
        facts: facts,
        targetChapter: 35,
      );

      // Only confirmed facts that are still valid at chapter 35
      expect(constraints, hasLength(2));
      expect(constraints[0].factId, 'fact-1');
      expect(constraints[0].blocking, isTrue);
      expect(constraints[1].factId, 'fact-2');
      // Unconfirmed fact is not a hard constraint
      expect(constraints.where((c) => c.factId == 'fact-3'), isEmpty);
    });

    test('expired facts do not produce constraints', () {
      const gate = ContinuityGate();
      final facts = [
        const ContinuityFact(
          id: 'fact-old',
          entityId: 'character:hero',
          claim: 'Hero was weak',
          validFromChapter: 1,
          validToChapter: 10,
          confirmed: true,
          severity: ContinuitySeverity.critical,
        ),
      ];

      final constraints = gate.preGenerationConstraints(
        facts: facts,
        targetChapter: 50,
      );

      expect(constraints, isEmpty);
    });
  });

  group('post-generation issue detection', () {
    test('detects contradiction with confirmed critical fact', () {
      const gate = ContinuityGate();
      final facts = [
        const ContinuityFact(
          id: 'fact-arm',
          entityId: 'character:ye-lan',
          claim: 'Ye Lan lost her left arm in chapter 12',
          validFromChapter: 12,
          validToChapter: null,
          confirmed: true,
          severity: ContinuitySeverity.critical,
        ),
      ];
      const generatedText = '叶澜伸出左手接住了飞剑。';

      final issues = gate.detectIssues(
        generatedText: generatedText,
        facts: facts,
        chapter: 20,
        entityMentions: [
          const EntityMention(entityId: 'character:ye-lan', start: 0, end: 2),
        ],
      );

      expect(issues, hasLength(1));
      expect(issues.first.factId, 'fact-arm');
      expect(issues.first.severity, ContinuitySeverity.critical);
      expect(issues.first.requiresOverride, isTrue);
      expect(issues.first.evidence, contains('左手'));
    });

    test('does not flag text that is consistent with facts', () {
      const gate = ContinuityGate();
      final facts = [
        const ContinuityFact(
          id: 'fact-arm',
          entityId: 'character:ye-lan',
          claim: 'Ye Lan lost her left arm in chapter 12',
          validFromChapter: 12,
          validToChapter: null,
          confirmed: true,
          severity: ContinuitySeverity.critical,
        ),
      ];
      const generatedText = '叶澜用右手握剑，空荡的左袖随风飘动。';

      final issues = gate.detectIssues(
        generatedText: generatedText,
        facts: facts,
        chapter: 20,
        entityMentions: [
          const EntityMention(entityId: 'character:ye-lan', start: 0, end: 2),
        ],
      );

      expect(issues, isEmpty);
    });

    test('high-risk issues block adoption without explicit override', () {
      const gate = ContinuityGate();
      final issues = [
        const ContinuityIssue(
          factId: 'fact-1',
          entityId: 'character:hero',
          description: 'Contradicts established death',
          evidence: 'hero walks in',
          severity: ContinuitySeverity.critical,
          proposedAction: ContinuityAction.blockAdoption,
          requiresOverride: true,
        ),
      ];

      final decision = gate.adoptionDecision(issues);
      expect(decision.canAdopt, isFalse);
      expect(decision.blockingIssues, hasLength(1));

      final overridden = gate.adoptionDecision(
        issues,
        overriddenFactIds: {'fact-1'},
      );
      expect(overridden.canAdopt, isTrue);
    });

    test('low-severity issues produce warnings but do not block', () {
      const gate = ContinuityGate();
      final issues = [
        const ContinuityIssue(
          factId: 'fact-2',
          entityId: 'location:city',
          description: 'Minor timeline inconsistency',
          evidence: 'market open at night',
          severity: ContinuitySeverity.low,
          proposedAction: ContinuityAction.warn,
          requiresOverride: false,
        ),
      ];

      final decision = gate.adoptionDecision(issues);
      expect(decision.canAdopt, isTrue);
      expect(decision.warnings, hasLength(1));
    });
  });

  group('false positive budget', () {
    test('invention vs contradiction distinction', () {
      const gate = ContinuityGate();
      // A new fact not in the graph is an invention, not a contradiction
      final facts = <ContinuityFact>[];
      const generatedText = '叶澜突然飞上了天空。';

      final issues = gate.detectIssues(
        generatedText: generatedText,
        facts: facts,
        chapter: 5,
        entityMentions: [
          const EntityMention(entityId: 'character:ye-lan', start: 0, end: 2),
        ],
      );

      // No facts to contradict, so no issues
      expect(issues, isEmpty);
    });
  });
}
