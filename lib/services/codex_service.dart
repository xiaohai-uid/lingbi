import 'package:lingbi/services/interfaces/i_codex_service.dart';
import 'package:flutter/foundation.dart';
import '../core/models/codex_entry.dart';
import '../core/database/zvec_service.dart';
import '../core/ai/ai_provider.dart';

class CodexService implements ICodexService {
  final ZVecService _zvec;

  CodexService({required ZVecService zvecService})
      : _zvec = zvecService;

  String _collectionName(CodexEntryType type) {
    switch (type) {
      case CodexEntryType.character:
        return 'characters';
      case CodexEntryType.location:
        return 'locations';
      case CodexEntryType.lore:
        return 'lore_entries';
      case CodexEntryType.plotNode:
        return 'plot_nodes';
    }
  }

  String _vectorField(CodexEntryType type) {
    switch (type) {
      case CodexEntryType.character:
        return 'profile_embedding';
      case CodexEntryType.location:
        return 'desc_embedding';
      case CodexEntryType.lore:
        return 'content_embedding';
      case CodexEntryType.plotNode:
        return 'summary_embedding';
    }
  }

  String _embedText(CodexEntry entry) {
    switch (entry.type) {
      case CodexEntryType.character:
        return '${entry.name} ${entry.description} ${entry.attributes['personality'] ?? ''} ${entry.attributes['backstory'] ?? ''}';
      case CodexEntryType.location:
        return '${entry.name} ${entry.description} ${entry.attributes['atmosphere'] ?? ''}';
      case CodexEntryType.lore:
        return '${entry.name} ${entry.description} ${entry.attributes['content'] ?? ''}';
      case CodexEntryType.plotNode:
        return '${entry.name} ${entry.description} ${entry.attributes['chapter'] ?? ''} ${entry.attributes['scene'] ?? ''}';
    }
  }

  /// Create a codex entry with auto-embedding
  @override
  Future<CodexEntry> create(CodexEntry entry, {AIProvider? provider}) async {
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
      debugPrint('Failed to generate embedding for codex entry: $e');
      }
    }
    return entry;
  }

  /// Get all entries of a type for a project
  @override
  @override
  Future<List<CodexEntry>> list(String projectId, CodexEntryType type) async {
    final results = await _zvec.query(
      _collectionName(type),
      filter: {'projectId': projectId},
    );
    return results.map((json) => CodexEntry.fromJson(json)).toList();
  }

  /// Get a single entry
  @override
  @override
  Future<CodexEntry?> get(String id, CodexEntryType type) async {
    final result = await _zvec.get<Map<String, dynamic>>(_collectionName(type), id);
    if (result == null) return null;
    return CodexEntry.fromJson(result);
  }

  /// Update an entry with auto-embedding
  @override
  Future<CodexEntry> update(CodexEntry entry, {AIProvider? provider}) async {
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
      debugPrint('Failed to generate embedding for codex entry: $e');
      }
    }
    return entry;
  }

  /// Delete an entry
  @override
  Future<void> delete(CodexEntry entry) async {
    await _zvec.delete(_collectionName(entry.type), entry.id);
  }

  /// Search entries across all types (text-based fallback)
  @override
  @override
  Future<List<CodexEntry>> search(String projectId, String query) async {
    final results = <CodexEntry>[];
    for (final type in CodexEntryType.values) {
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
  Future<List<CodexEntry>> semanticSearch(
    String projectId,
    String query, {
    required AIProvider provider,
    int limit = 10,
  }) async {
    if (!provider.isAvailable) return [];

    try {
      final queryVector = await provider.embed(query);
      final results = <CodexEntry>[];

      for (final type in CodexEntryType.values) {
        final vectorResults = await _zvec.vectorSearch(
          _collectionName(type),
          vectorField: _vectorField(type),
          vector: queryVector,
          filter: {'projectId': projectId},
          limit: limit,
        );
        results.addAll(vectorResults.map((json) => CodexEntry.fromJson(json)));
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
  @override
  Future<Map<CodexEntryType, List<CodexEntry>>> getAllForProject(String projectId) async {
    return {
      CodexEntryType.character: await list(projectId, CodexEntryType.character),
      CodexEntryType.location: await list(projectId, CodexEntryType.location),
      CodexEntryType.lore: await list(projectId, CodexEntryType.lore),
      CodexEntryType.plotNode: await list(projectId, CodexEntryType.plotNode),
    };
  }
}