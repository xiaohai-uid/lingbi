/// 仓库集成测试 — 测试 Drift 数据层 CRUD 操作
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lingbi/data/database/world_database.dart';

WorldDatabase createTestDb() => WorldDatabase(NativeDatabase.memory());

void main() {
  late WorldDatabase db;

  setUp(() {
    db = createTestDb();
  });

  group('Works CRUD', () {
    test('create and query work', () async {
      await db.into(db.works).insert(WorksCompanion.insert(
            id: 'w1',
            worldId: 'world1',
            title: '测试作品',
            description: '',
            type: 'novel',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      final works = await db.select(db.works).get();
      expect(works.length, 1);
      expect(works.first.title, '测试作品');
    });

    test('query by worldId', () async {
      for (var i = 1; i <= 2; i++) {
        await db.into(db.works).insert(WorksCompanion.insert(
              id: 'w$i',
              worldId: 'world1',
              title: '作品$i',
              description: '',
              type: 'novel',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
      }
      final works = await (db.select(db.works)
            ..where((t) => t.worldId.equals('world1')))
          .get();
      expect(works.length, 2);
    });

    test('update', () async {
      await db.into(db.works).insert(WorksCompanion.insert(
            id: 'w1',
            worldId: 'world1',
            title: '旧标题',
            description: '',
            type: 'novel',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await (db.update(db.works)..where((t) => t.id.equals('w1'))).write(
        WorksCompanion(title: const Value('新标题')),
      );
      final w = await (db.select(db.works)..where((t) => t.id.equals('w1')))
          .getSingle();
      expect(w.title, '新标题');
    });

    test('delete', () async {
      await db.into(db.works).insert(WorksCompanion.insert(
            id: 'w1',
            worldId: 'world1',
            title: '待删除',
            description: '',
            type: 'novel',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await (db.delete(db.works)..where((t) => t.id.equals('w1'))).go();
      expect(await db.select(db.works).get(), isEmpty);
    });
  });

  group('Volumes', () {
    test('ordered by volumeNumber', () async {
      await db.into(db.volumes).insert(VolumesCompanion.insert(
            id: 'v1',
            workId: 'w1',
            volumeNumber: 2,
            title: '第二卷',
            synopsis: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await db.into(db.volumes).insert(VolumesCompanion.insert(
            id: 'v2',
            workId: 'w1',
            volumeNumber: 1,
            title: '第一卷',
            synopsis: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      final vols = await (db.select(db.volumes)
            ..where((t) => t.workId.equals('w1'))
            ..orderBy([(t) => OrderingTerm(expression: t.volumeNumber)]))
          .get();
      expect(vols.first.volumeNumber, 1);
    });
  });

  group('Chapters', () {
    test('create with synopsis', () async {
      await db.into(db.chapters).insert(ChaptersCompanion.insert(
            id: 'c1',
            volumeId: 'v1',
            chapterNumber: 1,
            title: '第一章',
            synopsis: '故事开始',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      final ch = await (db.select(db.chapters)..where((t) => t.id.equals('c1')))
          .getSingle();
      expect(ch.synopsis, '故事开始');
    });
  });

  group('Scenes', () {
    test('create with fields', () async {
      await db.into(db.scenes).insert(ScenesCompanion.insert(
            id: 's1',
            chapterId: 'c1',
            sceneNumber: 1,
            title: '场景1',
            outlineDescription: '',
            locationId: '',
            timelineEventId: '',
            documentId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      final scenes = await (db.select(db.scenes)
            ..where((t) => t.chapterId.equals('c1')))
          .get();
      expect(scenes.length, 1);
    });
  });

  group('Characters', () {
    test('create with role', () async {
      await db.into(db.characters).insert(CharactersCompanion.insert(
            id: 'ch1',
            worldId: 'world1',
            name: '林映',
            role: '主角',
            description: '科学家',
            personality: '理性',
            backstory: '',
            motivation: '',
            arc: '',
            baseWeight: 100,
            tempWeight: 0,
            currentStatus: '',
            currentLocationId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      final chars = await (db.select(db.characters)
            ..where((t) => t.worldId.equals('world1')))
          .get();
      expect(chars.length, 1);
      expect(chars.first.name, '林映');
    });
  });

  group('Identities', () {
    test('create identity', () async {
      await db.into(db.identities).insert(IdentitiesCompanion.insert(
            id: 'i1',
            characterId: 'ch1',
            name: '掌门',
            description: '掌门',
            weight: 80,
            autoDetected: true,
            organizationId: '',
            establishedAfterEventId: '',
            expiresAfterEventId: '',
          ));
      expect(await db.select(db.identities).get(), hasLength(1));
    });
  });

  group('TimelineEvents', () {
    test('create event', () async {
      await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
            id: 't1',
            worldId: 'world1',
            title: '事件1',
            description: '重要事件',
            orderKey: '1',
            inStoryDate: '',
            inStoryDay: 0,
            duration: '',
            chapterAnchor: '',
            branchId: '',
            parentEventId: '',
            createdAt: DateTime.now(),
          ));
      expect(await db.select(db.timelineEvents).get(), hasLength(1));
    });
  });

  group('Factions', () {
    test('create faction', () async {
      await db.into(db.factions).insert(FactionsCompanion.insert(
            id: 'f1',
            worldId: 'world1',
            name: '青云宗',
            type: 'sect',
            description: '修仙门派',
            power: 500,
            territory: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.factions).get(), hasLength(1));
    });
  });

  group('Foreshadowing', () {
    test('create foreshadowing', () async {
      await db.into(db.foreshadowings).insert(ForeshadowingsCompanion.insert(
            id: 'fs1',
            worldId: 'world1',
            plantedEventId: 'e1',
            harvestedEventId: 'e2',
            status: 'planted',
            subtlety: 7,
            description: '',
            note: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.foreshadowings).get(), hasLength(1));
    });
  });

  group('Full hierarchy', () {
    test('Work→Volume→Chapter→Scene', () async {
      await db.into(db.works).insert(WorksCompanion.insert(
            id: 'w1',
            worldId: 'w1',
            title: '星穹之下',
            description: '',
            type: 'novel',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await db.into(db.volumes).insert(VolumesCompanion.insert(
            id: 'v1',
            workId: 'w1',
            volumeNumber: 1,
            title: '启程',
            synopsis: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await db.into(db.chapters).insert(ChaptersCompanion.insert(
            id: 'c1',
            volumeId: 'v1',
            chapterNumber: 1,
            title: '信号',
            synopsis: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await db.into(db.scenes).insert(ScenesCompanion.insert(
            id: 's1',
            chapterId: 'c1',
            sceneNumber: 1,
            title: '深空信号',
            timelineEventId: '',
            documentId: '',
            outlineDescription: '',
            locationId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.works).get(), hasLength(1));
      expect(await db.select(db.volumes).get(), hasLength(1));
      expect(await db.select(db.chapters).get(), hasLength(1));
      expect(await db.select(db.scenes).get(), hasLength(1));
    });
  });

  group('Locations', () {
    test('create location', () async {
      await db.into(db.locations).insert(LocationsCompanion.insert(
            id: 'l1',
            worldId: 'world1',
            name: '深空站',
            description: '监测站',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.locations).get(), hasLength(1));
    });
  });

  group('Lores', () {
    test('create lore', () async {
      await db.into(db.lores).insert(LoresCompanion.insert(
            id: 'lo1',
            worldId: 'world1',
            name: '古老传说',
            type: 'location',
            description: '星辰预言',
            triggerKeywords: '',
            enabled: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.lores).get(), hasLength(1));
    });
  });

  group('WorldRules', () {
    test('create rule', () async {
      await db.into(db.worldRules).insert(WorldRulesCompanion.insert(
            id: 'r1',
            worldId: 'world1',
            name: '魔法守恒',
            description: '能量守恒',
            scope: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.worldRules).get(), hasLength(1));
    });
  });

  group('Documents', () {
    test('create document', () async {
      await db.into(db.documents).insert(DocumentsCompanion.insert(
            id: 'd1',
            worldId: 'world1',
            workId: 'w1',
            filePath: '/doc.md',
            currentSceneId: 's1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      expect(await db.select(db.documents).get(), hasLength(1));
    });
  });
}
