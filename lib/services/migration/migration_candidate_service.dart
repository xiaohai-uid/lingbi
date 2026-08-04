/// Explicit legacy migration decisions (MP-09).
///
/// Builds a side-effect-free migration baseline of legacy projects under a
/// root, then applies one-time explicit upgrades chosen by the user.
/// Ambiguous/lossy metadata is refused, never guessed or rewritten.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/project/project_brief.dart';
import '../atomic_file_store.dart';
import '../migrations/legacy_canonical_reader.dart';
import '../migrations/schema_versions.dart';
import '../../features/project/data/project_brief_repository.dart';
import '../../shared/errors/app_error.dart';
import '../../shared/errors/result.dart';
import '../../shared/interfaces/mutation_protocol.dart';

enum MigrationCandidateStatus { pending, completed, refused }

final class MigrationCandidate {
  const MigrationCandidate({
    required this.id,
    required this.directoryPath,
    required this.name,
    required this.status,
    this.reason,
    required this.updatedAt,
  });

  factory MigrationCandidate.fromJson(Map<String, dynamic> json) =>
      MigrationCandidate(
        id: json['id'] as String,
        directoryPath: json['directoryPath'] as String,
        name: json['name'] as String,
        status: MigrationCandidateStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => MigrationCandidateStatus.pending,
        ),
        reason: json['reason'] as String?,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String) ??
            DateTime.now(),
      );

  final String id;
  final String directoryPath;
  final String name;
  final MigrationCandidateStatus status;
  final String? reason;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'directoryPath': directoryPath,
        'name': name,
        'status': status.name,
        if (reason != null) 'reason': reason,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

final class MigrationBaseline {
  const MigrationBaseline({
    required this.rootPath,
    required this.candidates,
    required this.ambiguousDirectories,
    required this.duplicateIdDirectories,
    required this.builtAt,
  });

  factory MigrationBaseline.fromJson(Map<String, dynamic> json) =>
      MigrationBaseline(
        rootPath: json['rootPath'] as String,
        candidates: (json['candidates'] as List)
            .map((c) => MigrationCandidate.fromJson(c as Map<String, dynamic>))
            .toList(),
        ambiguousDirectories: (json['ambiguousDirectories'] as List)
            .map((e) => e as String)
            .toList(),
        duplicateIdDirectories: (json['duplicateIdDirectories'] as List)
            .map((e) => e as String)
            .toList(),
        builtAt: DateTime.tryParse(json['builtAt'] as String) ??
            DateTime.now(),
      );

  final String rootPath;
  final List<MigrationCandidate> candidates;
  final List<String> ambiguousDirectories;
  final List<String> duplicateIdDirectories;
  final DateTime builtAt;

  Map<String, dynamic> toJson() => {
        'rootPath': rootPath,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'ambiguousDirectories': ambiguousDirectories,
        'duplicateIdDirectories': duplicateIdDirectories,
        'builtAt': builtAt.toIso8601String(),
      };
}

/// One-time explicit legacy upgrade decisions.
///
/// The baseline is persisted under `<root>/.lingbi-migration/baseline.json`
/// (never inside a project), so a scan can be repeated without re-deciding.
/// `accept` rewrites a legacy project's metadata to canonical *through the
/// MutationProtocol*; a lossless upgrade is required, otherwise the candidate
/// is refused and the files left untouched.
final class MigrationCandidateService {
  MigrationCandidateService({
    required this.projectRoot,
    MutationProtocol? mutationProtocol,
    AtomicFileStore? atomicStore,
  })  : _mutationProtocol = mutationProtocol,
        _atomicStore = atomicStore ?? AtomicFileStore();

  final String projectRoot;
  final MutationProtocol? _mutationProtocol;
  final AtomicFileStore _atomicStore;

  File get _baselineFile =>
      File(p.join(projectRoot, '.lingbi-migration', 'baseline.json'));

