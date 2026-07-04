import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /style/analyze - analyzes writing style.
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
        content: 'You are a style analysis assistant. Analyze the writing style of the given text and provide feedback on tone, voice, structure, and literary techniques.',
      ),
      ChatMessage(role: 'user', content: text),
    ];

    final stream = await litellmClient.chat(
      model: modelConfig.model,
      messages: messages,
      temperature: 0.3,
    );

    final chunks = await stream.toList();
    final analysis = chunks.join('');

    return Response(
      body: jsonEncode({
        'text': text,
        'analysis': analysis,
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