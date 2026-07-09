import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/faction.dart';

void main() {
  group('Faction', () {
    test('creates faction with default power', () {
      final f = Faction(name: '天剑宗');
      expect(f.power, 50);
      expect(f.memberIds, isEmpty);
    });

    test('serializes to/from JSON', () {
      final f = Faction(
        id: 'fac-1',
        name: '暗影阁',
        type: FactionType.organization,
        power: 80,
        territory: '江南',
        memberIds: ['c1', 'c2'],
        allyIds: ['fac-2'],
        rivalIds: ['fac-3'],
      );
      final json = f.toJson();
      expect(json['name'], '暗影阁');
      expect(json['type'], 'organization');
      final restored = Faction.fromJson(json);
      expect(restored.memberIds.length, 2);
    });

    test('FactionType displayName returns Chinese', () {
      expect(FactionType.sect.displayName, '宗门');
      expect(FactionType.nation.displayName, '国家');
    });
  });
}
