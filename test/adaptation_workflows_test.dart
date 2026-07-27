import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/workflows/adaptation/short_story_workflow.dart';
import 'package:lingbi/workflows/adaptation/drama_adaptation_workflow.dart';
import 'package:lingbi/workflows/adaptation/parallel_branch_workflow.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_adapt_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('short story workflow', () {
    test('derives a short story plan from project assets', () async {
      final workflow = ShortStoryWorkflow(storageDir: tempDir.path);
      final plan = await workflow.derive(
        projectId: 'proj-1',
        sourceAssets: const AdaptationSource(
          protagonist: 'Ye Lan',
          coreConflict: 'Revenge for the fallen northern border',
          worldRule: 'Martial arts cultivation system',
          theme: 'Sacrifice and redemption',
        ),
        targetLength: 8000,
      );

      expect(plan.id, isNotEmpty);
      expect(plan.structure, isNotEmpty);
      expect(plan.structure.first.beat, isNotEmpty);
      expect(plan.targetLength, 8000);
      expect(plan.derivedFrom, 'proj-1');
    });

    test('preserves stable character identity across adaptation', () async {
      final workflow = ShortStoryWorkflow(storageDir: tempDir.path);
      final plan = await workflow.derive(
        projectId: 'proj-1',
        sourceAssets: const AdaptationSource(
          protagonist: 'Ye Lan',
          coreConflict: 'Lost arm, seeks justice',
          worldRule: 'Night watch guards the city',
          theme: 'Perseverance',
        ),
        targetLength: 5000,
      );

      // Character identity is preserved
      expect(plan.characterIdentity.protagonist, 'Ye Lan');
      expect(plan.characterIdentity.coreTrait, isNotEmpty);
    });
  });

  group('drama adaptation workflow', () {
    test('converts story beats into scene/shot structure', () async {
      final workflow = DramaAdaptationWorkflow(storageDir: tempDir.path);
      final result = await workflow.adapt(
        projectId: 'proj-1',
        sourceBeats: const [
          StoryBeat(id: 'b1', chapter: 1, summary: 'Ye Lan enters the city'),
          StoryBeat(id: 'b2', chapter: 1, summary: 'Confrontation at the gate'),
          StoryBeat(id: 'b3', chapter: 2, summary: 'Night watch briefing'),
        ],
        episodeTarget: 1,
      );

      expect(result.episodes, hasLength(1));
      expect(result.episodes.first.scenes, isNotEmpty);
      expect(result.episodes.first.scenes.first.shots, isNotEmpty);
      // Traceability: each shot links back to a source beat
      for (final scene in result.episodes.first.scenes) {
        for (final shot in scene.shots) {
          expect(shot.sourceBeatId, isNotEmpty);
        }
      }
    });

    test('export produces structured output', () async {
      final workflow = DramaAdaptationWorkflow(storageDir: tempDir.path);
      final result = await workflow.adapt(
        projectId: 'proj-1',
        sourceBeats: const [
          StoryBeat(id: 'b1', chapter: 1, summary: 'Opening scene'),
        ],
        episodeTarget: 1,
      );

      final exported = workflow.export(result);
      expect(exported, contains('Episode 1'));
      expect(exported, contains('Scene'));
      expect(exported, contains('Shot'));
    });
  });

  group('parallel branch workflow', () {
    test('creates a reversible branch from a divergence point', () async {
      final workflow = ParallelBranchWorkflow(storageDir: tempDir.path);
      final branch = await workflow.createBranch(
        projectId: 'proj-1',
        divergenceChapter: 10,
        branchName: 'what-if-gu-chen-betrays',
        premise: 'Gu Chen reveals himself as a traitor in chapter 10',
      );

      expect(branch.id, isNotEmpty);
      expect(branch.divergenceChapter, 10);
      expect(branch.isReversible, isTrue);
      expect(branch.status, BranchStatus.active);
    });

    test('reverting a branch restores the original timeline', () async {
      final workflow = ParallelBranchWorkflow(storageDir: tempDir.path);
      final branch = await workflow.createBranch(
        projectId: 'proj-1',
        divergenceChapter: 5,
        branchName: 'alt-ending',
        premise: 'The city falls',
      );

      final reverted = await workflow.revertBranch(branch.id);
      expect(reverted.status, BranchStatus.reverted);
      expect(reverted.revertedAt, isNotNull);
    });

    test('branches are isolated and do not affect the main timeline', () async {
      final workflow = ParallelBranchWorkflow(storageDir: tempDir.path);
      await workflow.createBranch(
        projectId: 'proj-1',
        divergenceChapter: 3,
        branchName: 'branch-a',
        premise: 'Alt A',
      );
      await workflow.createBranch(
        projectId: 'proj-1',
        divergenceChapter: 7,
        branchName: 'branch-b',
        premise: 'Alt B',
      );

      final branches = await workflow.listBranches('proj-1');
      expect(branches, hasLength(2));
      // Main timeline is unaffected
      final mainTimeline = await workflow.getMainTimeline('proj-1');
      expect(mainTimeline.activeBranches, isEmpty);
    });
  });
}
