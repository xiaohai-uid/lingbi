/// The single, durable contract passed from template selection through every
/// project workflow. UI labels may change; these values may not be discarded.
final class ProjectBrief {
  const ProjectBrief({
    required this.title,
    required this.genreId,
    required this.templateId,
    this.targetPlatform,
    this.targetLength,
    this.audience,
    this.premise,
    this.revision = 0,
  });

  factory ProjectBrief.fromJson(Map<String, dynamic> json) => ProjectBrief(
        title: (json['title'] ?? json['name'] ?? '').toString(),
        genreId: (json['genreId'] ?? json['genre'] ?? '').toString(),
        templateId: (json['templateId'] ?? '').toString(),
        targetPlatform:
            (json['targetPlatform'] ?? json['platform'])?.toString(),
        targetLength: _readInt(json['targetLength']),
        audience: json['audience']?.toString(),
        premise: (json['premise'] ?? json['description'])?.toString(),
        revision: _readInt(json['revision']) ?? 0,
      );

  final String title;
  final String genreId;
  final String templateId;
  final String? targetPlatform;
  final int? targetLength;
  final String? audience;
  final String? premise;
  final int revision;

  ProjectBrief copyWith({
    String? title,
    String? genreId,
    String? templateId,
    String? targetPlatform,
    int? targetLength,
    String? audience,
    String? premise,
    int? revision,
  }) =>
      ProjectBrief(
        title: title ?? this.title,
        genreId: genreId ?? this.genreId,
        templateId: templateId ?? this.templateId,
        targetPlatform: targetPlatform ?? this.targetPlatform,
        targetLength: targetLength ?? this.targetLength,
        audience: audience ?? this.audience,
        premise: premise ?? this.premise,
        revision: revision ?? this.revision,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'genreId': genreId,
        'templateId': templateId,
        if (targetPlatform != null) 'targetPlatform': targetPlatform,
        if (targetLength != null) 'targetLength': targetLength,
        if (audience != null) 'audience': audience,
        if (premise != null) 'premise': premise,
        'revision': revision,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBrief &&
          title == other.title &&
          genreId == other.genreId &&
          templateId == other.templateId &&
          targetPlatform == other.targetPlatform &&
          targetLength == other.targetLength &&
          audience == other.audience &&
          premise == other.premise &&
          revision == other.revision;

  @override
  int get hashCode => Object.hash(
        title,
        genreId,
        templateId,
        targetPlatform,
        targetLength,
        audience,
        premise,
        revision,
      );

  static int? _readInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
