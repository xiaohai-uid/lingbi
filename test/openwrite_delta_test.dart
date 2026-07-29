/// 对标 OpenWrite 补齐项的单元测试（无网络、可离线运行）：
///   1. DOCX 导出产物可被 `archive` 解回且含正文；
///   2. 写作循环在候选未确认时不写盘、确认（autoApprove）后原子写盘；
///   3. ContextCompiler 接线后 mandatory 项不被预算挤掉。
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/modules/context/context_compiler.dart';
import 'package:lingbi/services/agent/novel_writing_loop.dart';
import 'package:lingbi/services/export_service.dart';

/// 返回固定正文的假 Provider（复现足量中文字，供离线测试写作循环）。
class _FakeProvider extends AIProvider {
  _FakeProvider(this.reply);

  final String reply;

  @override
  String get name => 'fake';
  @override
  String get displayName => 'Fake';
  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield reply;
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      reply;

  @override
  Future<List<double>> embed(String text) async => const [];

  @override
  Future<void> dispose() async {}
}

void main() {
  group('DOCX 导出', () {
    test('产物为合法 OOXML zip 且 word/document.xml 含正文', () async {
      final tempDir = Directory.systemTemp.createTempSync('lingbi-docx-');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final savePath = '${tempDir.path}/out.docx';

      final service = ExportService();
      await service.exportAsDocx(
        title: '测试书名',
        content: '# 第1章 觉醒\n\n林尘睁开双眼，灵气涌入丹田。\n\n他知道，命运自此改变。',
        savePath: savePath,
      );

      final bytes = File(savePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toSet();
      // 必备 OOXML 部件齐全。
      expect(
          names,
          containsAll(<String>[
            '[Content_Types].xml',
            '_rels/.rels',
            'word/document.xml',
            'word/_rels/document.xml.rels',
          ]));

      final doc = archive.findFile('word/document.xml')!;
      final xml = utf8.decode(doc.content as List<int>);
      expect(xml, contains('测试书名'));
      expect(xml, contains('林尘睁开双眼'));
      expect(xml, contains('觉醒'));
    });
  });

  group('NovelWritingLoop 候选与落盘', () {
    late Directory tempDir;
    late String projectDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lingbi-loop-');
      projectDir = tempDir.path.replaceAll(r'\', '/');
      Directory('$projectDir/小说资料').createSync(recursive: true);
      File('$projectDir/小说资料/人物库.md').writeAsStringSync('# 人物库\n- 主角：林尘');
      File('$projectDir/小说资料/世界观.md').writeAsStringSync('# 世界观\n修炼体系：炼气→筑基');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    NovelWritingLoop buildLoop() {
      final body = '# 第1章 起势\n\n${'林尘运转玄天诀，灵气如潮涌入四肢百骸。' * 30}';
      return NovelWritingLoop(
        provider: _FakeProvider(body),
        projectDir: projectDir,
        minChineseChars: 100,
      );
    }

    test('proposeNextChapter 生成候选但不写盘', () async {
      final loop = buildLoop();
      final candidate = await loop.proposeNextChapter(guidance: '开篇');

      expect(candidate.isEmpty, isFalse);
      expect(candidate.chapterNumber, 1);
      expect(candidate.chineseCharCount, greaterThan(100));
      // 未确认：章节文件与摘要都不应存在。
      expect(File('$projectDir/章节内容/第1章.md').existsSync(), isFalse);
      expect(File('$projectDir/小说资料/章节摘要.md').existsSync(), isFalse);
    });

    test('writeNextChapter 未确认（无 confirm/autoApprove）不写盘并返回 null', () async {
      final loop = buildLoop();
      final result = await loop.writeNextChapter(guidance: '开篇');

      expect(result, isNull);
      expect(File('$projectDir/章节内容/第1章.md').existsSync(), isFalse);
    });

    test('writeNextChapter 拒绝（confirm=false）不写盘', () async {
      final loop = buildLoop();
      final result = await loop.writeNextChapter(
        guidance: '开篇',
        confirm: (_) async => false,
      );

      expect(result, isNull);
      expect(File('$projectDir/章节内容/第1章.md').existsSync(), isFalse);
    });

    test('writeNextChapter autoApprove 原子写盘并更新摘要', () async {
      final loop = buildLoop();
      final result = await loop.writeNextChapter(
        guidance: '开篇',
        autoApprove: true,
      );

      expect(result, isNotNull);
      final chapterFile = File(result!.chapterPath);
      expect(chapterFile.existsSync(), isTrue);
      final written = chapterFile.readAsStringSync();
      expect(written, contains('林尘运转玄天诀'));
      // 摘要更新，供下一章上下文。
      final summary = File(result.summaryPath);
      expect(summary.existsSync(), isTrue);
      expect(summary.readAsStringSync(), contains('第1章'));
    });

    test('provider error text is never auto-approved as chapter content',
        () async {
      final loop = NovelWritingLoop(
        provider: _FakeProvider('请求过于频繁，请稍后再试'),
        projectDir: projectDir,
        minChineseChars: 100,
      );

      final candidate = await loop.proposeNextChapter(guidance: '开篇');
      final result = await loop.writeNextChapter(
        guidance: '开篇',
        autoApprove: true,
      );

      expect(candidate.isEmpty, isTrue);
      expect(candidate.warnings, contains('请求过于频繁，请稍后再试'));
      expect(result, isNull);
      expect(File('$projectDir/章节内容/第1章.md').existsSync(), isFalse);
    });
  });

  group('ContextCompiler mandatory 保护', () {
    test('预算极小时 mandatory 项仍获分配、不被挤掉', () {
      const compiler = ContextCompiler(config: CompilerConfig(tokenBudget: 50));
      final entries = <ContextEntry>[
        ContextEntry(
          id: 'canon',
          source: '人物库.md',
          reason: '主角设定',
          timePoint: null,
          priority: ContextPriority.mandatory,
          content: '主角林尘，修炼玄天诀。' * 40,
        ),
        for (var i = 0; i < 5; i++)
          ContextEntry(
            id: 'recent-$i',
            source: '第$i章.md',
            reason: '最近章节',
            timePoint: i,
            priority: ContextPriority.high,
            content: '这是第 $i 章的正文内容，用于挤占上下文预算。' * 40,
          ),
      ];

      final compiled = compiler.compile(entries, currentChapter: 6);
      final canon = compiled.entries.firstWhere((e) => e.id == 'canon');

      expect(canon.allocatedTokens, greaterThan(0));
      expect(canon.truncationStatus, isNot(TruncationStatus.omitted));
      expect(canon.content, isNotEmpty);
      expect(compiled.text, contains('林尘'));
    });
  });
}
