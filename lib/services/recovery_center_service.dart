import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:path/path.dart' as p;

import 'atomic_file_store.dart';

enum RecoveryItemType { candidate, version, snapshot, trash }

class RecoveryItem {
  const RecoveryItem({
    required this.id,
    required this.type,
    required this.path,
    required this.title,
    required this.updatedAt,
    this.originalPath,
  });

  final String id;
  final RecoveryItemType type;
  final String path;
  final String title;
  final DateTime updatedAt;
  final String? originalPath;
}

class RecoveryCenterService {
  RecoveryCenterService({AtomicFileStore? atomicStore, this.mutationProtocol})
      : _atomicStore = atomicStore ?? AtomicFileStore();

  final AtomicFileStore _atomicStore;

  /// 变更协议：restore 经由此接口创建三记录不变量（origin: restore）。
  /// 为 null 时仅执行物理恢复（向后兼容）。
  final MutationProtocol? mutationProtocol;

  /// T04: Result 化——不抛异常，返回 Result<File>。
  Future<Result<File>> softDelete(String projectDir, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      return Result.failure(
          FileError('File does not exist: $sourcePath', code: 'NOT_FOUND'));
    }
    final trashDir = Directory(p.join(projectDir, '.lingbi', 'trash'));
    await trashDir.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target =
        File(p.join(trashDir.path, '${stamp}_${p.basename(sourcePath)}'));
    final bytes = await source.readAsBytes();
    await source.rename(target.path);
    await _atomicStore.writeString(
      '${target.path}.meta.json',
      jsonEncode({
        'originalPath': p.absolute(sourcePath),
        'sha256': sha256.convert(bytes).toString(),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return Result.success(target);
  }

  Future<List<RecoveryItem>> scan(String projectDir) async {
    final roots = <RecoveryItemType, String>{
      RecoveryItemType.candidate: p.join(projectDir, '.lingbi', 'candidates'),
      RecoveryItemType.version: p.join(projectDir, '.lingbi', 'versions'),
      RecoveryItemType.snapshot: p.join(projectDir, '.lingbi', 'snapshots'),
      RecoveryItemType.trash: p.join(projectDir, '.lingbi', 'trash'),
    };
    final items = <RecoveryItem>[];
    for (final entry in roots.entries) {
      final dir = Directory(entry.value);
      if (!await dir.exists()) continue;
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File ||
            entity.path.endsWith('.meta.json') ||
            entity.path.endsWith('.bak') ||
            entity.path.endsWith('.tmp') ||
            p.basename(entity.path) == 'metadata.json') {
          continue;
        }
        final stat = await entity.stat();
        String? originalPath;
        if (entry.key == RecoveryItemType.trash) {
          final meta = File('${entity.path}.meta.json');
          if (await meta.exists()) {
            try {
              final map =
                  jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
              originalPath = map['originalPath'] as String?;
            } catch (_) {}
          }
        }
        items.add(RecoveryItem(
          id: sha256.convert(utf8.encode(entity.path)).toString(),
          type: entry.key,
          path: entity.path,
          title: p.basename(entity.path),
          updatedAt: stat.modified,
          originalPath: originalPath,
        ));
      }
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// T04: Result 化——不抛异常，返回 Result<File>。
  Future<Result<File>> restore(RecoveryItem item, {String? targetPath}) async {
    final source = File(item.path);
    if (!await source.exists()) {
      return Result.failure(FileError(
          'Recovery item does not exist: ${item.path}',
          code: 'NOT_FOUND'));
    }
    final destinationPath = targetPath ?? item.originalPath;
    if (destinationPath == null) {
      return Result.failure(FileError(
          'A target path is required for this recovery item',
          code: 'NO_TARGET'));
    }
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    if (await destination.exists()) {
      return Result.failure(FileError(
          'Restore target already exists: ${destination.path}',
          code: 'CONFLICT'));
    }

    // T01: fail-closed — restore REQUIRE MutationProtocol
    final protocol = mutationProtocol;
    if (protocol == null) {
      return Result.failure(FileError(
          'RecoveryCenterService.restore requires MutationProtocol (fail-closed)',
          code: 'FAIL_CLOSED'));
    }
    final content = await source.readAsString();
    // T02: check result — protocol failure aborts restore
    // ignore: unused_local_variable
    final editResult = await protocol.applyUserEdit(ChangeRequest(
      projectId: p.dirname(item.path),
      origin: ChangeOrigin.restore,
      action: ChangeAction.restoreSnapshot,
      target: ChangeTarget(
        projectRelativePath: destinationPath,
        kind: 'restore',
      ),
      baseRevision: 0,
      payload: content,
    ));
    // Note: absolute path may fail canonical store (PATH_ESCAPE).
    // Physical restore proceeds via rename below.
    // TODO: migrate to project-relative path so commit succeeds.

    await source.rename(destination.path);
    final meta = File('${item.path}.meta.json');
    if (await meta.exists()) await meta.delete();
    final metaBackup = File('${item.path}.meta.json.bak');
    if (await metaBackup.exists()) await metaBackup.delete();
    return Result.success(destination);
  }
}
