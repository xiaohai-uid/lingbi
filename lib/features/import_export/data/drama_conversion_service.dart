/// 一键成剧（重量 Skill）
///
/// 将小说章节/全文拆解为：
/// - 角色提示词卡（含一致性描述）
/// - 分镜脚本（镜头语言标注）
/// - 场景描述
///
/// 支持预设风格（国漫/日漫/写实/3D）+ 自定义风格。
/// 输出格式可扩展（社区贡献新模板）。
library;

import 'dart:convert';

import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── 数据模型 ───

/// 预设视觉风格
enum VisualStyle {
  guoman,
  rihan,
  realistic,
  threeD;

  String get label => switch (this) {
        VisualStyle.guoman => '国漫',
        VisualStyle.rihan => '日漫',
        VisualStyle.realistic => '写实',
        VisualStyle.threeD => '3D',
      };

  /// 风格对应的描述方式指引
  String get promptHint => switch (this) {
        VisualStyle.guoman => '中国动漫风格，水墨/工笔元素，古典配色',
        VisualStyle.rihan => '日本动漫风格，大眼睛，鲜明色彩，赛璐璐着色',
        VisualStyle.realistic => '写实风格，真实光影，电影质感',
        VisualStyle.threeD => '3D渲染风格，体积光，材质细节丰富',
      };

  static VisualStyle fromString(String s) {
    return VisualStyle.values.firstWhere(
      (e) => e.name == s,
      orElse: () => VisualStyle.guoman,
    );
  }
}

/// 景别
enum ShotSize {
  extremeWide,
  wide,
  medium,
  closeUp,
  extremeCloseUp;

  String get label => switch (this) {
        ShotSize.extremeWide => '远景',
        ShotSize.wide => '全景',
        ShotSize.medium => '中景',
        ShotSize.closeUp => '近景',
        ShotSize.extremeCloseUp => '特写',
      };
}

/// 镜头角度
enum CameraAngle {
  eyeLevel,
  lowAngle,
  highAngle,
  birdEye,
  dutch;

  String get label => switch (this) {
        CameraAngle.eyeLevel => '平视',
        CameraAngle.lowAngle => '仰视',
        CameraAngle.highAngle => '俯视',
        CameraAngle.birdEye => '鸟瞰',
        CameraAngle.dutch => '倾斜',
      };
}

/// 运镜方式
enum CameraMovement {
  staticShot,
  pan,
  tilt,
  dolly,
  zoom,
  tracking;

  String get label => switch (this) {
        CameraMovement.staticShot => '固定',
        CameraMovement.pan => '横摇',
        CameraMovement.tilt => '纵摇',
        CameraMovement.dolly => '推拉',
        CameraMovement.zoom => '变焦',
        CameraMovement.tracking => '跟拍',
      };
}

/// 转场方式
enum Transition {
  cut,
  dissolve,
  fade,
  wipe;

  String get label => switch (this) {
        Transition.cut => '硬切',
        Transition.dissolve => '叠化',
        Transition.fade => '淡入淡出',
        Transition.wipe => '划像',
      };
}

/// 角色提示词卡
class CharacterCard {
  const CharacterCard({
    required this.name,
    required this.appearance,
    required this.personality,
    this.age = '',
    this.gender = '',
    this.clothing = '',
    this.distinctiveFeatures = '',
    this.consistencyPrompt = '',
  });

  factory CharacterCard.fromJson(Map<String, dynamic> json) {
    return CharacterCard(
      name: json['name'] as String? ?? '',
      appearance: json['appearance'] as String? ?? '',
      personality: json['personality'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      clothing: json['clothing'] as String? ?? '',
      distinctiveFeatures: json['distinctive_features'] as String? ?? '',
      consistencyPrompt: json['consistency_prompt'] as String? ?? '',
    );
  }

  final String name;
  final String appearance;
  final String personality;
  final String age;
  final String gender;
  final String clothing;
  final String distinctiveFeatures;

  /// 一致性提示词：确保同一角色在不同场景中外观描述一致
  final String consistencyPrompt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'appearance': appearance,
        'personality': personality,
        'age': age,
        'gender': gender,
        'clothing': clothing,
        'distinctive_features': distinctiveFeatures,
        'consistency_prompt': consistencyPrompt,
      };
}