  /// Scan the root for projects and build the baseline from the current disk
  /// state. Side-effect free: legacy projects are never rewritten, and a
  /// project that already migrated is reported as migrated (no candidate).
  /// The persisted baseline keeps the one-time decision history for
  /// [accept]'s ALREADY_DECIDED guard.
  Future<Result<MigrationBaseline>> buildBaseline() async {
    final root = Directory(projectRoot);
    if (!await root.exists()) {
      return Result.success(MigrationBaseline(
        rootPath: projectRoot,
        candidates: const [],
        ambiguousDirectories: const [],
        duplicateIdDirectories: const [],
        builtAt: DateTime.now().toUtc(),
      ));
    }

    final candidates = <MigrationCandidate>[];
    final ambiguous = <String>[];
    final idToDirectory = <String, String>{};
    final duplicateDirectories = <String>[];

    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final kind = await LegacyCanonicalReader.inspect(entity.path);
      if (kind == ProjectMetadataKind.future) {
        // 高于当前构建的元数据：拒绝降级迁移，交给人工处理。
        ambiguous.add(entity.path);
        continue;
      }
      if (kind != ProjectMetadataKind.legacy) {
        // Canonical projects still contribute their id to duplicate detection.
        final canonical = await LegacyCanonicalReader.readCanonical(entity.path);
        if (canonical != null) {
          final existing = idToDirectory[canonical.id];
          if (existing != null) {
            duplicateDirectories.addAll([existing, entity.path]);
          } else {
            idToDirectory[canonical.id] = entity.path;
          }
        }
        continue;
      }

      final descriptor = await LegacyCanonicalReader.readLegacy(entity.path);
      final id = descriptor.hasBrief
          ? await _legacyId(entity.path)
          : 'unknown';
      if (id != 'unknown') {
        final existing = idToDirectory[id];
        if (existing != null) {
          duplicateDirectories.addAll([existing, entity.path]);
        } else {
          idToDirectory[id] = entity.path;
        }
      }
      if (descriptor.hasBrief) {
        candidates.add(MigrationCandidate(
          id: _candidateId(entity.path),
          directoryPath: entity.path,
          name: descriptor.name ?? '',
          status: MigrationCandidateStatus.pending,
          updatedAt: DateTime.now().toUtc(),
        ));
      } else {
        // Ambiguous/lossy metadata still surfaces as a candidate so the user
        // gets an explicit refusal instead of silence; accept() refuses it.
        candidates.add(MigrationCandidate(
          id: _candidateId(entity.path),
          directoryPath: entity.path,
          name: descriptor.name ?? '',
          status: MigrationCandidateStatus.pending,
          updatedAt: DateTime.now().toUtc(),
        ));
        ambiguous.add(entity.path);
      }
    }

