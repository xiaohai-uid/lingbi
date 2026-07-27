/// Diagnostic events with field allow-list, secret redaction,
/// retention, and export. Never collects manuscript contents.
library;

import 'dart:convert';
import 'dart:io';

/// Fields that are allowed in diagnostic events.
const _allowedFields = {
  'app_version',
  'os',
  'os_version',
  'locale',
  'endpoint',
  'latency_ms',
  'model_id',
  'provider',
  'status_code',
  'error_type',
  'feature',
  'duration_ms',
  'session_id',
  'data',
};

/// Fields that must always be redacted.
const _redactedFields = {
  'authorization',
  'api_key',
  'token',
  'secret',
  'password',
  'manuscript_content',
  'content',
  'text',
};

/// A single diagnostic event.
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.type,
    required this.fields,
    this.timestamp,
  });

  final String type;
  final Map<String, String> fields;
  final DateTime? timestamp;

  /// Returns a sanitized copy with only allowed fields and no secrets.
  DiagnosticEvent sanitized() {
    final clean = <String, String>{};
    for (final entry in fields.entries) {
      final key = entry.key.toLowerCase();
      if (_redactedFields.contains(key)) continue;
      if (!_allowedFields.contains(entry.key)) continue;
      clean[entry.key] = entry.value;
    }
    return DiagnosticEvent(
      type: type,
      fields: clean,
      timestamp: timestamp,
    );
  }

  Map<String, Object?> toJson() => {
        'type': type,
        'fields': fields,
        'timestamp': (timestamp ?? DateTime.now().toUtc()).toIso8601String(),
      };

  factory DiagnosticEvent.fromJson(Map<String, dynamic> json) =>
      DiagnosticEvent(
        type: json['type'] as String,
        fields: (json['fields'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );
}

/// Collects, stores, purges, and exports diagnostic events.
class DiagnosticCollector {
  DiagnosticCollector({
    required this.storageDir,
    required this.retentionDays,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final String storageDir;
  final int retentionDays;
  final DateTime Function() _clock;

  String _eventsFile() => '$storageDir/diagnostics/events.jsonl';

  Future<void> record(DiagnosticEvent event) async {
    final dir = Directory('$storageDir/diagnostics');
    await dir.create(recursive: true);
    final sanitized = event.sanitized();
    final file = File(_eventsFile());
    await file.writeAsString(
      '${jsonEncode(sanitized.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<DiagnosticEvent>> export() async {
    final file = File(_eventsFile());
    if (!await file.exists()) return [];
    final lines = await file.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => DiagnosticEvent.fromJson(jsonDecode(l) as Map<String, dynamic>))
        .toList();
  }

  Future<String> exportJson() async {
    final events = await export();
    return const JsonEncoder.withIndent('  ')
        .convert(events.map((e) => e.toJson()).toList());
  }

  Future<void> purgeExpired() async {
    final events = await export();
    final cutoff = _clock().subtract(Duration(days: retentionDays));
    final kept = events.where((e) {
      final ts = e.timestamp ?? _clock();
      return ts.isAfter(cutoff);
    }).toList();

    final file = File(_eventsFile());
    if (kept.isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.writeAsString(
      kept.map((e) => jsonEncode(e.toJson())).join('\n') + '\n',
      flush: true,
    );
  }
}
