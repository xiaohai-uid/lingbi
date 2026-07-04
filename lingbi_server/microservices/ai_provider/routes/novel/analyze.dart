import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /novel/analyze - analyzes novel content (plot, characters, themes).
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
            'You are a novel analysis assistant. Analyze the given novel content for plot structure, character development, themes, pacing, and narrative techniques. Provide constructive feedback and suggestions.',
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