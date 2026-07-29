import 'dart:convert';
import 'dart:io';

import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/modules/story_graph/story_graph.dart';

final class StoryGraphRevisionConflict implements Exception {
  const StoryGraphRevisionConflict(
      {required this.expected, required this.actual});

  final int expected;
  final int actual;

  @override
  String toString() =>
      'StoryGraphRevisionConflict(expected: $expected, actual: $actual)';
}

/// Durable seam for one project's time-aware story assertions.
final class StoryGraphRepository {
  StoryGraphRepository({required Directory rootDirectory})
      : _rootDirectory = rootDirectory;

  final Directory _rootDirectory;

  Future<StoryGraph> load(String projectId) async {
    final file = _fileFor(projectId);
    if (!await file.exists()) return StoryGraph.empty(projectId);
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Story graph must be a JSON object');
    }
    final graph = StoryGraph.fromJson(decoded);
    if (graph.projectId != projectId) {
      throw const FormatException('Story graph projectId does not match file');
    }
    return graph;
  }

  Future<StoryGraph> save(
    StoryGraph graph, {
    int? expectedRevision,
  }) async {
    final current = await load(graph.projectId);
    if (expectedRevision != null && current.revision != expectedRevision) {
      throw StoryGraphRevisionConflict(
        expected: expectedRevision,
        actual: current.revision,
      );
    }
    final persisted = graph.copyWith(revision: current.revision + 1);
    await _writeAtomically(_fileFor(graph.projectId), persisted.toJson());
    return persisted;
  }

  Future<List<StoryFact>> factsAt(
    String projectId,
    int chapter, {
    String? entityId,
    String? predicate,
  }) async =>
      (await load(projectId)).factsAt(
        chapter,
        entityId: entityId,
        predicate: predicate,
      );

  Future<StoryGraph> confirm(String projectId, String assertionId) async {
    final graph = await load(projectId);
    return save(graph.confirm(assertionId), expectedRevision: graph.revision);
  }

  Future<StoryGraph> reject(String projectId, String assertionId) async {
    final graph = await load(projectId);
    return save(graph.reject(assertionId), expectedRevision: graph.revision);
  }

  Future<StoryGraph> undo(String projectId, String assertionId) async {
    final graph = await load(projectId);
    return save(graph.undo(assertionId), expectedRevision: graph.revision);
  }

  Future<StoryGraph> migrateFromCanon(
    String projectId,
    Iterable<CanonEntry> entries,
  ) async {
    var graph = await load(projectId);
    for (final entry
        in entries.where((entry) => entry.projectId == projectId)) {
      graph = graph.withEntity(
        StoryEntity(
          id: entry.id,
          type: _entityType(entry.type),
          canonicalName: entry.name,
          aliases: _aliases(entry.attributes['aliases']),
          attributes: Map.unmodifiable(entry.attributes),
        ),
      );
      if (entry.description.trim().isNotEmpty) {
        final sourceDocumentId =
            entry.attributes['sourceDocumentId'] as String? ??
                'canon:${entry.id}';
        graph = graph.withFact(
          StoryFact(
            id: 'canon:${entry.id}:description',
            entityId: entry.id,
            predicate: '描述',
            value: entry.description,
            validFromChapter:
                _chapter(entry.attributes['validFromChapter']) ?? 0,
            validToChapter: _chapter(entry.attributes['validToChapter']),
            sourceDocumentId: sourceDocumentId,
            sourceRange: SourceRange(start: 0, end: entry.description.length),
            confidence: 1,
            confirmation: ConfirmationStatus.confirmed,
          ),
        );
      }
    }
    return save(graph, expectedRevision: graph.revision);
  }

  File _fileFor(String projectId) {
    if (projectId.isEmpty ||
        projectId.contains('/') ||
        projectId.contains(r'\') ||
        projectId.contains('..')) {
      throw ArgumentError.value(projectId, 'projectId', 'Unsafe project ID');
    }
    return File(
      '${_rootDirectory.path}${Platform.pathSeparator}$projectId.story_graph.json',
    );
  }

  Future<void> _writeAtomically(
    File file,
    Map<String, dynamic> data,
  ) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temp.writeAsString(jsonEncode(data), flush: true);
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

StoryEntityType _entityType(CanonEntryType type) => switch (type) {
      CanonEntryType.character => StoryEntityType.character,
      CanonEntryType.location => StoryEntityType.location,
      CanonEntryType.lore => StoryEntityType.lore,
      CanonEntryType.plotNode => StoryEntityType.plotNode,
    };

List<String> _aliases(Object? value) {
  if (value is String) {
    return value
        .split(RegExp(r'[,，、]'))
        .map((alias) => alias.trim())
        .where((alias) => alias.isNotEmpty)
        .toList(growable: false);
  }
  if (value is List) {
    return value
        .whereType<String>()
        .map((alias) => alias.trim())
        .where((alias) => alias.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

int? _chapter(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
