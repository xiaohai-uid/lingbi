import 'package:lingbi/core/models/story_beat.dart';
import 'package:lingbi/services/storage_service.dart';

/// 故事节拍存储仓库 — 基于 StorageService (JSON 文件)
class StoryBeatsRepository {
  final StorageService _storage;
  static const _collection = 'story_beats';

  StoryBeatsRepository({required StorageService storageService})
      : _storage = storageService;

  /// 获取项目所有节拍，按 sequence 排序
  Future<List<StoryBeat>> getBeats(String projectId) async {
    final results = await _storage.query(_collection, filter: {'projectId': projectId});
    final beats = results.map((json) => StoryBeat.fromJson(json)).toList();
    beats.sort((a, b) => a.sequence.compareTo(b.sequence));
    return beats;
  }

  /// 保存节拍（创建或更新）
  Future<void> saveBeat(StoryBeat beat) async {
    await _storage.upsert(_collection, beat.id, beat.toJson());
  }

  /// 删除节拍
  Future<void> deleteBeat(String beatId) async {
    await _storage.delete(_collection, beatId);
  }

  /// 重排节拍顺序
  Future<void> reorderBeats(String projectId, List<String> beatIds) async {
    for (var i = 0; i < beatIds.length; i++) {
      final beat = await _storage.get(_collection, beatIds[i]);
      if (beat != null) {
        beat['sequence'] = i;
        await _storage.upsert(_collection, beatIds[i], beat);
      }
    }
  }
}