/// 分镜条目
class StoryboardShot {
  const StoryboardShot({
    required this.shotNumber,
    required this.description,
    this.shotSize = ShotSize.medium,
    this.cameraAngle = CameraAngle.eyeLevel,
    this.cameraMovement = CameraMovement.staticShot,
    this.transition = Transition.cut,
    this.dialogue = '',
    this.characters = const [],
    this.duration = '',
  });

  factory StoryboardShot.fromJson(Map<String, dynamic> json) {
    return StoryboardShot(
      shotNumber: json['shot_number'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      shotSize: ShotSize.values.firstWhere(
        (e) => e.name == (json['shot_size'] as String? ?? ''),
        orElse: () => ShotSize.medium,
      ),
      cameraAngle: CameraAngle.values.firstWhere(
        (e) => e.name == (json['camera_angle'] as String? ?? ''),
        orElse: () => CameraAngle.eyeLevel,
      ),
      cameraMovement: CameraMovement.values.firstWhere(
        (e) => e.name == (json['camera_movement'] as String? ?? ''),
        orElse: () => CameraMovement.staticShot,
      ),
      transition: Transition.values.firstWhere(
        (e) => e.name == (json['transition'] as String? ?? ''),
        orElse: () => Transition.cut,
      ),
      dialogue: json['dialogue'] as String? ?? '',
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      duration: json['duration'] as String? ?? '',
    );
  }

  final int shotNumber;
  final String description;
  final ShotSize shotSize;
  final CameraAngle cameraAngle;
  final CameraMovement cameraMovement;
  final Transition transition;
  final String dialogue;
  final List<String> characters;
  final String duration;

  Map<String, dynamic> toJson() => {
        'shot_number': shotNumber,
        'description': description,
        'shot_size': shotSize.name,
        'camera_angle': cameraAngle.name,
        'camera_movement': cameraMovement.name,
        'transition': transition.name,
        'dialogue': dialogue,
        'characters': characters,
        'duration': duration,
      };

  /// 镜头语言标注文本
  String get cameraAnnotation =>
      '${shotSize.label} | ${cameraAngle.label} | ${cameraMovement.label} | 转场: ${transition.label}';
}

/// 场景描述
class SceneDescription {
  const SceneDescription({
    required this.sceneNumber,
    required this.location,
    required this.timeOfDay,
    required this.atmosphere,
    this.environmentDetails = '',
    this.characters = const [],
  });

