import '../../core/models/novel_structure.dart';
import 'layer1_generator.dart';
import 'layer2_generator.dart';
import 'layer3_generator.dart';

/// 小说生成服务 — 编排三层生成管线
///
/// Layer 1: 创意 → 梗概+人设
/// Layer 2: 梗概 → 卷章细纲
/// Layer 3: 细纲 → 逐场景正文（流式）
class NovelService {
  NovelService({
    Layer1Generator? layer1,
    Layer2Generator? layer2,
    Layer3Generator? layer3,
    String? providerName,
  })  : _layer1 = layer1 ?? Layer1Generator(),
        _layer2 = layer2 ?? Layer2Generator(),
        _layer3 = layer3 ?? Layer3Generator() {
    // 统一设置 Provider
    if (providerName != null) {
      _layer1.providerName = providerName;
      _layer2.providerName = providerName;
      _layer3.providerName = providerName;
    }
  }
  final Layer1Generator _layer1;
  final Layer2Generator _layer2;
  final Layer3Generator _layer3;

  /// 全流程：创意 → 完整小说
  ///
  /// 返回一个 [NovelGenerationResult]，包含生成的三层结构。
  Future<NovelGenerationResult> generateFull({
    required String userIdea,
    String genre = '玄幻',
    String style = 'qidian',
    int numCharacters = 4,
    int numVolumes = 3,
    int chaptersPerVolume = 10,
    int scenesPerChapter = 4,
  }) async {
    // Layer 1
    final layer1 = await _layer1.generate(
      userIdea: userIdea,
      genre: genre,
      style: style,
      numCharacters: numCharacters,
    );

    // Layer 2
    final layer2 = await _layer2.generate(
      synopsis: layer1,
      numVolumes: numVolumes,
      chaptersPerVolume: chaptersPerVolume,
      scenesPerChapter: scenesPerChapter,
    );

    return NovelGenerationResult(
      synopsis: layer1,
      structure: layer2,
    );
  }

  /// 仅生成梗概 (Layer 1)
  Future<SynopsisAndCharacters> generateSynopsis({
    required String userIdea,
    String genre = '玄幻',
    int numCharacters = 4,
  }) {
    return _layer1.generate(
      userIdea: userIdea,
      genre: genre,
      numCharacters: numCharacters,
    );
  }

  /// 仅生成细纲 (Layer 2)
  Future<LayeredNovelStructure> generateOutline({
    required SynopsisAndCharacters synopsis,
    int numVolumes = 3,
    int chaptersPerVolume = 10,
    int scenesPerChapter = 4,
  }) {
    return _layer2.generate(
      synopsis: synopsis,
      numVolumes: numVolumes,
      chaptersPerVolume: chaptersPerVolume,
      scenesPerChapter: scenesPerChapter,
    );
  }

  /// 流式生成章节正文 (Layer 3)
  Stream<String> streamChapter({
    required ChapterOutline chapter,
    required SynopsisAndCharacters synopsis,
  }) {
    return _layer3.generateChapter(
      chapter: chapter,
      synopsis: synopsis,
    );
  }
}

/// 小说生成结果
class NovelGenerationResult {
  const NovelGenerationResult({
    required this.synopsis,
    required this.structure,
  });
  final SynopsisAndCharacters synopsis;
  final LayeredNovelStructure structure;

  int get totalVolumes => structure.volumes.length;
  int get totalChapters =>
      structure.volumes.fold(0, (sum, v) => sum + v.chapters.length);
  int get totalScenes => structure.volumes.fold(
        0,
        (sum, v) => sum + v.chapters.fold(0, (s, c) => s + c.scenes.length),
      );
}
