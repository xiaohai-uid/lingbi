/// Canonical revision and deterministic content hashing.
///
/// Domain-layer value objects — no Flutter, no dart:io.
/// See ADR-009 for classification and revision rules.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// An immutable snapshot identifier for a canonical file at a given revision.
final class CanonicalRevision {
  const CanonicalRevision({
    required this.number,
    required this.contentHash,
  });

  /// Monotonically increasing revision counter.
  final int number;

  /// Lowercase SHA-256 hex of the canonical serialization.
  final String contentHash;

  /// Returns true when both revision number and content hash agree.
  bool matches(CanonicalRevision other) =>
      number == other.number && contentHash == other.contentHash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalRevision &&
          number == other.number &&
          contentHash == other.contentHash;

  @override
  int get hashCode => Object.hash(number, contentHash);

  @override
  String toString() => 'CanonicalRevision($number, $contentHash)';
}

/// Computes a deterministic SHA-256 hash over a JSON-compatible map.
///
/// Object keys are sorted recursively (lexicographic). List order is
/// preserved. All values are included (null, nested maps, lists).
/// The result is lowercase hexadecimal (64 characters).
String canonicalJsonHash(Map<String, dynamic> value) {
  final canonical = _canonicalize(value);
  final bytes = utf8.encode(canonical);
  return sha256.convert(bytes).toString();
}

/// Computes a deterministic SHA-256 hash over text content.
///
/// CRLF (`\r\n`) sequences are normalized to LF (`\n`). Standalone `\r`
/// is left unchanged. Leading/trailing whitespace is NOT trimmed.
/// The result is lowercase hexadecimal (64 characters).
String canonicalTextHash(String value) {
  final normalized = value.replaceAll('\r\n', '\n');
  final bytes = utf8.encode(normalized);
  return sha256.convert(bytes).toString();
}

/// Produces a canonical JSON string with recursively sorted keys.
String _canonicalize(Object? value) {
  final buffer = StringBuffer();
  _writeValue(value, buffer);
  return buffer.toString();
}

void _writeValue(Object? value, StringBuffer buffer) {
  if (value == null) {
    buffer.write('null');
  } else if (value is Map<String, dynamic>) {
    _writeMap(value, buffer);
  } else if (value is Map) {
    _writeMap(Map<String, dynamic>.from(value), buffer);
  } else if (value is List) {
    _writeList(value, buffer);
  } else if (value is String) {
    _writeString(value, buffer);
  } else if (value is bool) {
    buffer.write(value ? 'true' : 'false');
  } else if (value is num) {
    buffer.write(value.toString());
  } else {
    // Fallback: encode as string representation.
    _writeString(value.toString(), buffer);
  }
}

void _writeMap(Map<String, dynamic> map, StringBuffer buffer) {
  buffer.write('{');
  final keys = map.keys.toList()..sort();
  for (var i = 0; i < keys.length; i++) {
    if (i > 0) buffer.write(',');
    _writeString(keys[i], buffer);
    buffer.write(':');
    _writeValue(map[keys[i]], buffer);
  }
  buffer.write('}');
}

void _writeList(List list, StringBuffer buffer) {
  buffer.write('[');
  for (var i = 0; i < list.length; i++) {
    if (i > 0) buffer.write(',');
    _writeValue(list[i], buffer);
  }
  buffer.write(']');
}

void _writeString(String value, StringBuffer buffer) {
  buffer.write('"');
  for (final rune in value.runes) {
    switch (rune) {
      case 0x22: // "
        buffer.write(r'\"');
      case 0x5C: // \
        buffer.write(r'\\');
      case 0x08: // backspace
        buffer.write(r'\b');
      case 0x0C: // form feed
        buffer.write(r'\f');
      case 0x0A: // newline
        buffer.write(r'\n');
      case 0x0D: // carriage return
        buffer.write(r'\r');
      case 0x09: // tab
        buffer.write(r'\t');
      default:
        if (rune < 0x20) {
          buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else {
          buffer.writeCharCode(rune);
        }
    }
  }
  buffer.write('"');
}
