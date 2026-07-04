import 'dart:convert';
import 'package:lingbi_server/models/chat_request.dart';
import 'package:lingbi_server/models/chat_response.dart';

class ChatService {
  // Mock implementation for testing
  // In production, this would connect to actual AI models
  
  Stream<ChatResponse> chatStream(ChatRequest request) async* {
    // Simulate streaming response
    final mockResponse = 'This is a mock streaming response for model: ${request.model}';
    final chunks = mockResponse.split(' ');
    
    for (var chunk in chunks) {
      yield ChatResponse(
        id: 'chatcmpl-test',
        object: 'chat.completion.chunk',
        created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        model: request.model,
        choices: [
          ChatChoice(
            index: 0,
            delta: Delta(content: '$chunk '),
            finishReason: null,
          ),
        ],
      );
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Stream<ChatResponse> styleAnalyzeStream(ChatRequest request) async* {
    // Style analysis mock
    yield ChatResponse(
      id: 'stylecmpl-test',
      object: 'chat.completion.chunk',
      created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: request.model,
      choices: [
        ChatChoice(
          index: 0,
          delta: Delta(content: 'Analyzing style...'),
          finishReason: null,
        ),
      ],
    );
  }

  Stream<ChatResponse> novelAnalyzeStream(ChatRequest request) async* {
    // Novel analysis mock
    yield ChatResponse(
      id: 'novelcmpl-test',
      object: 'chat.completion.chunk',
      created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: request.model,
      choices: [
        ChatChoice(
          index: 0,
          delta: Delta(content: 'Analyzing novel structure...'),
          finishReason: null,
        ),
      ],
    );
  }

  Stream<ChatResponse> continueWritingStream(ChatRequest request) async* {
    // Continue writing mock
    yield ChatResponse(
      id: 'continuecmpl-test',
      object: 'chat.completion.chunk',
      created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: request.model,
      choices: [
        ChatChoice(
          index: 0,
          delta: Delta(content: 'Continuing the story...'),
          finishReason: null,
        ),
      ],
    );
  }

  Future<List<double>> getEmbedding(String text) async {
    // Mock embedding
    return List<double>.generate(text.length, (i) => i.toDouble());
  }

  Future<List<Map<String, dynamic>>> listModels() async {
    // Mock models
    return [
      {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo', 'enabled': true},
      {'id': 'gpt-4', 'name': 'GPT-4', 'enabled': true},
      {'id': 'claude-3', 'name': 'Claude 3', 'enabled': true},
    ];
  }

  Future<Map<String, dynamic>> addModel(Map<String, dynamic> model) async {
    // Mock add model
    return model;
  }

  Future<void> deleteModel(String modelId) async {
    // Mock delete model
    print('Deleted model: $modelId');
  }

  Future<void> setActiveModel(String modelId) async {
    // Mock set active model
    print('Set active model: $modelId');
  }
}