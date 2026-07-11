/// 测试: 字数统计工具
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/utils/word_counter.dart';

void main() {
  group('countWords', () {
    test('纯英文字数', () {
      expect(countWords('hello world'), 2);
      expect(countWords('this is a test'), 4);
    });

    test('纯中文字数', () {
      expect(countWords('你好世界'), 4);
      expect(countWords('这是一个测试'), 6);
    });

    test('中英混合', () {
      // hello(1英文词) + 世界(2中文字) = 3
      expect(countWords('hello 世界'), 3);
      // Wait, let me reconsider
    });

    test('中英混合2', () {
      // 'hello世界' → hello(1英文词) + 世界(2中文字) = 3
      final result = countWords('hello世界');
      expect(result, 3);
    });

    test('包含空格和标点', () {
      expect(countWords('  hello  世界 '), 3); // hello(1) + 世界(2)
      final result = countWords('你好，世界！');
      expect(result, 4); // 你/好/世/界
    });

    test('空字符串', () {
      expect(countWords(''), 0);
      expect(countWords('   '), 0);
    });

    test('数字和英文混合', () {
      // 'hello123world' → 1个英文词
      expect(countWords('hello123world'), 1);
      // '第1章' → 第(1) + 1(数字) + 章(1) = 3
      final result = countWords('第1章');
      expect(result, 3);
    });
  });
}