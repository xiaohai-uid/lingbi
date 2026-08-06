import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lingbi_no_syscmd_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('specs expose project tools and never expose system_command', () {
    final registry = AgentToolRegistry(
      mutationProtocol: _cmdProtocol(),
      projectDir: tempDir.path,
    );
    final names = registry.specs.map((spec) => spec.name).toList();

    expect(names, contains('file_read'));
    expect(names, contains('file_write'));
    expect(names, contains('list_dir'));
    expect(names, isNot(contains('system_command')));
    expect(names, isNot(contains('cmd')));
    expect(names, isNot(contains('powershell')));
    expect(names, isNot(contains('python')));
    expect(names, isNot(contains('node')));
    expect(names, isNot(contains('dart')));
    expect(names, isNot(contains('flutter')));
  });

  test('system_command execution is unavailable', () async {
    final registry = AgentToolRegistry(
      mutationProtocol: _cmdProtocol(),
      projectDir: tempDir.path,
    );

    final result = await registry.execute(const ToolCall(
      id: '1',
      name: 'system_command',
      argumentsJson: '{"command":"echo should-not-run"}',
    ));

    expect(result.isError, isTrue);
    expect(result.content, contains('未知工具'));
  });
}

LocalMutationProtocol _cmdProtocol() => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '/tmp/lingbi-no-syscmd'),
      store: FileCanonicalStore(
        projectRoot: '/tmp',
        atomicStore: AtomicFileStore(),
      ),
    );
