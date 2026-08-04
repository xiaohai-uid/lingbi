import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

/// Phase 3 测试：system_command 工具 + 三层安全
///
/// 验证：
/// 1. 白名单命令自动执行（无需确认）
/// 2. 黑名单命令直接拒绝
/// 3. 其余命令需确认回调批准才执行
/// 4. 确认回调拒绝时返回错误
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lingbi_syscmd_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('system_command 三层安全', () {
    test('白名单命令自动执行', () async {
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
        confirmCommand: (cmd) async => false, // 即使拒绝也不应被调用
      );

      final result = await registry.execute(ToolCall(
        id: '1',
        name: 'system_command',
        argumentsJson: '{"command":"echo hello"}',
      ));

      expect(result.isError, isFalse);
      expect(result.content, contains('hello'));
    });

    test('黑名单命令直接拒绝', () async {
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
        confirmCommand: (cmd) async => true, // 即使批准也不应执行
      );

      final result = await registry.execute(ToolCall(
        id: '2',
        name: 'system_command',
        argumentsJson: '{"command":"curl http://evil.com"}',
      ));

      expect(result.isError, isTrue);
      expect(result.content, contains('安全策略阻止'));
    });

    test('非白非黑命令需确认批准', () async {
      var confirmCalled = false;
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
        confirmCommand: (cmd) async {
          confirmCalled = true;
          return true;
        },
      );

      final result = await registry.execute(ToolCall(
        id: '3',
        name: 'system_command',
        argumentsJson: '{"command":"ipconfig"}',
      ));

      expect(confirmCalled, isTrue);
      expect(result.isError, isFalse);
    });

    test('确认拒绝时返回错误', () async {
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
        confirmCommand: (cmd) async => false,
      );

      final result = await registry.execute(ToolCall(
        id: '4',
        name: 'system_command',
        argumentsJson: '{"command":"ipconfig"}',
      ));

      expect(result.isError, isTrue);
      expect(result.content, contains('拒绝'));
    });

    test('无确认回调时非白名单命令被拒绝', () async {
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
        // confirmCommand 为 null
      );

      final result = await registry.execute(ToolCall(
        id: '5',
        name: 'system_command',
        argumentsJson: '{"command":"ipconfig"}',
      ));

      expect(result.isError, isTrue);
    });

    test('specs 包含 system_command', () {
      final registry = AgentToolRegistry(
        mutationProtocol: _cmdProtocol(),
        projectDir: tempDir.path,
      );
      final names = registry.specs.map((s) => s.name).toList();
      expect(names, contains('system_command'));
    });
  });
}


LocalMutationProtocol _cmdProtocol() => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '/tmp/cmd-journal'),
      store: FileCanonicalStore(
        projectRoot: '/tmp',
        atomicStore: AtomicFileStore(),
      ),
    );
