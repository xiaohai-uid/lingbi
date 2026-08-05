import 'dart:convert';

/// Repair callback used by [OutputGate.repair].
typedef RepairFn = Future<String> Function(String output, List<String> errors);

/// Result of validating or repairing a node output.
final class GateResult {
  const GateResult({
    required this.passed,
    this.errors = const [],
    this.repairedOutput,
    this.repairRounds = 0,
  });

  final bool passed;
  final List<String> errors;
  final String? repairedOutput;
  final int repairRounds;
}

/// Base output gate with a bounded repair loop.
abstract class OutputGate {
  const OutputGate();

  GateResult validate(String output);

  Future<GateResult> repair({
    required String output,
    required RepairFn repair,
    int maxRounds = 1,
  }) async {
    var current = output;
    var rounds = 0;
    while (true) {
      final result = validate(current);
      if (result.passed) {
        return GateResult(
          passed: true,
          repairedOutput: rounds == 0 ? null : current,
          repairRounds: rounds,
        );
      }
      if (rounds >= maxRounds) {
        return GateResult(
          passed: false,
          errors: [...result.errors, 'gate_exhausted'],
          repairRounds: rounds,
        );
      }
      final repaired = await repair(current, result.errors);
      rounds++;
      if (repaired == current) {
        return GateResult(
          passed: false,
          errors: [...result.errors, 'gate_exhausted'],
          repairRounds: rounds,
        );
      }
      current = repaired;
    }
  }
}

/// Structure gate: parses JSON and requires fields.
final class StructureGate extends OutputGate {
  const StructureGate({required this.requiredFields});

  final List<String> requiredFields;

  @override
  GateResult validate(String output) {
    try {
      final json = jsonDecode(output);
      if (json is! Map<String, dynamic>) {
        return const GateResult(
          passed: false,
          errors: ['output is not a JSON object'],
        );
      }
      final missing =
          requiredFields.where((field) => !json.containsKey(field)).toList();
      if (missing.isNotEmpty) {
        return GateResult(
          passed: false,
          errors: missing.map((field) => 'missing field: $field').toList(),
        );
      }
      return const GateResult(passed: true);
    } catch (e) {
      return GateResult(passed: false, errors: ['invalid JSON: $e']);
    }
  }
}

/// Length gate for chapter/paragraph word ranges.
final class LengthGate extends OutputGate {
  const LengthGate({required this.min, required this.max});

  final int min;
  final int max;

  @override
  GateResult validate(String output) {
    final length = output.trim().length;
    if (length < min) {
      return GateResult(
        passed: false,
        errors: ['length $length below min $min'],
      );
    }
    if (length > max) {
      return GateResult(
        passed: false,
        errors: ['length $length above max $max'],
      );
    }
    return const GateResult(passed: true);
  }
}

/// Approximate de-AI style gate.
final class StyleGate extends OutputGate {
  const StyleGate({this.maxCliches = 1});

  final int maxCliches;

  static const _cliches = [
    '首先',
    '其次',
    '总之',
    '众所周知',
    '综上所述',
    '值得注意的是',
  ];

  @override
  GateResult validate(String output) {
    final count = _cliches.where(output.contains).length;
    if (count > maxCliches) {
      return GateResult(
        passed: false,
        errors: ['too many cliches: $count'],
      );
    }
    return const GateResult(passed: true);
  }
}

/// Downstream rejection reason targeting one upstream node.
final class RejectReason {
  const RejectReason({
    required this.fromNodeId,
    required this.targetNodeId,
    required this.reason,
  });

  factory RejectReason.fromJson(Map<String, dynamic> json) => RejectReason(
        fromNodeId: json['fromNodeId'] as String,
        targetNodeId: json['targetNodeId'] as String,
        reason: json['reason'] as String,
      );

  final String fromNodeId;
  final String targetNodeId;
  final String reason;

  Map<String, dynamic> toJson() => {
        'fromNodeId': fromNodeId,
        'targetNodeId': targetNodeId,
        'reason': reason,
      };
}
