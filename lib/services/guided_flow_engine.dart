/// GuidedFlowEngine — 数据驱动的引导流程状态机
///
/// 职责：
/// 1. 从 YAML/JSON 文件加载 GuidedFlowDefinition
/// 2. 管理流程状态推进（当前步骤 → 下一步）
/// 3. AI 辅助完成判定（调用 LLM 评估，非关键词匹配）
/// 4. 暂停/恢复（状态持久化到 ProjectMetaRepository）
/// 5. 步骤完成时触发产出物写入 ProjectMetaRepository
/// 6. 支持长篇/短篇两种流程模板
library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/models/guided_flow_definition.dart';
import 'package:lingbi/core/models/guided_flow_state.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

/// 完成判定结果
class CompletionJudgment {
  const CompletionJudgment({
    required this.isComplete,
    this.reason = '',
    this.followUpQuestion,
  });

  /// 是否满足完成标准
  final bool isComplete;

  /// AI 给出的判定理由
  final String reason;

  /// 未完成时的追问（引导用户补充）
  final String? followUpQuestion;
}

/// 引导流程引擎
class GuidedFlowEngine {
  GuidedFlowEngine({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  /// 已加载的流程定义缓存（flowId -> definition）
  final Map<String, GuidedFlowDefinition> _definitions = {};

  /// 当前活跃状态（projectId -> state）
  final Map<String, GuidedFlowState> _activeStates = {};

  /// 状态文件名
  static const String _stateFileName = 'guided_flow_state.json';

  /// 更换 AI Provider（如用户切换供应商）
  set aiProvider(AIProvider provider) {
    _aiProvider = provider;
  }

  // ─── 定义加载 ───

  /// 从 JSON 字符串加载流程定义
  GuidedFlowDefinition loadDefinitionFromJson(String jsonContent) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    final definition = GuidedFlowDefinition.fromJson(data);
    _definitions[definition.id] = definition;
    return definition;
  }

  /// 从 YAML 字符串加载流程定义
  GuidedFlowDefinition loadDefinitionFromYaml(String yamlContent) {
    final yamlMap = loadYaml(yamlContent) as YamlMap;
    final jsonMap = _yamlMapToJson(yamlMap);
    final definition = GuidedFlowDefinition.fromJson(jsonMap);
    _definitions[definition.id] = definition;
    return definition;
  }

  /// 从文件加载流程定义（根据扩展名自动选择解析器）
  Future<GuidedFlowDefinition> loadDefinitionFromFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    if (filePath.endsWith('.yaml') || filePath.endsWith('.yml')) {
      return loadDefinitionFromYaml(content);
    }
    return loadDefinitionFromJson(content);
  }

  /// 注册已构建好的流程定义（供 Skill Runtime 调用）
  void registerDefinition(GuidedFlowDefinition definition) {
    _definitions[definition.id] = definition;
  }

  /// 获取已注册的流程定义
  GuidedFlowDefinition? getDefinition(String flowId) => _definitions[flowId];

  /// 列出所有已注册的流程定义
  List<GuidedFlowDefinition> get allDefinitions =>
      _definitions.values.toList();

  // ─── 状态管理 ───

  /// 启动新流程（或恢复已有流程）
  Future<GuidedFlowState> startFlow({
    required String flowId,
    required String projectId,
  }) async {
    final definition = _definitions[flowId];
    if (definition == null) {
      throw StateError('Flow definition not found: $flowId');
    }

    // 尝试恢复已有状态
    final existing = await _loadState(projectId);
    if (existing != null && existing.flowId == flowId && !existing.isCompleted) {
      existing.resume();
      _activeStates[projectId] = existing;
      await _saveState(projectId, existing);
      return existing;
    }

    // 创建新状态
    final state = GuidedFlowState(
      flowId: flowId,
      projectId: projectId,
      status: GuidedFlowStatus.inProgress,
    );
    _activeStates[projectId] = state;
    await _saveState(projectId, state);
    return state;
  }

  /// 获取项目当前流程状态
  Future<GuidedFlowState?> getState(String projectId) async {
    if (_activeStates.containsKey(projectId)) {
      return _activeStates[projectId];
    }
    final state = await _loadState(projectId);
    if (state != null) {
      _activeStates[projectId] = state;
    }
    return state;
  }

