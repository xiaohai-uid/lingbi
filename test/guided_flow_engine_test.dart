
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/guided_flow_definition.dart';
import 'package:lingbi/shared/models/guided_flow_state.dart';
import 'package:lingbi/services/guided_flow_engine.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── Mock AIProvider ───

class MockAIProvider extends AIProvider {
  MockAIProvider({this.responses = const []});

  final List<String> responses;
  int _callIndex = 0;
  final List<List<ChatMessage>> callHistory = [];

  @override
  String get name => 'mock';

  @override
  String get displayName => 'Mock Provider';

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
    callHistory.add(messages);
    if (_callIndex < responses.length) {
      return responses[_callIndex++];
    }
    return '{"isComplete": false, "reason": "继续对话", "followUpQuestion": "请补充更多细节"}';
  }

  @override
  Future<List<double>> embed(String text) async => [0.1, 0.2, 0.3];

  @override
  Future<void> dispose() async {}
}

// ─── Mock IProjectMetaRepository ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  String _key(String projectId, String fileName) => '$projectId/$fileName';

  @override
  Future<Map<String, dynamic>?> read(
      String projectId, String fileName) async {
    return _store[_key(projectId, fileName)];
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    _store[_key(projectId, fileName)] = data;
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store.keys
        .where((k) => k.startsWith('$projectId/'))
        .map((k) => k.split('/').last)
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    _store.remove(_key(projectId, fileName));
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';

  /// 测试辅助：获取存储的数据
  Map<String, dynamic>? getStored(String projectId, String fileName) =>
      _store[_key(projectId, fileName)];
}

// ─── 测试用流程定义 ───

const _testFlowJson = '''
{
  "id": "test-long",
  "genre": "测试",
  "type": "long",
  "steps": [
    {
      "id": "world",
      "name": "世界观构建",
      "prompt": "引导用户构建世界观",
      "constraints": ["必须包含地理环境", "必须包含力量体系"],
      "completionCriteria": "用户已描述完整的地理环境和力量体系",
      "outputs": [
        {
          "targetFile": "worldbuilding.json",
          "extractPrompt": "提取世界观设定"
        }
      ]
    },
    {
      "id": "characters",
      "name": "核心角色",
      "prompt": "引导用户创建核心角色",
      "constraints": ["至少一个主角"],
      "completionCriteria": "用户已创建至少一个有完整设定的主角",
      "outputs": [
        {
          "targetFile": "characters.json",
          "extractPrompt": "提取角色设定"
        }
      ]
    }
  ]
}
''';

const _testFlowYaml = '''
id: yaml-short
genre: 悬疑
type: short
steps:
  - id: emotion
    name: 情绪设计
    prompt: 引导用户设计情绪曲线
    constraints:
      - 必须有反转
    completionCriteria: 用户已设计完整的情绪曲线
    outputs:
      - targetFile: emotion_design.json
        extractPrompt: 提取情绪设计
  - id: twist
    name: 反转构思
    prompt: 引导用户构思反转
    constraints: []
    completionCriteria: 用户已确定反转方案
    outputs: []
''';

