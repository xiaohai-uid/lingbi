import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';

void main() {
  group('AgentToolRegistry 沙箱', () {
    late Directory dir;
    late AgentToolRegistry registry;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('lingbi-agent-registry-');
      registry = AgentToolRegistry(projectDir: dir.path);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    ToolCall call(String name, Map<String, dynamic> args) => ToolCall(
          id: 'id-$name',
          name: name,
          argumentsJson: jsonEncode(args),
        );

    test('file_write 写入项目内文件并可读回', () async {
      final w = await registry
          .execute(call('file_write', {'path': '章节内容/第1章.md', 'content': '# 第1章\n\n正文'}));
      expect(w.isError, isFalse);
      expect(File('${dir.path}/章节内容/第1章.md').existsSync(), isTrue);

      final r = await registry
          .execute(call('file_read', {'path': '章节内容/第1章.md'}));
      expect(r.isError, isFalse);
      expect(r.content, contains('正文'));
    });

    test('拒绝 .. 逃逸出项目目录', () async {
      final r = await registry
          .execute(call('file_read', {'path': '../../secret.txt'}));
      expect(r.isError, isTrue);
      expect(r.content, contains('拒绝访问'));
    });

    test('拒绝项目外的绝对路径', () async {
      final outside = Platform.isWindows ? r'C:\Windows\System32' : '/etc';
      final r = await registry.execute(call('list_dir', {'path': outside}));
      expect(r.isError, isTrue);
    });

    test('list_dir 列出已写入的文件', () async {
      File('${dir.path}/a.md').writeAsStringSync('x');
      final r = await registry.execute(call('list_dir', {'path': ''}));
      expect(r.isError, isFalse);
      expect(r.content, contains('a.md'));
    });

    test('file_read 超长内容被截断', () async {
      File('${dir.path}/big.md').writeAsStringSync('字' * 20000);
      final r = await registry.execute(call('file_read', {'path': 'big.md'}));
      expect(r.content, contains('已截断'));
    });

    test('confirmWrite 拒绝时不落盘', () async {
      final reg = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (p, c) async => false,
      );
      final w = await reg
          .execute(call('file_write', {'path': 'x.md', 'content': 'hi'}));
      expect(w.content, contains('拒绝'));
      expect(File('${dir.path}/x.md').existsSync(), isFalse);
    });

    test('specs 按回调可用性暴露 question / skill_lookup', () {
      expect(registry.specs.map((s) => s.name), isNot(contains('question')));
      final reg2 = AgentToolRegistry(
        projectDir: dir.path,
        askUser: (q, o) async => 'ok',
        skillLookup: (n) async => 'body',
      );
      final names = reg2.specs.map((s) => s.name).toList();
      expect(names, containsAll(['file_read', 'file_write', 'list_dir', 'question', 'skill_lookup']));
    });
  });
}
