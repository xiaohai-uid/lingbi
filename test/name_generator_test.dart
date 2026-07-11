/// 测试: NameGenerator — AI 取名功能
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/generation/name_generator.dart';

void main() {
  group('NameGenerator', () {
    test('buildPrompt 包含类型、风格和分类要求', () {
      final prompt = NameGenerator.buildPrompt(
          genre: '玄幻', style: '起点爆款');

      expect(prompt, contains('玄幻'), reason: 'prompt 应包含类型');
      expect(prompt, contains('起点爆款'), reason: 'prompt 应包含风格');
      expect(prompt, contains('角色名'), reason: '应有角色名分类');
      expect(prompt, contains('地名'), reason: '应有地名分类');
      expect(prompt, contains('功法'), reason: '应有功法/招式分类');
      expect(prompt, contains('10'), reason: '应要求至少10个');
    });

    test('parseNames 解析正确的格式', () {
      const text = '【角色名】\n'
          '1. 林北辰 - 主角，天资聪颖\n'
          '2. 萧云 - 配角，性格豪爽\n'
          '【地名】\n'
          '1. 天元大陆 - 故事主要发生地\n'
          '【功法】\n'
          '1. 九天玄功 - 上古功法\n';

      final result = NameGenerator.parseNames(text);

      expect(result['角色名'], hasLength(2));
      expect(result['角色名']![0], '林北辰 - 主角，天资聪颖');
      expect(result['地名'], hasLength(1));
      expect(result['地名']![0], '天元大陆 - 故事主要发生地');
      expect(result['功法'], hasLength(1));
      expect(result['功法']![0], '九天玄功 - 上古功法');
    });

    test('parseNames 处理空输入', () {
      final result = NameGenerator.parseNames('');
      expect(result, isEmpty);
    });

    test('parseNames 处理没有分类标记的文本', () {
      final result = NameGenerator.parseNames('一些随机文本\n没有分类格式');
      expect(result, isEmpty);
    });
  });
}