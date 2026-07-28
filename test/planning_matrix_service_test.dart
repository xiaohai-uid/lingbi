import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/planning_matrix_service.dart';

void main() {
  late Directory tempDir;
  late PlanningMatrixService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_planning_');
    service = PlanningMatrixService(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('scene card CRUD', () {
    test('creates a scene card with stable ID and persists it', () async {
      final card = await service.createCard(
        projectId: 'proj-1',
        title: 'Opening battle',
        povCharacter: 'character:ye-lan',
        location: 'location:qing-wu',
        subplot: 'main-quest',
        chapterIndex: 1,
      );

      expect(card.id, isNotEmpty);
      expect(card.title, 'Opening battle');
      expect(card.revision, 1);

      final loaded = await service.getCards('proj-1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, card.id);
    });

    test('updates a card with optimistic revision check', () async {
      final card = await service.createCard(
        projectId: 'proj-1',
        title: 'Scene A',
        chapterIndex: 1,
      );

      final updated = await service.updateCard(
        projectId: 'proj-1',
        cardId: card.id,
        expectedRevision: 1,
        title: 'Scene A revised',
      );

      expect(updated.revision, 2);
      expect(updated.title, 'Scene A revised');
    });

    test('rejects update with stale revision', () async {
      final card = await service.createCard(
        projectId: 'proj-1',
        title: 'Scene A',
        chapterIndex: 1,
      );
      await service.updateCard(
        projectId: 'proj-1',
        cardId: card.id,
        expectedRevision: 1,
        title: 'Scene A v2',
      );

      expect(
        () => service.updateCard(
          projectId: 'proj-1',
          cardId: card.id,
          expectedRevision: 1,
          title: 'Stale update',
        ),
        throwsA(isA<RevisionConflictException>()),
      );
    });
  });

  group('filtering and reorder', () {
    test('filters by POV, location, and subplot', () async {
      await service.createCard(
        projectId: 'proj-1',
        title: 'Battle',
        povCharacter: 'character:ye-lan',
        location: 'location:qing-wu',
        subplot: 'main-quest',
        chapterIndex: 1,
      );
      await service.createCard(
        projectId: 'proj-1',
        title: 'Romance',
        povCharacter: 'character:gu-chen',
        location: 'location:mountain',
        subplot: 'romance',
        chapterIndex: 2,
      );
      await service.createCard(
        projectId: 'proj-1',
        title: 'Battle 2',
        povCharacter: 'character:ye-lan',
        location: 'location:mountain',
        subplot: 'main-quest',
        chapterIndex: 3,
      );

      final byPov = await service.getCards(
        'proj-1',
        filter: const SceneFilter(povCharacter: 'character:ye-lan'),
      );
      expect(byPov, hasLength(2));

      final byLocation = await service.getCards(
        'proj-1',
        filter: const SceneFilter(location: 'location:mountain'),
      );
      expect(byLocation, hasLength(2));

      final bySubplot = await service.getCards(
        'proj-1',
        filter: const SceneFilter(subplot: 'romance'),
      );
      expect(bySubplot, hasLength(1));
      expect(bySubplot.first.title, 'Romance');
    });

    test('drag reorder updates chapter indices transactionally', () async {
      final c1 = await service.createCard(
        projectId: 'proj-1',
        title: 'First',
        chapterIndex: 1,
      );
      final c2 = await service.createCard(
        projectId: 'proj-1',
        title: 'Second',
        chapterIndex: 2,
      );
      final c3 = await service.createCard(
        projectId: 'proj-1',
        title: 'Third',
        chapterIndex: 3,
      );

      // Move c3 to position 1
      await service.reorder(
        projectId: 'proj-1',
        orderedIds: [c3.id, c1.id, c2.id],
      );

      final cards = await service.getCards('proj-1');
      expect(cards[0].id, c3.id);
      expect(cards[0].chapterIndex, 1);
      expect(cards[1].id, c1.id);
      expect(cards[1].chapterIndex, 2);
      expect(cards[2].id, c2.id);
      expect(cards[2].chapterIndex, 3);
    });

    test('undo restores previous order', () async {
      final c1 = await service.createCard(
        projectId: 'proj-1',
        title: 'First',
        chapterIndex: 1,
      );
      final c2 = await service.createCard(
        projectId: 'proj-1',
        title: 'Second',
        chapterIndex: 2,
      );

      await service.reorder(
        projectId: 'proj-1',
        orderedIds: [c2.id, c1.id],
      );
      await service.undoReorder('proj-1');

      final cards = await service.getCards('proj-1');
      expect(cards[0].id, c1.id);
      expect(cards[1].id, c2.id);
    });
  });

  group('100-chapter scale', () {
    test('handles 100 cards with filtering and reorder', () async {
      for (var i = 0; i < 100; i++) {
        await service.createCard(
          projectId: 'proj-big',
          title: 'Chapter ${i + 1}',
          povCharacter: i.isEven ? 'character:a' : 'character:b',
          chapterIndex: i + 1,
        );
      }

      final all = await service.getCards('proj-big');
      expect(all, hasLength(100));

      final filtered = await service.getCards(
        'proj-big',
        filter: const SceneFilter(povCharacter: 'character:a'),
      );
      expect(filtered, hasLength(50));

      // Reverse order
      final reversed = all.reversed.map((c) => c.id).toList();
      await service.reorder(projectId: 'proj-big', orderedIds: reversed);

      final afterReorder = await service.getCards('proj-big');
      expect(afterReorder.first.title, 'Chapter 100');
      expect(afterReorder.last.title, 'Chapter 1');
    });
  });
}
