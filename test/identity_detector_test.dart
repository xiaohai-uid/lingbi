import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/identity/identity_rules.dart';
import 'package:lingbi/services/identity/rule_matcher.dart';
import 'package:lingbi/services/identity/detector_cache.dart';
import 'package:lingbi/services/identity/identity_detector.dart';
import 'package:lingbi/data/database/world_database.dart' show Character;

Character _testChar({String id = 'char-1', String name = '林月', int w = 50}) {
  return Character(
      id: id,
      worldId: 'w-1',
      name: name,
      description: '',
      role: '主角',
      personality: '',
      backstory: '',
      motivation: '',
      arc: '',
      baseWeight: w,
      tempWeight: 0,
      currentStatus: '',
      currentLocationId: '',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025));
}

void main() {
  // ========== RuleMatcher ==========
  group('RuleMatcher', () {
    late RuleMatcher m;
    setUp(() {
      m = RuleMatcher();
    });

    test('称呼匹配成功', () {
      final r = m.match(
          text: '林月师妹好',
          sceneCharacterIds: ['c1'],
          characterNameMap: {'c1': '林月'});
      expect(r, isNotEmpty);
      expect(r.first.identityName, '师妹');
    });

    test('无匹配返回空', () {
      expect(
          m.match(
              text: '天气不错',
              sceneCharacterIds: ['c1'],
              characterNameMap: {'c1': '林月'}),
          isEmpty);
    });

    test('多规则同时匹配', () {
      final r = m.match(
          text: '青云真人师尊在上，林月师妹也在',
          sceneCharacterIds: ['c1', 'c2'],
          characterNameMap: {'c1': '青云真人', 'c2': '林月'});
      expect(r.length, 2);
      expect(r.map((e) => e.identityName).toSet(), contains('师父/师尊'));
      expect(r.map((e) => e.identityName).toSet(), contains('师妹'));
    });

    test('空文本返回空', () {
      expect(m.match(text: '', sceneCharacterIds: ['c1']), isEmpty);
    });

    test('空角色列表返回空', () {
      expect(m.match(text: '师妹今天', sceneCharacterIds: []), isEmpty);
    });

    test('角色名+称呼模式', () {
      final r = m.match(
          text: '林月师妹修为精进',
          sceneCharacterIds: ['c1'],
          characterNameMap: {'c1': '林月'});
      expect(r, isNotEmpty);
    });

    test('去重', () {
      final r = m.match(
          text: '掌门在上掌门明鉴掌门英明',
          sceneCharacterIds: ['c1'],
          characterNameMap: {'c1': '青云真人'});
      expect(r.where((e) => e.identityName == '掌门/宗主'), hasLength(1));
    });

    test('直接称呼-行首', () {
      expect(
          m.match(
              text: '掌门！今日',
              sceneCharacterIds: ['c1'],
              characterNameMap: {'c1': '青云真人'}),
          isNotEmpty);
    });

    test('直接称呼-句号后', () {
      expect(
          m.match(
              text: '来了。掌门！',
              sceneCharacterIds: ['c1'],
              characterNameMap: {'c1': '青云真人'}),
          isNotEmpty);
    });

    test('句中无角色名前缀不匹配', () {
      expect(
          m.match(
              text: '参见掌门大人',
              sceneCharacterIds: ['c1'],
              characterNameMap: {'c1': '青云真人'}),
          isEmpty);
    });
  });

  // ========== DetectorCache ==========
  group('DetectorCache', () {
    late DetectorCache c;
    const r = DetectionResult(
        sceneId: 's1',
        candidates: [
          IdentityCandidate(
              characterId: 'c1',
              identityName: '师妹',
              confidence: 0.9,
              source: 'rule:师妹')
        ],
        source: 'rule');

    setUp(() {
      c = DetectorCache(maxSize: 3);
    });

    test('set/get', () {
      c.set('s1', r);
      expect(c.get('s1'), isNotNull);
    });

    test('未命中返回null', () {
      expect(c.get('none'), isNull);
    });

    test('LRU淘汰', () {
      c.set('s1', r);
      c.set('s2', const DetectionResult(sceneId: 's2'));
      c.set('s3', const DetectionResult(sceneId: 's3'));
      c.get('s1');
      c.set('s4', const DetectionResult(sceneId: 's4'));
      expect(c.get('s1'), isNotNull);
      expect(c.get('s2'), isNull);
    });

    test('invalidate', () {
      c.set('s1', r);
      c.invalidate('s1');
      expect(c.get('s1'), isNull);
    });

    test('clear', () {
      c.set('s1', r);
      c.clear();
      expect(c.size, 0);
    });
  });

  // ========== IdentityDetector ==========
  group('IdentityDetector', () {
    late IdentityDetector d;
    final c1 = _testChar(id: 'c1', name: '青云真人');
    final c2 = _testChar(id: 'c2');

    setUp(() {
      d = IdentityDetector();
    });

    test('缓存命中直接返回', () async {
      await d.detect(
          sceneText: '掌门在上',
          sceneCharacters: [c1, c2],
          sceneId: 's1',
          volumeId: 'v1');
      final r2 = await d.detect(
          sceneText: '掌门在上',
          sceneCharacters: [c1, c2],
          sceneId: 's1',
          volumeId: 'v1');
      expect(r2.hasResults, isTrue);
    });

    test('不同sceneId独立计算', () async {
      final a = await d.detect(
          sceneText: '掌门',
          sceneCharacters: [c1, c2],
          sceneId: 'a',
          volumeId: 'v1');
      final b = await d.detect(
          sceneText: '师尊',
          sceneCharacters: [c1, c2],
          sceneId: 'b',
          volumeId: 'v1');
      expect(a.sceneId, 'a');
      expect(b.candidates.first.identityName, '师父/师尊');
    });

    test('完整匹配流程', () async {
      final r = await d.detect(
          sceneText: '师妹修为大进，师尊欣慰',
          sceneCharacters: [c1, c2],
          sceneId: 's2',
          volumeId: 'v1');
      expect(r.hasResults, isTrue);
      expect(r.source, 'rule');
    });

    test('无称呼返回空', () async {
      final r = await d.detect(
          sceneText: '今天天气不错',
          sceneCharacters: [c1, c2],
          sceneId: 's3',
          volumeId: 'v1');
      expect(r.hasResults, isFalse);
    });

    test('空角色返回空', () async {
      final r = await d.detect(
          sceneText: '掌门驾到',
          sceneCharacters: [],
          sceneId: 's4',
          volumeId: 'v1');
      expect(r.hasResults, isFalse);
    });

    test('invalidateScene', () async {
      await d.detect(
          sceneText: '掌门',
          sceneCharacters: [c1, c2],
          sceneId: 's5',
          volumeId: 'v1');
      d.invalidateScene('s5');
      final r = await d.detect(
          sceneText: '掌门',
          sceneCharacters: [c1, c2],
          sceneId: 's5',
          volumeId: 'v1');
      expect(r.hasResults, isTrue);
    });

    test('LLM兜底默认关闭', () async {
      final r = await d.detect(
          sceneText: '今天天气不错',
          sceneCharacters: [c1, c2],
          sceneId: 's6',
          volumeId: 'v1');
      expect(r.hasResults, isFalse);
      expect(r.source, 'none');
    });
  });

  group('DetectionResult', () {
    test('hasResults为true当candidates非空', () {
      expect(
          const DetectionResult(
                  sceneId: 's',
                  candidates: [
                    IdentityCandidate(
                        characterId: 'c',
                        identityName: '掌门',
                        confidence: 0.9,
                        source: 'r')
                  ],
                  source: 'r')
              .hasResults,
          isTrue);
    });
    test('newIdentities返回candidates', () {
      const r = DetectionResult(
          sceneId: 's',
          candidates: [
            IdentityCandidate(
                characterId: 'c',
                identityName: '掌门',
                confidence: 0.9,
                source: 'r')
          ],
          source: 'r');
      expect(r.newIdentities, r.candidates);
    });
  });
}
