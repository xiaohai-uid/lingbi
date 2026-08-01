/// File-based checkpoint store using AtomicFileStore.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/runtime/checkpoint.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/checkpoint_store.dart';

/// Persists checkpoints as JSON files at basePath/runId/checkpoint.json.
final class FileCheckpointStore implements CheckpointStore {
  FileCheckpointStore({required this.basePath});

  final String basePath;

  File _checkpointFile(String runId) =>
      File('$basePath/$runId/checkpoint.json');

  @override
  Future<Result<void>> save(Checkpoint checkpoint) async {
    final file = _checkpointFile(checkpoint.runId);
    await file.parent.create(recursive: true);

    final json = checkpoint.toJson();
    json['checkpoint_hash'] = _computeHash(checkpoint);
    json['created_at'] = DateTime.now().toUtc().toIso8601String();

    // Atomic write: tmp + rename
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(file.path);

    return Result.success(null);
  }

  @override
  Future<Result<Checkpoint?>> load(String runId) async {
    final file = _checkpointFile(runId);
    if (!await file.exists()) return Result.success(null);

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final checkpoint = Checkpoint.fromJson(json);

      // Validate hash integrity
      final expectedHash = _computeHash(checkpoint);
      if (checkpoint.checkpointHash != expectedHash) {
        return Result.success(null); // Corrupted checkpoint
      }

      return Result.success(checkpoint);
    } catch (_) {
      return Result.success(null); // Unreadable checkpoint
    }
  }

  @override
  Future<Result<void>> delete(String runId) async {
    final file = _checkpointFile(runId);
    if (await file.exists()) {
      await file.delete();
    }
    return Result.success(null);
  }

  String _computeHash(Checkpoint checkpoint) {
    final payload =
        '${checkpoint.runId}:${checkpoint.lastEventSequence}:${checkpoint.lastEventHash}:${checkpoint.status.wireName}:${checkpoint.projectBriefRevision}';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