    final baseline = MigrationBaseline(
      rootPath: projectRoot,
      candidates: candidates,
      ambiguousDirectories: ambiguous,
      duplicateIdDirectories: duplicateDirectories.toSet().toList(),
      builtAt: DateTime.now().toUtc(),
    );
    await _persistBaseline(baseline);
    return Result.success(baseline);
  }

  /// Status of one candidate (from the persisted baseline).
  Future<Result<MigrationCandidate>> status(String candidateId) async {
    final baseline = await _readPersistedBaseline();
    if (baseline == null) {
      return Result.failure(FileError(
        'Migration baseline not built yet',
        code: 'NO_BASELINE',
      ));
    }
    for (final candidate in baseline.candidates) {
      if (candidate.id == candidateId) {
        return Result.success(candidate);
      }
    }
    return Result.failure(FileError(
      'Migration candidate not found: $candidateId',
      code: 'NOT_FOUND',
    ));
  }

  /// One-time explicit upgrade of a legacy project to canonical metadata.
  /// Returns refused (LOSSY) when the metadata cannot be upgraded losslessly.
  Future<Result<MigrationCandidate>> accept(String candidateId) async {
    final baseline = await _readPersistedBaseline();
    if (baseline == null) {
      return Result.failure(FileError(
        'Migration baseline not built yet; run buildBaseline first',
        code: 'NO_BASELINE',
      ));
    }
    final index = baseline.candidates
        .indexWhere((c) => c.id == candidateId);
    if (index < 0) {
      return Result.failure(FileError(
        'Migration candidate not found: $candidateId',
        code: 'NOT_FOUND',
      ));
    }
    final candidate = baseline.candidates[index];
    if (candidate.status != MigrationCandidateStatus.pending) {
      return Result.failure(FileError(
        'Migration already decided: ${candidate.status.name}',
        code: 'ALREADY_DECIDED',
      ));
    }
    if (baseline.ambiguousDirectories.contains(candidate.directoryPath)) {
      final refused = _mark(candidate, MigrationCandidateStatus.refused,
          'lossy metadata cannot be upgraded automatically');
      await _updateCandidate(baseline, refused);
      return Result.failure(FileError(
        'LOSSY_MIGRATION_REFUSED: ${candidate.directoryPath}',
        code: 'LOSSY_MIGRATION_REFUSED',
      ));
    }

    final upgraded = await _upgradeToCanonical(candidate);
    if (upgraded.errorOrNull() != null) {
      return Result.failure(upgraded.errorOrNull()!);
    }
    final completed = _mark(candidate, MigrationCandidateStatus.completed, null);
    await _updateCandidate(baseline, completed);
    return Result.success(completed);
  }

  Future<Result<void>> _upgradeToCanonical(MigrationCandidate candidate) async {
    final protocol = _mutationProtocol;
    if (protocol == null) {
      return Result.failure(FileError(
        'MutationProtocol required for migration upgrade (fail-closed)',
        code: 'PROTOCOL_REQUIRED',
      ));
    }
    final descriptor =
        await LegacyCanonicalReader.readLegacy(candidate.directoryPath);
    if (!descriptor.hasBrief) {
      return Result.failure(FileError(
        'LOSSY_MIGRATION_REFUSED: ${candidate.directoryPath}',
        code: 'LOSSY_MIGRATION_REFUSED',
      ));
    }
    final raw = await LegacyCanonicalReader.readRawMetadata(
      candidate.directoryPath,
    );
    if (raw == null) {
      return Result.failure(FileError(
        'LOSSY_MIGRATION_REFUSED: metadata unreadable: ${candidate.directoryPath}',
        code: 'LOSSY_MIGRATION_REFUSED',
      ));
    }

    final brief = ProjectBrief(
      title: descriptor.name ?? '未命名项目',
      genreId: descriptor.genre ?? '',
      templateId: descriptor.genre != null && descriptor.genre!.isNotEmpty
          ? 'genre:${descriptor.genre}'
          : '',
      premise: raw['description'] as String? ?? '',
    );

    final metadataFile =
        File(p.join(candidate.directoryPath, '.lingbi', 'project.json'));
    if (!await metadataFile.exists()) {
      return Result.failure(FileError(
        'LOSSY_MIGRATION_REFUSED: metadata missing: ${candidate.directoryPath}',
        code: 'LOSSY_MIGRATION_REFUSED',
      ));
    }

    // 以磁盘实际 brief revision 做 CAS（不硬编码 0，避免覆盖已有修订）。
    final currentRevision = raw['projectBrief'] is Map<String, dynamic> &&
            (raw['projectBrief'] as Map<String, dynamic>)['revision'] is int
        ? (raw['projectBrief'] as Map<String, dynamic>)['revision'] as int
        : 0;

    try {
      final project = await ProjectBriefRepository(
        candidate.directoryPath,
        mutationProtocol: protocol,
      ).write(
        brief,
        expectedRevision: currentRevision,
        baseMetadata: {
          ...raw,
          'schemaVersion': SchemaVersions.project,
          'id': raw['id'] as String,
          'name': descriptor.name ?? '未命名项目',
          'directoryPath': candidate.directoryPath,
        },
      );
      if (project.revision < 1) {
        return Result.failure(FileError(
          'Migration upgrade produced no brief',
          code: 'UPGRADE_FAILED',
        ));
      }
    } catch (error) {
      return Result.failure(FileError(
        'Migration upgrade failed: $error',
        code: 'UPGRADE_FAILED',
      ));
    }
    return Result.success(null);
  }

  Future<String> _legacyId(String directoryPath) async {
    final raw = await LegacyCanonicalReader.readRawMetadata(directoryPath);
    final id = raw?['id'];
    if (id is String && id.isNotEmpty) return id;
    return 'unknown';
  }

  String _candidateId(String directoryPath) {
    final normalized = directoryPath.replaceAll(r'\', '/').toLowerCase();
    final bytes = utf8.encode(normalized);
    var hash = 0;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return 'mig-$hash';
  }

  MigrationCandidate _mark(
    MigrationCandidate candidate,
    MigrationCandidateStatus status,
    String? reason,
  ) =>
      MigrationCandidate(
        id: candidate.id,
        directoryPath: candidate.directoryPath,
        name: candidate.name,
        status: status,
        reason: reason,
        updatedAt: DateTime.now().toUtc(),
      );

  Future<void> _updateCandidate(
    MigrationBaseline baseline,
    MigrationCandidate updated,
  ) async {
    final candidates = baseline.candidates
        .map((c) => c.id == updated.id ? updated : c)
        .toList();
    await _persistBaseline(MigrationBaseline(
      rootPath: baseline.rootPath,
      candidates: candidates,
      ambiguousDirectories: baseline.ambiguousDirectories,
      duplicateIdDirectories: baseline.duplicateIdDirectories,
      builtAt: baseline.builtAt,
    ));
  }

  Future<void> _persistBaseline(MigrationBaseline baseline) async {
    await _atomicStore.writeString(
      _baselineFile.path,
      jsonEncode(baseline.toJson()),
    );
  }

  Future<MigrationBaseline?> _readPersistedBaseline() async {
    if (!await _baselineFile.exists()) return null;
    try {
      final decoded =
          jsonDecode(await _baselineFile.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final parsed = MigrationBaseline.fromJson(decoded);
      if (parsed.rootPath != projectRoot) return null;
      return parsed;
    } catch (_) {
      return null;
    }
  }
}
