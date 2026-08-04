import 'package:lingbi/domain/mutation/canonical_envelope.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

/// 资产级冲突（保留给 UI 展示；协议层使用 typed Result）。
class ProjectAssetConflict implements Exception {
  const ProjectAssetConflict({
    required this.assetId,
    required this.expectedRevision,
    required this.actualRevision,
  });

  final String assetId;
  final int expectedRevision;
  final int actualRevision;

  @override
  String toString() => 'ProjectAssetConflict($assetId: expected '
      '$expectedRevision, actual $actualRevision)';
}

/// 项目概览资产仓库。
///
/// The canonical unit is the complete `assets.json` canonical file: the
/// candidate payload, the receipt evidence and the final disk bytes are the
/// same envelope (ADR-009/ADR-010). The file revision is the mutation
/// conflict authority; the per-asset revision is display-only state.
class ProjectAssetRepository {
  ProjectAssetRepository({
    required IProjectMetaRepository metaRepository,
    required MutationProtocol mutationProtocol,
  })  : _metaRepository = metaRepository,
        _mutationProtocol = mutationProtocol;

  static const fileName = 'assets.json';
  final IProjectMetaRepository _metaRepository;
  final MutationProtocol _mutationProtocol;

  Future<List<ProjectAsset>> list(String projectId) async {
    final assets = await _readAssets(projectId);
    return assets
        .toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
  }

  Future<List<ProjectAsset>> ensureOverviewAssets(String projectId) async {
    final assets = await _readAssets(projectId);
    final existingTypes = assets.map((asset) => asset.type).toSet();
    for (final type in ProjectAssetType.values) {
      if (!existingTypes.contains(type)) {
        assets.add(ProjectAsset.initial(projectId: projectId, type: type));
      }
    }
    assets.sort((a, b) => a.type.index.compareTo(b.type.index));
    if (existingTypes.length != ProjectAssetType.values.length) {
      // Initialization is a canonical mutation: go through the protocol.
      final fileRevision = await _readFileRevision(projectId);
      final commit = await _commitFullFile(
        projectId,
        assets,
        fileRevision,
      );
      if (commit.errorOrNull() != null) {
        throw StateError(
          'MutationProtocol failed to initialize overview assets: '
          '${commit.errorOrNull()}',
        );
      }
    }
    return List.unmodifiable(assets);
  }

  /// Save one asset as part of a complete canonical file commit.
  ///
  /// [expectedRevision] is the canonical file revision the caller observed;
  /// a stale value fails with a typed REVISION_CONFLICT.
  Future<Result<ProjectAsset>> save(
    ProjectAsset asset, {
    required int expectedRevision,
  }) async {
    final fileRevision = await _readFileRevision(asset.projectId);
    if (fileRevision != expectedRevision) {
      return Result.failure(FileError(
        'REVISION_CONFLICT: $fileName expected revision=$expectedRevision '
        'actual=$fileRevision',
        typedCode: MutationErrorCode.revisionConflict,
      ));
    }

    final assets = await _readAssets(asset.projectId);
    final index = assets.indexWhere((candidate) => candidate.id == asset.id);
    if (index < 0) {
      return Result.failure(FileError(
        'Unknown project asset: ${asset.id}',
        code: 'NOT_FOUND',
      ));
    }
    final current = assets[index];
    final committed = asset.copyWith(
      revision: current.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    final updated = assets.toList()..[index] = committed;

    final commit = await _commitFullFile(
      asset.projectId,
      updated,
      fileRevision,
    );
    if (commit.errorOrNull() != null) {
      return Result.failure(commit.errorOrNull()!);
    }
    return Result.success(committed);
  }

  Future<Result<void>> _commitFullFile(
    String projectId,
    List<ProjectAsset> assets,
    int fileRevision,
  ) async {
    final payload = <String, dynamic>{
      'assets': assets.map((asset) => asset.toJson()).toList(),
    };
    final envelope = CanonicalJsonEnvelope(
      schemaVersion: CanonicalJsonEnvelope.currentSchemaVersion,
      revision: fileRevision + 1,
      contentHash: canonicalPayloadHash(payload),
      payload: payload,
    );
    final encoded = envelope.encode();

    final result = await _mutationProtocol.applyUserEdit(ChangeRequest(
      projectId: projectId,
      origin: ChangeOrigin.userUi,
      action: ChangeAction.replaceAsset,
      target: const ChangeTarget(
        projectRelativePath: 'project_meta/$fileName',
        kind: 'project_asset',
      ),
      baseRevision: fileRevision,
      payload: encoded,
    ));
    if (result.errorOrNull() != null) {
      return Result.failure(result.errorOrNull()!);
    }
    return Result.success(null);
  }

  /// (assets, fileRevision) from a canonical envelope or a legacy file.
  Future<(List<ProjectAsset>, int)> _readFile(String projectId) async {
    final raw = await _metaRepository.read(projectId, fileName);
    if (raw == null) return (<ProjectAsset>[], 0);

    final envelopePayload = raw['payload'];
    if (envelopePayload is Map<String, dynamic>) {
      final revision = raw['revision'];
      return (
        _parseAssets(envelopePayload),
        revision is int ? revision : 0,
      );
    }
    // Legacy {_schemaVersion, ...} shape: business payload is the whole map.
    return (_parseAssets(raw), 0);
  }

  List<ProjectAsset> _parseAssets(Map<String, dynamic> payload) {
    final rawAssets = payload['assets'];
    if (rawAssets is! List) return [];
    return rawAssets
        .whereType<Map>()
        .map((json) => ProjectAsset.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<List<ProjectAsset>> _readAssets(String projectId) async =>
      (await _readFile(projectId)).$1;

  Future<int> _readFileRevision(String projectId) async =>
      (await _readFile(projectId)).$2;
}
