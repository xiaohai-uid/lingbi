import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/canon_entry.dart';

void main() {
  group('CanonEntry (Character)', () {
    test('creates Character with default values', () {
      final char = Character(worldId: 'world-1', name: '林月');
      expect(char.name, '林月');
      expect(char.worldId, 'world-1');
      expect(char.type, CanonType.character);
      expect(char.appearance, '');
      expect(char.personality, '');
      expect(char.tags, isEmpty);
    });

    test('serializes Character to/from JSON', () {
      final char = Character(
        id: 'char-1',
        worldId: 'world-1',
        name: '林月',
        description: '女主角',
        tags: ['主角', '修仙'],
        appearance: '白衣胜雪',
        personality: '温柔坚韧',
        background: '青云宗弟子',
        archetype: 'hero',
      );
      final json = char.toJson();
      expect(json['type'], 'character');
      expect(json['name'], '林月');
      expect(json['appearance'], '白衣胜雪');

      final restored = Character.fromJson(json);
      expect(restored.id, char.id);
      expect(restored.name, char.name);
      expect(restored.appearance, char.appearance);
      expect(restored.personality, char.personality);
      expect(restored.archetype, 'hero');
    });
  });

  group('CanonEntry (Location)', () {
    test('creates Location with default values', () {
      final loc = Location(worldId: 'world-1', name: '青云宗');
      expect(loc.name, '青云宗');
      expect(loc.type, CanonType.location);
      expect(loc.atmosphere, '');
    });

    test('serializes Location to/from JSON', () {
      final loc = Location(
        id: 'loc-1',
        worldId: 'world-1',
        name: '青云宗',
        description: '修仙门派',
        atmosphere: '仙气缭绕',
        associatedEvents: ['event-1'],
      );
      final json = loc.toJson();
      expect(json['type'], 'location');
      expect(json['atmosphere'], '仙气缭绕');

      final restored = Location.fromJson(json);
      expect(restored.name, '青云宗');
      expect(restored.atmosphere, '仙气缭绕');
      expect(restored.associatedEvents, ['event-1']);
    });
  });

  group('CanonEntry (Lore)', () {
    test('creates Lore with default values', () {
      final lore = Lore(worldId: 'world-1', name: '修仙体系');
      expect(lore.name, '修仙体系');
      expect(lore.type, CanonType.lore);
      expect(lore.category, '');
    });

    test('serializes Lore to/from JSON', () {
      final lore = Lore(
        id: 'lore-1',
        worldId: 'world-1',
        name: '修仙体系',
        description: '筑基、金丹、元婴',
        category: 'magic',
      );
      final json = lore.toJson();
      expect(json['type'], 'lore');
      expect(json['category'], 'magic');

      final restored = Lore.fromJson(json);
      expect(restored.name, '修仙体系');
      expect(restored.category, 'magic');
    });
  });

  group('CanonEntry (WorldRule)', () {
    test('creates WorldRule with default values', () {
      final rule = WorldRule(worldId: 'world-1', name: '灵气规则');
      expect(rule.name, '灵气规则');
      expect(rule.type, CanonType.worldRule);
      expect(rule.scope, '');
      expect(rule.isHardRule, false);
    });

    test('serializes WorldRule to/from JSON', () {
      final rule = WorldRule(
        id: 'rule-1',
        worldId: 'world-1',
        name: '灵气规则',
        description: '灵气越浓修炼越快',
        scope: 'volume-1',
        isHardRule: true,
      );
      final json = rule.toJson();
      expect(json['type'], 'worldRule');
      expect(json['scope'], 'volume-1');
      expect(json['isHardRule'], true);

      final restored = WorldRule.fromJson(json);
      expect(restored.name, '灵气规则');
      expect(restored.scope, 'volume-1');
      expect(restored.isHardRule, true);
    });
  });

  group('CanonType', () {
    test('has 4 canonical types', () {
      expect(CanonType.values.length, 4);
      expect(CanonType.values, contains(CanonType.character));
      expect(CanonType.values, contains(CanonType.location));
      expect(CanonType.values, contains(CanonType.lore));
      expect(CanonType.values, contains(CanonType.worldRule));
    });
  });
}
