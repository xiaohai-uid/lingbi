import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/context/writing_context.dart';
import 'package:lingbi/services/context/resolver_cache.dart';
import 'package:lingbi/services/context/context_injector.dart';
import 'package:lingbi/data/database/world_database.dart';

// Helper: create a minimal Scene
Scene _testScene({String id = 's1', String title = '测试场景'}) {
  return Scene(
    id: id,
    chapterId: 'ch1',
    sceneNumber: 1,
    title: title,
    outlineDescription: '场景描述',
    locationId: '',
    timelineEventId: '',
    documentId: 'doc1',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

// Helper: create a minimal Location
Location _testLocation({String id = 'loc1', String name = '青云宗'}) {
  return Location(
    id: id,
    worldId: 'w1',
    name: name,
    description: '修仙门派',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

// Helper: create a minimal Character
Character _testChar({String id = 'c1', String name = '林月', int w = 50}) {
  return Character(
    id: id,
    worldId: 'w1',
    name: name,
    description: '',
    role: '主角',
    personality: '温柔',
    backstory: '',
    motivation: '',
    arc: '',
    baseWeight: w,
    tempWeight: 0,
    currentStatus: '',
    currentLocationId: '',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

void main() {
  // ========== WritingContext ==========
  group('WritingContext', () {
    test('topCharacters 返回权重最高的N个', () {
      final ctx = WritingContext(
        scene: _testScene(),
        chapterTitle: '第一章',
        volumeTitle: '第一卷',
        characters: [
          ScopedCharacter(
              character: _testChar(name: '主角', w: 80), effectiveWeight: 80),
          ScopedCharacter(
              character: _testChar(id: 'c2', name: '配角'), effectiveWeight: 50),
          ScopedCharacter(
              character: _testChar(id: 'c3', name: '路人', w: 20),
              effectiveWeight: 20),
        ],
      );
      expect(ctx.topCharacters(2).length, 2);
      expect(ctx.topCharacters(2).first.effectiveWeight, 80);
      expect(ctx.topCharacters(2).last.effectiveWeight, 50);
    });

    test('topCharacters N大于总数时返回全部', () {
      final ctx = WritingContext(
          scene: _testScene(),
          chapterTitle: '章',
          volumeTitle: '卷',
          characters: [
            ScopedCharacter(character: _testChar(), effectiveWeight: 50)
          ]);
      expect(ctx.topCharacters(10).length, 1);
    });
  });

  // ========== ResolverCache ==========
  group('ResolverCache', () {
    late ResolverCache c;
    setUp(() {
      c = ResolverCache(maxSize: 3);
    });
    final ctx = WritingContext(
        scene: _testScene(), chapterTitle: '章', volumeTitle: '卷');

    test('set/get', () {
      c.set('w1', 'v1', 'ch1', ctx);
      expect(c.get('w1', 'v1', 'ch1'), isNotNull);
    });

    test('未命中返回null', () {
      expect(c.get('w1', 'v1', 'none'), isNull);
    });

    test('invalidate', () {
      c.set('w1', 'v1', 'ch1', ctx);
      c.invalidate('w1', 'v1', 'ch1');
      expect(c.get('w1', 'v1', 'ch1'), isNull);
    });

    test('clear', () {
      c.set('w1', 'v1', 'ch1', ctx);
      c.clear();
      expect(c.size, 0);
    });

    test('LRU淘汰', () {
      for (int i = 1; i <= 3; i++) {
        c.set('w$i', 'v', 'ch', ctx);
      }
      c.get('w1', 'v', 'ch'); // access w1
      c.set('w4', 'v', 'ch', ctx); // should evict w2
      expect(c.get('w1', 'v', 'ch'), isNotNull);
      expect(c.get('w2', 'v', 'ch'), isNull);
    });
  });

  // ========== ContextInjector ==========
  group('ContextInjector', () {
    test('buildWritingPrompt 包含4层结构', () {
      final loc = _testLocation();
      final ch = _testChar();
      final ctx = WritingContext(
        scene: _testScene(),
        chapterTitle: '第一章',
        volumeTitle: '第一卷',
        location: loc,
        characters: [ScopedCharacter(character: ch, effectiveWeight: 50)],
        recentEvents: [
          TimelineEvent(
              id: 'e1',
              worldId: 'w1',
              title: '事件',
              description: '描述',
              orderKey: 'a',
              inStoryDate: '',
              inStoryDay: 0,
              duration: '',
              chapterAnchor: '',
              branchId: '',
              parentEventId: '',
              createdAt: DateTime(2025))
        ],
      );
      final injector = ContextInjector();
      final prompt = injector.buildWritingPrompt(context: ctx, userInput: '续写');

      expect(prompt, contains('当前场景'));
      expect(prompt, contains('出场角色'));
      expect(prompt, contains('时间线上下文'));
      expect(prompt, contains('用户指令'));
      expect(prompt, contains('续写'));
      expect(prompt, contains('青云宗'));
      expect(prompt, contains('林月'));
    });

    test('无规则和事件时跳过对应层', () {
      final ctx = WritingContext(
          scene: _testScene(),
          chapterTitle: '章',
          volumeTitle: '卷',
          characters: [
            ScopedCharacter(character: _testChar(), effectiveWeight: 50)
          ]);
      final injector = ContextInjector();
      final prompt = injector.buildWritingPrompt(context: ctx);
      expect(prompt, contains('当前场景'));
      expect(prompt, contains('出场角色'));
      expect(prompt, isNot(contains('世界观规则')));
    });

    test('estimateTokens 估算逻辑', () {
      final injector = ContextInjector();
      expect(injector.estimateTokens('你好世界'), 1); // 4 chars → 1 token
      expect(injector.estimateTokens('你好世界你好世界你好世界'), 3); // 12 chars → 3
      expect(injector.estimateTokens(''), 0);
    });

    test('buildWritingPrompt 不含用户输入时跳过指令层', () {
      final ctx = WritingContext(
          scene: _testScene(),
          chapterTitle: '章',
          volumeTitle: '卷',
          characters: [
            ScopedCharacter(character: _testChar(), effectiveWeight: 50)
          ]);
      final prompt = ContextInjector().buildWritingPrompt(context: ctx);
      expect(prompt, isNot(contains('用户指令')));
    });
  });

  // ========== TokenCounter ==========
  group('TokenCounter', () {
    test('estimate 计算', () {
      expect(TokenCounter.estimate('你好世界'), 1);
      expect(TokenCounter.estimate(''), 0);
    });

    test('estimateCost 计算费用', () {
      expect(TokenCounter.estimateCost(tokens: 1000, pricePer1M: 8),
          closeTo(0.008, 0.0001));
      expect(TokenCounter.estimateCost(tokens: 0, pricePer1M: 8), 0);
    });

    test('formatCost 格式化', () {
      expect(TokenCounter.formatCost(0.001), '¥0.0010');
      expect(TokenCounter.formatCost(0.5), '¥0.500');
      expect(TokenCounter.formatCost(12.34), '¥12.34');
    });
  });

  // ========== ScopedCharacter ==========
  group('ScopedCharacter', () {
    test('创建和字段访问', () {
      final ch = _testChar();
      final sc = ScopedCharacter(character: ch, effectiveWeight: 80);
      expect(sc.character.name, '林月');
      expect(sc.effectiveWeight, 80);
      expect(sc.activeIdentities, isEmpty);
      expect(sc.primaryIdentity, isNull);
    });
  });
}
