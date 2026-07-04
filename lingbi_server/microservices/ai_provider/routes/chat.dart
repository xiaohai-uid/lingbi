import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /chat - streams chat completions using SSE format.
/// Also handles GET /chat - returns dialog session info.
Response onRequest(RequestContext context) async {
  // Handle GET - list sessions
  if (context.request.method == HttpMethod.get) {
    try {
      final sessions = chatService.listSessions();
      return Response(
        body: jsonEncode({
          'sessions': sessions.map((s) => s.toJson()).toList(),
        }),
      );
    } catch (e) {
      return Response(
        statusCode: 500,
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  // Handle POST - chat completion
  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json as Map<String, dynamic>;
      final model = body['model'] ?? '';
      final messagesJson = body['messages'] as List;
      final temperature = (body['temperature'] as num?)?.toDouble() ?? 0.7;
      final maxTokens = (body['max_tokens'] as num?)?.toInt() ?? 2048;
      final stream = body['stream'] as bool? ?? true;
      final sessionId = body['session_id'] as String?;

      // Select model configuration
      final modelConfig = model.isNotEmpty
          ? modelConfigService.getModel(model)
          : modelConfigService.listModels().firstOrNull;

      if (modelConfig == null) {
        return Response(
          statusCode: 400,
          body: jsonEncode({'error': 'No model configured'}),
        );
      }

      final messages = messagesJson
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      if (!stream) {
        // Non-streaming response
        final content = await chatService.chatSync(
          model: modelConfig.model,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
        );

        return Response(
          body: jsonEncode({
            'id': 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}',
            'object': 'chat.completion',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'model': modelConfig.model,
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': content},
                'finish_reason': 'stop',
              }
            ],
            'usage': {
              'prompt_tokens': -1,
              'completion_tokens': -1,
              'total_tokens': -1,
            },
          }),
        );
      }

      // Streaming response using SSE
      final id = 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}';

      return Response.stream(
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'X-Accel-Buffering': 'no',
        },
        body: chatService
            .chat(
              model: modelConfig.model,
              messages: messages,
              temperature: temperature,
              maxTokens: maxTokens,
              sessionId: sessionId,
            )
            .map((chunk) {
          if (chunk == '[DONE]') {
            return 'data: [DONE]\n\n';
          }
          return 'data: ${jsonEncode({
            'id': id,
            'object': 'chat.completion.chunk',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'model': modelConfig.model,
            'choices': [
              {
                'index': 0,
                'delta': {'content': chunk},
                'finish_reason': null,
              }
            ],
          })}\n\n';
        }).asBroadcastStream(),
      );
    } catch (e) {
      return Response(
        statusCode: 500,
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  return Response(
    statusCode: 405,
    body: jsonEncode({'error': 'Method not allowed'}),
  );
}