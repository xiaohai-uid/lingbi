import 'dart:convert';
import 'dart:io';

import 'first_chapter_event.dart';

abstract interface class FirstChapterStateStore {
  Future<FirstChapterState?> read(String projectId);
  Future<void> write(FirstChapterState state);
}

class FileFirstChapterStateStore implements FirstChapterStateStore {
  FileFirstChapterStateStore({required String projectDirectory})
      : stateFilePath =
            '$projectDirectory/.lingbi/workflows/first_chapter.json';

  final String stateFilePath;

  @override
  Future<FirstChapterState?> read(String projectId) async {
    final file = File(stateFilePath);
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final state = FirstChapterState.fromJson(json);
      return state.projectId == projectId ? state : null;
    } catch (_) {
      final backup = File('$stateFilePath.bak');
      if (!await backup.exists()) return null;
      final json =
          jsonDecode(await backup.readAsString()) as Map<String, dynamic>;
      final state = FirstChapterState.fromJson(json);
      return state.projectId == projectId ? state : null;
    }
  }

  @override
  Future<void> write(FirstChapterState state) async {
    final file = File(stateFilePath);
    final temp = File('$stateFilePath.tmp');
    final backup = File('$stateFilePath.bak');
    await file.parent.create(recursive: true);
    await temp.writeAsString(jsonEncode(state.toJson()), flush: true);
    try {
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) await file.rename(backup.path);
      await temp.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }
}
