/// Append-only local mutation journal with hash-chain integrity.
///
/// Layout: `{basePath}/events.jsonl`
/// Each line: schema_version, sequence, event_id, event_type, aggregate_id,
/// timestamp, payload_hash, previous_event_hash, and optional idempotency_key.
///
/// Crash safety: a truncated final line is discarded on recovery.
/// Duplicate event_id or idempotency_key returns the existing record.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// A single journal event (immutable value).
final class JournalEvent {
  const JournalEvent({
    required this.eventId,
    required this.eventType,
    required this.aggregateId,
    required this.payload,
    this.idempotencyKey,
    this.schemaVersion = 1,
    this.sequence = 0,
    this.timestamp,
    this.payloadHash = '',
    this.previousEventHash = '',
  });

  factory JournalEvent.fromJson(Map<String, dynamic> json) => JournalEvent(
        schemaVersion: json['schema_version'] as int? ?? 1,
        sequence: json['sequence'] as int? ?? 0,
        eventId: json['event_id'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        aggregateId: json['aggregate_id'] as String? ?? '',
        timestamp: json['timestamp'] as String?,
        payloadHash: json['payload_hash'] as String? ?? '',
        previousEventHash: json['previous_event_hash'] as String? ?? '',
        idempotencyKey: json['idempotency_key'] as String?,
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      );

  final int schemaVersion;
  final int sequence;
  final String eventId;
  final String eventType;
  final String aggregateId;
  final String? timestamp;
  final String payloadHash;
  final String previousEventHash;
  final String? idempotencyKey;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'sequence': sequence,
        'event_id': eventId,
        'event_type': eventType,
        'aggregate_id': aggregateId,
        'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
        'payload_hash': payloadHash,
        'previous_event_hash': previousEventHash,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        'payload': payload,
      };

  JournalEvent copyWith({
    int? sequence,
    String? timestamp,
    String? payloadHash,
    String? previousEventHash,
  }) =>
      JournalEvent(
        schemaVersion: schemaVersion,
        sequence: sequence ?? this.sequence,
        eventId: eventId,
        eventType: eventType,
        aggregateId: aggregateId,
        timestamp: timestamp ?? this.timestamp,
        payloadHash: payloadHash ?? this.payloadHash,
        previousEventHash: previousEventHash ?? this.previousEventHash,
        idempotencyKey: idempotencyKey,
        payload: payload,
      );
}

/// Result of an append operation.
final class AppendResult {
  const AppendResult({required this.event, required this.duplicate});

  final JournalEvent event;
  final bool duplicate;
}

/// Append-only JSONL journal with hash-chain integrity.
final class LocalMutationJournal {
  LocalMutationJournal({required this.basePath});

  final String basePath;

  static const _zeroHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  File get _eventsFile => File('$basePath/events.jsonl');

  /// Append an event to the journal.
  ///
  /// Returns the persisted event. If event_id or idempotency_key already
  /// exists, returns the existing record with duplicate=true.
  Future<AppendResult> append(JournalEvent event) async {
    final existing = await readAll();

    // Duplicate event_id check
    final byId = existing.where((e) => e.eventId == event.eventId);
    if (byId.isNotEmpty) {
      return AppendResult(event: byId.first, duplicate: true);
    }

    // Duplicate idempotency_key check
    if (event.idempotencyKey != null) {
      final byKey =
          existing.where((e) => e.idempotencyKey == event.idempotencyKey);
      if (byKey.isNotEmpty) {
        return AppendResult(event: byKey.first, duplicate: true);
      }
    }

    final sequence = existing.isEmpty ? 1 : existing.last.sequence + 1;
    final previousHash =
        existing.isEmpty ? _zeroHash : _hashEvent(existing.last);
    final payloadHash = _hashPayload(event.payload);

    final stamped = event.copyWith(
      sequence: sequence,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      payloadHash: payloadHash,
      previousEventHash: previousHash,
    );

    await _eventsFile.parent.create(recursive: true);
    final line = '${jsonEncode(stamped.toJson())}\n';
    await _eventsFile.writeAsString(line,
        mode: FileMode.append, flush: true);

    return AppendResult(event: stamped, duplicate: false);
  }

  /// Read all valid events in sequence order.
  ///
  /// A truncated or unparseable final line is silently discarded (crash
  /// recovery). A corrupted middle line stops parsing at that point.
  Future<List<JournalEvent>> readAll() async {
    if (!await _eventsFile.exists()) return [];

    final content = await _eventsFile.readAsString();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    final events = <JournalEvent>[];

    for (final line in lines) {
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        events.add(JournalEvent.fromJson(json));
      } catch (_) {
        // Truncated final line or corruption: stop parsing.
        break;
      }
    }

    return events;
  }

  /// Read events filtered by aggregate id.
  Future<List<JournalEvent>> readByAggregate(String aggregateId) async {
    final all = await readAll();
    return all.where((e) => e.aggregateId == aggregateId).toList();
  }

  /// Validate the hash chain integrity.
  ///
  /// Returns true if the chain is intact, false if any event's
  /// previous_event_hash does not match the computed hash of its predecessor.
  Future<bool> validateChain() async {
    final events = await readAll();
    if (events.isEmpty) return true;

    // First event must reference zero hash
    if (events.first.previousEventHash != _zeroHash) return false;

    for (var i = 1; i < events.length; i++) {
      final expectedHash = _hashEvent(events[i - 1]);
      if (events[i].previousEventHash != expectedHash) return false;
    }

    return true;
  }

  /// Compute the deterministic hash of a journal event line.
  String _hashEvent(JournalEvent event) {
    final canonical = jsonEncode(event.toJson());
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  /// Compute the hash of a payload map.
  String _hashPayload(Map<String, dynamic> payload) {
    final canonical = jsonEncode(payload);
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
