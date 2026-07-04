import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /chat - streams chat completions using SSE format.
Response onRequest(RequestContext context) async {
  try {
    final body = await context.request.json as Map<String, dynamic>;
    final model = body['model'] ?? '';
    final messagesJson = body['messages'] as List;
    final temperature = (body['temperature'] as num?)?.toDouble() ?? 0.7;
    final maxTokens = (body['max_tokens'] as num?)?.toInt() ?? 2048;
    final stream = body['stream'] as bool? ?? true;

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
      final stream = await litellmClient.chat(
        model: modelConfig.model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        stream: false,
      );

      final chunks = await stream.toList();
      final content = chunks.join('');

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
        }),
      );
    }

    // Streaming response using SSE
    final stream = await litellmClient.chat(
      model: modelConfig.model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final id = 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}';

    return Response.stream(
      headers: {'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache'},
      body: Stream.fromFuture(
        stream.asyncMap(
          (chunk) async {
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
          },
        ).asBroadcastStream(),
      ),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}