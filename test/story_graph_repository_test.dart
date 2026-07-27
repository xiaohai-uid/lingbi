import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/modules/story_graph/story_graph.dart';
import 'package:lingbi/modules/story_graph/story_graph_repository.dart';

void main() {
  late Directory tempDir;
  late StoryGraphRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_story_graph_');
    repository = StoryGraphRepository(rootDirectory: tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('aliases identify one stable entity after persistence', () async {
    final graph = StoryGraph.empty('project-1').withEntity(
      const StoryEntity(
        id: 'character:ye-lan',
        type: StoryEntityType.character,
        canonicalName: '叶澜',
        aliases: ['阿澜', '小叶'],
      ),
    );

    await repository.save(graph);
    final restored = await repository.load('project-1');

    expect(restored.findEntity('叶澜')?.id, 'character:ye-lan');
    expect(restored.findEntity('阿澜')?.id, 'character:ye-lan');
    expect(restored.findEntity('小叶')?.id, 'character:ye-lan');
  });

  test('temporal query returns the fact valid in that chapter', () async {
    var graph = StoryGraph.empty('project-1').withEntity(
      const StoryEntity(
        id: 'character:ye-lan',
        type: StoryEntityType.character,
        canonicalName: '叶澜',
      ),
    );
    graph = graph
        .withFact(
          const StoryFact(
            id: 'fact:realm:qi',
            entityId: 'character:ye-lan',
            predicate: '境界',
            value: '炼气',
            validFromChapter: 1,
            validToChapter: 4,
            sourceDocumentId: 'chapter-1',
            sourceRange: SourceRange(start: 12, end: 18),
            confidence: 0.98,
            confirmation: ConfirmationStatus.confirmed,
          ),
        )
        .withFact(
          const StoryFact(
            id: 'fact:realm:foundation',
            entityId: 'character:ye-lan',
            predicate: '境界',
            value: '筑基',
            validFromChapter: 5,
            sourceDocumentId: 'chapter-5',
            sourceRange: SourceRange(start: 20, end: 26),
            confidence: 0.96,
            confirmation: ConfirmationStatus.confirmed,
          ),
        );
    await repository.save(graph);

    expect(
      (await repository.factsAt('project-1', 4)).single.value,
      '炼气',
    );
    expect(
      (await repository.factsAt('project-1', 5)).single.value,
      '筑基',
    );
  });

  test('evidence and confirmation survive a stable JSON round trip', () async {
    final graph = StoryGraph.empty('project-1')
        .withEntity(
          const StoryEntity(
            id: 'character:ye-lan',
            type: StoryEntityType.character,
            canonicalName: '叶澜',
          ),
        )
        .withFact(
          const StoryFact(
            id: 'fact:scar',
            entityId: 'character:ye-lan',
            predicate: '特征',
            value: '左眉有疤',
            validFromChapter: 2,
            sourceDocumentId: 'chapter-2',
            sourceRange: SourceRange(start: 31, end: 36),
            confidence: 0.87,
            confirmation: ConfirmationStatus.pending,
          ),
        );

    await repository.save(graph);
    final pending = (await repository.load('project-1')).facts.single;

    expect(pending.sourceDocumentId, 'chapter-2');
    expect(pending.sourceRange, const SourceRange(start: 31, end: 36));
    expect(pending.confidence, 0.87);
    expect(pending.confirmation, ConfirmationStatus.pending);
    expect(await repository.factsAt('project-1', 2), isEmpty);

    await repository.confirm('project-1', pending.id);
    expect((await repository.factsAt('project-1', 2)).single.id, 'fact:scar');
  });

  test('relations require confirmation and can be retracted without erasure',
      () async {
    final graph = StoryGraph.empty('project-1')
        .withEntity(
          const StoryEntity(
            id: 'character:ye-lan',
            type: StoryEntityType.character,
            canonicalName: '叶澜',
          ),
        )
        .withEntity(
          const StoryEntity(
            id: 'character:gu-chen',
            type: StoryEntityType.character,
            canonicalName: '顾尘',
          ),
        )
        .withRelation(
          const StoryRelation(
            id: 'relation:mentor',
            fromEntityId: 'character:gu-chen',
            toEntityId: 'character:ye-lan',
            predicate: '师徒',
            validFromChapter: 3,
            sourceDocumentId: 'chapter-3',
            sourceRange: SourceRange(start: 8, end: 19),
            confidence: 0.92,
            confirmation: ConfirmationStatus.pending,
          ),
        );
    await repository.save(graph);

    expect((await repository.load('project-1')).relationsAt(3), isEmpty);
    await repository.confirm('project-1', 'relation:mentor');
    expect((await repository.load('project-1')).relationsAt(3), hasLength(1));

    await repository.undo('project-1', 'relation:mentor');
    final restored = await repository.load('project-1');
    expect(restored.relationsAt(3), isEmpty);
    expect(restored.relations.single.isRetracted, isTrue);
  });

  test('undo retracts a fact but preserves its evidence audit trail', () async {
    final graph = StoryGraph.empty('project-1').withFact(
      const StoryFact(
        id: 'fact:wrong-eye',
        entityId: 'character:ye-lan',
        predicate: '瞳色',
        value: '金色',
        validFromChapter: 1,
        sourceDocumentId: 'chapter-1',
        sourceRange: SourceRange(start: 40, end: 42),
        confidence: 0.7,
        confirmation: ConfirmationStatus.confirmed,
      ),
    );
    await repository.save(graph);

    await repository.undo('project-1', 'fact:wrong-eye');
    final restored = await repository.load('project-1');

    expect(await repository.factsAt('project-1', 1), isEmpty);
    expect(restored.facts.single.isRetracted, isTrue);
    expect(restored.facts.single.sourceDocumentId, 'chapter-1');
    expect(restored.facts.single.sourceRange.start, 40);
  });

  test('Canon migration is stable, idempotent, and preserves aliases',
      () async {
    final canon = CanonEntry(
      id: 'canon-ye-lan',
      projectId: 'project-1',
      type: CanonEntryType.character,
      name: '叶澜',
      description: '青梧城的巡夜人',
      attributes: {
        'aliases': ['阿澜', '小叶'],
        'validFromChapter': 1,
        'sourceDocumentId': 'canon-characters',
      },
    );

    await repository.migrateFromCanon('project-1', [canon]);
    await repository.migrateFromCanon('project-1', [canon]);
    final restored = await repository.load('project-1');

    expect(restored.entities, hasLength(1));
    expect(restored.findEntity('阿澜')?.id, 'canon-ye-lan');
    expect(
      restored.facts.where((fact) => fact.predicate == '描述'),
      hasLength(1),
    );
    expect(restored.facts.single.sourceDocumentId, 'canon-characters');
    expect(restored.facts.single.confirmation, ConfirmationStatus.confirmed);
  });
}
