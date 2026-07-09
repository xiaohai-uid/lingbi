import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/world.dart';

void main() {
  group('World', () {
    test('creates with default values', () {
      final world = World(name: '测试世界');
      expect(world.name, '测试世界');
      expect(world.description, '');
      expect(world.genres, isEmpty);
      expect(world.timelineMode, 'linear');
      expect(world.id.isNotEmpty, true);
    });

    test('creates with all fields', () {
      final world = World(
        id: 'world-1',
        name: '修仙大陆',
        description: '一个修仙世界',
        genres: ['fantasy', 'wuxia'],
        timelineMode: 'branch',
      );
      expect(world.id, 'world-1');
      expect(world.name, '修仙大陆');
      expect(world.description, '一个修仙世界');
      expect(world.genres, ['fantasy', 'wuxia']);
      expect(world.timelineMode, 'branch');
    });

    test('serializes to/from JSON', () {
      final world = World(
        id: 'world-1',
        name: '修仙大陆',
        description: '一个修仙世界',
        genres: ['fantasy'],
      );
      final json = world.toJson();
      expect(json['id'], 'world-1');
      expect(json['name'], '修仙大陆');
      expect(json['description'], '一个修仙世界');
      expect(json['genres'], ['fantasy']);
      expect(json['timelineMode'], 'linear');
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('updatedAt'), true);

      final restored = World.fromJson(json);
      expect(restored.id, world.id);
      expect(restored.name, world.name);
      expect(restored.description, world.description);
      expect(restored.genres, world.genres);
      expect(restored.timelineMode, world.timelineMode);
    });

    test('copyWith updates only specified fields', () {
      final world = World(
        id: 'world-1',
        name: '修仙大陆',
        description: '描述',
        genres: ['fantasy'],
      );
      final updated = world.copyWith(name: '新名称', genres: ['mystery']);
      expect(updated.id, 'world-1');
      expect(updated.name, '新名称');
      expect(updated.description, '描述');
      expect(updated.genres, ['mystery']);
      expect(updated.timelineMode, 'linear');
    });

    test('handles null/empty JSON fields gracefully', () {
      final json = {'id': 'world-1', 'name': '测试'};
      final world = World.fromJson(json);
      expect(world.id, 'world-1');
      expect(world.name, '测试');
      expect(world.description, '');
      expect(world.genres, isEmpty);
      expect(world.timelineMode, 'linear');
    });

    test('creates unique IDs by default', () {
      final world1 = World(name: 'World 1');
      final world2 = World(name: 'World 2');
      expect(world1.id != world2.id, true);
    });
  });
}
