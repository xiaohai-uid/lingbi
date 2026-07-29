import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

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

class ProjectAssetRepository {
  ProjectAssetRepository({required IProjectMetaRepository metaRepository})
      : _metaRepository = metaRepository;

  static const fileName = 'assets.json';
  final IProjectMetaRepository _metaRepository;

  Future<List<ProjectAsset>> list(String projectId) async {
    final data = await _metaRepository.read(projectId, fileName);
    final rawAssets = data?['assets'];
    if (rawAssets is! List) return [];
    return rawAssets
        .whereType<Map>()
        .map((json) => ProjectAsset.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
  }

  Future<List<ProjectAsset>> ensureOverviewAssets(String projectId) async {
    final assets = await list(projectId);
    final existingTypes = assets.map((asset) => asset.type).toSet();
    for (final type in ProjectAssetType.values) {
      if (!existingTypes.contains(type)) {
        assets.add(ProjectAsset.initial(projectId: projectId, type: type));
      }
    }
    assets.sort((a, b) => a.type.index.compareTo(b.type.index));
    if (existingTypes.length != ProjectAssetType.values.length) {
      await _write(projectId, assets);
    }
    return List.unmodifiable(assets);
  }

  Future<ProjectAsset> save(
    ProjectAsset asset, {
    required int expectedRevision,
  }) async {
    final assets = await ensureOverviewAssets(asset.projectId);
    final index = assets.indexWhere((candidate) => candidate.id == asset.id);
    if (index < 0) {
      throw StateError('Unknown project asset: ${asset.id}');
    }
    final current = assets[index];
    if (current.revision != expectedRevision) {
      throw ProjectAssetConflict(
        assetId: asset.id,
        expectedRevision: expectedRevision,
        actualRevision: current.revision,
      );
    }
    final committed = asset.copyWith(
      revision: current.revision + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    final updated = assets.toList()..[index] = committed;
    await _write(asset.projectId, updated);
    return committed;
  }

  Future<void> _write(String projectId, List<ProjectAsset> assets) {
    return _metaRepository.write(projectId, fileName, {
      'assets': assets.map((asset) => asset.toJson()).toList(),
    });
  }
}
