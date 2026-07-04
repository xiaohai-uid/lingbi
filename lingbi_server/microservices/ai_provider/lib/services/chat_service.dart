import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';

/// Manages a single conversation dialog with context window management.
class DialogSession {
  final String id;
  final String modelId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  String? systemPrompt;

  DialogSession({
    required this.id,
    required this.modelId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.systemPrompt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Adds a message to the conversation.
  void addMessage(ChatMessage message) {
    messages.add(message);
    updatedAt = DateTime.now();
  }

  /// Serializes the dialog for the model request.
  List<ChatMessage> toRequestMessages() {
    final result = <ChatMessage>[];
    if (systemPrompt != null && systemPrompt!.isNotEmpty) {
      result.add(ChatMessage(role: 'system', content: systemPrompt!));
    }
    result.addAll(messages);
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelId': modelId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'systemPrompt': systemPrompt,
      };
}

/// Configuration for context window management.
class ContextWindowConfig {
  final int maxMessages;
  final int maxTokens;

  const ContextWindowConfig({
    this.maxMessages = 50,
    this.maxTokens = 8192,
  });
}

/// Service for managing AI chat dialogs, context windows,
/// and stream response processing.
///
/// This service provides high-level operations for:
/// - Creating and managing dialog sessions
/// - Managing system prompts
/// - Context window truncation
/// - Stream response assembly
/// - Integration with LiteLLMClient
class ChatService {
  final LiteLLMClient _client;
  final ModelConfigService _modelConfigService;
  final Map<String, DialogSession> _sessions = {};
  final ContextWindowConfig _contextConfig;

  ChatService({
    required LiteLLMClient client,
    required ModelConfigService modelConfigService,
    ContextWindowConfig? contextConfig,
  })  : _client = client,
        _modelConfigService = modelConfigService,
        _contextConfig = contextConfig ?? const ContextWindowConfig();

  // ---------------------------------------------------------------------------
  // Dialog / Session Management
  // ---------------------------------------------------------------------------

  /// Creates a new dialog session.
  DialogSession createSession({
    required String modelId,
    String? systemPrompt,
  }) {
    final id = _generateSessionId();
    final session = DialogSession(
      id: id,
      modelId: modelId,
      systemPrompt: systemPrompt,
    );
    _sessions[id] = session;
    return session;
  }

  /// Gets an existing session by ID.
  DialogSession? getSession(String sessionId) => _sessions[sessionId];

  /// Deletes a session.
  void deleteSession(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// Lists all active sessions.
  List<DialogSession> listSessions() => _sessions.values.toList();

  /// Cleans up sessions older than [age].
  void cleanupSessions(Duration age) {
    final cutoff = DateTime.now().subtract(age);
    _sessions.removeWhere((_, session) => session.updatedAt.isBefore(cutoff));
  }

  // ---------------------------------------------------------------------------
  // System Prompt Management
  // ---------------------------------------------------------------------------

  /// Sets the system prompt for a session.
  void setSystemPrompt(String sessionId, String prompt) {
    _sessions[sessionId]?.systemPrompt = prompt;
  }

  /// Gets the system prompt for a session.
  String? getSystemPrompt(String sessionId) {
    return _sessions[sessionId]?.systemPrompt;
  }

  // ---------------------------------------------------------------------------
  // Context Window Management
  // ---------------------------------------------------------------------------

  /// Truncates messages to fit within the context window.
  ///
  /// Keeps the system prompt and most recent messages, dropping old ones.
  List<ChatMessage> truncateMessages(List<ChatMessage> messages) {
    if (messages.length <= _contextConfig.maxMessages) {
      return messages;
    }

    // Keep system prompt + most recent messages
    final systemMessages =
        messages.where((m) => m.role == 'system').toList();
    final nonSystemMessages =
        messages.where((m) => m.role != 'system').toList();

    final truncated = nonSystemMessages
        .skip(nonSystemMessages.length - _contextConfig.maxMessages)
        .toList();

    return [...systemMessages, ...truncated];
  }

  // ---------------------------------------------------------------------------
  // Chat Completion
  // ---------------------------------------------------------------------------

  /// Sends a chat message and returns a streaming response.
  ///
  /// If [sessionId] is provided, the message is added to the session's history.
  /// If [keepHistory] is true (default), the response is also added.
  Stream<String> chat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
    String? sessionId,
    bool keepHistory = true,
  }) async* {
    // Apply context window truncation
    final truncatedMessages = truncateMessages(messages);

    // Send to LiteLLM
    final stream = await _client.chat(
      model: model,
      messages: truncatedMessages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: true,
    );

    // Process the stream
    String fullResponse = '';
    final completer = Completer<String>();

    await for (final chunk in stream) {
      if (chunk == '[DONE]') {
        if (!completer.isCompleted) {
          completer.complete(fullResponse);
        }
        yield '[DONE]';
        continue;
      }
      if (chunk.startsWith('[ERROR]')) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(chunk.substring(7)));
        }
        yield chunk;
        continue;
      }
      fullResponse += chunk;
      yield chunk;
    }

    // Wait for the stream to finish
    if (!completer.isCompleted) {
      completer.complete(fullResponse);
    }

    // Update session history
    if (keepHistory && sessionId != null) {
      final session = _sessions[sessionId];
      if (session != null && messages.isNotEmpty) {
        session.addMessage(messages.last);
        if (fullResponse.isNotEmpty) {
          session.addMessage(
            ChatMessage(role: 'assistant', content: fullResponse),
          );
        }
      }
    }
  }

  /// Sends a chat message and returns the full (non-streaming) response.
  Future<String> chatSync({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final stream = await _client.chat(
      model: model,
      messages: truncateMessages(messages),
      temperature: temperature,
      maxTokens: maxTokens,
      stream: false,
    );
    final chunks = await stream.toList();
    return chunks.join('');
  }

  // ---------------------------------------------------------------------------
  // Specialized Writing Features
  // ---------------------------------------------------------------------------

  /// Analyzes writing style of the given text.
  Future<String> analyzeStyle({
    required String text,
    String? modelId,
  }) async {
    final modelConfig = _resolveModel(modelId);
    if (modelConfig == null) {
      throw LiteLLMException('No model configured for style analysis');
    }

    final messages = [
      ChatMessage(
        role: 'system',
        content:
            'You are a style analysis assistant. Analyze the writing style of the given text and provide feedback on tone, voice, structure, and literary techniques.',
      ),
      ChatMessage(role: 'user', content: text),
    ];

    return chatSync(
      model: modelConfig.model,
      messages: messages,
      temperature: 0.3,
    );
  }

  /// Analyzes novel content (plot, characters, themes).
  Future<String> analyzeNovel({
    required String text,
    String? modelId,
  }) async {
    final modelConfig = _resolveModel(modelId);
    if (modelConfig == null) {
      throw LiteLLMException('No model configured for novel analysis');
    }

    final messages = [
      ChatMessage(
        role: 'system',
        content:
            'You are a novel analysis assistant. Analyze the given novel content for plot structure, character development, themes, pacing, and narrative techniques. Provide constructive feedback and suggestions.',
      ),
      ChatMessage(role: 'user', content: text),
    ];

    return chatSync(
      model: modelConfig.model,
      messages: messages,
      temperature: 0.3,
    );
  }

  /// Continues writing from the given text.
  Future<String> continueWriting({
    required String text,
    String? modelId,
  }) async {
    final modelConfig = _resolveModel(modelId);
    if (modelConfig == null) {
      throw LiteLLMException('No model configured for writing continuation');
    }

    final messages = [
      ChatMessage(
        role: 'system',
        content:
            'You are a creative writing assistant. Continue the given text naturally, maintaining the same style, tone, and narrative flow. Do not add any explanations or meta-text - just continue the writing.',
      ),
      ChatMessage(role: 'user', content: text),
    ];

    return chatSync(
      model: modelConfig.model,
      messages: messages,
      temperature: 0.8,
    );
  }

  /// Gets embeddings for the given text.
  Future<List<double>> getEmbedding({
    required String text,
    String? modelId,
  }) async {
    final modelConfig = _resolveModel(modelId);
    if (modelConfig == null) {
      throw LiteLLMException('No model configured for embeddings');
    }

    return _client.embed(
      model: modelConfig.model,
      input: text,
    );
  }

  /// Lists available models from the service and registry.
  Future<List<Map<String, dynamic>>> listModels() async {
    final registered = _modelConfigService.listModels();
    return registered
        .map((m) => {
              'id': m.id,
              'name': m.name,
              'type': m.type,
              'model': m.model,
              'enabled': m.enabled,
            })
        .toList();
  }

  /// Adds a new model from a map of parameters.
  Future<Map<String, dynamic>> addModel(Map<String, dynamic> modelData) async {
    final config = ModelConfig.fromJson(modelData);
    await _modelConfigService.addModel(config);
    return config.toJson();
  }

  /// Deletes a model by ID.
  Future<void> deleteModel(String modelId) async {
    await _modelConfigService.removeModel(modelId);
  }

  /// Sets the active model.
  Future<void> setActiveModel(String modelId) async {
    final model = _modelConfigService.setActiveModel(modelId);
    if (model == null) {
      throw LiteLLMException('Model not found: $modelId');
    }
  }

  /// Resolves the model configuration for a request.
  ModelConfig? _resolveModel(String? modelId) {
    if (modelId != null && modelId.isNotEmpty) {
      return _modelConfigService.getModel(modelId);
    }
    // Use active model or first enabled model
    if (_modelConfigService.activeModelId != null) {
      return _modelConfigService.getModel(_modelConfigService.activeModelId!);
    }
    return _modelConfigService.firstEnabledModel;
  }

  /// Generates a unique session ID.
  String _generateSessionId() {
    final random = Random().nextInt(1 << 32);
    final time = DateTime.now().millisecondsSinceEpoch;
    return 'session_${time}_$random';
  }
}