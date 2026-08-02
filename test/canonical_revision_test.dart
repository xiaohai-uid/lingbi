import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';

void main() {
  group('CanonicalRevision', () {
    test('matches returns true for identical number and hash', () {
      const a = CanonicalRevision(number: 3, contentHash: 'abc123');
      const b = CanonicalRevision(number: 3, contentHash: 'abc123');
      expect(a.matches(b), isTrue);
    });

    test('matches returns false for different number', () {
      const a = CanonicalRevision(number: 3, contentHash: 'abc123');
      const b = CanonicalRevision(number: 4, contentHash: 'abc123');
      expect(a.matches(b), isFalse);
    });

    test('matches returns false for different hash', () {
      const a = CanonicalRevision(number: 3, contentHash: 'abc123');
      const b = CanonicalRevision(number: 3, contentHash: 'def456');
      expect(a.matches(b), isFalse);
    });
  });

  group('canonicalJsonHash', () {
    test('produces a 64-character lowercase hex string', () {
      final hash = canonicalJsonHash({'key': 'value'});
      expect(hash, hasLength(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('same map with different key insertion order produces same hash', () {
      final map1 = <String, dynamic>{'alpha': 1, 'beta': 2, 'gamma': 3};
      final map2 = <String, dynamic>{'gamma': 3, 'alpha': 1, 'beta': 2};
      expect(canonicalJsonHash(map1), equals(canonicalJsonHash(map2)));
    });

    test('nested maps are recursively key-sorted', () {
      final map1 = <String, dynamic>{
        'outer': <String, dynamic>{'z': 1, 'a': 2},
        'first': true,
      };
      final map2 = <String, dynamic>{
        'first': true,
        'outer': <String, dynamic>{'a': 2, 'z': 1},
      };
      expect(canonicalJsonHash(map1), equals(canonicalJsonHash(map2)));
    });

    test('list order is preserved (not sorted)', () {
      final map1 = <String, dynamic>{'items': [1, 2, 3]};
      final map2 = <String, dynamic>{'items': [3, 2, 1]};
      expect(canonicalJsonHash(map1), isNot(equals(canonicalJsonHash(map2))));
    });

    test('one changed scalar changes the hash', () {
      final original = <String, dynamic>{'title': 'Hello', 'revision': 1};
      final modified = <String, dynamic>{'title': 'Hello', 'revision': 2};
      expect(
        canonicalJsonHash(original),
        isNot(equals(canonicalJsonHash(modified))),
      );
    });

    test('empty map produces a valid hash', () {
      final hash = canonicalJsonHash({});
      expect(hash, hasLength(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('null values are included in hash', () {
      final withNull = <String, dynamic>{'key': null};
      final withValue = <String, dynamic>{'key': 'value'};
      expect(
        canonicalJsonHash(withNull),
        isNot(equals(canonicalJsonHash(withValue))),
      );
    });

    test('unicode content produces stable hash', () {
      final map = <String, dynamic>{'标题': '灵笔', 'content': '第一章'};
      final hash1 = canonicalJsonHash(map);
      final hash2 = canonicalJsonHash(map);
      expect(hash1, equals(hash2));
    });
  });

  group('canonicalTextHash', () {
    test('produces a 64-character lowercase hex string', () {
      final hash = canonicalTextHash('hello world');
      expect(hash, hasLength(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('CRLF and LF produce the same hash', () {
      final crlf = canonicalTextHash('line1\r\nline2\r\nline3');
      final lf = canonicalTextHash('line1\nline2\nline3');
      expect(crlf, equals(lf));
    });

    test('mixed line endings normalize to LF', () {
      final mixed = canonicalTextHash('a\r\nb\nc\r\nd');
      final allLf = canonicalTextHash('a\nb\nc\nd');
      expect(mixed, equals(allLf));
    });

    test('does not trim leading or trailing whitespace', () {
      final padded = canonicalTextHash('  hello  ');
      final trimmed = canonicalTextHash('hello');
      expect(padded, isNot(equals(trimmed)));
    });

    test('content change produces different hash', () {
      final v1 = canonicalTextHash('chapter one content');
      final v2 = canonicalTextHash('chapter two content');
      expect(v1, isNot(equals(v2)));
    });

    test('empty string produces a valid hash', () {
      final hash = canonicalTextHash('');
      expect(hash, hasLength(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('lone CR without LF is not normalized', () {
      // Only \r\n → \n; a standalone \r stays as-is
      final loneCr = canonicalTextHash('a\rb');
      final lf = canonicalTextHash('a\nb');
      expect(loneCr, isNot(equals(lf)));
    });
  });
}
