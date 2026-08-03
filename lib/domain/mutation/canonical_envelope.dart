/// Versioned canonical JSON envelope for project-owned state.
library;

import 'dart:convert';

import 'canonical_revision.dart';

final class CanonicalJsonEnvelope {
  const CanonicalJsonEnvelope({
    required this.schemaVersion,
    required this.revision,
    required this.contentHash,
    required this.payload,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int revision;
  final String contentHash;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'revision': revision,
        'content_hash': contentHash,
        'payload': payload,
      };

  String encode() => canonicalJsonEncode(toJson());

  static CanonicalJsonEnvelope decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Canonical envelope must be a JSON object');
    }
    return fromJson(Map<String, dynamic>.from(decoded));
  }

  static CanonicalJsonEnvelope fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schema_version'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported canonical schema: $schemaVersion');
    }

    final revision = json['revision'];
    final contentHash = json['content_hash'];
    final rawPayload = json['payload'];
    if (revision is! int || contentHash is! String || rawPayload is! Map) {
      throw const FormatException('Malformed canonical envelope');
    }

    final payload = Map<String, dynamic>.from(rawPayload);
    if (canonicalPayloadHash(payload) != contentHash) {
      throw const FormatException('Canonical payload hash mismatch');
    }

    return CanonicalJsonEnvelope(
      schemaVersion: schemaVersion as int,
      revision: revision,
      contentHash: contentHash,
      payload: payload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalJsonEnvelope &&
          schemaVersion == other.schemaVersion &&
          revision == other.revision &&
          contentHash == other.contentHash &&
          canonicalJsonEncode(payload) == canonicalJsonEncode(other.payload);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        revision,
        contentHash,
        canonicalJsonEncode(payload),
      );
}
