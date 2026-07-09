/// 故事节拍模型
class StoryBeat {
  StoryBeat({
    String? id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.colorIndex = 0,
    this.sequence = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  factory StoryBeat.fromJson(Map<String, dynamic> json) => StoryBeat(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        colorIndex: json['colorIndex'] as int? ?? 0,
        sequence: json['sequence'] as int? ?? 0,
      );
  final String id;
  final String projectId;
  String title;
  String description;
  int colorIndex;
  int sequence;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'colorIndex': colorIndex,
        'sequence': sequence,
      };

  StoryBeat copyWith({
    String? title,
    String? description,
    int? colorIndex,
    int? sequence,
  }) =>
      StoryBeat(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        colorIndex: colorIndex ?? this.colorIndex,
        sequence: sequence ?? this.sequence,
      );
}
