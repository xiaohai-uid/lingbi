/// 质量审查服务(本地启发式)测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/quality_service.dart';
import 'package:lingbi/core/models/quality_report.dart';

void main() {
  final service = const QualityService();

  QualityDimension dim(QualityReport r, String label) =>
      r.byLabel(label)!;

  group('空文本', () {
    test('全部维度为 0', () {
      final r = service.analyze('');
      for (final d in r.dimensions) {
        expect(d.score, 0);
        expect(d.display, '0.0/10');
      }
    });
  });

  group('钩子密度', () {
    test('高悬念文本得分高', () {
      final text = List.filled(20, '悬念转折危机秘密反转伏笔背叛死亡觉醒')
          .join('。');
      final r = service.analyze(text);
      expect(dim(r, '钩子密度').score, greaterThan(5));
    });

    test('平淡文本得分低', () {
      final text = '他走到门口。她端起茶杯。风吹过树梢。天色渐渐暗了。';
      final r = service.analyze(text);
      expect(dim(r, '钩子密度').score, lessThan(3));
    });
  });

  group('人物深度', () {
    test('纯对话文本得分高', () {
      final text = '「你去哪？」\n「我不知道。」\n「跟我来。」\n「为什么？」';
      final r = service.analyze(text);
      expect(dim(r, '人物深度').score, greaterThan(5));
    });

    test('传入已知角色名可提升多样度', () {
      final text = '林月看着陈曦。陈曦叹了口气。林月握紧了剑。';
      final withNames = service.analyze(text, characterNames: ['林月', '陈曦']);
      final without = service.analyze(text);
      expect(dim(withNames, '人物深度').score,
          greaterThanOrEqualTo(dim(without, '人物深度').score));
    });
  });

  group('情节密度', () {
    test('短句密集文本得分高于长段独白', () {
      final dense = List.filled(15, '他拔剑。敌退。城破。火起。')
          .join('');
      final prose =
          '夜色如墨一般缓缓铺展开来，远处的山峦在月光下显得格外静谧而悠远，微风拂过林梢，带来一阵若有若无的凉意与远方的犬吠。';
      expect(dim(service.analyze(dense), '情节密度').score,
          greaterThan(dim(service.analyze(prose), '情节密度').score));
    });
  });

  group('优化建议', () {
    test('低分维度生成对应建议', () {
      final text = '天色暗了。风停了。他坐下。';
      final r = service.analyze(text);
      expect(r.suggestions, isNotEmpty);
      expect(r.suggestions.join(), contains('钩子'));
    });

    test('高质量文本无建议', () {
      // 对话 + 悬念 + 多句,四项都应较高
      final text = List.filled(12, '「快走！」悬念转折危机。林月拔剑，敌退。')
          .join('');
      final r = service.analyze(text, characterNames: ['林月']);
      // 至少不应产生低分建议
      expect(r.dimensions.every((d) => d.score >= 5), isTrue);
    });
  });
}
