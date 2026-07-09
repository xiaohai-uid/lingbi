import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:storage/lib/vector_store.dart';

void main() {
  late VectorStore store;
  late String dbPath;

  setUp(() async {
    dbPath = '/tmp/test_storage_${DateTime.now().millisecondsSinceEpoch}.db';
    store = await VectorStore.initialize(dbPath);
  });

  tearDown(() {
    store.close();
    try {
      File(dbPath).deleteSync();
    } catch (e) {}
  });

  test('upsert stores a vector with payload', () async {
    final vector = [0.1, 0.2, 0.3, 0.4, 0.5];
    await store.upsert('v1', vector, payload: {'name': 'test'});

    final result = await store.getById('v1');
    expect(result, isNotNull);
    expect(result!['id'], 'v1');
    expect(result['payload'], {'name': 'test'});
  });

  test('upsert updates existing vector', () async {
    await store.upsert('v1', [0.1, 0.2], payload: {'version': 1});
    await store.upsert('v1', [0.3, 0.4], payload: {'version': 2});

    final result = await store.getById('v1');
    expect(result!['payload'], {'version': 2});
  });

  test('getById returns null for nonexistent', () async {
    final result = await store.getById('nonexistent');
    expect(result, isNull);
  });

  test('delete removes a vector', () async {
    await store.upsert('v1', [0.1, 0.2]);
    await store.delete('v1');

    final result = await store.getById('v1');
    expect(result, isNull);
  });

  test('search returns vectors by cosine similarity', () async {
    await store.upsert('v1', [1.0, 0.0, 0.0], payload: {'name': 'v1'});
    await store.upsert('v2', [0.0, 1.0, 0.0], payload: {'name': 'v2'});
    await store.upsert('v3', [0.1, 0.0, 0.0], payload: {'name': 'v3'});

    final results = await store.search([1.0, 0.0, 0.0], limit: 2);
    expect(results.length, 2);
    // v1 is most similar (distance ~0)
    expect(results[0]['distance'], closeTo(0.0, 0.1));
    expect(results[1]['distance'], closeTo(1.0, 0.1));
  });

  test('search filters by namespace', () async {
    await store.upsert('v1', [0.1, 0.2],
        namespace: 'default', payload: {'name': 'default'});
    await store.upsert('v2', [0.3, 0.4],
        namespace: 'other', payload: {'name': 'other'});

    final results = await store.search([0.1, 0.2], namespace: 'default');
    expect(results.length, 1);
    expect(results[0]['id'], 'v1');
  });

  test('cosine distance calculation', () async {
    // Test that cosine distance is between 0 and 1
    await store.upsert('v1', [1.0, 0.0], payload: {'name': 'v1'});
    await store.upsert('v2', [0.0, 1.0], payload: {'name': 'v2'});

    final results = await store.search([1.0, 0.0], limit: 2);
    for (final r in results) {
      expect(r['distance'] is double, true);
      expect(r['distance'], inInclusiveRange(0.0, 1.0));
    }
  });

  test('upsert with different namespaces', () async {
    await store.upsert('v1', [0.1, 0.2],
        namespace: 'ns1', payload: {'ns': 'ns1'});
    await store.upsert('v2', [0.3, 0.4],
        namespace: 'ns2', payload: {'ns': 'ns2'});

    final result1 = await store.getById('v1', namespace: 'ns1');
    expect(result1!['payload'], {'ns': 'ns1'});

    final result2 = await store.getById('v2', namespace: 'ns2');
    expect(result2!['payload'], {'ns': 'ns2'});
  });

  test('getById with wrong namespace returns null', () async {
    await store.upsert('v1', [0.1, 0.2],
        namespace: 'ns1', payload: {'ns': 'ns1'});
    final result = await store.getById('v1', namespace: 'ns2');
    expect(result, isNull);
  });
}
