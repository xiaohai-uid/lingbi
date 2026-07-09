/// ContextResolver — 上下文解析器
///
/// 根据当前写作位置，收集并组装完整的写作上下文。
library context_resolver;

import 'writing_context.dart';
import 'resolver_cache.dart';
import '../../data/database/world_database.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/scene_repository.dart';
import '../../data/repositories/timeline_repository.dart';
import '../identity/identity_detector.dart';
import 'package:drift/drift.dart';

/// 上下文解析器
class ContextResolver {
  ContextResolver({
    required this.db,
    required this.characterRepo,
    required this.sceneRepo,
    required this.timelineRepo,
    IdentityDetector? identityDetector,
    ResolverCache? cache,
  })  : identityDetector = identityDetector ?? IdentityDetector(),
        cache = cache ?? ResolverCache();
  final WorldDatabase db;
  final CharacterRepository characterRepo;
  final SceneRepository sceneRepo;
  final TimelineRepository timelineRepo;
  final IdentityDetector identityDetector;
  final ResolverCache cache;

  /// 解析写作上下文
  Future<WritingContext> resolve({
    required String workId,
    required String volumeId,
    required String chapterId,
  }) async {
    // 1. 检查缓存
    final cached = cache.get(workId, volumeId, chapterId);
    if (cached != null) return cached;

    // 2. 查询章节信息
    final chapters = await (db.select(db.chapters)
          ..where((t) => t.id.equals(chapterId)))
        .get();
    if (chapters.isEmpty) {
      throw Exception('Chapter not found: $chapterId');
    }
    final chapter = chapters.first;

    // 3. 查询卷信息
    final volumes = await (db.select(db.volumes)
          ..where((t) => t.id.equals(volumeId)))
        .get();
    final volumeTitle = volumes.isNotEmpty ? volumes.first.title : '';

    // 4. 查询所有场景
    final scenes = await sceneRepo.getScenesForChapter(chapterId);
    if (scenes.isEmpty) {
      throw Exception('No scenes found for chapter: $chapterId');
    }
    final scene = scenes.first;

    // 5. 解析场景上下文
    final sceneContext = await sceneRepo.getSceneContext(scene.id);

    // 6. 查询时间线
    final works =
        await (db.select(db.works)..where((t) => t.id.equals(workId))).get();
    if (works.isEmpty) throw Exception('Work not found: $workId');
    final worldId = works.first.worldId;

    final recentEvents = await timelineRepo.getRecentEvents(worldId);

    // 7. 查询角色（按权重排序）
    final allCharacters = await (db.select(db.characters)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.baseWeight, mode: OrderingMode.desc)
          ])
          ..limit(20))
        .get();

    // 计算有效权重并构建 ScopedCharacter
    final scopedCharacters = <ScopedCharacter>[];
    for (final char in allCharacters) {
      final effectiveWeight =
          await characterRepo.getEffectiveWeight(char.id, volumeId: volumeId);
      final identities = await characterRepo.getIdentities(char.id);
      scopedCharacters.add(ScopedCharacter(
        character: char,
        effectiveWeight: effectiveWeight,
        activeIdentities: identities,
        primaryIdentity: identities.isNotEmpty ? identities.first : null,
      ));
    }

    // 按有效权重排序
    scopedCharacters
        .sort((a, b) => b.effectiveWeight.compareTo(a.effectiveWeight));

    // 8. 身份识别
    if (sceneContext != null) {
      final content = await sceneRepo.getDocumentContent(scene.documentId);
      if (content != null && content.isNotEmpty) {
        await identityDetector.detect(
          sceneText: content,
          sceneCharacters: allCharacters,
          sceneId: scene.id,
          volumeId: volumeId,
        );
      }
    }

    // 9. 构建 WritingContext
    final context = WritingContext(
      scene: scene,
      chapterTitle: chapter.title,
      volumeTitle: volumeTitle,
      location: sceneContext?.location,
      characters: scopedCharacters,
      relevantRules: [], // 规则查询可选
      recentEvents: recentEvents,
    );

    // 10. 写入缓存
    cache.set(workId, volumeId, chapterId, context);

    return context;
  }

  /// 清除缓存（用户编辑后调用）
  void invalidateCache(String workId, String volumeId, String chapterId) {
    cache.invalidate(workId, volumeId, chapterId);
  }
}
