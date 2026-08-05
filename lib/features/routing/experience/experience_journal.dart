import 'dart:convert';
import 'dart:io';

import 'experience_entry.dart';

export 'experience_entry.dart';

/// JSONL experience journal used by Fusion module C.
class ExperienceJournal {
  ExperienceJournal({required String basePath}) : _dir = Directory(basePath);

  final Directory _dir;
  static int _sequence = 0;

  void recordCompleted({
    required String scene,
    required String userMessage,
    String summary = '',
    List<String> nodeChain = const [],
    String? outputGateResult,
  }) {
    _append(ExperienceEntry(
      id: _nextId(),
      scene: scene,
      userMessage: userMessage,
      outcome: ExperienceOutcome.completed,
      summary: summary,
      nodeChain: nodeChain,
      outputGateResult: outputGateResult,
    ));
  }

  void recordMiss({
    required String scene,
    required String userMessage,
    String summary = '未命中可用路由',
  }) {
    _append(ExperienceEntry(
      id: _nextId(),
      scene: scene,
      userMessage: userMessage,
      outcome: ExperienceOutcome.miss,
      summary: summary,
    ));
  }

  void recordFailed({
    required String scene,
    required String userMessage,
    String summary = '',
    List<String> nodeChain = const [],
    String? outputGateResult,
  }) {
    _append(ExperienceEntry(
      id: _nextId(),
      scene: scene,
      userMessage: userMessage,
      outcome: ExperienceOutcome.failed,
      summary: summary,
      nodeChain: nodeChain,
      outputGateResult: outputGateResult,
    ));
  }

  /// Returns entries whose scene exactly matches, newest first.
  List<ExperienceEntry> search(String scene) {
    _dir.createSync(recursive: true);
    final file = File('${_dir.path}/experience.jsonl');
    if (!file.existsSync()) return const [];

    final entries = <ExperienceEntry>[];
    for (final line in file.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      try {
        final entry = ExperienceEntry.fromJson(
          jsonDecode(line) as Map<String, dynamic>,
        );
        if (entry.scene == scene) entries.add(entry);
      } catch (_) {
        // Ignore malformed lines so a corrupt journal does not crash routing.
      }
    }
    entries.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return entries;
  }

  void _append(ExperienceEntry entry) {
    _dir.createSync(recursive: true);
    final file = File('${_dir.path}/experience.jsonl');
    file.writeAsStringSync(
      '${jsonEncode(entry.toJson())}\n',
      mode: FileMode.append,
    );
  }

  String _nextId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final seq = _sequence++;
    return 'exp-$now-$seq';
  }
}
