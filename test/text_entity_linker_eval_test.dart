import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/modules/story_graph/story_graph.dart';
import 'package:lingbi/modules/story_graph/text_entity_linker.dart';

void main() {
  const entities = [
    StoryEntity(
      id: 'character:ye-lan',
      type: StoryEntityType.character,
      canonicalName: '叶澜',
      aliases: ['阿澜', '小叶'],
    ),
    StoryEntity(
      id: 'character:gu-chen',
      type: StoryEntityType.character,
      canonicalName: '顾尘',
      aliases: ['顾先生'],
    ),
    StoryEntity(
      id: 'location:qing-wu',
      type: StoryEntityType.location,
      canonicalName: '青梧城',
      aliases: ['青梧'],
    ),
    StoryEntity(
      id: 'faction:night-watch',
      type: StoryEntityType.faction,
      canonicalName: '巡夜司',
      aliases: ['夜司'],
    ),
  ];

  test('links canonical names and aliases with exact evidence ranges', () {
    const text = '阿澜回到青梧城，顾先生已在巡夜司门前等她。';
    final mentions = const TextEntityLinker().link(text, entities);

    expect(
      mentions
          .map((mention) => (
                mention.entityId,
                mention.matchedText,
                mention.range.start,
                mention.range.end,
              ))
          .toList(),
      [
        ('character:ye-lan', '阿澜', 0, 2),
        ('location:qing-wu', '青梧城', 4, 7),
        ('character:gu-chen', '顾先生', 8, 11),
        ('faction:night-watch', '巡夜司', 13, 16),
      ],
    );
  });

  test('longest alias wins and duplicate aliases do not create overlaps', () {
    const overlapping = [
      StoryEntity(
        id: 'location:city',
        type: StoryEntityType.location,
        canonicalName: '青梧城',
        aliases: ['青梧'],
      ),
      StoryEntity(
        id: 'location:mountain',
        type: StoryEntityType.location,
        canonicalName: '青梧山',
        aliases: ['青梧'],
      ),
    ];

    final mentions = const TextEntityLinker().link('青梧城外落雨。', overlapping);

    expect(mentions, hasLength(1));
    expect(mentions.single.entityId, 'location:city');
    expect(mentions.single.matchedText, '青梧城');
  });

  test('checked-in synthetic Chinese fiction corpus reaches F1 >= 0.90', () {
    // 合法合成语料；gold 是人工标注的 (文档序号, 实体 ID, 起止 UTF-16 偏移)。
    const corpus = [
      '叶澜第一次踏进青梧城，便被巡夜司拦下。',
      '入夜后，阿澜跟着顾尘去了青梧山。',
      '顾先生告诉小叶：夜司并不信任外乡人。',
      '青梧城钟声响起时，叶澜与顾尘同时回头。',
      '山雨封路，巡夜司只得暂守青梧。',
    ];
    const gold = <(int, String, int, int)>{
      (0, 'character:ye-lan', 0, 2),
      (0, 'location:qing-wu', 7, 10),
      (0, 'faction:night-watch', 13, 16),
      (1, 'character:ye-lan', 4, 6),
      (1, 'character:gu-chen', 8, 10),
      (1, 'location:qing-wu', 12, 15),
      (2, 'character:gu-chen', 0, 3),
      (2, 'character:ye-lan', 5, 7),
      (2, 'faction:night-watch', 8, 10),
      (3, 'location:qing-wu', 0, 3),
      (3, 'character:ye-lan', 9, 11),
      (3, 'character:gu-chen', 12, 14),
      (4, 'faction:night-watch', 5, 8),
      (4, 'location:qing-wu', 12, 14),
    };
    final predicted = <(int, String, int, int)>{};
    for (var documentIndex = 0;
        documentIndex < corpus.length;
        documentIndex++) {
      for (final mention
          in const TextEntityLinker().link(corpus[documentIndex], entities)) {
        predicted.add((
          documentIndex,
          mention.entityId,
          mention.range.start,
          mention.range.end,
        ));
      }
    }

    final truePositives = predicted.intersection(gold).length;
    final precision = truePositives / predicted.length;
    final recall = truePositives / gold.length;
    final f1 = 2 * precision * recall / (precision + recall);

    expect(f1, greaterThanOrEqualTo(0.90), reason: 'F1=$f1');
  });
}
