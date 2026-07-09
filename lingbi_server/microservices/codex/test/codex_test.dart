import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:codex/lib/codex_store.dart';

void main() {
  late CodexStore store;
  late String dbPath;

  setUp(() async {
    dbPath = '/tmp/test_codex_${DateTime.now().millisecondsSinceEpoch}.db';
    store = await CodexStore.initialize(dbPath);
  });

  tearDown(() {
    store.close();
    try {
      File(dbPath).deleteSync();
    } catch (e) {}
  });

  test('create entry returns correct type', () async {
    final entry = await store.create('character', '孙悟空', description: '齐天大圣');
    expect(entry['type'], 'character');
    expect(entry['name'], '孙悟空');
    expect(entry['description'], '齐天大圣');
  });

  test('create entry with tags and metadata', () async {
    final entry = await store.create(
      'location',
      '花果山',
      tags: ['山', '水'],
      metadata: {'region': '东方'},
    );
    expect(entry['tags'], ['山', '水']);
    expect(entry['metadata'], {'region': '东方'});
  });

  test('create with invalid type throws exception', () async {
    expect(
      () => store.create('invalid', 'test'),
      throwsException,
    );
  });

  test('getById returns entry', () async {
    final created = await store.create('character', '猪八戒');
    final result = await store.getById(created['id']);
    expect(result, isNotNull);
    expect(result!['name'], '猪八戒');
  });

  test('getById returns null for nonexistent', () async {
    final result = await store.getById('nonexistent');
    expect(result, isNull);
  });

  test('list returns all entries', () async {
    await store.create('character', '孙悟空');
    await store.create('character', '猪八戒');
    await store.create('location', '花果山');

    final all = await store.list();
    expect(all.length, 3);
  });

  test('list filters by type', () async {
    await store.create('character', '孙悟空');
    await store.create('location', '花果山');

    final characters = await store.list(type: 'character');
    expect(characters.length, 1);
    expect(characters[0]['name'], '孙悟空');
  });

  test('update entry', () async {
    final created = await store.create('character', '孙悟空');
    final updated = await store.update(
      created['id'],
      name: '齐天大圣',
      description: '升级了',
    );
    expect(updated!['name'], '齐天大圣');
    expect(updated['description'], '升级了');
  });

  test('update nonexistent returns null', () async {
    final updated = await store.update('nonexistent', name: 'test');
    expect(updated, isNull);
  });

  test('delete entry', () async {
    final created = await store.create('character', '孙悟空');
    final deleted = await store.delete(created['id']);
    expect(deleted, true);
  });

  test('delete nonexistent returns false', () async {
    final deleted = await store.delete('nonexistent');
    expect(deleted, false);
  });

  test('create and list multiple types', () async {
    await store.create('character', '唐僧');
    await store.create('location', '西天');
    await store.create('lore', '西游记');

    final all = await store.list();
    expect(all.length, 3);

    final characters = await store.list(type: 'character');
    expect(characters.length, 1);
    final locations = await store.list(type: 'location');
    expect(locations.length, 1);
  });
}