void main() {
  late MockMetaRepository metaRepo;
  late MockAIProvider aiProvider;
  late GuidedFlowEngine engine;

  setUp(() {
    metaRepo = MockMetaRepository();
    aiProvider = MockAIProvider(responses: [
      '你好！让我们开始构建世界观。首先，你的故事发生在什么样的世界？',
      '{"isComplete": false, "reason": "还需要力量体系", "followUpQuestion": "力量体系是什么？"}',
      '{"isComplete": true, "reason": "世界观已完整", "followUpQuestion": null}',
      '{"geography": "大陆", "powerSystem": "灵气修炼"}',
      '很好！现在让我们创建核心角色。你的主角是谁？',
      '{"isComplete": true, "reason": "角色已完整", "followUpQuestion": null}',
      '{"protagonist": "林逸", "personality": "坚韧"}',
    ]);
    engine = GuidedFlowEngine(
      metaRepository: metaRepo,
      aiProvider: aiProvider,
    );
  });

  group('GuidedFlowDefinition 加载', () {
    test('从 JSON 加载流程定义', () {
      final definition = engine.loadDefinitionFromJson(_testFlowJson);

      expect(definition.id, 'test-long');
      expect(definition.genre, '测试');
      expect(definition.type, GuidedFlowType.long);
      expect(definition.steps.length, 2);
      expect(definition.steps[0].id, 'world');
      expect(definition.steps[0].name, '世界观构建');
      expect(definition.steps[0].constraints.length, 2);
      expect(definition.steps[0].outputs.length, 1);
      expect(definition.steps[0].outputs[0].targetFile, 'worldbuilding.json');
    });

    test('从 YAML 加载流程定义', () {
      final definition = engine.loadDefinitionFromYaml(_testFlowYaml);

      expect(definition.id, 'yaml-short');
      expect(definition.genre, '悬疑');
      expect(definition.type, GuidedFlowType.short);
      expect(definition.steps.length, 2);
      expect(definition.steps[0].id, 'emotion');
      expect(definition.steps[0].constraints, ['必须有反转']);
      expect(definition.steps[1].outputs, isEmpty);
    });

    test('注册和获取定义', () {
      final definition = engine.loadDefinitionFromJson(_testFlowJson);
      expect(engine.getDefinition('test-long'), isNotNull);
      expect(engine.getDefinition('test-long')!.id, definition.id);
      expect(engine.getDefinition('nonexistent'), isNull);
    });

    test('allDefinitions 返回所有已注册定义', () {
      engine.loadDefinitionFromJson(_testFlowJson);
      engine.loadDefinitionFromYaml(_testFlowYaml);
      expect(engine.allDefinitions.length, 2);
    });
  });

  group('流程状态管理', () {
    test('startFlow 创建新状态', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      final state = await engine.startFlow(
        flowId: 'test-long',
        projectId: 'proj-1',
      );

      expect(state.flowId, 'test-long');
      expect(state.projectId, 'proj-1');
      expect(state.currentStepIndex, 0);
      expect(state.status, GuidedFlowStatus.inProgress);
    });

    test('startFlow 未注册定义时抛异常', () async {
      expect(
        () => engine.startFlow(flowId: 'nonexistent', projectId: 'proj-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('getState 获取持久化状态', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      // 新引擎实例从持久化恢复
      final engine2 = GuidedFlowEngine(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
      engine2.loadDefinitionFromJson(_testFlowJson);
      final state = await engine2.getState('proj-1');

      expect(state, isNotNull);
      expect(state!.flowId, 'test-long');
      expect(state.status, GuidedFlowStatus.inProgress);
    });

    test('getCurrentStep 返回当前步骤', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      final step = engine.getCurrentStep('proj-1');
      expect(step, isNotNull);
      expect(step!.id, 'world');
    });

    test('getProgress 计算正确进度', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      expect(engine.getProgress('proj-1'), 0);
    });
  });

  group('暂停/恢复', () {
    test('pauseFlow 暂停状态', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');
      await engine.pauseFlow('proj-1');

      final state = await engine.getState('proj-1');
      expect(state!.status, GuidedFlowStatus.paused);
    });

    test('resumeFlow 恢复状态', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');
      await engine.pauseFlow('proj-1');
      await engine.resumeFlow('proj-1');

      final state = await engine.getState('proj-1');
      expect(state!.status, GuidedFlowStatus.inProgress);
    });

    test('startFlow 恢复已有未完成流程', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');
      await engine.pauseFlow('proj-1');

      // 重新 startFlow 应恢复
      final state = await engine.startFlow(
        flowId: 'test-long',
        projectId: 'proj-1',
      );
      expect(state.status, GuidedFlowStatus.inProgress);
      expect(state.currentStepIndex, 0);
    });
  });

  group('对话处理 + 完成判定', () {
    test('processUserInput 返回 AI 响应', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      final response = await engine.processUserInput(
        projectId: 'proj-1',
        userInput: '故事发生在一个灵气大陆',
      );

      expect(response.aiMessage, isNotEmpty);
      expect(response.currentStepName, '世界观构建');
      expect(response.isFlowComplete, false);
    });

    test('步骤完成后自动推进到下一步', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      // 第1轮：AI 回复（callIndex 0）
      await engine.processUserInput(
        projectId: 'proj-1',
        userInput: '灵气大陆',
      );

      // 第2轮：AI 判定未完成（callIndex 1）
      await engine.processUserInput(
        projectId: 'proj-1',
        userInput: '有修炼体系',
      );

      // 第3轮：AI 判定完成（callIndex 2）+ 提取产出（callIndex 3）
      final response = await engine.processUserInput(
        projectId: 'proj-1',
        userInput: '地理环境是九州大陆',
      );

      expect(response.isStepComplete, true);
      // 推进到第二步
      final state = await engine.getState('proj-1');
      expect(state!.currentStepIndex, 1);
    });

    test('步骤完成时写入产出物到 MetaRepository', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      // 模拟完成第一步
      await engine.processUserInput(
          projectId: 'proj-1', userInput: '灵气大陆');
      await engine.processUserInput(
          projectId: 'proj-1', userInput: '有修炼体系');
      await engine.processUserInput(
          projectId: 'proj-1', userInput: '地理环境是九州大陆');

      // 验证产出物写入
      final worldbuilding =
          metaRepo.getStored('proj-1', 'worldbuilding.json');
      expect(worldbuilding, isNotNull);
    });

    test('无活跃流程时抛异常', () async {
      expect(
        () => engine.processUserInput(
            projectId: 'no-flow', userInput: 'test'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('generateStepOpening', () {
    test('生成步骤开场白', () async {
      engine.loadDefinitionFromJson(_testFlowJson);
      await engine.startFlow(flowId: 'test-long', projectId: 'proj-1');

      final opening = await engine.generateStepOpening('proj-1');
      expect(opening, isNotEmpty);
      expect(aiProvider.callHistory, isNotEmpty);
    });
  });

  group('GuidedFlowState 序列化', () {
    test('toJson/fromJson 往返一致', () {
      final state = GuidedFlowState(
        flowId: 'test-long',
        projectId: 'proj-1',
        currentStepIndex: 1,
        status: GuidedFlowStatus.inProgress,
        conversationHistory: const [
          ConversationTurn(role: 'user', content: '你好'),
          ConversationTurn(role: 'assistant', content: '你好！'),
        ],
        stepOutputs: const {'world': '已完成: 世界观构建'},
      );

      final json = state.toJson();
      final restored = GuidedFlowState.fromJson(json);

      expect(restored.flowId, state.flowId);
      expect(restored.projectId, state.projectId);
      expect(restored.currentStepIndex, state.currentStepIndex);
      expect(restored.status, state.status);
      expect(restored.conversationHistory.length, 2);
      expect(restored.stepOutputs['world'], '已完成: 世界观构建');
    });

    test('状态转换方法', () {
      final state = GuidedFlowState(
        flowId: 'test',
        projectId: 'p1',
      );

      expect(state.status, GuidedFlowStatus.notStarted);

      state.markInProgress();
      expect(state.status, GuidedFlowStatus.inProgress);

      state.pause();
      expect(state.status, GuidedFlowStatus.paused);

      state.resume();
      expect(state.status, GuidedFlowStatus.inProgress);

      state.advanceToNextStep();
      expect(state.currentStepIndex, 1);
      expect(state.conversationHistory, isEmpty);

      state.markCompleted();
      expect(state.isCompleted, true);
    });
  });

  group('GuidedFlowDefinition 序列化', () {
    test('toJson/fromJson 往返一致', () {
      final definition = engine.loadDefinitionFromJson(_testFlowJson);
      final json = definition.toJson();
      final restored = GuidedFlowDefinition.fromJson(json);

      expect(restored.id, definition.id);
      expect(restored.genre, definition.genre);
      expect(restored.type, definition.type);
      expect(restored.steps.length, definition.steps.length);
      expect(restored.steps[0].constraints.length, 2);
    });
  });
}
