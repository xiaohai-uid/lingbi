/// 三层生成管线 — 共享数据模型
library novel_models;

/// Layer 1 输入：创意
class Layer1Request {
  final String idea;
  final String genre;
  final String style;

  const Layer1Request({
    required this.idea,
    this.genre = 'fantasy',
    this.style = 'qidian',
  });

  Map<String, dynamic> toJson() => {
        'idea': idea,
        'genre': genre,
        'style': style,
      };

  factory Layer1Request.fromJson(Map<String, dynamic> json) => Layer1Request(
        idea: json['idea'] as String,
        genre: json['genre'] as String? ?? 'fantasy',
        style: json['style'] as String? ?? 'qidian',
      );
}

/// Layer 1 输出：梗概 + 角色
class Layer1Response {
  final String synopsis;
  final String setting;
  final List<String> themes;
  final List<Map<String, dynamic>> characters;

  const Layer1Response({
    required this.synopsis,
    required this.setting,
    this.themes = const [],
    this.characters = const [],
  });

  Map<String, dynamic> toJson() => {
        'synopsis': synopsis,
        'setting': setting,
        'themes': themes,
        'characters': characters,
      };

  factory Layer1Response.fromJson(Map<String, dynamic> json) => Layer1Response(
        synopsis: json['synopsis'] as String,
        setting: json['setting'] as String? ?? '',
        themes: (json['themes'] as List?)?.cast<String>() ?? [],
        characters:
            (json['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
}

/// Layer 2 输入
class Layer2Request {
  final String synopsis;
  final String setting;
  final List<String> themes;
  final int numVolumes;
  final int numChaptersPerVolume;

  const Layer2Request({
    required this.synopsis,
    this.setting = '',
    this.themes = const [],
    this.numVolumes = 3,
    this.numChaptersPerVolume = 8,
  });

  Map<String, dynamic> toJson() => {
        'synopsis': synopsis,
        'setting': setting,
        'themes': themes,
        'numVolumes': numVolumes,
        'numChaptersPerVolume': numChaptersPerVolume,
      };

  factory Layer2Request.fromJson(Map<String, dynamic> json) => Layer2Request(
        synopsis: json['synopsis'] as String,
        setting: json['setting'] as String? ?? '',
        themes: (json['themes'] as List?)?.cast<String>() ?? [],
        numVolumes: json['numVolumes'] as int? ?? 3,
        numChaptersPerVolume: json['numChaptersPerVolume'] as int? ?? 8,
      );
}

/// Layer 2 输出：卷纲
class Layer2Response {
  final List<Map<String, dynamic>> volumes;

  const Layer2Response({required this.volumes});

  Map<String, dynamic> toJson() => {'volumes': volumes};

  factory Layer2Response.fromJson(Map<String, dynamic> json) => Layer2Response(
        volumes: (json['volumes'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
}

/// Layer 3 输入：场景上下文
class Layer3Request {
  final String chapterTitle;
  final String sceneOutline;
  final String context;
  final List<String> characters;
  final String genre;
  final String style;

  const Layer3Request({
    required this.chapterTitle,
    required this.sceneOutline,
    this.context = '',
    this.characters = const [],
    this.genre = 'fantasy',
    this.style = 'qidian',
  });

  Map<String, dynamic> toJson() => {
        'chapterTitle': chapterTitle,
        'sceneOutline': sceneOutline,
        'context': context,
        'characters': characters,
        'genre': genre,
        'style': style,
      };
}
