/// 一键成剧 — 单元测试
///
/// 覆盖：拆解/风格/一致性/格式
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/import_export/data/drama_conversion_service.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── Mock ───

class MockAIProvider implements AIProvider {
  String mockResponse = '';

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      mockResponse;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async => [];
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 构造模拟 AI 返回的 JSON
String _mockDramaJson() {
  return jsonEncode({
    'character_cards': [
      {
        'name': '林逸',
        'appearance': '黑发青年，身形修长，目光坚毅',
        'personality': '沉稳内敛，重情义',
        'age': '18',
        'gender': '男',
        'clothing': '青色长袍',
        'distinctive_features': '左眉尾有一道细疤',
        'consistency_prompt': '黑发青年，身形修长，青色长袍，左眉尾细疤',
      },
      {
        'name': '苏瑶',
        'appearance': '白衣少女，长发如瀑',
        'personality': '灵动活泼',
        'age': '17',
        'gender': '女',
        'clothing': '白色连衣裙',
        'distinctive_features': '额间一点朱砂',
        'consistency_prompt': '白衣少女，长发如瀑，额间朱砂',
      },
    ],
    'storyboard_shots': [
      {
        'shot_number': 1,
        'description': '林逸站在山巅，远眺云海',
        'shot_size': 'extremeWide',
        'camera_angle': 'lowAngle',
        'camera_movement': 'pan',
        'transition': 'fade',
        'dialogue': '',
        'characters': ['林逸'],
        'duration': '3s',
      },
      {
        'shot_number': 2,
        'description': '苏瑶从林中走出，微笑',
        'shot_size': 'medium',
        'camera_angle': 'eyeLevel',
        'camera_movement': 'tracking',
        'transition': 'cut',
        'dialogue': '你果然在这里。',
        'characters': ['苏瑶'],
        'duration': '2s',
      },
    ],
    'scenes': [
      {
        'scene_number': 1,
        'location': '天柱山巅',
        'time_of_day': '黄昏',
        'atmosphere': '壮阔苍凉',
        'environment_details': '云海翻涌，残阳如血',
        'characters': ['林逸', '苏瑶'],
      },
    ],
  });
}

void main() {
  group('VisualStyle', () {
    test('label 中文标签', () {
      expect(VisualStyle.guoman.label, '国漫');
      expect(VisualStyle.rihan.label, '日漫');
      expect(VisualStyle.realistic.label, '写实');
      expect(VisualStyle.threeD.label, '3D');
    });

    test('promptHint 非空', () {
      for (final style in VisualStyle.values) {
        expect(style.promptHint, isNotEmpty);
      }
    });

    test('fromString 解析', () {
      expect(VisualStyle.fromString('rihan'), VisualStyle.rihan);
      expect(VisualStyle.fromString('unknown'), VisualStyle.guoman);
    });
  });

  group('镜头语言枚举', () {
    test('ShotSize 标签', () {
      expect(ShotSize.extremeWide.label, '远景');
      expect(ShotSize.closeUp.label, '近景');
    });

    test('CameraAngle 标签', () {
      expect(CameraAngle.lowAngle.label, '仰视');
      expect(CameraAngle.birdEye.label, '鸟瞰');
    });

    test('CameraMovement 标签', () {
      expect(CameraMovement.tracking.label, '跟拍');
    });

    test('Transition 标签', () {
      expect(Transition.dissolve.label, '叠化');
    });
  });

  group('CharacterCard', () {
    test('fromJson / toJson 往返', () {
      const card = CharacterCard(
        name: '林逸',
        appearance: '黑发青年',
        personality: '沉稳',
        age: '18',
        gender: '男',
        clothing: '青袍',
        distinctiveFeatures: '眉疤',
        consistencyPrompt: '黑发+青袍+眉疤',
      );

      final json = card.toJson();
      final restored = CharacterCard.fromJson(json);

      expect(restored.name, '林逸');
      expect(restored.appearance, '黑发青年');
      expect(restored.consistencyPrompt, '黑发+青袍+眉疤');
    });
  });

  group('StoryboardShot', () {
    test('fromJson / toJson 往返', () {
      const shot = StoryboardShot(
        shotNumber: 1,
        description: '远景',
        shotSize: ShotSize.extremeWide,
        cameraAngle: CameraAngle.lowAngle,
        cameraMovement: CameraMovement.pan,
        transition: Transition.fade,
        characters: ['林逸'],
        duration: '3s',
      );

      final json = shot.toJson();
      final restored = StoryboardShot.fromJson(json);

      expect(restored.shotNumber, 1);
      expect(restored.shotSize, ShotSize.extremeWide);
      expect(restored.cameraAngle, CameraAngle.lowAngle);
      expect(restored.transition, Transition.fade);
    });

    test('cameraAnnotation 格式化', () {
      const shot = StoryboardShot(
        shotNumber: 1,
        description: '测试',
        shotSize: ShotSize.closeUp,
        cameraAngle: CameraAngle.highAngle,
        cameraMovement: CameraMovement.zoom,
        transition: Transition.dissolve,
      );

      expect(shot.cameraAnnotation, '近景 | 俯视 | 变焦 | 转场: 叠化');
    });
  });

  group('DramaConversionService 转换', () {
    late MockAIProvider aiProvider;
    late DramaConversionService service;

    setUp(() {
      aiProvider = MockAIProvider();
      service = DramaConversionService(aiProvider: aiProvider);
    });

    test('convert 返回完整结果', () async {
      aiProvider.mockResponse = _mockDramaJson();

      final result = await service.convert(
        novelText: '林逸站在山巅，远眺云海。苏瑶从林中走出。',
      );

      expect(result.isSuccess, isTrue);
      expect(result.characterCards.length, 2);
      expect(result.storyboardShots.length, 2);
      expect(result.scenes.length, 1);
      expect(result.style, VisualStyle.guoman);
    });

    test('convert 空文本返回错误', () async {
      final result = await service.convert(novelText: '  ');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('为空'));
    });

    test('convert AI异常返回错误', () async {
      aiProvider.mockResponse = 'not json at all';

      final result = await service.convert(novelText: '测试文本');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('解析'));
    });

    test('convert 支持代码块包裹的 JSON', () async {
      aiProvider.mockResponse = '```json\n${_mockDramaJson()}\n```';

      final result = await service.convert(novelText: '测试');
      expect(result.isSuccess, isTrue);
      expect(result.characterCards.length, 2);
    });

    test('extractCharacters 提取角色', () async {
      aiProvider.mockResponse = jsonEncode([
        {
          'name': '张三',
          'appearance': '壮汉',
          'personality': '豪爽',
          'age': '30',
          'gender': '男',
          'clothing': '',
          'distinctive_features': '',
          'consistency_prompt': '壮汉张三',
        },
      ]);

      final cards = await service.extractCharacters(novelText: '张三大笑。');
      expect(cards.length, 1);
      expect(cards.first.name, '张三');
    });

    test('extractCharacters 空文本返回空', () async {
      final cards = await service.extractCharacters(novelText: '');
      expect(cards, isEmpty);
    });
  });

  group('角色一致性', () {
    test('buildConsistencyPrompt 包含关键信息', () {
      final service = DramaConversionService(
        aiProvider: MockAIProvider(),
      );

      const card = CharacterCard(
        name: '林逸',
        appearance: '黑发青年，身形修长',
        personality: '沉稳',
        clothing: '青色长袍',
        distinctiveFeatures: '左眉尾细疤',
      );

      final prompt = service.buildConsistencyPrompt(card, VisualStyle.rihan);

      expect(prompt, contains('林逸'));
      expect(prompt, contains('日漫'));
      expect(prompt, contains('黑发青年'));
      expect(prompt, contains('青色长袍'));
      expect(prompt, contains('左眉尾细疤'));
      expect(prompt, contains('一致'));
    });
  });

  group('风格与格式', () {
    test('预设风格 4 种', () {
      expect(VisualStyle.values.length, 4);
    });

    test('内置输出格式 3 种', () {
      final service = DramaConversionService(
        aiProvider: MockAIProvider(),
      );
      expect(service.formats.length, 3);
      expect(service.formats.any((f) => f.id == 'standard'), isTrue);
      expect(service.formats.any((f) => f.id == 'comic'), isTrue);
      expect(service.formats.any((f) => f.id == 'animation'), isTrue);
    });

    test('registerFormat 扩展格式', () {
      final service = DramaConversionService(
        aiProvider: MockAIProvider(),
      );

      service.registerFormat(const OutputFormatTemplate(
        id: 'game_cg',
        name: '游戏CG',
        formatPrompt: '游戏CG分镜格式',
      ));

      expect(service.formats.length, 4);
      expect(service.formats.any((f) => f.id == 'game_cg'), isTrue);
    });

    test('CustomStyleParams 自定义风格', () {
      const params = CustomStyleParams(
        colorPalette: '暗色系',
        lightingMood: '低调光',
      );

      expect(params.isEmpty, isFalse);
      final section = params.toPromptSection();
      expect(section, contains('暗色系'));
      expect(section, contains('低调光'));
    });

    test('CustomStyleParams 空参数', () {
      const params = CustomStyleParams();
      expect(params.isEmpty, isTrue);
      expect(params.toPromptSection(), isEmpty);
    });
  });

  group('DramaConversionResult', () {
    test('toJson 序列化', () {
      const result = DramaConversionResult(
        characterCards: [
          CharacterCard(name: 'A', appearance: 'a', personality: 'x'),
        ],
        storyboardShots: [
          StoryboardShot(shotNumber: 1, description: 'test'),
        ],
        scenes: [
          SceneDescription(
            sceneNumber: 1,
            location: '山巅',
            timeOfDay: '黄昏',
            atmosphere: '壮阔',
          ),
        ],
        style: VisualStyle.threeD,
      );

      final json = result.toJson();
      expect(json['style'], 'threeD');
      expect((json['character_cards'] as List).length, 1);
      expect((json['storyboard_shots'] as List).length, 1);
      expect((json['scenes'] as List).length, 1);
    });
  });
}
