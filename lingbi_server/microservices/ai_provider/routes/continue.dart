import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /continue - continues text generation from a prompt.
Response onRequest(RequestContext context) async {
  try {
    final body = await context.request.json as Map<String, dynamic>;
    final text = body['text'] as String? ?? '';
    final modelId = body['model'] as String? ?? '';

    final modelConfig = modelId.isNotEmpty
        ? modelConfigService.getModel(modelId)
        : modelConfigService.listModels().firstOrNull;

    if (modelConfig == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'No model configured'}),
      );
    }

    final messages = [
      ChatMessage(
        role: 'system',
        content:
            'You are a creative writing assistant. Continue the given text naturally, maintaining the same style, tone, and narrative flow. Do not add any explanations or meta-text - just continue the writing.',
      ),
      ChatMessage(role: 'user', content: text),
    ];

    final stream = await litellmClient.chat(
      model: modelConfig.model,
      messages: messages,
      temperature: 0.8,
    );

    final chunks = await stream.toList();
    final continuation = chunks.join('');

    return Response(
      body: jsonEncode({
        'text': text,
        'continuation': continuation,
        'model': modelConfig.model,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}