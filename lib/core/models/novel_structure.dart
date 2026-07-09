/// 三层生成管线 — 数据模型
///
/// 从 AI_NovelGenerator 的 pydantic_definitions/ 移植到 Dart。
library;

/// 角色档案
class CharacterProfile {
  const CharacterProfile({
    required this.name,
    required this.role,
    this.age,
    this.personality = '',
    this.backstory,
    this.motivation,
    this.arc,
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) =>
      CharacterProfile(
        name: json['name'] as String,
        role: json['role'] as String? ?? '配角',
        age: json['age'] as int?,
        personality: json['personality'] as String? ?? '',
        backstory: json['backstory'] as String?,
        motivation: json['motivation'] as String?,
        arc: json['arc'] as String?,
      );
  final String name;
  final String role; // 主角/配角/反派
  final int? age;
  final String personality;
  final String? backstory;
  final String? motivation;
  final String? arc;

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        if (age != null) 'age': age,
        'personality': personality,
        if (backstory != null) 'backstory': backstory,
        if (motivation != null) 'motivation': motivation,
        if (arc != null) 'arc': arc,
      };
}

/// Layer 1 输出：故事梗概 + 核心人设
class SynopsisAndCharacters {
  const SynopsisAndCharacters({
    required this.synopsis,
    this.setting = '',
    this.themes = const [],
    this.characters = const [],
  });

  factory SynopsisAndCharacters.fromJson(Map<String, dynamic> json) =>
      SynopsisAndCharacters(
        synopsis: json['synopsis'] as String,
        setting: json['setting'] as String? ?? '',
        themes: (json['themes'] as List?)?.cast<String>() ?? [],
        characters: (json['characters'] as List?)
                ?.map(
                    (c) => CharacterProfile.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
  final String synopsis; // 500-1000 字
  final String setting; // 时代/世界设定
  final List<String> themes; // 核心主题
  final List<CharacterProfile> characters;

  Map<String, dynamic> toJson() => {
        'synopsis': synopsis,
        'setting': setting,
        'themes': themes,
        'characters': characters.map((c) => c.toJson()).toList(),
      };
}

/// 场景大纲
class SceneOutline {
  const SceneOutline({
    this.sceneNumber = 0,
    required this.title,
    required this.summary,
    required this.characters,
    required this.location,
    this.mood,
    this.conflict,
  });

  factory SceneOutline.fromJson(Map<String, dynamic> json) => SceneOutline(
        sceneNumber: json['sceneNumber'] as int? ?? 0,
        title: json['title'] as String,
        summary: json['summary'] as String,
        characters: (json['characters'] as List?)?.cast<String>() ?? [],
        location: json['location'] as String? ?? '',
        mood: json['mood'] as String?,
        conflict: json['conflict'] as String?,
      );
  final int sceneNumber;
  final String title;
  final String summary; // 100-300 字
  final List<String> characters;
  final String location;
  final String? mood;
  final String? conflict;

  Map<String, dynamic> toJson() => {
        'sceneNumber': sceneNumber,
        'title': title,
        'summary': summary,
        'characters': characters,
        'location': location,
        if (mood != null) 'mood': mood,
        if (conflict != null) 'conflict': conflict,
      };
}

/// 章节大纲
class ChapterOutline {
  const ChapterOutline({
    this.chapterNumber = 0,
    required this.title,
    required this.summary,
    this.hook,
    this.scenes = const [],
  });

  factory ChapterOutline.fromJson(Map<String, dynamic> json) => ChapterOutline(
        chapterNumber: json['chapterNumber'] as int? ?? 0,
        title: json['title'] as String,
        summary: json['summary'] as String,
        hook: json['hook'] as String?,
        scenes: (json['scenes'] as List?)
                ?.map((s) => SceneOutline.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
  final int chapterNumber;
  final String title;
  final String summary; // 200-500 字
  final String? hook; // 章末钩子
  final List<SceneOutline> scenes;

  Map<String, dynamic> toJson() => {
        'chapterNumber': chapterNumber,
        'title': title,
        'summary': summary,
        if (hook != null) 'hook': hook,
        'scenes': scenes.map((s) => s.toJson()).toList(),
      };
}

/// 卷大纲
class VolumeOutline {
  const VolumeOutline({
    this.volumeNumber = 0,
    required this.title,
    required this.summary,
    this.chapters = const [],
  });

  factory VolumeOutline.fromJson(Map<String, dynamic> json) => VolumeOutline(
        volumeNumber: json['volumeNumber'] as int? ?? 0,
        title: json['title'] as String,
        summary: json['summary'] as String,
        chapters: (json['chapters'] as List?)
                ?.map((c) => ChapterOutline.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
  final int volumeNumber;
  final String title;
  final String summary; // 300-800 字
  final List<ChapterOutline> chapters;

  Map<String, dynamic> toJson() => {
        'volumeNumber': volumeNumber,
        'title': title,
        'summary': summary,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };
}

/// Layer 2 输出：完整分卷结构
class LayeredNovelStructure {
  const LayeredNovelStructure({this.volumes = const []});

  factory LayeredNovelStructure.fromJson(Map<String, dynamic> json) =>
      LayeredNovelStructure(
        volumes: (json['volumes'] as List?)
                ?.map((v) => VolumeOutline.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );
  final List<VolumeOutline> volumes;

  Map<String, dynamic> toJson() => {
        'volumes': volumes.map((v) => v.toJson()).toList(),
      };
}