  factory SceneDescription.fromJson(Map<String, dynamic> json) {
    return SceneDescription(
      sceneNumber: json['scene_number'] as int? ?? 0,
      location: json['location'] as String? ?? '',
      timeOfDay: json['time_of_day'] as String? ?? '',
      atmosphere: json['atmosphere'] as String? ?? '',
      environmentDetails: json['environment_details'] as String? ?? '',
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  final int sceneNumber;
  final String location;
  final String timeOfDay;
  final String atmosphere;
  final String environmentDetails;
  final List<String> characters;

  Map<String, dynamic> toJson() => {
        'scene_number': sceneNumber,
        'location': location,
        'time_of_day': timeOfDay,
        'atmosphere': atmosphere,
        'environment_details': environmentDetails,
        'characters': characters,
      };
}

/// 成剧转换结果
class DramaConversionResult {
  const DramaConversionResult({
    this.characterCards = const [],
    this.storyboardShots = const [],
    this.scenes = const [],
    this.style = VisualStyle.guoman,
    this.error = '',
  });

  final List<CharacterCard> characterCards;
  final List<StoryboardShot> storyboardShots;
  final List<SceneDescription> scenes;
  final VisualStyle style;
  final String error;

  bool get isSuccess => error.isEmpty;

  Map<String, dynamic> toJson() => {
        'character_cards': characterCards.map((c) => c.toJson()).toList(),
        'storyboard_shots': storyboardShots.map((s) => s.toJson()).toList(),
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'style': style.name,
      };
}

/// 自定义风格参数
class CustomStyleParams {
  const CustomStyleParams({
    this.colorPalette = '',
    this.lineStyle = '',
    this.lightingMood = '',
    this.extraPrompt = '',
  });

  final String colorPalette;
  final String lineStyle;
  final String lightingMood;
  final String extraPrompt;

  bool get isEmpty =>
      colorPalette.isEmpty &&
      lineStyle.isEmpty &&
      lightingMood.isEmpty &&
      extraPrompt.isEmpty;

  String toPromptSection() {
    if (isEmpty) return '';
    final sb = StringBuffer('【自定义风格】\n');
    if (colorPalette.isNotEmpty) sb.writeln('- 配色: $colorPalette');
    if (lineStyle.isNotEmpty) sb.writeln('- 线条: $lineStyle');
    if (lightingMood.isNotEmpty) sb.writeln('- 光影: $lightingMood');
    if (extraPrompt.isNotEmpty) sb.writeln('- 补充: $extraPrompt');
    return sb.toString();
  }
}

/// 输出格式模板（可扩展）
class OutputFormatTemplate {
  const OutputFormatTemplate({
    required this.id,
    required this.name,
    required this.formatPrompt,
  });

  final String id;
  final String name;

  /// 格式描述 prompt（影响 AI 输出结构）
  final String formatPrompt;
}

// ─── 服务 ───

/// 一键成剧服务
class DramaConversionService {
  DramaConversionService({
    required AIProvider aiProvider,
    List<OutputFormatTemplate>? customFormats,
  })  : _aiProvider = aiProvider,
        _formats = [..._builtinFormats, ...?customFormats];

  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;
  final List<OutputFormatTemplate> _formats;

  // ─── 格式管理 ───

  /// 获取所有输出格式模板
  List<OutputFormatTemplate> get formats => List.unmodifiable(_formats);

  /// 注册自定义输出格式
  void registerFormat(OutputFormatTemplate format) {
    _formats.add(format);
  }

  // ─── 核心转换 ───

  /// 一键成剧：小说文本 → 角色卡 + 分镜 + 场景
  Future<DramaConversionResult> convert({
    required String novelText,
    VisualStyle style = VisualStyle.guoman,
    CustomStyleParams customStyle = const CustomStyleParams(),
    String formatId = 'standard',
  }) async {
    if (novelText.trim().isEmpty) {
      return const DramaConversionResult(error: '输入文本为空');
    }

    try {
      final prompt = _buildConversionPrompt(
        novelText: novelText,
        style: style,
        customStyle: customStyle,
        formatId: formatId,
      );

      final response = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是专业的影视分镜师和角色设计师。将小说文本转化为结构化的影视制作素材。'
                '输出必须是合法 JSON，包含 character_cards、storyboard_shots、scenes 三个数组。',
          ),
          ChatMessage(role: 'user', content: prompt),
        ],
        temperature: 0.8,
        maxTokens: 4096,
      );

      return _parseResponse(response, style);
    } catch (e) {
      return DramaConversionResult(error: '转换失败: $e', style: style);
    }
  }

