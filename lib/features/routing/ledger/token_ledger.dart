import 'dart:convert';
import 'dart:io';

/// One model call accounted to a workflow node.
final class TokenLedgerEntry {
  const TokenLedgerEntry({
    required this.runId,
    required this.nodeId,
    required this.attempt,
    required this.promptTokens,
    required this.completionTokens,
    required this.providerId,
    this.createdAt,
  });

  factory TokenLedgerEntry.fromJson(Map<String, dynamic> json) {
    return TokenLedgerEntry(
      runId: json['runId'] as String,
      nodeId: json['nodeId'] as String,
      attempt: json['attempt'] as int,
      promptTokens: json['promptTokens'] as int,
      completionTokens: json['completionTokens'] as int,
      providerId: json['providerId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  final String runId;
  final String nodeId;
  final int attempt;
  final int promptTokens;
  final int completionTokens;
  final String providerId;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'nodeId': nodeId,
        'attempt': attempt,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'providerId': providerId,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}

/// Aggregated token usage for a run or node.
final class TokenUsage {
  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.attempts,
  });

  final int promptTokens;
  final int completionTokens;
  final int attempts;

  int get totalTokens => promptTokens + completionTokens;
}

/// JSONL token ledger from Fusion module D.
class TokenLedger {
  TokenLedger({required String basePath}) : _dir = Directory(basePath);

  final Directory _dir;

  void append(TokenLedgerEntry entry) {
    _dir.createSync(recursive: true);
    final file = File('${_dir.path}/token_ledger.jsonl');
    file.writeAsStringSync(
      '${jsonEncode(entry.toJson())}\n',
      mode: FileMode.append,
    );
  }

  Future<TokenUsage> summarize(String runId) async {
    final entries = await _readAll();
    final filtered = entries.where((e) => e.runId == runId);
    return _aggregate(filtered);
  }

  Future<Map<String, TokenUsage>> summarizeByNode(String runId) async {
    final entries = await _readAll();
    final result = <String, List<TokenLedgerEntry>>{};
    for (final entry in entries.where((e) => e.runId == runId)) {
      result.putIfAbsent(entry.nodeId, () => []).add(entry);
    }
    return {
      for (final entry in result.entries) entry.key: _aggregate(entry.value),
    };
  }

  Future<List<String>> listRunIds() async {
    final entries = await _readAll();
    return entries.map((e) => e.runId).toSet().toList();
  }

  TokenUsage _aggregate(Iterable<TokenLedgerEntry> entries) {
    var prompt = 0;
    var completion = 0;
    var attempts = 0;
    for (final entry in entries) {
      prompt += entry.promptTokens;
      completion += entry.completionTokens;
      attempts += 1;
    }
    return TokenUsage(
      promptTokens: prompt,
      completionTokens: completion,
      attempts: attempts,
    );
  }

  Future<List<TokenLedgerEntry>> _readAll() async {
    _dir.createSync(recursive: true);
    final file = File('${_dir.path}/token_ledger.jsonl');
    if (!await file.exists()) return const [];
    final result = <TokenLedgerEntry>[];
    for (final line in await file.readAsLines()) {
      if (line.trim().isEmpty) continue;
      try {
        result.add(
          TokenLedgerEntry.fromJson(jsonDecode(line) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip malformed lines.
      }
    }
    return result;
  }
}
