import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/review/data/clarity_check_service.dart';

void main() {
  late ClarityCheckService service;

  setUp(() {
    service = ClarityCheckService();
  });

  group('ClarityCheckService', () {
    // ── A. 模糊规则匹配 ──────────────────────────────

    group('模糊规则匹配', () {
      test('关键词"帮我写"触发确认', () {
        final result = service.assess('帮我写');
        expect(result.needsClarification, isTrue);
        expect(result.question, isNotEmpty);
        expect(result.quickOptions, isNotEmpty);
      });

      test('关键词"写一段"触发确认', () {
        final result = service.assess('写一段');
        expect(result.needsClarification, isTrue);
        expect(result.question, isNotEmpty);
        expect(result.quickOptions, isNotEmpty);
      });

      test('关键词"帮我创作"触发确认', () {
        final result = service.assess('帮我创作');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"续写"触发确认', () {
        final result = service.assess('续写');
        expect(result.needsClarification, isTrue);
        expect(result.question, isNotEmpty);
        expect(result.quickOptions, isNotEmpty);
      });

      test('关键词"继续写"触发确认', () {
        final result = service.assess('继续写');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"接着写"触发确认', () {
        final result = service.assess('接着写');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"改一下"触发确认', () {
        final result = service.assess('改一下');
        expect(result.needsClarification, isTrue);
        expect(result.question, isNotEmpty);
        expect(result.quickOptions, isNotEmpty);
      });

      test('关键词"修改"触发确认', () {
        final result = service.assess('修改');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"润色"触发确认', () {
        final result = service.assess('润色');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"优化"触发确认', () {
        final result = service.assess('优化');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"扩写"触发确认', () {
        final result = service.assess('扩写');
        expect(result.needsClarification, isTrue);
        expect(result.question, isNotEmpty);
        expect(result.quickOptions, isNotEmpty);
      });

      test('关键词"展开"触发确认', () {
        final result = service.assess('展开');
        expect(result.needsClarification, isTrue);
      });

      test('关键词"详细写"触发确认', () {
        final result = service.assess('详细写');
        expect(result.needsClarification, isTrue);
      });

      test('规则1的quickOptions内容正确', () {
        final result = service.assess('帮我写');
        expect(result.quickOptions, contains('短篇片段'));
        expect(result.quickOptions, contains('完整章节'));
        expect(result.quickOptions, contains('对话场景'));
        expect(result.quickOptions.length, 4);
      });

      test('规则2的quickOptions内容正确', () {
        final result = service.assess('续写');
        expect(result.quickOptions, contains('顺着当前情节'));
        expect(result.quickOptions, contains('引入转折'));
        expect(result.quickOptions, contains('500字左右'));
        expect(result.quickOptions.length, 4);
      });

      test('规则3的quickOptions内容正确', () {
        final result = service.assess('改一下');
        expect(result.quickOptions, contains('更文学'));
        expect(result.quickOptions, contains('更口语'));
        expect(result.quickOptions, contains('更紧凑'));
        expect(result.quickOptions.length, 4);
      });

      test('规则4的quickOptions内容正确', () {
        final result = service.assess('扩写');
        expect(result.quickOptions, contains('角色心理'));
        expect(result.quickOptions, contains('环境描写'));
        expect(result.quickOptions, contains('对话细节'));
        expect(result.quickOptions.length, 4);
      });
    });

    // ── B. 长输入自动跳过 ────────────────────────────

    group('长输入自动跳过', () {
      test('超过50字符的文本自动跳过确认', () {
        // 51 个字符
        const longInput = '这是一段非常长的输入文本，目的是测试当输入超过五十个字符时系统是否会自动跳过确认流程。';
        final result = service.assess(longInput);
        expect(result.needsClarification, isFalse);
      });

      test('包含模糊关键词但超过50字符也跳过', () {
        // 包含"帮我写"但总长度 > 50
        const longWithKeyword =
            '帮我写一篇关于人工智能在医疗领域应用的深度分析报告，需要包含最新的案例研究和未来发展趋势的完整章节内容。';
        final result = service.assess(longWithKeyword);
        expect(result.needsClarification, isFalse);
      });
    });

    // ── C. 无匹配规则的短输入 ────────────────────────

    group('无匹配规则的短输入', () {
      test('普通短句"今天天气不错"通过', () {
        final result = service.assess('今天天气不错');
        expect(result.needsClarification, isFalse);
      });

      test('足够具体的请求通过', () {
        final result = service.assess('请帮我分析这段文字的结构和修辞手法');
        expect(result.needsClarification, isFalse);
      });
    });

    // ── D. 边界情况 ──────────────────────────────────

    group('边界情况', () {
      test('空字符串通过', () {
        final result = service.assess('');
        expect(result.needsClarification, isFalse);
      });

      test('纯空格通过', () {
        final result = service.assess('   ');
        expect(result.needsClarification, isFalse);
      });

      test('刚好50字符的模糊输入触发规则', () {
        // trim 后恰好 50 字符，包含模糊关键词，应该触发
        // 构造：以"帮我写"开头，总长度 = 50
        final input = '帮我写${'一' * 47}'; // 3 + 47 = 50
        expect(input.trim().length, 50);
        final result = service.assess(input);
        expect(result.needsClarification, isTrue);
      });

      test('51字符的模糊输入自动跳过', () {
        final input = '帮我写${'一' * 48}'; // 3 + 48 = 51
        expect(input.trim().length, 51);
        final result = service.assess(input);
        expect(result.needsClarification, isFalse);
      });

      test('前后空格被trim后再判断长度', () {
        // "帮我写" + 47个"一" + 大量空格 → trim 后 = 50，应触发
        final input = '  帮我写${'一' * 47}   ';
        expect(input.trim().length, 50);
        final result = service.assess(input);
        expect(result.needsClarification, isTrue);
      });
    });

    // ── E. "直接生成" 选项 ───────────────────────────

    group('"直接生成"逃生口', () {
      test('规则1包含"直接生成"', () {
        final result = service.assess('帮我写');
        expect(result.quickOptions, contains('直接生成'));
      });

      test('规则2包含"直接生成"', () {
        final result = service.assess('续写');
        expect(result.quickOptions, contains('直接生成'));
      });

      test('规则3包含"直接生成"', () {
        final result = service.assess('改一下');
        expect(result.quickOptions, contains('直接生成'));
      });

      test('规则4包含"直接生成"', () {
        final result = service.assess('扩写');
        expect(result.quickOptions, contains('直接生成'));
      });
    });
  });
}
