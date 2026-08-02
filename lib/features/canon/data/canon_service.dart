import 'package:lingbi/shared/interfaces/i_canon_service.dart';
import 'package:flutter/foundation.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

class CanonService implements ICanonService {

  CanonService({required ZVecService zvecService})
      : _zvec = zvecService;
  final ZVecService _zvec;

  String _collectionName(CanonEntryType type) {
    switch (type) {
      case CanonEntryType.character:
        return 'characters';
      case CanonEntryType.location:
        return 'locations';
      case CanonEntryType.lore:
        return 'lore_entries';
      case CanonEntryType.plotNode:
        return 'plot_nodes';
    }
  }

  String _vectorField(CanonEntryType type) {
    switch (type) {
      case CanonEntryType.character:
        return 'profile_embedding';
      case CanonEntryType.location:
        return 'desc_embedding';
      case CanonEntryType.lore:
        return 'content_embedding';
      case CanonEntryType.plotNode:
        return 'summary_embedding';
    }
  }

  String _embedText(CanonEntry entry) {
    switch (entry.type) {
      case CanonEntryType.character:
        return '${entry.name} ${entry.description} ${entry.attributes['personality'] ?? ''} ${entry.attributes['backstory'] ?? ''}';
      case CanonEntryType.location:
        return '${entry.name} ${entry.description} ${entry.attributes['atmosphere'] ?? ''}';
      case CanonEntryType.lore:
        return '${entry.name} ${entry.description} ${entry.attributes['content'] ?? ''}';
      case CanonEntryType.plotNode:
        return '${entry.name} ${entry.description} ${entry.attributes['chapter'] ?? ''} ${entry.attributes['scene'] ?? ''}';
    }
  }

  /// Create a canon entry with auto-embedding
  @override
  Future<CanonEntry> create(CanonEntry entry, {AIProvider? provider}) async {
    await _zvec.upsert(_collectionName(entry.type), entry.id, entry.toJson());
    if (provider != null && provider.isAvailable) {
      try {
        final text = _embedText(entry);
        final embedding = await provider.embed(text);
        await _zvec.updateVector(
          _collectionName(entry.type),
          entry.id,
          _vectorField(entry.type),
          embedding,
        );
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Failed to generate embedding for canon entry: $e');
      }
    }
    return entry;
  }

  /// Get all entries of a type for a project
  @override
  Future<List<CanonEntry>> list(String projectId, CanonEntryType type) async {
    final results = await _zvec.query(
      _collectionName(type),
      filter: {'projectId': projectId},
    );
    return results.map((json) => CanonEntry.fromJson(json)).toList();
  }

  /// Get a single entry
  @override
  Future<CanonEntry?> get(String id, CanonEntryType type) async {
    final result = await _zvec.get<Map<String, dynamic>>(_collectionName(type), id);
    if (result == null) return null;
    return CanonEntry.fromJson(result);
  }

  /// Update an entry with auto-embedding
  @override
  Future<CanonEntry> update(CanonEntry entry, {AIProvider? provider}) async {
    entry.updatedAt = DateTime.now();
    await _zvec.upsert(_collectionName(entry.type), entry.id, entry.toJson());
    if (provider != null && provider.isAvailable) {
      try {
        final text = _embedText(entry);
        final embedding = await provider.embed(text);
        await _zvec.updateVector(
          _collectionName(entry.type),
          entry.id,
          _vectorField(entry.type),
          embedding,
        );
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Failed to generate embedding for canon entry: $e');
      }
    }
    return entry;
  }

  /// Delete an entry
  @override
  Future<void> delete(CanonEntry entry) async {
    await _zvec.delete(_collectionName(entry.type), entry.id);
  }

  /// Search entries across all types (text-based fallback)
  @override
  Future<List<CanonEntry>> search(String projectId, String query) async {
    final results = <CanonEntry>[];
    for (final type in CanonEntryType.values) {
      final entries = await list(projectId, type);
      final lowerQuery = query.toLowerCase();
      results.addAll(entries.where((e) =>
          e.name.toLowerCase().contains(lowerQuery) ||
          e.description.toLowerCase().contains(lowerQuery)));
    }
    return results;
  }

  /// Semantic search using vector similarity
  @override
  Future<List<CanonEntry>> semanticSearch(
    String projectId,
    String query, {
    required AIProvider provider,
    int limit = 10,
  }) async {
    if (!provider.isAvailable) return [];

    try {
      final queryVector = await provider.embed(query);
      final results = <CanonEntry>[];

      for (final type in CanonEntryType.values) {
        final vectorResults = await _zvec.vectorSearch(
          _collectionName(type),
          vectorField: _vectorField(type),
          vector: queryVector,
          filter: {'projectId': projectId},
          limit: limit,
        );
        results.addAll(vectorResults.map((json) => CanonEntry.fromJson(json)));
      }

      return results;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Semantic search error: $e');
      return [];
    }
  }

  /// Get all entries for a project (all types)
  @override
  Future<Map<CanonEntryType, List<CanonEntry>>> getAllForProject(String projectId) async {
    return {
      CanonEntryType.character: await list(projectId, CanonEntryType.character),
      CanonEntryType.location: await list(projectId, CanonEntryType.location),
      CanonEntryType.lore: await list(projectId, CanonEntryType.lore),
      CanonEntryType.plotNode: await list(projectId, CanonEntryType.plotNode),
    };
  }
}
