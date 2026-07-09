import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/foreshadowing.dart';

void main() {
  group('ForeshadowStatus', () {
    test('has 4 statuses', () {
      expect(ForeshadowStatus.values.length, 4);
      expect(ForeshadowStatus.values, contains(ForeshadowStatus.planted));
      expect(ForeshadowStatus.values, contains(ForeshadowStatus.growing));
      expect(ForeshadowStatus.values, contains(ForeshadowStatus.harvested));
      expect(ForeshadowStatus.values, contains(ForeshadowStatus.abandoned));
    });

    test('fromString parses correctly', () {
      expect(ForeshadowStatus.fromString('planted'), ForeshadowStatus.planted);
      expect(ForeshadowStatus.fromString('growing'), ForeshadowStatus.growing);
      expect(
          ForeshadowStatus.fromString('harvested'), ForeshadowStatus.harvested);
      expect(
          ForeshadowStatus.fromString('abandoned'), ForeshadowStatus.abandoned);
      expect(ForeshadowStatus.fromString('unknown'), ForeshadowStatus.planted);
    });

    test('displayName is Chinese', () {
      expect(ForeshadowStatus.planted.displayName, '已埋设');
      expect(ForeshadowStatus.harvested.displayName, '已回收');
    });
  });

  group('Foreshadowing', () {
    test('creates with default values', () {
      final fsh = Foreshadowing(
        worldId: 'world-1',
        plantedEventId: 'event-1',
      );
      expect(fsh.worldId, 'world-1');
      expect(fsh.plantedEventId, 'event-1');
      expect(fsh.status, ForeshadowStatus.planted);
      expect(fsh.subtlety, 5);
      expect(fsh.harvestedEventId, isNull);
      expect(fsh.description, '');
      expect(fsh.note, '');
    });

    test('harvest updates status and event', () {
      final fsh = Foreshadowing(
        worldId: 'world-1',
        plantedEventId: 'event-1',
        description: '这把剑是魔剑',
        subtlety: 7,
      );

      expect(fsh.status, ForeshadowStatus.planted);
      fsh.harvest('event-50');
      expect(fsh.status, ForeshadowStatus.harvested);
      expect(fsh.harvestedEventId, 'event-50');
    });

    test('abandon updates status', () {
      final fsh = Foreshadowing(
        worldId: 'world-1',
        plantedEventId: 'event-1',
        description: '伏笔',
        subtlety: 3,
      );
      fsh.abandon();
      expect(fsh.status, ForeshadowStatus.abandoned);
    });

    test('serializes to/from JSON', () {
      final fsh = Foreshadowing(
        id: 'fsh-1',
        worldId: 'world-1',
        plantedEventId: 'event-1',
        harvestedEventId: 'event-50',
        status: ForeshadowStatus.harvested,
        subtlety: 8,
        description: '悬疑伏笔',
        note: '第三幕回收',
      );

      final json = fsh.toJson();
      expect(json['id'], 'fsh-1');
      expect(json['plantedEventId'], 'event-1');
      expect(json['harvestedEventId'], 'event-50');
      expect(json['status'], 'harvested');
      expect(json['subtlety'], 8);
      expect(json['description'], '悬疑伏笔');

      final restored = Foreshadowing.fromJson(json);
      expect(restored.id, fsh.id);
      expect(restored.status, ForeshadowStatus.harvested);
      expect(restored.subtlety, 8);
      expect(restored.harvestedEventId, 'event-50');
    });

    test('handles null harvestedEventId in JSON', () {
      final fsh = Foreshadowing(
        worldId: 'world-1',
        plantedEventId: 'event-1',
        description: '未回收',
      );
      final json = fsh.toJson();
      expect(json['harvestedEventId'], isNull);

      final restored = Foreshadowing.fromJson(json);
      expect(restored.harvestedEventId, isNull);
      expect(restored.status, ForeshadowStatus.planted);
    });

    test('serialization roundtrip preserves all fields', () {
      final fsh = Foreshadowing(
        worldId: 'world-1',
        plantedEventId: 'event-1',
        subtlety: 2,
        description: '隐藏线索',
        note: '极其隐蔽',
      );
      final json = fsh.toJson();
      final restored = Foreshadowing.fromJson(json);
      expect(restored.worldId, fsh.worldId);
      expect(restored.plantedEventId, fsh.plantedEventId);
      expect(restored.subtlety, fsh.subtlety);
      expect(restored.description, fsh.description);
      expect(restored.note, fsh.note);
    });
  });
}
