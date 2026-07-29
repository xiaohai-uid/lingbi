/// ≥1 万字玄幻真实小说验证（免费 API，真实网络）。
///
/// 读环境变量 `SENSENOVA_API_KEY`，无 key 自动 skip。
/// 用 `deepseek-v4-flash` + 玄幻设定，通过 [NovelWritingLoop] 以 autoApprove
/// 连续生成多章，累计直到总中文字数 ≥ 10000，并断言真实落盘与跨章连贯性。
@Tags(['network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/sensenova_provider.dart';
import 'package:lingbi/services/agent/novel_writing_loop.dart';

void main() {
  final apiKey = Platform.environment['SENSENOVA_API_KEY'];
  final skipReason = (apiKey == null || apiKey.isEmpty)
      ? 'SENSENOVA_API_KEY 未设置，跳过真实网络生成测试'
      : null;

  const protagonist = '林尘';
  const cultivationTerm = '玄天诀';
  const realmTerm = '筑基';

  test(
    '用 deepseek-v4-flash 连续生成 ≥10000 中文字的玄幻小说并真实落盘',
    () async {
      final tempDir =
          Directory.systemTemp.createTempSync('lingbi-10k-novel-');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final projectDir = tempDir.path.replaceAll(r'\', '/');

      // 1. 写入玄幻设定（人物库 / 世界观）到维护文档。
      final settingsDir = Directory('$projectDir/小说资料')
        ..createSync(recursive: true);
      File('${settingsDir.path}/人物库.md').writeAsStringSync('''
# 人物库

## 主角
- 姓名：$protagonist
- 身份：青云宗外门弟子
- 性格：隐忍坚韧，遇强则强
- 金手指：体内寄宿上古剑灵，可吞噬灵气淬炼剑体
- 初始境界：$realmTerm 期一层

## 重要配角
- 苏清妩：青云宗内门天才，与林尘亦敌亦友
- 玄阳子：外门执事长老，暗中考验林尘
''');
      File('${settingsDir.path}/世界观.md').writeAsStringSync('''
# 世界观

## 修炼体系
境界由低到高：炼气 → $realmTerm → 金丹 → 元婴 → 化神。
突破需灵气淬体、道心稳固，并渡过心魔劫。

## 核心功法
- $cultivationTerm：主角所修的剑修顶级功法，讲究以剑入道、剑心通明。

## 势力
- 青云宗：正道大宗，主角所在宗门。
- 血魔殿：邪道势力，与青云宗世代为敌。

## 地理
东玄大陆，灵气自东向西递减，秘境多藏于东荒群山。
''');

      final provider = SenseNovaProvider(
        apiKey: apiKey,
        modelOverride: 'deepseek-v4-flash',
      );
      addTearDown(provider.dispose);

      final loop = NovelWritingLoop(
        provider: provider,
        projectDir: projectDir,
        minChineseChars: 1500,
        recentChapterCount: 3,
      );

      final stopwatch = Stopwatch()..start();
      var total = 0;
      final perChapter = <int>[];
      final paths = <String>[];
      const maxChapters = 10;

      for (var i = 0; i < maxChapters && total < 10000; i++) {
        final guidance = i == 0
            ? '开篇：$protagonist 在青云宗外门遭同门排挤，于藏经阁偶得 $cultivationTerm 残卷，剑灵初醒。'
            : '承接前文推进剧情：$protagonist 借 $cultivationTerm 修炼，冲突升级，向 $realmTerm 后期突破。';
        final result = await loop.writeNextChapter(
          guidance: guidance,
          autoApprove: true,
        );

        expect(result, isNotNull, reason: '第 ${i + 1} 章应被 autoApprove 落盘');
        final candidate = result!.candidate;

        // 不得出现请求失败/空正文。
        expect(candidate.isEmpty, isFalse, reason: '第 ${i + 1} 章正文为空');
        for (final w in candidate.warnings) {
          expect(w.contains('请求失败') || w.contains('API Key'), isFalse,
              reason: '第 ${i + 1} 章出现错误：$w');
        }
        expect(candidate.content.contains('请求失败'), isFalse);

        // 章节文件真实落盘。
        expect(File(result.chapterPath).existsSync(), isTrue,
            reason: '章节文件未落盘：${result.chapterPath}');

        total += candidate.chineseCharCount;
        perChapter.add(candidate.chineseCharCount);
        paths.add(result.chapterPath);
      }
      stopwatch.stop();

      // 断言：总字数 ≥ 10000。
      expect(total, greaterThanOrEqualTo(10000),
          reason: '累计中文字数不足 10000：$total（每章：$perChapter）');

      // 连贯性：主角名与修炼术语在多章中一致复现。
      final protagonistChapters = paths
          .where((p) => File(p).readAsStringSync().contains(protagonist))
          .length;
      expect(protagonistChapters, greaterThanOrEqualTo(2),
          reason: '主角名「$protagonist」跨章复现不足');

      final allText = paths.map((p) => File(p).readAsStringSync()).join('\n');
      expect(
        allText.contains(cultivationTerm) || allText.contains(realmTerm),
        isTrue,
        reason: '修炼体系术语未在正文中出现，连贯性不足',
      );

      // 章节摘要文件应生成，供下一章上下文。
      expect(File('$projectDir/小说资料/章节摘要.md').existsSync(), isTrue);

      // 证据打印。
      // ignore: avoid_print
      print('=== 10K 玄幻小说生成证据 ===');
      // ignore: avoid_print
      print('模型: deepseek-v4-flash');
      // ignore: avoid_print
      print('章节数: ${perChapter.length}，每章中文字数: $perChapter');
      // ignore: avoid_print
      print('总中文字数: $total');
      // ignore: avoid_print
      print('总耗时: ${stopwatch.elapsed.inSeconds}s');
      // ignore: avoid_print
      print('落盘路径:\n${paths.join('\n')}');
    },
    timeout: const Timeout(Duration(minutes: 15)),
    skip: skipReason,
  );
}
