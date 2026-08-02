/// JSONL-based local RunStore adapter.
///
/// Stores events at `{basePath}/{runId}/events.jsonl`.
/// Hash chain and duplicate rules mirror LocalMutationJournal.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/runtime/run_models.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/run_store.dart';

/// File-based RunStore using append-only JSONL per Run.
final class JsonlRunStore implements RunStore {
  JsonlRunStore({required this.basePath});

  final String basePath;

  static const _zeroHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  File _eventsFile(String runId) => File('$basePath/$runId/events.jsonl');

  @override
  Future<Result<RunEvent>> append(RunEvent event) async {
    final existing = await _readEvents(event.runId);

    // Duplicate idempotency key check
    if (event.idempotencyKey != null) {
      final dup = existing
          .where((e) => e.idempotencyKey == event.idempotencyKey);
      if (dup.isNotEmpty) {
        return Result.success(dup.first);
      }
    }

    final sequence = existing.isEmpty ? 1 : existing.last.sequence + 1;
    final previousHash =
        existing.isEmpty ? _zeroHash : _hashEvent(existing.last);
    final payloadHash = _hashPayload(event.payload);

    final stamped = event.copyWith(
      sequence: sequence,
      occurredAt: DateTime.now().toUtc().toIso8601String(),
      payloadHash: payloadHash,
      previousEventHash: previousHash,
    );

    final file = _eventsFile(event.runId);
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(stamped.toJson())}\n',
        mode: FileMode.append, flush: true);

    return Result.success(stamped);
  }

  @override
  Future<Result<List<RunEvent>>> readAll(String runId) async {
    final events = await _readEvents(runId);
    return Result.success(events);
  }

  @override
  Future<Result<List<RunEvent>>> readFrom(
      String runId, int fromSequence) async {
    final events = await _readEvents(runId);
    final filtered =
        events.where((e) => e.sequence >= fromSequence).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<bool>> validateChain(String runId) async {
    final events = await _readEvents(runId);
    if (events.isEmpty) return Result.success(true);

    if (events.first.previousEventHash != _zeroHash) {
      return Result.success(false);
    }

    for (var i = 1; i < events.length; i++) {
      final expected = _hashEvent(events[i - 1]);
      if (events[i].previousEventHash != expected) {
        return Result.success(false);
      }
    }

    return Result.success(true);
  }

  @override
  Future<Result<List<String>>> listRuns() async {
    final dir = Directory(basePath);
    if (!await dir.exists()) return Result.success([]);

    final runIds = <String>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (await _eventsFile(name).exists()) {
          runIds.add(name);
        }
      }
    }
    return Result.success(runIds);
  }

  Future<List<RunEvent>> _readEvents(String runId) async {
    final file = _eventsFile(runId);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    final events = <RunEvent>[];

    for (final line in lines) {
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        events.add(RunEvent.fromJson(json));
      } catch (_) {
        break; // Truncated final line recovery
      }
    }

    return events;
  }

  String _hashEvent(RunEvent event) {
    return sha256.convert(utf8.encode(jsonEncode(event.toJson()))).toString();
  }

  String _hashPayload(Map<String, dynamic> payload) {
    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }
}
