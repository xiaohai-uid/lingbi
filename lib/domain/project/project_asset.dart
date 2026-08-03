enum ProjectAssetType {
  protagonist,
  worldRules,
  outline,
  openingScene,
  firstChapter,
}

enum ProjectAssetState {
  notStarted,
  generating,
  editable,
  awaitingConfirmation,
  failed,
}

enum ProjectAssetSource { user, ai, imported }

class ProjectAsset {
  const ProjectAsset({
    required this.id,
    required this.projectId,
    required this.type,
    required this.title,
    required this.storagePath,
    required this.revision,
    required this.source,
    required this.state,
    required this.updatedAt,
  });

  factory ProjectAsset.initial({
    required String projectId,
    required ProjectAssetType type,
  }) {
    final definition = _definitions[type]!;
    return ProjectAsset(
      id: 'asset:$projectId:${type.name}',
      projectId: projectId,
      type: type,
      title: definition.title,
      storagePath: definition.storagePath,
      revision: 0,
      source: ProjectAssetSource.user,
      state: ProjectAssetState.notStarted,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  factory ProjectAsset.fromJson(Map<String, dynamic> json) => ProjectAsset(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        type: ProjectAssetType.values.byName(json['type'] as String),
        title: json['title'] as String,
        storagePath: json['storagePath'] as String,
        revision: json['revision'] as int? ?? 0,
        source: ProjectAssetSource.values.byName(
          json['source'] as String? ?? ProjectAssetSource.user.name,
        ),
        state: ProjectAssetState.values.byName(
          json['state'] as String? ?? ProjectAssetState.notStarted.name,
        ),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String id;
  final String projectId;
  final ProjectAssetType type;
  final String title;
  final String storagePath;

  /// 展示级版本号，随每次保存递增。正典冲突权威是 canonical 文件的
  /// 文件 revision（由 MutationProtocol 校验），不是此字段。
  final int revision;
  final ProjectAssetSource source;
  final ProjectAssetState state;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'type': type.name,
        'title': title,
        'storagePath': storagePath,
        'revision': revision,
        'source': source.name,
        'state': state.name,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  ProjectAsset copyWith({
    String? title,
    String? storagePath,
    int? revision,
    ProjectAssetSource? source,
    ProjectAssetState? state,
    DateTime? updatedAt,
  }) =>
      ProjectAsset(
        id: id,
        projectId: projectId,
        type: type,
        title: title ?? this.title,
        storagePath: storagePath ?? this.storagePath,
        revision: revision ?? this.revision,
        source: source ?? this.source,
        state: state ?? this.state,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

const _definitions = <ProjectAssetType, ({String title, String storagePath})>{
  ProjectAssetType.protagonist: (
    title: '主角',
    storagePath: 'project_meta/characters.json'
  ),
  ProjectAssetType.worldRules: (
    title: '世界规则',
    storagePath: 'project_meta/worldbuilding.json'
  ),
  ProjectAssetType.outline: (
    title: '故事大纲',
    storagePath: 'project_meta/outline.json'
  ),
  ProjectAssetType.openingScene: (
    title: '开场设计',
    storagePath: 'project_meta/opening_scene.json'
  ),
  ProjectAssetType.firstChapter: (
    title: '第一章',
    storagePath: 'chapters/first-chapter.md'
  ),
};