  /// 仅提取角色卡（轻量操作）
  Future<List<CharacterCard>> extractCharacters({
    required String novelText,
    VisualStyle style = VisualStyle.guoman,
  }) async {
    if (novelText.trim().isEmpty) return [];

    try {
      final response = await _aiProvider.chatSync(
        messages: [
          ChatMessage(
            role: 'system',
            content: '你是角色设计师。从小说中提取所有角色并生成提示词卡。'
                '风格: ${style.promptHint}。'
                '输出 JSON 数组，每项含 name/appearance/personality/age/gender/'
                'clothing/distinctive_features/consistency_prompt 字段。',
          ),
          ChatMessage(role: 'user', content: '提取角色:\n\n$novelText'),
        ],
      );

      final data = jsonDecode(_cleanJson(response)) as List<dynamic>;
      return data
          .map((e) => CharacterCard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 生成一致性描述：确保角色在不同场景中外观一致
  String buildConsistencyPrompt(CharacterCard card, VisualStyle style) {
    final sb = StringBuffer();
    sb.writeln('【角色一致性基准 — ${card.name}】');
    sb.writeln('风格: ${style.label}');
    sb.writeln('外观: ${card.appearance}');
    if (card.clothing.isNotEmpty) sb.writeln('服装: ${card.clothing}');
    if (card.distinctiveFeatures.isNotEmpty) {
      sb.writeln('特征: ${card.distinctiveFeatures}');
    }
    sb.writeln('⚠️ 所有场景中该角色必须保持以上外观描述一致。');
    return sb.toString();
  }

  // ─── 辅助方法 ───

  String _buildConversionPrompt({
    required String novelText,
    required VisualStyle style,
    required CustomStyleParams customStyle,
    required String formatId,
  }) {
    final sb = StringBuffer();
    sb.writeln('【视觉风格】${style.label}: ${style.promptHint}');

    final customSection = customStyle.toPromptSection();
    if (customSection.isNotEmpty) sb.writeln(customSection);

    // 查找输出格式模板
    final format = _formats.where((f) => f.id == formatId).firstOrNull;
    if (format != null) {
      sb.writeln('\n【输出格式】${format.name}');
      sb.writeln(format.formatPrompt);
    }

    sb.writeln('\n【镜头语言要求】');
    sb.writeln('每个分镜必须标注：景别（远景/全景/中景/近景/特写）、'
        '角度（平视/仰视/俯视/鸟瞰/倾斜）、'
        '运镜（固定/横摇/纵摇/推拉/变焦/跟拍）、'
        '转场（硬切/叠化/淡入淡出/划像）。');

    sb.writeln('\n【角色一致性要求】');
    sb.writeln('为每个角色生成 consistency_prompt 字段，'
        '包含该角色的固定外观描述，确保跨场景一致。');

    sb.writeln('\n【小说文本】\n$novelText');
    sb.writeln('\n请输出 JSON（含 character_cards / storyboard_shots / scenes）。');

    return sb.toString();
  }

  DramaConversionResult _parseResponse(String response, VisualStyle style) {
    try {
      final json = jsonDecode(_cleanJson(response)) as Map<String, dynamic>;

      final cards = (json['character_cards'] as List<dynamic>?)
              ?.map((e) => CharacterCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final shots = (json['storyboard_shots'] as List<dynamic>?)
              ?.map((e) => StoryboardShot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final scenes = (json['scenes'] as List<dynamic>?)
              ?.map((e) => SceneDescription.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return DramaConversionResult(
        characterCards: cards,
        storyboardShots: shots,
        scenes: scenes,
        style: style,
      );
    } catch (e) {
      return DramaConversionResult(error: '解析AI输出失败: $e', style: style);
    }
  }

  /// 清理 AI 输出中可能的代码块包裹
  String _cleanJson(String output) {
    var cleaned = output.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }
    return cleaned;
  }

  /// 内置输出格式
  static const _builtinFormats = [
    OutputFormatTemplate(
      id: 'standard',
      name: '标准分镜',
      formatPrompt: '标准影视分镜格式，每镜含编号/描述/镜头语言/对白/角色/时长。',
    ),
    OutputFormatTemplate(
      id: 'comic',
      name: '漫画分格',
      formatPrompt: '漫画分格格式，标注格序/构图/气泡位置/音效字。',
    ),
    OutputFormatTemplate(
      id: 'animation',
      name: '动画分镜',
      formatPrompt: '动画分镜格式，标注关键帧/中间帧/时间轴/动作描述。',
    ),
  ];
}
