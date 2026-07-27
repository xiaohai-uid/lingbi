/// Planning matrix service for scene card management.
///
/// Provides CRUD, filtering, transactional reorder with undo, and
/// chapter synchronization for scene cards stored as portable JSON.
library;

import 'dart:convert';
import 'dart:io';

import 'package:lingbi/domain/planning/scene_card.dart';

export 'package:lingbi/domain/planning/scene_card.dart'
    show RevisionConflictException;

class SceneFilter {
  const SceneFilter({this.povCharacter, this.location, this.subplot});

  final String? povCharacter;
  final String? location;
  final String? subplot;

  bool matches(SceneCard card) {
    if (povCharacter != null && card.povCharacter != povCharacter) return false;
    if (location != null && card.location != location) return false;
    if (subplot != null && card.subplot != subplot) return false;
    return true;
  }
}

class PlanningMatrixService {
  PlanningMatrixService({required this.storageDir});

  final String storageDir;
  final Map<String, List<List<String>>> _reorderHistory = {};

  String _projectDir(String projectId) => '$storageDir/$projectId';
  String _cardsFile(String projectId) => '${_projectDir(projectId)}/scenes.json';

  Future<List<SceneCard>> _loadAll(String projectId) async {
    final file = File(_cardsFile(projectId));
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SceneCard.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
  }

  Future<void> _saveAll(String projectId, List<SceneCard> cards) async {
    final dir = Directory(_projectDir(projectId));
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(_cardsFile(projectId));
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(cards.map((c) => c.toJson()).toList()),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<SceneCard> createCard({
    required String projectId,
    required String title,
    required int chapterIndex,
    String? povCharacter,
    String? location,
    String? subplot,
    String? summary,
    List<String> beats = const [],
  }) async {
    final cards = await _loadAll(projectId);
    final card = SceneCard(
      id: 'scene-${DateTime.now().microsecondsSinceEpoch}-${cards.length}',
      projectId: projectId,
      title: title,
      chapterIndex: chapterIndex,
      revision: 1,
      povCharacter: povCharacter,
      location: location,
      subplot: subplot,
      summary: summary,
      beats: beats,
      updatedAt: DateTime.now().toUtc(),
    );
    cards.add(card);
    await _saveAll(projectId, cards);
    return card;
  }

  Future<SceneCard> updateCard({
    required String projectId,
    required String cardId,
    required int expectedRevision,
    String? title,
    String? povCharacter,
    String? location,
    String? subplot,
    String? summary,
    List<String>? beats,
  }) async {
    final cards = await _loadAll(projectId);
    final index = cards.indexWhere((c) => c.id == cardId);
    if (index < 0) {
      throw const RevisionConflictException('Card not found');
    }
    final existing = cards[index];
    if (existing.revision != expectedRevision) {
      throw RevisionConflictException(
        'Expected revision $expectedRevision but found ${existing.revision}',
      );
    }
    final updated = existing.copyWith(
      title: title,
      povCharacter: povCharacter,
      location: location,
      subplot: subplot,
      summary: summary,
      beats: beats,
      revision: existing.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    cards[index] = updated;
    await _saveAll(projectId, cards);
    return updated;
  }

  Future<List<SceneCard>> getCards(
    String projectId, {
    SceneFilter? filter,
  }) async {
    final cards = await _loadAll(projectId);
    if (filter == null) return cards;
    return cards.where(filter.matches).toList();
  }

  Future<void> reorder({
    required String projectId,
    required List<String> orderedIds,
  }) async {
    final cards = await _loadAll(projectId);
    // Save current order for undo
    _reorderHistory.putIfAbsent(projectId, () => []);
    _reorderHistory[projectId]!
        .add(cards.map((c) => c.id).toList());

    final cardMap = {for (final c in cards) c.id: c};
    final reordered = <SceneCard>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final card = cardMap[orderedIds[i]];
      if (card != null) {
        reordered.add(card.copyWith(
          chapterIndex: i + 1,
          revision: card.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ));
      }
    }
    await _saveAll(projectId, reordered);
  }

  Future<void> undoReorder(String projectId) async {
    final history = _reorderHistory[projectId];
    if (history == null || history.isEmpty) return;
    final previousOrder = history.removeLast();
    final cards = await _loadAll(projectId);
    final cardMap = {for (final c in cards) c.id: c};
    final restored = <SceneCard>[];
    for (var i = 0; i < previousOrder.length; i++) {
      final card = cardMap[previousOrder[i]];
      if (card != null) {
        restored.add(card.copyWith(
          chapterIndex: i + 1,
          revision: card.revision + 1,
          updatedAt: DateTime.now().toUtc(),
        ));
      }
    }
    await _saveAll(projectId, restored);
  }
}
