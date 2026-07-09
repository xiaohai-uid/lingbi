import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/character_edge.dart';

void main() {
  group('CharacterEdge', () {
    test('creates edge with default strength', () {
      const edge = CharacterEdge(
        sourceId: 'char-1',
        targetId: 'char-2',
        type: RelationshipType.mentor,
      );
      expect(edge.sourceId, 'char-1');
      expect(edge.targetId, 'char-2');
      expect(edge.type, RelationshipType.mentor);
      expect(edge.strength, 5);
    });

    test('creates edge with all fields', () {
      const edge = CharacterEdge(
        sourceId: 'char-1',
        targetId: 'char-2',
        type: RelationshipType.rival,
        strength: 9,
        description: '生死宿敌',
        events: ['plot-1'],
      );
      expect(edge.strength, 9);
      expect(edge.events, ['plot-1']);
    });

    test('serializes to/from JSON', () {
      const edge = CharacterEdge(
        sourceId: 'a',
        targetId: 'b',
        type: RelationshipType.lover,
        strength: 10,
      );
      final json = edge.toJson();
      expect(json['type'], 'lover');
      expect(json['strength'], 10);
      final restored = CharacterEdge.fromJson(json);
      expect(restored.type, RelationshipType.lover);
    });

    test('reverse creates opposite direction edge', () {
      const edge = CharacterEdge(
        sourceId: 'a',
        targetId: 'b',
        type: RelationshipType.mentor,
      );
      final reversed = edge.reverse();
      expect(reversed.sourceId, 'b');
      expect(reversed.targetId, 'a');
    });
  });

  group('RelationshipType', () {
    test('fromString parses all types', () {
      expect(RelationshipType.fromString('mentor'), RelationshipType.mentor);
      expect(RelationshipType.fromString('rival'), RelationshipType.rival);
      expect(RelationshipType.fromString('unknown'), RelationshipType.neutral);
    });

    test('displayName returns Chinese names', () {
      expect(RelationshipType.mentor.displayName, '师徒');
      expect(RelationshipType.lover.displayName, '恋人');
      expect(RelationshipType.neutral.displayName, '中立');
    });
  });
}
