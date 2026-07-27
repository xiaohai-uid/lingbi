import 'dart:io';

typedef AtomicReplace = Future<void> Function(File source, File destination);

/// Crash-safe file replacement with a recoverable previous generation.
class AtomicFileStore {
  AtomicFileStore({AtomicReplace? replace}) : _replace = replace ?? _rename;

  final AtomicReplace _replace;

  static Future<void> _rename(File source, File destination) async {
    await source.rename(destination.path);
  }

  Future<void> writeString(String path, String content) async {
    final temp = File('$path.tmp');
    await temp.parent.create(recursive: true);
    await temp.writeAsString(content, flush: true);
    await _commit(path, temp);
  }

  Future<void> writeBytes(String path, List<int> content) async {
    final temp = File('$path.tmp');
    await temp.parent.create(recursive: true);
    await temp.writeAsBytes(content, flush: true);
    await _commit(path, temp);
  }

  Future<void> _commit(String path, File temp) async {
    final target = File(path);
    final backup = File('$path.bak');
    var movedOriginal = false;
    try {
      if (await target.exists()) {
        if (await backup.exists()) await backup.delete();
        await target.rename(backup.path);
        movedOriginal = true;
      }
      await _replace(temp, target);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      if (movedOriginal && !await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  Future<String?> readString(
    String path, {
    bool Function(String value)? validator,
  }) async {
    for (final file in [File(path), File('$path.bak')]) {
      if (!await file.exists()) continue;
      try {
        final value = await file.readAsString();
        if (validator == null || validator(value)) return value;
      } catch (_) {
        // Try the previous committed generation.
      }
    }
    return null;
  }
}
