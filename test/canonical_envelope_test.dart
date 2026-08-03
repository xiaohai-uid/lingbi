import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_envelope.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';

void main() {
  const payload = <String, dynamic>{
    'title': '第一章',
    'assets': [
      {'id': 'asset-1', 'name': '主角'},
    ],
  };

  test('encodes the canonical envelope and hashes payload only', () {
    final envelope = CanonicalJsonEnvelope(
      schemaVersion: 1,
      revision: 7,
      contentHash: canonicalPayloadHash(payload),
      payload: payload,
    );

    expect(
      envelope.encode(),
      equals(
        '{"content_hash":"${canonicalPayloadHash(payload)}",'
        '"payload":{"assets":[{"id":"asset-1","name":"主角"}],'
        '"title":"第一章"},"revision":7,"schema_version":1}',
      ),
    );
    expect(envelope.contentHash, equals(canonicalPayloadHash(payload)));
  });

  test('decodes a canonical envelope and round-trips it', () {
    final original = CanonicalJsonEnvelope(
      schemaVersion: 1,
      revision: 2,
      contentHash: canonicalPayloadHash(payload),
      payload: payload,
    );

    final decoded = CanonicalJsonEnvelope.decode(original.encode());

    expect(decoded, equals(original));
    expect(decoded.encode(), equals(original.encode()));
  });

  test('does not include envelope metadata in payload hash', () {
    final first = CanonicalJsonEnvelope(
      schemaVersion: 1,
      revision: 1,
      contentHash: canonicalPayloadHash(payload),
      payload: payload,
    );
    final second = CanonicalJsonEnvelope(
      schemaVersion: 1,
      revision: 99,
      contentHash: canonicalPayloadHash(payload),
      payload: payload,
    );

    expect(first.contentHash, equals(second.contentHash));
  });

  test('rejects an unknown schema version', () {
    final json = jsonEncode({
      'schema_version': 2,
      'revision': 1,
      'content_hash': canonicalPayloadHash(payload),
      'payload': payload,
    });

    expect(
      () => CanonicalJsonEnvelope.decode(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a payload whose hash does not match', () {
    final json = jsonEncode({
      'schema_version': 1,
      'revision': 1,
      'content_hash': canonicalPayloadHash({'other': true}),
      'payload': payload,
    });

    expect(
      () => CanonicalJsonEnvelope.decode(json),
      throwsA(isA<FormatException>()),
    );
  });
}