  /// 获取当前步骤定义
  GuidedFlowStep? getCurrentStep(String projectId) {
    final state = _activeStates[projectId];
    if (state == null) return null;
    final definition = _definitions[state.flowId];
    if (definition == null) return null;
    if (state.currentStepIndex >= definition.steps.length) return null;
    return definition.steps[state.currentStepIndex];
  }

  /// 获取流程进度（0.0 ~ 1.0）
  double getProgress(String projectId) {
    final state = _activeStates[projectId];
    if (state == null) return 0;
    final definition = _definitions[state.flowId];
    if (definition == null || definition.steps.isEmpty) return 0;
    if (state.isCompleted) return 1;
    return state.currentStepIndex / definition.steps.length;
  }

  // ─── 对话处理 ───

  /// 处理用户输入，返回 AI 响应
  ///
  /// 1. 将用户输入加入对话历史
  /// 2. 构建 AI 上下文（步骤 prompt + 约束 + 对话历史）
  /// 3. 调用 AI 生成响应
  /// 4. AI 同时判定是否满足完成标准
  Future<GuidedFlowResponse> processUserInput({
    required String projectId,
    required String userInput,
  }) async {
    final state = _activeStates[projectId];
    if (state == null) {
      throw StateError('No active flow for project: $projectId');
    }
    final definition = _definitions[state.flowId];
    if (definition == null) {
      throw StateError('Flow definition not found: ${state.flowId}');
    }
    final step = definition.steps[state.currentStepIndex];

    // 记录用户输入
    state.addConversationTurn(ConversationTurn(
      role: 'user',
      content: userInput,
      timestamp: DateTime.now(),
    ));

    // 构建 AI 消息
    final messages = _buildChatMessages(step, state, userInput);

    // 调用 AI 生成响应
    final aiResponse = await _aiProvider.chatSync(
      messages: messages,
    );

    // 记录 AI 响应
    state.addConversationTurn(ConversationTurn(
      role: 'assistant',
      content: aiResponse,
      timestamp: DateTime.now(),
    ));

    // AI 辅助完成判定
    final judgment = await _judgeCompletion(step, state);

    // 如果完成，触发产出物写入和状态推进
    if (judgment.isComplete) {
      await _completeCurrentStep(projectId, state, definition, step);
    }

    await _saveState(projectId, state);

    return GuidedFlowResponse(
      aiMessage: aiResponse,
      isStepComplete: judgment.isComplete,
      judgmentReason: judgment.reason,
      followUpQuestion: judgment.followUpQuestion,
      currentStepName: step.name,
      progress: getProgress(projectId),
      isFlowComplete: state.isCompleted,
    );
  }

  /// 生成当前步骤的开场白（AI 主动提问）
  Future<String> generateStepOpening(String projectId) async {
    final state = _activeStates[projectId];
    if (state == null) {
      throw StateError('No active flow for project: $projectId');
    }
    final definition = _definitions[state.flowId];
    if (definition == null) {
      throw StateError('Flow definition not found: ${state.flowId}');
    }
    final step = definition.steps[state.currentStepIndex];

    final messages = <ChatMessage>[
      ChatMessage(
        role: 'system',
        content: _buildSystemPrompt(step, state),
      ),
      const ChatMessage(
        role: 'user',
        content: '请开始引导我完成这个步骤。先问我第一个问题。',
      ),
    ];

    final opening = await _aiProvider.chatSync(
      messages: messages,
      temperature: 0.8,
    );

    // 记录到对话历史
    state.addConversationTurn(ConversationTurn(
      role: 'assistant',
      content: opening,
      timestamp: DateTime.now(),
    ));
    await _saveState(projectId, state);

    return opening;
  }

  // ─── 暂停/恢复 ───

  /// 暂停流程
  Future<void> pauseFlow(String projectId) async {
    final state = _activeStates[projectId];
    if (state == null) return;
    state.pause();
    await _saveState(projectId, state);
  }

