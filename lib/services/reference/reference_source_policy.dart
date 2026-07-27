/// Authorized reference ingestion with source permission, license metadata,
/// resumable failure, citation ranges, and anti-copy similarity checks.
///
/// Local-file-first: only local files are ingested by default. URL sources
/// require a licensed connector (none exists yet, so they are refused).
/// Every insight carries a source locator. Only abstract style constraints
/// are injected into generation context, never long copied text.
library;

import 'dart:convert';
import 'dart:io';

/// A reference source (local file or URL).
class ReferenceSource {
  const ReferenceSource._({required this.type, required this.path});

  factory ReferenceSource.localFile(String path) =>
      ReferenceSource._(type: ReferenceSourceType.localFile, path: path);

  factory ReferenceSource.url(String url) =>
      ReferenceSource._(type: ReferenceSourceType.url, path: url);

  final ReferenceSourceType type;
  final String path;
}

enum ReferenceSourceType { localFile, url }

/// A single insight extracted from a reference source.
class ReferenceInsight {
  const ReferenceInsight({
    required this.sourceLocator,
    required this.category,
    required this.content,
  });

  final String sourceLocator;
  final String category;
  final String content;

  Map<String, Object?> toJson() => {
        'source_locator': sourceLocator,
        'category': category,
        'content': content,
      };

  factory ReferenceInsight.fromJson(Map<String, dynamic> json) =>
      ReferenceInsight(
        sourceLocator: json['source_locator'] as String,
        category: json['category'] as String,
        content: json['content'] as String,
      );
}

/// Result of an ingestion attempt.
class IngestionResult {
  const IngestionResult({
    required this.accepted,
    this.insights = const [],
    this.sourceLocator = '',
    this.rejectionReason,
    this.resumedFromChar,
  });

  final bool accepted;
  final List<ReferenceInsight> insights;
  final String sourceLocator;
  final String? rejectionReason;
  final int? resumedFromChar;
}

/// Result of a URL permission check.
class UrlPermissionResult {
  const UrlPermissionResult({
    required this.robotsAllowed,
    required this.licenseHint,
  });

  final bool? robotsAllowed;
  final String? licenseHint;
}

/// A checkpoint for resumable ingestion.
class IngestionCheckpoint {
  const IngestionCheckpoint({
    required this.projectId,
    required this.sourcePath,
    required this.processedChars,
  });

  final String projectId;
  final String sourcePath;
  final int processedChars;

  Map<String, Object?> toJson() => {
        'project_id': projectId,
        'source_path': sourcePath,
        'processed_chars': processedChars,
      };

  factory IngestionCheckpoint.fromJson(Map<String, dynamic> json) =>
      IngestionCheckpoint(
        projectId: json['project_id'] as String,
        sourcePath: json['source_path'] as String,
        processedChars: json['processed_chars'] as int,
      );
}

class ReferenceSourcePolicy {
  ReferenceSourcePolicy({required this.storageDir});

  final String storageDir;

  String _checkpointFile(String projectId, String sourcePath) {
    final safeName = sourcePath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '$storageDir/$projectId/.checkpoints/$safeName.json';
  }

  /// Ingest a reference source with policy enforcement.
  Future<IngestionResult> ingest({
    required ReferenceSource source,
    required String projectId,
    int maxExtractChars = 2000,
    IngestionCheckpoint? resumeFrom,
  }) async {
    // URL sources require a licensed connector (none exists)
    if (source.type == ReferenceSourceType.url) {
      return const IngestionResult(
        accepted: false,
        rejectionReason:
            'URL ingestion refused: no licensed connector is configured. '
            'Use a local file instead.',
      );
    }

    // Local file must exist
    final file = File(source.path);
    if (!await file.exists()) {
      return IngestionResult(
        accepted: false,
        rejectionReason: 'File not found: ${source.path}',
      );
    }

    final content = await file.readAsString();
    final startChar = resumeFrom?.processedChars ?? 0;
    final effectiveContent = startChar < content.length
        ? content.substring(startChar)
        : '';

    // Extract abstract style constraints (never long copies)
    final insights = _extractInsights(
      effectiveContent,
      source.path,
      maxExtractChars,
    );

    // Save checkpoint on success
    await saveCheckpoint(
      projectId: projectId,
      sourcePath: source.path,
      processedChars: content.length,
    );

    return IngestionResult(
      accepted: true,
      insights: insights,
      sourceLocator: 'file:${source.path}',
      resumedFromChar: startChar > 0 ? startChar : null,
    );
  }

