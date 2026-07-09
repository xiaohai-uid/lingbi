import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/novel_structure.dart';

void main() {
  group('CharacterProfile', () {
    test('creates with all fields', () {
      const profile = CharacterProfile(
        name: '张三',
        role: '主角',
        age: 25,
        personality: '坚毅果断',
        backstory: '出身寒门，历经磨难',
        motivation: '为父报仇，振兴家族',
        arc: '从懦弱到坚强',
      );
      expect(profile.name, '张三');
      expect(profile.age, 25);
    });

    test('serializes to/from JSON', () {
      const profile = CharacterProfile(
        name: '李四',
        role: '反派',
        personality: '阴险狡诈',
      );
      final json = profile.toJson();
      expect(json['name'], '李四');
      expect(json['role'], '反派');
      final restored = CharacterProfile.fromJson(json);
      expect(restored.name, '李四');
      expect(restored.personality, '阴险狡诈');
    });
  });

  group('SynopsisAndCharacters', () {
    test('creates and serializes', () {
      const data = SynopsisAndCharacters(
        synopsis: '这是一个关于复仇的故事...',
        setting: '古代江湖',
        themes: ['复仇', '成长', '友情'],
        characters: [CharacterProfile(name: '主角', role: '主角')],
      );
      final json = data.toJson();
      expect(json['synopsis'], contains('复仇'));
      expect(json['setting'], '古代江湖');
      expect((json['themes'] as List).length, 3);
      final restored = SynopsisAndCharacters.fromJson(json);
      expect(restored.characters.length, 1);
    });
  });

  group('SceneOutline', () {
    test('creates with default sceneNumber', () {
      const scene = SceneOutline(
        title: '初遇',
        summary: '两人在集市相遇',
        characters: ['主角', '配角'],
        location: '长安集市',
      );
      expect(scene.sceneNumber, 0);
      expect(scene.title, '初遇');
    });

    test('serializes to/from JSON', () {
      const scene = SceneOutline(
        sceneNumber: 2,
        title: '决战',
        summary: '最终对决',
        characters: ['主角', '反派'],
        location: '华山之巅',
        mood: '紧张',
      );
      final json = scene.toJson();
      expect(json['sceneNumber'], 2);
      expect(json['location'], '华山之巅');
      final restored = SceneOutline.fromJson(json);
      expect(restored.mood, '紧张');
    });
  });

  group('ChapterOutline', () {
    test('creates with scenes', () {
      const chapter = ChapterOutline(
        title: '第一章',
        summary: '故事开端',
        scenes: [
          SceneOutline(
              title: '初遇', summary: '相遇', characters: [], location: '京城')
        ],
      );
      expect(chapter.scenes.length, 1);
    });

    test('serializes', () {
      const chapter = ChapterOutline(
        chapterNumber: 1,
        title: '风云再起',
        summary: '主角卷入阴谋',
        hook: '神秘信件出现',
        scenes: [
          SceneOutline(
              title: '来信',
              summary: '收到神秘信件',
              characters: ['主角'],
              location: '家中')
        ],
      );
      final json = chapter.toJson();
      expect(json['chapterNumber'], 1);
      expect(json['hook'], '神秘信件出现');
      final restored = ChapterOutline.fromJson(json);
      expect(restored.scenes.length, 1);
    });
  });

  group('VolumeOutline', () {
    test('serializes with chapters', () {
      const volume = VolumeOutline(
        volumeNumber: 1,
        title: '风起',
        summary: '一切的开始',
        chapters: [
          ChapterOutline(chapterNumber: 1, title: '启程', summary: '出发'),
          ChapterOutline(chapterNumber: 2, title: '遭遇', summary: '遇到危险'),
        ],
      );
      final json = volume.toJson();
      expect((json['chapters'] as List).length, 2);
      final restored = VolumeOutline.fromJson(json);
      expect(restored.chapters[1].title, '遭遇');
    });
  });

  group('LayeredNovelStructure', () {
    test('serializes complete structure', () {
      const structure = LayeredNovelStructure(volumes: [
        VolumeOutline(volumeNumber: 1, title: '第一卷', summary: '开端', chapters: [
          ChapterOutline(
              chapterNumber: 1,
              title: '第一章',
              summary: '故事开始',
              scenes: [
                SceneOutline(
                    sceneNumber: 1,
                    title: '场景一',
                    summary: '开场',
                    characters: [],
                    location: '京城'),
              ]),
        ]),
      ]);
      final json = structure.toJson();
      expect((json['volumes'] as List).length, 1);
      final restored = LayeredNovelStructure.fromJson(json);
      expect(restored.volumes.first.chapters.first.scenes.first.title, '场景一');
    });
  });
}