  /// 恢复流程
  Future<void> resumeFlow(String projectId) async {
    final state = _activeStates[projectId] ?? await _loadState(projectId);
    if (state == null) return;
    state.resume();
    _activeStates[projectId] = state;
    await _saveState(projectId, state);
  }

  // ─── 内部方法 ───

  /// 完成当前步骤：写入产出物 + 推进状态
  Future<void> _completeCurrentStep(
    String projectId,
    GuidedFlowState state,
    GuidedFlowDefinition definition,
    GuidedFlowStep step,
  ) async {
    // 写入产出物
    for (final output in step.outputs) {
      await _writeStepOutput(projectId, step, output, state);
    }

    // 记录步骤产出摘要
    state.stepOutputs[step.id] = '已完成: ${step.name}';

    // 推进状态
    if (state.currentStepIndex >= definition.steps.length - 1) {
      state.markCompleted();
    } else {
      state.advanceToNextStep();
    }
  }

  /// 写入步骤产出物到 ProjectMetaRepository
  Future<void> _writeStepOutput(
    String projectId,
    GuidedFlowStep step,
    StepOutput output,
    GuidedFlowState state,
  ) async {
    if (output.targetFile.isEmpty) return;

    // 用 AI 从对话中提取结构化数据
    final conversationText = state.conversationHistory
        .map((t) => '${t.role}: ${t.content}')
        .join('\n');

    final extractMessages = <ChatMessage>[
      const ChatMessage(
        role: 'system',
        content: '你是一个数据提取助手。请从对话中提取结构化信息，以 JSON 格式输出。'
            '只输出 JSON，不要添加其他说明。',
      ),
      ChatMessage(
        role: 'user',
        content: '${output.extractPrompt}\n\n对话内容：\n$conversationText',
      ),
    ];

    try {
      final extracted = await _aiProvider.chatSync(
        messages: extractMessages,
        temperature: 0.3,
        maxTokens: 4096,
      );

      // 解析 JSON（容错：去除可能的代码块包裹）
      final jsonStr = _extractJson(extracted);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      await _metaRepository.write(projectId, output.targetFile, data);
    } catch (_) {
      // 提取失败不阻断流程，写入原始对话摘要
      await _metaRepository.write(projectId, output.targetFile, {
        'stepId': step.id,
        'stepName': step.name,
        'rawConversation': conversationText,
        'extractedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// AI 辅助完成判定
  Future<CompletionJudgment> _judgeCompletion(
    GuidedFlowStep step,
    GuidedFlowState state,
  ) async {
    if (step.completionCriteria.isEmpty) {
      // 无完成标准时，至少需要一轮对话
      return CompletionJudgment(
        isComplete: state.conversationHistory.length >= 4,
        reason: '无明确完成标准，基于对话轮次判定',
      );
    }

    final conversationText = state.conversationHistory
        .map((t) => '${t.role}: ${t.content}')
        .join('\n');

    final messages = <ChatMessage>[
      const ChatMessage(
        role: 'system',
        content: '你是一个引导流程完成度评估器。根据对话内容判断用户是否满足了完成标准。\n'
            '请以 JSON 格式回复：\n'
            '{"isComplete": true/false, "reason": "判定理由", "followUpQuestion": "未完成时的追问（完成时为null）"}\n'
            '只输出 JSON，不要添加其他说明。',
      ),
      ChatMessage(
        role: 'user',
        content: '完成标准：${step.completionCriteria}\n\n'
            '约束条件：${step.constraints.join('；')}\n\n'
            '对话内容：\n$conversationText',
      ),
    ];

    try {
      final response = await _aiProvider.chatSync(
        messages: messages,
        temperature: 0.2,
        maxTokens: 512,
      );

      final jsonStr = _extractJson(response);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      return CompletionJudgment(
        isComplete: data['isComplete'] as bool? ?? false,
        reason: data['reason'] as String? ?? '',
        followUpQuestion: data['followUpQuestion'] as String?,
      );
    } catch (_) {
      // AI 判定失败时不阻断，返回未完成
      return const CompletionJudgment(
        isComplete: false,
        reason: 'AI 判定服务暂时不可用，请继续对话',
      );
    }
  }

  /// 构建聊天消息（包含步骤上下文）
  List<ChatMessage> _buildChatMessages(
    GuidedFlowStep step,
    GuidedFlowState state,
    String userInput,
  ) {
    final messages = <ChatMessage>[
      ChatMessage(
        role: 'system',
        content: _buildSystemPrompt(step, state),
      ),
    ];

    // 加入对话历史（最近 10 轮，避免 token 溢出）
    final history = state.conversationHistory;
    final startIdx = history.length > 20 ? history.length - 20 : 0;
    for (var i = startIdx; i < history.length - 1; i++) {
      final turn = history[i];
      messages.add(ChatMessage(role: turn.role, content: turn.content));
    }

    // 当前用户输入
    messages.add(ChatMessage(role: 'user', content: userInput));
    return messages;
  }

  /// 构建系统 prompt
  String _buildSystemPrompt(GuidedFlowStep step, GuidedFlowState state) {
    final buffer = StringBuffer();
    buffer.writeln('你是一个专业的小说创作引导助手。');
    buffer.writeln('当前步骤：${step.name}');
    buffer.writeln();
    buffer.writeln('## 引导目标');
    buffer.writeln(step.prompt);
    buffer.writeln();

    if (step.constraints.isNotEmpty) {
      buffer.writeln('## 约束条件');
      for (final c in step.constraints) {
        buffer.writeln('- $c');
      }
      buffer.writeln();
    }

    if (step.completionCriteria.isNotEmpty) {
      buffer.writeln('## 完成标准');
      buffer.writeln(step.completionCriteria);
      buffer.writeln();
    }

    // 注入已完成步骤的产出摘要
    if (state.stepOutputs.isNotEmpty) {
      buffer.writeln('## 已完成步骤');
      for (final entry in state.stepOutputs.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    buffer.writeln('## 交互规则');
    buffer.writeln('1. 主动提问，引导用户思考和回答');
    buffer.writeln('2. 每次只问 1-2 个问题，不要一次性列出所有问题');
    buffer.writeln('3. 根据用户回答追问细节或确认');
    buffer.writeln('4. 当信息足够时，总结并确认，然后告知可以进入下一步');
    buffer.writeln('5. 保持对话自然流畅，像朋友聊天一样');

    return buffer.toString();
  }

  /// 持久化状态
  Future<void> _saveState(String projectId, GuidedFlowState state) async {
    await _metaRepository.write(
      projectId,
      _stateFileName,
      state.toJson(),
    );
  }

  /// 加载持久化状态
  Future<GuidedFlowState?> _loadState(String projectId) async {
    try {
      final data = await _metaRepository.read(projectId, _stateFileName);
      if (data == null) return null;
      return GuidedFlowState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 从 AI 输出中提取 JSON（容错处理）
  String _extractJson(String text) {
    var cleaned = text.trim();
    // 去除 ```json ... ``` 包裹
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }
    return cleaned;
  }

  /// YamlMap → Map<String, dynamic> 递归转换
  Map<String, dynamic> _yamlMapToJson(YamlMap yamlMap) {
    final result = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      result[entry.key.toString()] = _yamlValueToJson(entry.value);
    }
    return result;
  }

  dynamic _yamlValueToJson(dynamic value) {
    if (value is YamlMap) return _yamlMapToJson(value);
    if (value is YamlList) {
      return value.map(_yamlValueToJson).toList();
    }
    return value;
  }
}

/// 引导流程响应
class GuidedFlowResponse {
  const GuidedFlowResponse({
    required this.aiMessage,
    required this.isStepComplete,
    this.judgmentReason = '',
    this.followUpQuestion,
    required this.currentStepName,
    required this.progress,
    required this.isFlowComplete,
  });

  /// AI 回复内容
  final String aiMessage;

  /// 当前步骤是否完成
  final bool isStepComplete;

  /// 完成判定理由
  final String judgmentReason;

  /// 未完成时的追问
  final String? followUpQuestion;

  /// 当前步骤名称
  final String currentStepName;

  /// 整体进度（0.0 ~ 1.0）
  final double progress;

  /// 整个流程是否完成
  final bool isFlowComplete;
}
