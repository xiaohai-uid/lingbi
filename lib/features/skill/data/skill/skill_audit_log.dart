import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum SkillAuditOutcome { allowed, denied, failed }

class AuditIntegrityException implements Exception {
  const AuditIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'AuditIntegrityException: $message';
}

class SkillAuditRecord {
  SkillAuditRecord({
    required this.sequence,
    required this.timestamp,
    required this.skillId,
    required this.projectId,
    required this.operation,
    required this.outcome,
    required Map<String, String> details,
    required this.previousHash,
    required this.hash,
  }) : details = Map.unmodifiable(details);

  factory SkillAuditRecord.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    if (rawDetails is! Map) {
      throw const AuditIntegrityException('Audit details are malformed');
    }
    return SkillAuditRecord(
      sequence: json['sequence'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
      skillId: json['skill_id'] as String,
      projectId: json['project_id'] as String,
      operation: json['operation'] as String,
      outcome: SkillAuditOutcome.values.byName(json['outcome'] as String),
      details: rawDetails.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      previousHash: json['previous_hash'] as String,
      hash: json['hash'] as String,
    );
  }

  final int sequence;
  final DateTime timestamp;
  final String skillId;
  final String projectId;
  final String operation;
  final SkillAuditOutcome outcome;
  final Map<String, String> details;
  final String previousHash;
  final String hash;

  Map<String, Object> toJson() => {
        'sequence': sequence,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'skill_id': skillId,
        'project_id': projectId,
        'operation': operation,
        'outcome': outcome.name,
        'details': details,
        'previous_hash': previousHash,
        'hash': hash,
      };
}

class SkillAuditLog {
  SkillAuditLog({
    required this.filePath,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String filePath;
  final DateTime Function() _clock;

  Future<SkillAuditRecord> append({
    required String skillId,
    required String projectId,
    required String operation,
    required SkillAuditOutcome outcome,
    Map<String, String> details = const {},
  }) async {
    final previous = await readVerified();
    final sequence = previous.length + 1;
    final previousHash = previous.isEmpty ? '' : previous.last.hash;
    final timestamp = _clock().toUtc();
    final hash = _hashRecord(
      sequence: sequence,
      timestamp: timestamp,
      skillId: skillId,
      projectId: projectId,
      operation: operation,
      outcome: outcome,
      details: details,
      previousHash: previousHash,
    );
    final record = SkillAuditRecord(
      sequence: sequence,
      timestamp: timestamp,
      skillId: skillId,
      projectId: projectId,
      operation: operation,
      outcome: outcome,
      details: details,
      previousHash: previousHash,
      hash: hash,
    );
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(record.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
    return record;
  }

  Future<List<SkillAuditRecord>> readVerified() async {
    final file = File(filePath);
    if (!await file.exists()) return const [];
    final lines = await file.readAsLines();
    final records = <SkillAuditRecord>[];
    var previousHash = '';
    for (final line in lines.where((line) => line.trim().isNotEmpty)) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic>) {
          throw const AuditIntegrityException('Audit record is malformed');
        }
        final record = SkillAuditRecord.fromJson(decoded);
        final expected = _hashRecord(
          sequence: record.sequence,
          timestamp: record.timestamp,
          skillId: record.skillId,
          projectId: record.projectId,
          operation: record.operation,
          outcome: record.outcome,
          details: record.details,
          previousHash: previousHash,
        );
        if (record.sequence != records.length + 1 ||
            record.previousHash != previousHash ||
            record.hash != expected) {
          throw AuditIntegrityException(
            'Audit chain failed at record ${record.sequence}',
          );
        }
        records.add(record);
        previousHash = record.hash;
      } on AuditIntegrityException {
        rethrow;
      } catch (error) {
        throw AuditIntegrityException('Cannot decode audit record: $error');
      }
    }
    return List.unmodifiable(records);
  }

  static String _hashRecord({
    required int sequence,
    required DateTime timestamp,
    required String skillId,
    required String projectId,
    required String operation,
    required SkillAuditOutcome outcome,
    required Map<String, String> details,
    required String previousHash,
  }) {
    final sortedDetails = Map.fromEntries(
      details.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sha256
        .convert(utf8.encode(jsonEncode({
          'sequence': sequence,
          'timestamp': timestamp.toUtc().toIso8601String(),
          'skill_id': skillId,
          'project_id': projectId,
          'operation': operation,
          'outcome': outcome.name,
          'details': sortedDetails,
          'previous_hash': previousHash,
        })))
        .toString();
  }
}
