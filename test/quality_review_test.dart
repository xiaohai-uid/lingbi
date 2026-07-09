import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/quality/review_pipeline.dart';

void main() {
  group('CharacterConsistency', () {
    test('consistent text returns high score', () {
      const text = '张三推开门，大步走进房间。他的眼神坚毅，步伐稳健。'
          '作为经历过无数战斗的战士，他从不畏惧任何挑战。';
      final result = CharacterConsistency.check(text, {'张三': '坚毅果断的战士'});
      expect(result.deviationScore, lessThan(30));
      expect(result.isConsistent, isTrue);
    });

    test('contradictory behavior detected', () {
      const text = '张三突然瑟瑟发抖，泪流满面，完全不像一个身经百战的战士。';
      final result = CharacterConsistency.check(text, {'张三': '坚毅果断的战士'});
      expect(result.deviationScore, greaterThan(50));
      expect(result.isConsistent, isFalse);
    });

    test('no character profiles returns unknown', () {
      const text = '一段普通的描写。';
      final result = CharacterConsistency.check(text, {});
      expect(result.isConsistent, isTrue);
      expect(result.deviationScore, 0);
    });

    test('checkWithLLM falls back to static check when no PromptService',
        () async {
      final cc = CharacterConsistency();
      const text = '张三推开门，大步走进房间。';
      final result = await cc.checkWithLLM(text, {'张三': '坚毅果断的战士'});
      expect(result, isA<CharacterConsistencyResult>());
    });

    test('CharacterConsistencyResult fromJson works', () {
      final json = {
        'isConsistent': false,
        'deviationScore': 75,
        'reason': '行为矛盾',
        'issues': [
          {
            'type': 'personality',
            'description': '张三的行为与坚毅设定矛盾',
            'currentBehavior': '颤抖',
            'conflictingHistory': '坚毅',
            'severity': 8,
          }
        ],
      };
      final result = CharacterConsistencyResult.fromJson(json);
      expect(result.isConsistent, isFalse);
      expect(result.deviationScore, 75);
      expect(result.issues.length, 1);
      expect(result.issues[0].type, 'personality');
    });
  });

  group('HookDensity', () {
    test('dense text passes qidian standard', () {
      const text = '突然！一道黑影闪过。张三猛然出手，一拳轰碎了对方的防御！'
          '周围的人都惊呆了。但这仅仅是开始——更可怕的还在后面。'
          '李四冷冷一笑："你以为这就结束了？"';
      final result = HookDensity.calculate(text);
      expect(result.meetsRequirement, isTrue, reason: '起点要求 ≥0.5 个爽点/1000字');
    });

    test('thin text fails requirement', () {
      const text = '天气很好。张三走在路上。路边有花。风吹过来。感觉很舒服。';
      final result = HookDensity.calculate(text);
      expect(result.meetsRequirement, isFalse);
    });

    test('tomato platform requires higher density', () {
      const text = '突然！一道黑影闪过。张三猛然出手，一拳轰碎了对方的防御！'
          '周围的人都惊呆了。但这仅仅是开始——更可怕的还在后面。';
      final result = HookDensity.calculate(text, platform: 'fanqie');
      // 番茄要求更高，可能不满足
      expect(result.density, greaterThan(0));
    });
  });

  group('FormatReview', () {
    test('well-formatted text passes', () {
      const text = '这是一个段落。\n\n这是另一个段落。\n\n"你好，"他说，"今天天气真好。"';
      final result = FormatReview.check(text);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('overly long paragraph flagged', () {
      final text = '这是一个非常长的段落。' * 200;
      final result = FormatReview.check(text);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.type == 'long_paragraph'), isTrue);
    });

    test('prohibited content flagged', () {
      const text = '```json\n{"key": "value"}\n```\n下面开始故事。';
      final result = FormatReview.check(text);
      expect(result.hasProhibitedContent, isTrue);
    });
  });

  group('ReviewPipeline', () {
    test('generates comprehensive report', () async {
      const text = '张三推开门，大步走进房间。他的眼神坚毅，步伐稳健。'
          '突然！一道黑影闪过。张三猛然出手！';
      final report = await ReviewPipeline.review(
        text,
        characterProfiles: {'张三': '坚毅果断的战士'},
      );
      expect(report, isA<ReviewReport>());
      expect(report.overallScore, greaterThan(0));
      expect(report.needsRewrite, isA<bool>());
    });

    test('bad text gets low score', () async {
      final text = '天气很好。' * 100;
      final report = await ReviewPipeline.review(text);
      expect(report.overallScore, lessThan(4.0));
      expect(report.needsRewrite, isTrue);
    });
  });
}
