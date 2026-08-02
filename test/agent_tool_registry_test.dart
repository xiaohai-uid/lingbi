import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  group('AgentToolRegistry 沙箱', () {
    late Directory dir;
    late Directory journalDir;
    late AgentToolRegistry registry;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('lingbi-agent-registry-');
      journalDir = Directory.systemTemp.createTempSync('lingbi-reg-journal-');
      final protocol = LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: journalDir.path),
        store: FileCanonicalStore(
          projectRoot: dir.path,
          atomicStore: AtomicFileStore(),
        ),
      );
      registry = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (path, content) async => true,
        mutationProtocol: protocol,
      );
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
      journalDir.deleteSync(recursive: true);
    });

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
      final rejJournal = Directory.systemTemp.createTempSync('lingbi-rej-');
      final reg = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (p, c) async => false,
        mutationProtocol: LocalMutationProtocol(
          journal: LocalMutationJournal(basePath: rejJournal.path),
          store: FileCanonicalStore(
            projectRoot: dir.path,
            atomicStore: AtomicFileStore(),
          ),
        ),
      );
      final w = await reg
          .execute(call('file_write', {'path': 'x.md', 'content': 'hi'}));
      expect(w.content, contains('拒绝'));
      expect(File('${dir.path}/x.md').existsSync(), isFalse);
      rejJournal.deleteSync(recursive: true);
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

  group('AgentToolRegistry MutationProtocol 集成', () {
    late Directory dir;
    late Directory journalDir;
    late LocalMutationProtocol protocol;
    late AgentToolRegistry registry;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('lingbi-agent-mutation-');
      journalDir = Directory.systemTemp.createTempSync('lingbi-journal-');
      protocol = LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: journalDir.path),
        store: FileCanonicalStore(
          projectRoot: dir.path,
          atomicStore: AtomicFileStore(),
        ),
      );
      registry = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (path, content) async => true,
        mutationProtocol: protocol,
      );
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
      journalDir.deleteSync(recursive: true);
    });

    ToolCall call(String name, Map<String, dynamic> args) => ToolCall(
          id: 'id-$name',
          name: name,
          argumentsJson: jsonEncode(args),
        );

    test('file_write 经 MutationProtocol 创建 candidate + approval + receipt',
        () async {
      final w = await registry.execute(
          call('file_write', {'path': '章节内容/第1章.md', 'content': '# 第1章\n\n正文'}));
      expect(w.isError, isFalse);
      expect(w.content, contains('已写入'));

      // 验证 journal 中有 propose + approve + commit 三条记录
      final journal = LocalMutationJournal(basePath: journalDir.path);
      final allEvents = await journal.readAll();
      final types = allEvents.map((e) => e.eventType).toList();
      expect(types, contains('candidate_proposed'));
      expect(types, contains('candidate_approved'));
      expect(types, contains('candidate_committed'));
    });

    test('file_write 用户拒绝时经 MutationProtocol reject', () async {
      final reg = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (p, c) async => false,
        mutationProtocol: protocol,
      );
      final w = await reg
          .execute(call('file_write', {'path': 'x.md', 'content': 'hi'}));
      expect(w.content, contains('拒绝'));
      expect(File('${dir.path}/x.md').existsSync(), isFalse);

      // 验证 journal 中有 propose + reject
      final journal = LocalMutationJournal(basePath: journalDir.path);
      final allEvents = await journal.readAll();
      final types = allEvents.map((e) => e.eventType).toList();
      expect(types, contains('candidate_proposed'));
      expect(types, contains('candidate_rejected'));
      expect(types, isNot(contains('candidate_committed')));
    });

    test('file_write 无 MutationProtocol 时 fail-closed 拒绝写入', () async {
      final reg = AgentToolRegistry(
        projectDir: dir.path,
        confirmWrite: (p, c) async => true,
        // 不传 mutationProtocol
      );
      final w = await reg
          .execute(call('file_write', {'path': 'y.md', 'content': 'hello'}));
      expect(w.isError, isTrue);
      expect(w.content, contains('APPROVAL_REQUIRED'));
      expect(File('${dir.path}/y.md').existsSync(), isFalse);
    });
  });
}
