import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/services/guided_flow_engine.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

// ─── Mocks ───

class _MockAIProvider extends AIProvider {
  _MockAIProvider(this.responses);
  final List<String> responses;
  int _i = 0;

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield await chatSync(
        messages: messages, temperature: temperature, maxTokens: maxTokens);
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (_i < responses.length) return responses[_i++];
    return '{"isComplete": false, "reason": "继续"}';
  }

  @override
  Future<List<double>> embed(String text) async => const [];
  @override
  Future<void> dispose() async {}
}

class _MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> store = {};

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async =>
      store['$projectId/$fileName'];

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    store['$projectId/$fileName'] = data;
  }

  @override
  Future<List<String>> list(String projectId) async => store.keys
      .where((k) => k.startsWith('$projectId/'))
      .map((k) => k.split('/').last)
      .toList();

  @override
  Future<void> delete(String projectId, String fileName) async =>
      store.remove('$projectId/$fileName');

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';
}

const _flowJson = '''
{
  "id": "mirror-test",
  "genre": "玄幻",
  "type": "long",
  "steps": [
    {
      "id": "chars",
      "name": "角色",
      "prompt": "引导创建角色",
      "constraints": [],
      "completionCriteria": "已有主角",
      "outputs": [
        {"targetFile": "characters.json", "extractPrompt": "提取角色"}
      ]
    }
  ]
}
''';

void main() {
  test('p8：步骤产出同步镜像到 项目目录/小说资料/人物库.md', () async {
    final tempDir = Directory.systemTemp.createTempSync('lingbi-mirror-');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final projectDir = tempDir.path.replaceAll(r'\', '/');

    final engine = GuidedFlowEngine(
      metaRepository: _MockMetaRepository(),
      aiProvider: _MockAIProvider([
        'AI 回复',
        '{"isComplete": true, "reason": "完成"}',
        '{"protagonist": "林动", "personality": "坚韧"}',
      ]),
      projectDirResolver: (pid) async => projectDir,
    );
    engine.loadDefinitionFromJson(_flowJson);
    await engine.startFlow(flowId: 'mirror-test', projectId: 'p1');

    final resp = await engine.processUserInput(
      projectId: 'p1',
      userInput: '主角叫林动，性格坚韧。',
    );
    expect(resp.isStepComplete, isTrue);

    final md = File('$projectDir/小说资料/人物库.md');
    expect(md.existsSync(), isTrue, reason: '人物库.md 应被镜像落盘');
    final content = md.readAsStringSync();
    expect(content, contains('# 人物库'));
    expect(content, contains('## 人物设定'));
    expect(content, contains('林动'));
  });

  test('p8：未提供 projectDirResolver 时跳过镜像且不报错', () async {
    final engine = GuidedFlowEngine(
      metaRepository: _MockMetaRepository(),
      aiProvider: _MockAIProvider([
        'AI 回复',
        '{"isComplete": true, "reason": "完成"}',
        '{"protagonist": "林动"}',
      ]),
    );
    engine.loadDefinitionFromJson(_flowJson);
    await engine.startFlow(flowId: 'mirror-test', projectId: 'p2');
    final resp = await engine.processUserInput(
      projectId: 'p2',
      userInput: '主角林动。',
    );
    expect(resp.isStepComplete, isTrue);
  });
}
