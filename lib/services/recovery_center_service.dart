import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
  RecoveryCenterService({AtomicFileStore? atomicStore})
      : _atomicStore = atomicStore ?? AtomicFileStore();

  final AtomicFileStore _atomicStore;

  Future<File> softDelete(String projectDir, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('File does not exist', sourcePath);
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
    return target;
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

  Future<File> restore(RecoveryItem item, {String? targetPath}) async {
    final source = File(item.path);
    if (!await source.exists()) {
      throw FileSystemException('Recovery item does not exist', item.path);
    }
    final destinationPath = targetPath ?? item.originalPath;
    if (destinationPath == null) {
      throw StateError('A target path is required for this recovery item');
    }
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    if (await destination.exists()) {
      throw FileSystemException(
          'Restore target already exists', destination.path);
    }
    await source.rename(destination.path);
    final meta = File('${item.path}.meta.json');
    if (await meta.exists()) await meta.delete();
    final metaBackup = File('${item.path}.meta.json.bak');
    if (await metaBackup.exists()) await metaBackup.delete();
    return destination;
  }
}
