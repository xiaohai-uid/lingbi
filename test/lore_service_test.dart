/// 测试: LoreService — 世界设定自动引用
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/services/lore_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';

class _MemoryDatabaseManager extends DatabaseManager {
  final Map<String, WorldDatabase> _databases = {};
  @override
  Future<WorldDatabase> getDatabase(String worldId) async =>
      _databases.putIfAbsent(worldId, () => WorldDatabase(NativeDatabase.memory()));
  @override
  Future<void> closeAll() async {
    for (final db in _databases.values) await db.close();
    _databases.clear();
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  late _MemoryDatabaseManager databaseManager;
  late LoreService loreService;
  late WorldDatabase db;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('lingbi_lore_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    db = await databaseManager.getDatabase('world-1');
    loreService = LoreService(databaseManager: databaseManager);
  });

  tearDown(() async {
    await databaseManager.closeAll();
  });

  group('LoreService CRUD', () {
    test('createLore 创建条目', () async {
      final lore = await loreService.createLore(
        worldId: 'world-1',
        name: '天元大陆',
        type: 'location',
        description: '故事主要发生地，一个以修仙为尊的大陆',
        triggerKeywords: '天元,大陆,修仙界',
      );

      expect(lore.id, isNotEmpty);
      expect(lore.name, '天元大陆');
      expect(lore.type, 'location');
      expect(lore.enabled, true);
    });

    test('getLores 获取世界所有条目', () async {
      await loreService.createLore(
          worldId: 'world-1', name: '天元大陆', type: 'location', description: '', triggerKeywords: '');
      await loreService.createLore(
          worldId: 'world-1', name: '青云宗', type: 'faction', description: '', triggerKeywords: '');

      final lores = await loreService.getLores('world-1');
      expect(lores.length, 2);
    });

    test('updateLore 更新条目', () async {
      final lore = await loreService.createLore(
          worldId: 'world-1', name: '旧名', type: 'location', description: '', triggerKeywords: '');
      await loreService.updateLore(lore.id, worldId: 'world-1', name: '新名', enabled: false);
      final updated = await loreService.getLore(lore.id, worldId: 'world-1');
      expect(updated!.name, '新名');
      expect(updated!.enabled, false);
    });

    test('deleteLore 删除条目', () async {
      final lore = await loreService.createLore(
          worldId: 'world-1', name: '待删除', type: 'location', description: '', triggerKeywords: '');
      await loreService.deleteLore(lore.id, worldId: 'world-1');
      final result = await loreService.getLore(lore.id, worldId: 'world-1');
      expect(result, isNull);
    });
  });

  group('LoreService 关键词匹配', () {
    test('matchContext 匹配关键词返回相关条目', () async {
      await loreService.createLore(
        worldId: 'world-1',
        name: '天元大陆',
        type: 'location',
        description: '广袤无垠的修仙大陆',
        triggerKeywords: '天元,大陆,修仙界',
      );
      await loreService.createLore(
        worldId: 'world-1',
        name: '青云宗',
        type: 'faction',
        description: '正道第一宗门',
        triggerKeywords: '青云,宗门,正道',
      );

      final matched = await loreService.matchContext(worldId: 'world-1', text: '他来到天元大陆，加入青云宗');
      expect(matched.length, 2, reason: '应匹配到天元大陆和青云宗');
      expect(matched.any((l) => l.name == '天元大陆'), isTrue);
      expect(matched.any((l) => l.name == '青云宗'), isTrue);
    });

    test('matchContext 不匹配无关文本', () async {
      await loreService.createLore(
        worldId: 'world-1',
        name: '九天玄功',
        type: 'skill',
        description: '上古功法',
        triggerKeywords: '九天,玄功',
      );

      final matched = await loreService.matchContext(worldId: 'world-1', text: '他走在街上');
      expect(matched, isEmpty, reason: '不应匹配无关文本');
    });

    test('matchContext 只匹配已启用的条目', () async {
      await loreService.createLore(
        worldId: 'world-1',
        name: '已禁用条目',
        type: 'location',
        description: '不应出现',
        triggerKeywords: '禁用',
        enabled: false,
      );

      final matched = await loreService.matchContext(worldId: 'world-1', text: '禁用这个词应该匹配不到');
      expect(matched, isEmpty, reason: '禁用的条目不应匹配');
    });

    test('buildPromptContext 格式化匹配结果', () async {
      await loreService.createLore(
        worldId: 'world-1',
        name: '天元大陆',
        type: 'location',
        description: '广袤无垠的修仙大陆',
        triggerKeywords: '天元,大陆',
      );

      final context = await loreService.buildPromptContext(worldId: 'world-1', text: '在天元大陆上');
      expect(context, contains('天元大陆'));
      expect(context, contains('[location]'));
      expect(context, contains('广袤无垠的修仙大陆'));
    });

    test('buildPromptContext 无匹配时返回空字符串', () async {
      final context = await loreService.buildPromptContext(worldId: 'world-1', text: '普通文本');
      expect(context, isEmpty);
    });
  });
}