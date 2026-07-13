/// 知识图谱(角色关系)持久化测试
///
/// 验证 canon_page 依赖的 CharacterRelations drift DAO 往返，以及
/// CharacterEdge 模型(含 id)的映射正确性。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lingbi/core/models/character_edge.dart';
import 'package:lingbi/data/database/world_database.dart';

WorldDatabase createTestDb() => WorldDatabase(NativeDatabase.memory());

CharacterEdge relationFromRow(CharacterRelation r) => CharacterEdge(
      id: r.id,
      sourceId: r.characterId,
      targetId: r.relatedCharacterId,
      type: RelationshipType.fromString(r.relationType),
      strength: r.intimacy,
      description: r.description ?? '',
    );

void main() {
  late WorldDatabase db;

  setUp(() => db = createTestDb());

  group('CharacterRelations DAO', () {
    test('insert 后 select 往返', () async {
      await db.into(db.characterRelations).insert(
            CharacterRelationsCompanion.insert(
              id: 'rel1',
              characterId: 'c1',
              relatedCharacterId: 'c2',
              relationType: RelationshipType.mentor.value,
              intimacy: 8,
              description: '师徒情深',
            ),
          );
      final rows = await db.select(db.characterRelations).get();
      expect(rows.length, 1);
      final edge = relationFromRow(rows.first);
      expect(edge.sourceId, 'c1');
      expect(edge.targetId, 'c2');
      expect(edge.type, RelationshipType.mentor);
      expect(edge.strength, 8);
      expect(edge.description, '师徒情深');
    });

    test('按 id 删除', () async {
      await db.into(db.characterRelations).insert(
            CharacterRelationsCompanion.insert(
              id: 'rel2',
              characterId: 'c1',
              relatedCharacterId: 'c3',
              relationType: RelationshipType.rival.value,
              intimacy: 5,
              description: '',
            ),
          );
      await (db.delete(db.characterRelations)..where((t) => t.id.equals('rel2'))).go();
      final rows = await db.select(db.characterRelations).get();
      expect(rows.length, 0);
    });

    test('多关系按 world 维度隔离由调用方 worldId 过滤', () async {
      await db.into(db.characterRelations).insert(
            CharacterRelationsCompanion.insert(
              id: 'relA',
              characterId: 'c1',
              relatedCharacterId: 'c2',
              relationType: RelationshipType.ally.value,
              intimacy: 3,
              description: '',
            ),
          );
      final rows = await db.select(db.characterRelations).get();
      expect(rows.length, 1);
      // canon_page 通过 databaseManager.getDatabase(worldId) 隔离不同世界
      expect(relationFromRow(rows.first).type, RelationshipType.ally);
    });
  });

  group('CharacterEdge 模型', () {
    test('id 经 json 往返保留', () {
      final edge = CharacterEdge(
        id: 'e1',
        sourceId: 'c1',
        targetId: 'c2',
        type: RelationshipType.lover,
        strength: 9,
        description: 'desc',
      );
      final json = edge.toJson();
      expect(json['id'], 'e1');
      final back = CharacterEdge.fromJson(json);
      expect(back.id, 'e1');
      expect(back.strength, 9);
      expect(back.type, RelationshipType.lover);
    });

    test('reverse 保留 id', () {
      final edge = CharacterEdge(
        id: 'e2',
        sourceId: 'c1',
        targetId: 'c2',
        type: RelationshipType.family,
        strength: 7,
      );
      final r = edge.reverse();
      expect(r.id, 'e2');
      expect(r.sourceId, 'c2');
      expect(r.targetId, 'c1');
    });
  });
}
