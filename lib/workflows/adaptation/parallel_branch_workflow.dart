/// Parallel branch workflow for "what-if" story exploration.
///
/// Creates reversible branches from divergence points. Branches are
/// isolated from the main timeline and can be reverted without data loss.
library;

import 'dart:convert';
import 'dart:io';

enum BranchStatus { active, merged, reverted }

/// A parallel story branch.
class ParallelBranch {
  const ParallelBranch({
    required this.id,
    required this.projectId,
    required this.divergenceChapter,
    required this.branchName,
    required this.premise,
    required this.status,
    required this.createdAt,
    this.revertedAt,
  });

  factory ParallelBranch.fromJson(Map<String, dynamic> json) => ParallelBranch(
        id: json['id'] as String,
        projectId: json['project_id'] as String,
        divergenceChapter: json['divergence_chapter'] as int,
        branchName: json['branch_name'] as String,
        premise: json['premise'] as String,
        status: BranchStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        revertedAt: json['reverted_at'] != null
            ? DateTime.parse(json['reverted_at'] as String)
            : null,
      );

  final String id;
  final String projectId;
  final int divergenceChapter;
  final String branchName;
  final String premise;
  final BranchStatus status;
  final DateTime createdAt;
  final DateTime? revertedAt;

  bool get isReversible => status == BranchStatus.active;

  ParallelBranch copyWith({BranchStatus? status, DateTime? revertedAt}) {
    return ParallelBranch(
      id: id,
      projectId: projectId,
      divergenceChapter: divergenceChapter,
      branchName: branchName,
      premise: premise,
      status: status ?? this.status,
      createdAt: createdAt,
      revertedAt: revertedAt ?? this.revertedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'project_id': projectId,
        'divergence_chapter': divergenceChapter,
        'branch_name': branchName,
        'premise': premise,
        'status': status.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'reverted_at': revertedAt?.toUtc().toIso8601String(),
      };
}

/// Main timeline state (unaffected by branches).
class MainTimeline {
  const MainTimeline({required this.activeBranches});

  final List<String> activeBranches;
}

class ParallelBranchWorkflow {
  ParallelBranchWorkflow({required this.storageDir});

  final String storageDir;
  final Map<String, ParallelBranch> _branches = {};

  String _branchFile(String projectId) =>
      '$storageDir/$projectId/branches.json';

  Future<void> _persist(String projectId) async {
    final dir = Directory('$storageDir/$projectId');
    await dir.create(recursive: true);
    final branches = _branches.values
        .where((b) => b.projectId == projectId)
        .map((b) => b.toJson())
        .toList();
    await File(_branchFile(projectId))
        .writeAsString(jsonEncode(branches), flush: true);
  }

  Future<ParallelBranch> createBranch({
    required String projectId,
    required int divergenceChapter,
    required String branchName,
    required String premise,
  }) async {
    final branch = ParallelBranch(
      id: 'branch-${DateTime.now().microsecondsSinceEpoch}',
      projectId: projectId,
      divergenceChapter: divergenceChapter,
      branchName: branchName,
      premise: premise,
      status: BranchStatus.active,
      createdAt: DateTime.now().toUtc(),
    );
    _branches[branch.id] = branch;
    await _persist(projectId);
    return branch;
  }

  Future<ParallelBranch> revertBranch(String branchId) async {
    final branch = _branches[branchId];
    if (branch == null) {
      throw StateError('Branch not found: $branchId');
    }
    final reverted = branch.copyWith(
      status: BranchStatus.reverted,
      revertedAt: DateTime.now().toUtc(),
    );
    _branches[branchId] = reverted;
    await _persist(branch.projectId);
    return reverted;
  }

  Future<List<ParallelBranch>> listBranches(String projectId) async {
    return _branches.values
        .where((b) => b.projectId == projectId)
        .toList();
  }

  Future<MainTimeline> getMainTimeline(String projectId) async {
    // Main timeline is never affected by branches
    return const MainTimeline(activeBranches: []);
  }
}
