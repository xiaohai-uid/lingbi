/// Commit reconciliation for crash recovery.
///
/// Before a multi-file apply, an intent.json is persisted describing
/// all targets, before-hashes, and after-hashes. On restart, the
/// reconciler inspects actual file state and determines recovery action.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Possible recovery states for an interrupted transaction.
enum ReconciliationOutcome {
  /// All targets match after-hashes; transaction completed.
  alreadyApplied,

  /// All targets match before-hashes; safe to retry.
  safeToRetry,

  /// Mixed state; staged data can roll forward.
  rollForward,

  /// Inconsistent state; manual recovery required.
  manualRecoveryRequired,

  /// No pending transaction found.
  noPendingTransaction,
}

/// Result of a reconciliation check.
final class ReconciliationResult {
  const ReconciliationResult({
    required this.outcome,
    this.transactionId,
    this.details = '',
  });

  final ReconciliationOutcome outcome;
  final String? transactionId;
  final String details;
}

/// Inspects interrupted transactions and determines recovery action.
final class CommitReconciler {
  CommitReconciler({required this.projectRoot});

  final String projectRoot;

  String _intentPath(String transactionId) =>
      '$projectRoot/.lingbi/mutations/transactions/$transactionId/intent.json';

  /// Persist the intent before applying a multi-file transaction.
  Future<void> persistIntent({
    required String transactionId,
    required List<IntentEntry> entries,
  }) async {
    final path = _intentPath(transactionId);
    final file = File(path);
    await file.parent.create(recursive: true);
    final intent = {
      'transaction_id': transactionId,
      'state': 'prepared',
      'entries': entries.map((e) => e.toJson()).toList(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(intent), flush: true);
  }

  /// Mark a transaction as fully applied.
  Future<void> markApplied(String transactionId) async {
    final path = _intentPath(transactionId);
    final file = File(path);
    if (!await file.exists()) return;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    json['state'] = 'applied';
    json['applied_at'] = DateTime.now().toUtc().toIso8601String();
    await file.writeAsString(jsonEncode(json), flush: true);
  }

  /// Check the state of a pending transaction against actual file content.
  Future<ReconciliationResult> reconcile(String transactionId) async {
    final path = _intentPath(transactionId);
    final file = File(path);
    if (!await file.exists()) {
      return const ReconciliationResult(
        outcome: ReconciliationOutcome.noPendingTransaction,
      );
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final state = json['state'] as String? ?? '';
    if (state == 'applied') {
      return ReconciliationResult(
        outcome: ReconciliationOutcome.alreadyApplied,
        transactionId: transactionId,
      );
    }

    final entries = (json['entries'] as List<dynamic>)
        .map((e) => IntentEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    var allAfter = true;
    var allBefore = true;

    for (final entry in entries) {
      final target = File('$projectRoot/${entry.relativePath}');
      if (!await target.exists()) {
        allAfter = false;
        allBefore = false;
        break;
      }
      final actual = await target.readAsString();
      final actualHash = _hashText(actual);
      if (actualHash != entry.afterHash) allAfter = false;
      if (actualHash != entry.beforeHash) allBefore = false;
    }

    if (allAfter) {
      return ReconciliationResult(
        outcome: ReconciliationOutcome.alreadyApplied,
        transactionId: transactionId,
        details: 'All targets match after-hashes',
      );
    }
    if (allBefore) {
      return ReconciliationResult(
        outcome: ReconciliationOutcome.safeToRetry,
        transactionId: transactionId,
        details: 'All targets match before-hashes',
      );
    }
    return ReconciliationResult(
      outcome: ReconciliationOutcome.manualRecoveryRequired,
      transactionId: transactionId,
      details: 'Mixed state detected',
    );
  }

  String _hashText(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}

/// One entry in a transaction intent record.
final class IntentEntry {
  const IntentEntry({
    required this.relativePath,
    required this.beforeHash,
    required this.afterHash,
  });

  factory IntentEntry.fromJson(Map<String, dynamic> json) => IntentEntry(
        relativePath: json['relative_path'] as String? ?? '',
        beforeHash: json['before_hash'] as String? ?? '',
        afterHash: json['after_hash'] as String? ?? '',
      );

  final String relativePath;
  final String beforeHash;
  final String afterHash;

  Map<String, dynamic> toJson() => {
        'relative_path': relativePath,
        'before_hash': beforeHash,
        'after_hash': afterHash,
      };
}