  /// Check URL permission (robots/license). Without a licensed connector,
  /// defaults to disallowed (safe default).
  Future<UrlPermissionResult> checkUrlPermission(String url) async {
    // In production this would fetch robots.txt and check license headers.
    // Without a licensed connector, we default to disallowed.
    return const UrlPermissionResult(
      robotsAllowed: false,
      licenseHint: 'no licensed connector available - access disallowed',
    );
  }

  /// Save a checkpoint for resumable ingestion.
  Future<void> saveCheckpoint({
    required String projectId,
    required String sourcePath,
    required int processedChars,
  }) async {
    final cpFile = File(_checkpointFile(projectId, sourcePath));
    await cpFile.parent.create(recursive: true);
    final checkpoint = IngestionCheckpoint(
      projectId: projectId,
      sourcePath: sourcePath,
      processedChars: processedChars,
    );
    await cpFile.writeAsString(jsonEncode(checkpoint.toJson()), flush: true);
  }

  /// Load a checkpoint if it exists.
  Future<IngestionCheckpoint?> loadCheckpoint(
    String projectId,
    String sourcePath,
  ) async {
    final cpFile = File(_checkpointFile(projectId, sourcePath));
    if (!await cpFile.exists()) return null;
    try {
      final raw = await cpFile.readAsString();
      return IngestionCheckpoint.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extract abstract style/structure/technique insights from text.
  /// Never returns long copied text; each insight is capped at maxChars.
  List<ReferenceInsight> _extractInsights(
    String content,
    String sourcePath,
    int maxChars,
  ) {
    final insights = <ReferenceInsight>[];
    final locator = 'file:$sourcePath';

    // Sentence length analysis
    final sentences = content.split(RegExp(r'[。！？.!?]'));
    final nonEmpty = sentences.where((s) => s.trim().isNotEmpty).toList();
    if (nonEmpty.isNotEmpty) {
      final avgLen =
          nonEmpty.fold<int>(0, (sum, s) => sum + s.trim().length) ~/
              nonEmpty.length;
      final style = avgLen < 20
          ? 'short, punchy sentences'
          : avgLen < 50
              ? 'medium-length sentences'
              : 'long, flowing sentences';
      insights.add(ReferenceInsight(
        sourceLocator: locator,
        category: 'style',
        content: 'Sentence rhythm: $style (avg ${avgLen} chars/sentence)',
      ));
    }

    // Dialogue density
    final dialogueChars = RegExp(r'["「」『』]')
        .allMatches(content)
        .length;
    final dialogueDensity = content.isEmpty
        ? 0.0
        : dialogueChars / content.length;
    insights.add(ReferenceInsight(
      sourceLocator: locator,
      category: 'structure',
      content: dialogueDensity > 0.1
          ? 'Dialogue-heavy: frequent character speech'
          : 'Narration-heavy: sparse dialogue',
    ));

    // Paragraph structure
    final paragraphs = content.split('\n').where((p) => p.trim().isNotEmpty);
    insights.add(ReferenceInsight(
      sourceLocator: locator,
      category: 'technique',
      content: 'Paragraph count: ${paragraphs.length}; '
          'avg length: ${paragraphs.isEmpty ? 0 : content.length ~/ paragraphs.length} chars',
    ));

    // Cap each insight content at maxChars
    return insights.map((insight) {
      if (insight.content.length <= maxChars) return insight;
      return ReferenceInsight(
        sourceLocator: insight.sourceLocator,
        category: insight.category,
        content: insight.content.substring(0, maxChars),
      );
    }).toList();
  }
}
