import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /novel/analyze - analyzes novel content (plot, characters, themes).
Response onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final body = await context.request.json as Map<String, dynamic>;
    final text = body['text'] as String? ?? '';
    final modelId = body['model'] as String? ?? '';

    if (text.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'text is required'}),
      );
    }

    final analysis = await chatService.analyzeNovel(
      text: text,
      modelId: modelId.isNotEmpty ? modelId : null,
    );

    return Response(
      body: jsonEncode({
        'text': text,
        'analysis': analysis,
        'model': modelId,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
